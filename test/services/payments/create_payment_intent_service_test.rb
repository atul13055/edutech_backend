require "test_helper"

module Payments
  class CreatePaymentIntentServiceTest < ActiveSupport::TestCase
    def setup
      @tenant = Tenant.create!(name: "Create Intent Branch", subdomain: "cre-intent", code: "CREINT-100", status: "active")
      @student = Student.create!(tenant: @tenant, first_name: "Alice", roll_number: "SA100")
      @plan = FeePlan.create!(tenant: @tenant, name: "Gold Plan", total_amount: 10000.0, currency: "INR")
      @asg = StudentFeeAssignment.create!(tenant: @tenant, student: @student, fee_plan: @plan)
      @user = User.create!(tenant: @tenant, role: Role.create!(name: "Admin Role", key: "branch_admin", tenant: @tenant), first_name: "Admin", email: "cre_intent_admin@example.com", password: "password123")
      Current.tenant = @tenant
    end

    def teardown
      Current.reset
    end

    test "creates payment intent without deducting assignment outstanding balance" do
      service = CreatePaymentIntentService.new({
        student_fee_assignment_id: @asg.id,
        amount: 4000.0,
        currency: "INR",
        payment_method: "upi",
        idempotency_key: "svc-intent-1"
      }, user: @user)

      intent = service.call
      assert intent.persisted?
      assert_equal "created", intent.status
      assert_equal BigDecimal("4000.0"), intent.amount
      assert_equal BigDecimal("10000.0"), @asg.reload.outstanding_amount
    end

    test "idempotently replays identical request key with matching payload" do
      params = {
        student_fee_assignment_id: @asg.id,
        amount: 3000.0,
        currency: "INR",
        payment_method: "cash",
        idempotency_key: "svc-intent-replay"
      }

      intent1 = CreatePaymentIntentService.new(params, user: @user).call
      intent2 = CreatePaymentIntentService.new(params, user: @user).call

      assert_equal intent1.id, intent2.id
    end

    test "raises IdempotencyConflictError when same key used with different payload" do
      params1 = {
        student_fee_assignment_id: @asg.id,
        amount: 3000.0,
        currency: "INR",
        payment_method: "cash",
        idempotency_key: "svc-intent-conflict"
      }
      CreatePaymentIntentService.new(params1, user: @user).call

      params2 = params1.merge(amount: 5000.0)
      assert_raises(CreatePaymentIntentService::IdempotencyConflictError) do
        CreatePaymentIntentService.new(params2, user: @user).call
      end
    end

    test "rejects intent creation exceeding assignment outstanding amount" do
      params = {
        student_fee_assignment_id: @asg.id,
        amount: 15000.0,
        currency: "INR",
        payment_method: "upi",
        idempotency_key: "svc-overpay-intent"
      }

      assert_raises(Fees::PaymentCollectionService::OverpaymentError) do
        CreatePaymentIntentService.new(params, user: @user).call
      end
    end
  end
end
