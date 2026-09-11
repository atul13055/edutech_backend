require "test_helper"

module Fees
  class CreateRefundServiceTest < ActiveSupport::TestCase
    setup do
      @tenant = Tenant.create!(name: "Test Tenant CRS", subdomain: "test-crs", code: "TT-CRS-1", status: "active")
      @role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant)
      @user = User.create!(tenant: @tenant, role: @role, first_name: "Admin", email: "admin_crs@example.com", password: "password123")
      @student = Student.create!(tenant: @tenant, first_name: "Charlie", roll_number: "STU-CRS-1")

      @fee_plan = FeePlan.create!(tenant: @tenant, name: "Plan CRS", total_amount: 10000.0, currency: "INR")
      @assignment = StudentFeeAssignment.create!(tenant: @tenant, student: @student, fee_plan: @fee_plan)

      @fee_payment = FeePayment.create!(
        tenant: @tenant,
        student: @student,
        student_fee_assignment: @assignment,
        amount: 5000.0,
        currency: "INR",
        payment_method: "upi",
        status: "completed",
        idempotency_key: "fp-crs-1",
        paid_at: Time.current
      )

      Current.tenant = @tenant
    end

    test "successfully creates a payment refund request" do
      service = CreateRefundService.new({
        fee_payment_id: @fee_payment.id,
        amount: "1000.00",
        currency: "INR",
        reason: "Overcharged fee",
        idempotency_key: "ref-test-1"
      }, user: @user)

      refund = service.call

      assert_equal "requested", refund.status
      assert_equal BigDecimal("1000.00"), refund.amount
      assert_equal "INR", refund.currency
      assert_equal @fee_payment.id, refund.fee_payment_id
      assert_equal @user.id, refund.requested_by_id
    end

    test "replaces idempotency replay with same record" do
      params = {
        fee_payment_id: @fee_payment.id,
        amount: "1000.00",
        currency: "INR",
        reason: "Overcharged fee",
        idempotency_key: "ref-test-idempotent"
      }

      refund1 = CreateRefundService.new(params, user: @user).call
      refund2 = CreateRefundService.new(params, user: @user).call

      assert_equal refund1.id, refund2.id
    end

    test "raises IdempotencyConflictError when payload differs for same key" do
      params1 = {
        fee_payment_id: @fee_payment.id,
        amount: "1000.00",
        currency: "INR",
        reason: "Overcharged fee",
        idempotency_key: "ref-test-conflict"
      }

      params2 = params1.merge(amount: "2000.00")

      CreateRefundService.new(params1, user: @user).call

      assert_raises(CreateRefundService::IdempotencyConflictError) do
        CreateRefundService.new(params2, user: @user).call
      end
    end

    test "rejects refund if amount exceeds payment refundable balance" do
      service = CreateRefundService.new({
        fee_payment_id: @fee_payment.id,
        amount: "6000.00",
        currency: "INR",
        reason: "Invalid amount",
        idempotency_key: "ref-test-overrefund"
      }, user: @user)

      assert_raises(CreateRefundService::OverRefundError) do
        service.call
      end
    end

    test "rejects refund if currency does not match payment currency" do
      service = CreateRefundService.new({
        fee_payment_id: @fee_payment.id,
        amount: "500.00",
        currency: "USD",
        reason: "Currency test",
        idempotency_key: "ref-test-currency"
      }, user: @user)

      assert_raises(CreateRefundService::CurrencyMismatchError) do
        service.call
      end
    end
  end
end
