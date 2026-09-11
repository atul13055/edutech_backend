require "test_helper"

module Fees
  class PaymentCollectionServiceTest < ActiveSupport::TestCase
    def setup
      @tenant1 = Tenant.create!(name: "Branch Serv 1", subdomain: "b-serv1", code: "BSERV-100", status: "active")
      @tenant2 = Tenant.create!(name: "Branch Serv 2", subdomain: "b-serv2", code: "BSERV-200", status: "active")

      @admin_role1 = Role.create!(name: "Admin Role 1", key: "branch_admin", tenant: @tenant1)
      @collector1 = User.create!(tenant: @tenant1, role: @admin_role1, first_name: "Collector", email: "collector_serv@example.com", password: "password123")

      @student1 = Student.create!(tenant: @tenant1, first_name: "Charlie", roll_number: "STU-SERV1")
      @plan1 = FeePlan.create!(tenant: @tenant1, name: "Semester Plan", total_amount: 10000.0, currency: "INR")
      @inst1 = FeeInstallment.create!(tenant: @tenant1, fee_plan: @plan1, installment_number: 1, amount: 5000.0)

      @asg1 = StudentFeeAssignment.create!(tenant: @tenant1, student: @student1, fee_plan: @plan1)
    end

    test "successfully collects partial payment" do
      payment = PaymentCollectionService.call({
        student_fee_assignment_id: @asg1.id,
        amount: 4000.0,
        currency: "INR",
        payment_method: "upi",
        idempotency_key: "serv-idem-1"
      }, collector: @collector1)

      assert_equal 4000.0, payment.amount
      assert_equal "completed", payment.status
      assert_equal @collector1.id, payment.collected_by_id
      assert_equal 6000.0, @asg1.reload.outstanding_amount
      assert_equal "active", @asg1.status
    end

    test "successfully completes assignment on exact final payment" do
      PaymentCollectionService.call({
        student_fee_assignment_id: @asg1.id,
        amount: 6000.0,
        currency: "INR",
        payment_method: "cash",
        idempotency_key: "serv-idem-part1"
      }, collector: @collector1)

      final_payment = PaymentCollectionService.call({
        student_fee_assignment_id: @asg1.id,
        amount: 4000.0,
        currency: "INR",
        payment_method: "bank_transfer",
        idempotency_key: "serv-idem-part2"
      }, collector: @collector1)

      assert_equal 4000.0, final_payment.amount
      assert_equal 0.0, @asg1.reload.outstanding_amount
      assert_equal "completed", @asg1.status
    end

    test "rejects overpayment" do
      assert_raises(PaymentCollectionService::OverpaymentError) do
        PaymentCollectionService.call({
          student_fee_assignment_id: @asg1.id,
          amount: 15000.0,
          currency: "INR",
          payment_method: "cash",
          idempotency_key: "serv-idem-over"
        }, collector: @collector1)
      end
    end

    test "rejects currency mismatch" do
      assert_raises(PaymentCollectionService::CurrencyMismatchError) do
        PaymentCollectionService.call({
          student_fee_assignment_id: @asg1.id,
          amount: 1000.0,
          currency: "USD",
          payment_method: "cash",
          idempotency_key: "serv-idem-curr-mismatch"
        }, collector: @collector1)
      end
    end

    test "rejects cross tenant assignment" do
      assert_raises(PaymentCollectionService::CrossTenantError) do
        PaymentCollectionService.call({
          student_fee_assignment_id: @asg1.id,
          amount: 1000.0,
          currency: "INR",
          payment_method: "cash",
          idempotency_key: "serv-idem-cross"
        }, collector: @collector1, tenant_id: @tenant2.id)
      end
    end

    test "returns original payment safely on idempotent retry with identical payload" do
      p1 = PaymentCollectionService.call({
        student_fee_assignment_id: @asg1.id,
        amount: 3000.0,
        currency: "INR",
        payment_method: "upi",
        idempotency_key: "serv-idem-retry"
      }, collector: @collector1)

      p2 = PaymentCollectionService.call({
        student_fee_assignment_id: @asg1.id,
        amount: 3000.0,
        currency: "INR",
        payment_method: "upi",
        idempotency_key: "serv-idem-retry"
      }, collector: @collector1)

      assert_equal p1.id, p2.id
      assert_equal 1, FeePayment.where(idempotency_key: "serv-idem-retry").count
    end

    test "raises IdempotencyConflictError when same key is used with different payload" do
      PaymentCollectionService.call({
        student_fee_assignment_id: @asg1.id,
        amount: 3000.0,
        currency: "INR",
        payment_method: "upi",
        idempotency_key: "serv-idem-conflict"
      }, collector: @collector1)

      assert_raises(PaymentCollectionService::IdempotencyConflictError) do
        PaymentCollectionService.call({
          student_fee_assignment_id: @asg1.id,
          amount: 5000.0,
          currency: "INR",
          payment_method: "upi",
          idempotency_key: "serv-idem-conflict"
        }, collector: @collector1)
      end
    end

    test "creates installment allocation record when valid installment provided" do
      payment = PaymentCollectionService.call({
        student_fee_assignment_id: @asg1.id,
        fee_installment_id: @inst1.id,
        amount: 5000.0,
        currency: "INR",
        payment_method: "cheque",
        idempotency_key: "serv-idem-alloc"
      }, collector: @collector1)

      assert_equal 1, payment.fee_payment_allocations.count
      assert_equal @inst1.id, payment.fee_payment_allocations.first.fee_installment_id
      assert_equal 5000.0, payment.fee_payment_allocations.first.amount
    end

    test "prevents race condition overpayment under concurrent requests" do
      # Total amount is 10,000.
      # Request A attempts 7,000 and Request B attempts 5,000 concurrently.
      # Only one should succeed, while the second must fail with OverpaymentError.

      results = []
      t1 = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          results << PaymentCollectionService.call({
            student_fee_assignment_id: @asg1.id,
            amount: 7000.0,
            currency: "INR",
            payment_method: "upi",
            idempotency_key: "race-idem-A"
          }, collector: @collector1)
        rescue => e
          results << e
        end
      end

      t2 = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          results << PaymentCollectionService.call({
            student_fee_assignment_id: @asg1.id,
            amount: 5000.0,
            currency: "INR",
            payment_method: "cash",
            idempotency_key: "race-idem-B"
          }, collector: @collector1)
        rescue => e
          results << e
        end
      end

      t1.join
      t2.join

      successful_payments = results.select { |r| r.is_a?(FeePayment) }
      overpayment_errors = results.select { |r| r.is_a?(PaymentCollectionService::OverpaymentError) }

      assert_equal 1, successful_payments.length
      assert_equal 1, overpayment_errors.length
      assert_operator @asg1.reload.total_paid_amount, :<=, 10000.0
    end
  end
end
