require "test_helper"

module Payments
  class ReconciliationServiceTest < ActiveSupport::TestCase
    def setup
      @tenant = Tenant.create!(name: "Reconcile Branch", subdomain: "rec-intent", code: "RECINT-100", status: "active")
      @student = Student.create!(tenant: @tenant, first_name: "David", roll_number: "SD100")
      @plan = FeePlan.create!(tenant: @tenant, name: "Plan R", total_amount: 12000.0, currency: "INR")
      @asg = StudentFeeAssignment.create!(tenant: @tenant, student: @student, fee_plan: @plan)
      @user = User.create!(tenant: @tenant, role: Role.create!(name: "Admin Role", key: "branch_admin", tenant: @tenant), first_name: "Admin", email: "rec_admin@example.com", password: "password123")
      Current.tenant = @tenant

      @intent = PaymentIntent.create!(
        tenant: @tenant,
        student: @student,
        student_fee_assignment: @asg,
        amount: 6000.0,
        currency: "INR",
        payment_method: "upi",
        idempotency_key: "rec-intent-1",
        status: "unknown",
        unknown_at: Time.current
      )
    end

    def teardown
      Current.reset
    end

    test "reconciles unknown intent to succeeded and finalizes FeePayment" do
      reconciled = ReconciliationService.new(
        @intent.id,
        result_status: "succeeded",
        provider_transaction_id: "TXN-REC-777",
        user: @user
      ).call

      assert_equal "reconciled", reconciled.status
      assert_not_nil reconciled.reconciled_at

      @intent.reload
      assert_not_nil @intent.fee_payment_id
      assert_equal BigDecimal("6000.0"), @asg.reload.total_paid_amount
    end

    test "reconciles unknown intent to failed" do
      reconciled = ReconciliationService.new(
        @intent.id,
        result_status: "failed",
        failure_code: "BANK_DECLINED",
        failure_message: "Insufficient funds in bank account",
        user: @user
      ).call

      assert_equal "reconciled", reconciled.status
      assert_nil reconciled.fee_payment_id
      assert_equal BigDecimal("0.0"), @asg.reload.total_paid_amount
    end
  end
end
