require "test_helper"

module Fees
  class ProcessRefundServiceTest < ActiveSupport::TestCase
    setup do
      @tenant = Tenant.create!(name: "Test Tenant PRS", subdomain: "test-prs", code: "TT-PRS-1", status: "active")
      @role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant)
      @user = User.create!(tenant: @tenant, role: @role, first_name: "Admin", email: "admin_prs@example.com", password: "password123")
      @student = Student.create!(tenant: @tenant, first_name: "David", roll_number: "STU-PRS-1")

      @fee_plan = FeePlan.create!(tenant: @tenant, name: "Plan PRS", total_amount: 10000.0, currency: "INR")
      @assignment = StudentFeeAssignment.create!(tenant: @tenant, student: @student, fee_plan: @fee_plan)

      @fee_payment = FeePayment.create!(
        tenant: @tenant,
        student: @student,
        student_fee_assignment: @assignment,
        amount: 5000.0,
        currency: "INR",
        payment_method: "upi",
        status: "completed",
        idempotency_key: "fp-prs-1",
        paid_at: Time.current
      )

      Current.tenant = @tenant
    end

    test "completes refund and adjusts assignment outstanding balance without mutating original payment" do
      initial_paid = @assignment.total_paid_amount
      initial_outstanding = @assignment.outstanding_amount
      initial_payment_amount = @fee_payment.amount

      refund = CreateRefundService.new({
        fee_payment_id: @fee_payment.id,
        amount: "2000.00",
        currency: "INR",
        reason: "Partial refund",
        idempotency_key: "ref-proc-1"
      }, user: @user).call

      processed = ProcessRefundService.new(refund.id, user: @user).call

      assert_equal "completed", processed.status
      assert_equal BigDecimal("2000.00"), @fee_payment.reload.total_refunded_amount
      assert_equal BigDecimal("3000.00"), @fee_payment.refundable_amount

      # Verify original payment is IMMUTABLE
      assert_equal initial_payment_amount, @fee_payment.amount
      assert_equal "completed", @fee_payment.status

      # Verify assignment updated correctly
      @assignment.reload
      assert_equal initial_paid - BigDecimal("2000.00"), @assignment.net_paid_amount
      assert_equal initial_outstanding + BigDecimal("2000.00"), @assignment.outstanding_amount
    end

    test "prevents race condition under concurrent refund processing" do
      refund1 = CreateRefundService.new({
        fee_payment_id: @fee_payment.id,
        amount: "4000.00",
        currency: "INR",
        reason: "Refund candidate 1",
        idempotency_key: "ref-conc-1"
      }, user: @user).call

      refund2 = CreateRefundService.new({
        fee_payment_id: @fee_payment.id,
        amount: "3000.00",
        currency: "INR",
        reason: "Refund candidate 2",
        idempotency_key: "ref-conc-2"
      }, user: @user).call

      t1 = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Current.tenant = @tenant
          ProcessRefundService.new(refund1.id, user: @user).call
        end
      end

      t2 = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Current.tenant = @tenant
          ProcessRefundService.new(refund2.id, user: @user).call
        end
      end

      results = [ t1, t2 ].map do |t|
        t.join
        t.value
      rescue => e
        e
      end

      successes = results.select { |r| r.is_a?(PaymentRefund) }
      errors = results.select { |r| r.is_a?(CreateRefundService::OverRefundError) }

      assert_equal 1, successes.size
      assert_equal 1, errors.size
      assert_operator @fee_payment.reload.total_refunded_amount, :<=, BigDecimal("5000.00")
    end
  end
end
