require "test_helper"

class PaymentRefundTest < ActiveSupport::TestCase
  setup do
    @tenant = Tenant.create!(name: "Test Tenant M", subdomain: "test-m", code: "TTM-1", status: "active")
    @other_tenant = Tenant.create!(name: "Other Tenant M", subdomain: "other-m", code: "OTM-1", status: "active")

    @role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant)
    @user = User.create!(tenant: @tenant, role: @role, first_name: "Admin", email: "admin_m@example.com", password: "password123")
    @student = Student.create!(tenant: @tenant, first_name: "Alice", roll_number: "STU-M-1")
    @other_student = Student.create!(tenant: @other_tenant, first_name: "Bob", roll_number: "STU-M-2")

    @fee_plan = FeePlan.create!(tenant: @tenant, name: "Plan M", total_amount: 10000.0, currency: "INR")
    @assignment = StudentFeeAssignment.create!(tenant: @tenant, student: @student, fee_plan: @fee_plan)

    @fee_payment = FeePayment.create!(
      tenant: @tenant,
      student: @student,
      student_fee_assignment: @assignment,
      amount: 5000.0,
      currency: "INR",
      payment_method: "upi",
      status: "completed",
      idempotency_key: "fp-m-1",
      paid_at: Time.current
    )

    Current.tenant = @tenant
  end

  test "validates presence of amount, currency, reason, status, and idempotency_key" do
    refund = PaymentRefund.new
    assert_not refund.valid?
    assert_includes refund.errors[:amount], "can't be blank"
    assert_includes refund.errors[:reason], "can't be blank"
    assert_includes refund.errors[:idempotency_key], "can't be blank"
  end

  test "validates status transition state machine" do
    refund = PaymentRefund.create!(
      tenant: @tenant,
      fee_payment: @fee_payment,
      student: @student,
      student_fee_assignment: @assignment,
      requested_by: @user,
      amount: BigDecimal("500.00"),
      currency: "INR",
      reason: "Course cancellation",
      status: "requested",
      idempotency_key: "ref-sm-1"
    )

    assert refund.can_transition_to?("approved")
    assert refund.can_transition_to?("completed")
    assert refund.can_transition_to?("rejected")

    refund.transition_to!("approved")
    assert_equal "approved", refund.status
    assert_not_nil refund.approved_at

    refund.transition_to!("completed")
    assert_equal "completed", refund.status
    assert_not refund.can_transition_to?("requested")

    assert_raises(ArgumentError) do
      refund.transition_to!("requested")
    end
  end

  test "validates tenant boundary matching" do
    refund = PaymentRefund.new(
      tenant: @tenant,
      fee_payment: @fee_payment,
      student: @other_student,
      student_fee_assignment: @assignment,
      amount: BigDecimal("100.00"),
      currency: "INR",
      reason: "Test",
      idempotency_key: "ref-tb-1"
    )

    assert_not refund.valid?
    assert_includes refund.errors[:student], "must belong to your tenant"
  end
end
