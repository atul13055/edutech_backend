require "test_helper"

class PaymentIntentTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "Branch 1 Intent", subdomain: "b1-intent", code: "B1INT-100", status: "active")
    @tenant2 = Tenant.create!(name: "Branch 2 Intent", subdomain: "b2-intent", code: "B2INT-100", status: "active")

    @student1 = Student.create!(tenant: @tenant1, first_name: "John", roll_number: "S1001")
    @plan1 = FeePlan.create!(tenant: @tenant1, name: "Plan 1", total_amount: 10000.0, currency: "INR")
    @asg1 = StudentFeeAssignment.create!(tenant: @tenant1, student: @student1, fee_plan: @plan1)
  end

  test "validates required attributes and tenant boundary" do
    intent = PaymentIntent.new(
      tenant: @tenant1,
      student: @student1,
      student_fee_assignment: @asg1,
      amount: 5000.0,
      currency: "INR",
      payment_method: "upi",
      idempotency_key: "intent-key-1"
    )
    assert intent.valid?
  end

  test "rejects negative or zero amount" do
    intent = PaymentIntent.new(
      tenant: @tenant1,
      student: @student1,
      student_fee_assignment: @asg1,
      amount: 0,
      payment_method: "cash",
      idempotency_key: "zero-amt"
    )
    assert_not intent.valid?
    assert_includes intent.errors[:amount], "must be greater than 0"
  end

  test "enforces valid status transition state machine" do
    intent = PaymentIntent.create!(
      tenant: @tenant1,
      student: @student1,
      student_fee_assignment: @asg1,
      amount: 5000.0,
      currency: "INR",
      payment_method: "upi",
      idempotency_key: "trans-key-1"
    )
    assert_equal "created", intent.status

    assert intent.transition_to!("pending")
    assert_equal "pending", intent.status

    assert intent.transition_to!("succeeded")
    assert_equal "succeeded", intent.status
    assert_not_nil intent.succeeded_at

    # Invalid transition: succeeded -> pending
    assert_raises(ArgumentError) do
      intent.transition_to!("pending")
    end
  end

  test "rejects cross-tenant student assignment" do
    student2 = Student.create!(tenant: @tenant2, first_name: "Jane", roll_number: "S1002")
    intent = PaymentIntent.new(
      tenant: @tenant1,
      student: student2,
      student_fee_assignment: @asg1,
      amount: 2000.0,
      payment_method: "cash",
      idempotency_key: "cross-tenant-intent"
    )
    assert_not intent.valid?
    assert_includes intent.errors[:student], "must belong to your tenant"
  end
end
