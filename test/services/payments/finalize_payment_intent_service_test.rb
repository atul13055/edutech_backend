require "test_helper"

module Payments
  class FinalizePaymentIntentServiceTest < ActiveSupport::TestCase
    def setup
      @tenant = Tenant.create!(name: "Finalize Branch", subdomain: "fin-intent", code: "FININT-100", status: "active")
      @student = Student.create!(tenant: @tenant, first_name: "Bob", roll_number: "SB100")
      @plan = FeePlan.create!(tenant: @tenant, name: "Silver Plan", total_amount: 8000.0, currency: "INR")
      @asg = StudentFeeAssignment.create!(tenant: @tenant, student: @student, fee_plan: @plan)
      @user = User.create!(tenant: @tenant, role: Role.create!(name: "Admin Role", key: "branch_admin", tenant: @tenant), first_name: "Admin", email: "fin_intent_admin@example.com", password: "password123")
      Current.tenant = @tenant

      @intent = PaymentIntent.create!(
        tenant: @tenant,
        student: @student,
        student_fee_assignment: @asg,
        amount: 4000.0,
        currency: "INR",
        payment_method: "upi",
        idempotency_key: "fin-test-intent-1",
        created_by: @user
      )
    end

    def teardown
      Current.reset
    end

    test "finalizes payment intent and creates single FeePayment" do
      payment = FinalizePaymentIntentService.new(@intent, provider_transaction_id: "TXN-FIN-100", user: @user).call

      assert payment.persisted?
      assert_equal "completed", payment.status
      assert_equal BigDecimal("4000.0"), payment.amount

      @intent.reload
      assert_equal "succeeded", @intent.status
      assert_equal payment.id, @intent.fee_payment_id
      assert_equal "TXN-FIN-100", @intent.provider_transaction_id
      assert_equal BigDecimal("4000.0"), @asg.reload.total_paid_amount
    end

    test "subsequent finalization calls on already finalized intent return existing FeePayment idempotently" do
      payment1 = FinalizePaymentIntentService.new(@intent, provider_transaction_id: "TXN-FIN-100", user: @user).call
      payment2 = FinalizePaymentIntentService.new(@intent, provider_transaction_id: "TXN-FIN-100", user: @user).call

      assert_equal payment1.id, payment2.id
      assert_equal 1, FeePayment.where(student_fee_assignment_id: @asg.id).count
    end

    test "prevents race condition under concurrent finalization attempts" do
      t1 = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Current.tenant = @tenant
          FinalizePaymentIntentService.new(@intent, provider_transaction_id: "TXN-CONC-1", user: @user).call
        end
      end

      t2 = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Current.tenant = @tenant
          FinalizePaymentIntentService.new(@intent, provider_transaction_id: "TXN-CONC-2", user: @user).call
        end
      end

      p1 = t1.value
      p2 = t2.value

      assert_equal p1.id, p2.id
      assert_equal 1, FeePayment.where(student_fee_assignment_id: @asg.id).count
    end
  end
end
