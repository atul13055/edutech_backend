require "test_helper"

class FeePaymentTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "Branch Pay 1", subdomain: "b-pay1", code: "BPAY-100", status: "active")
    @tenant2 = Tenant.create!(name: "Branch Pay 2", subdomain: "b-pay2", code: "BPAY-200", status: "active")

    @student1 = Student.create!(tenant: @tenant1, first_name: "Alice", roll_number: "STU-PAY1")
    @student2 = Student.create!(tenant: @tenant2, first_name: "Bob", roll_number: "STU-PAY2")

    @plan1 = FeePlan.create!(tenant: @tenant1, name: "Plan A", total_amount: 10000.0, currency: "INR")
    @asg1 = StudentFeeAssignment.create!(tenant: @tenant1, student: @student1, fee_plan: @plan1)
  end

  test "valid fee payment" do
    payment = FeePayment.new(
      tenant: @tenant1,
      student: @student1,
      student_fee_assignment: @asg1,
      amount: 5000.0,
      currency: "INR",
      payment_method: "upi",
      idempotency_key: "idem-001",
      paid_at: Time.current
    )
    assert payment.valid?
  end

  test "validates positive amount" do
    payment = FeePayment.new(
      tenant: @tenant1,
      student: @student1,
      student_fee_assignment: @asg1,
      amount: 0.0,
      currency: "INR",
      payment_method: "cash",
      idempotency_key: "idem-zero"
    )
    assert_not payment.valid?
    assert_includes payment.errors[:amount], "must be greater than 0"
  end

  test "validates payment method inclusion" do
    payment = FeePayment.new(
      tenant: @tenant1,
      student: @student1,
      student_fee_assignment: @asg1,
      amount: 1000.0,
      currency: "INR",
      payment_method: "crypto",
      idempotency_key: "idem-invalid-method"
    )
    assert_not payment.valid?
    assert_includes payment.errors[:payment_method], "is not included in the list"
  end

  test "validates currency matches assignment" do
    payment = FeePayment.new(
      tenant: @tenant1,
      student: @student1,
      student_fee_assignment: @asg1,
      amount: 1000.0,
      currency: "USD",
      payment_method: "upi",
      idempotency_key: "idem-bad-curr"
    )
    assert_not payment.valid?
    assert_includes payment.errors[:currency], "must match assignment currency (INR)"
  end

  test "prevents cross tenant student assignment payment" do
    payment = FeePayment.new(
      tenant: @tenant1,
      student: @student2,
      student_fee_assignment: @asg1,
      amount: 1000.0,
      payment_method: "cash",
      idempotency_key: "idem-cross-student"
    )
    assert_not payment.valid?
    assert_includes payment.errors[:student], "must belong to your tenant"
  end

  test "enforces immutability of completed payment on update" do
    payment = FeePayment.create!(
      tenant: @tenant1,
      student: @student1,
      student_fee_assignment: @asg1,
      amount: 4000.0,
      currency: "INR",
      payment_method: "bank_transfer",
      idempotency_key: "idem-immutable"
    )

    payment.amount = 2000.0
    assert_not payment.valid?
    assert_includes payment.errors[:base], "Completed fee payments are immutable and cannot be modified"
  end

  test "prevents destruction of completed payment" do
    payment = FeePayment.create!(
      tenant: @tenant1,
      student: @student1,
      student_fee_assignment: @asg1,
      amount: 3000.0,
      currency: "INR",
      payment_method: "cash",
      idempotency_key: "idem-no-destroy"
    )

    assert_raises(ActiveRecord::RecordNotDestroyed) do
      payment.destroy!
    end
  end
end
