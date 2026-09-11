require "test_helper"

class FeePaymentBlueprintTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create!(name: "Branch Pay BP", subdomain: "b-pbp", code: "BPBP-100", status: "active")
    @student = Student.create!(tenant: @tenant, first_name: "Emma", roll_number: "STU-PBP1")
    @plan = FeePlan.create!(tenant: @tenant, name: "Blueprint Plan", total_amount: 8000.0, currency: "INR")
    @asg = StudentFeeAssignment.create!(tenant: @tenant, student: @student, fee_plan: @plan)

    @payment = FeePayment.create!(
      tenant: @tenant,
      student: @student,
      student_fee_assignment: @asg,
      amount: 4000.0,
      currency: "INR",
      payment_method: "upi",
      payment_reference: "UPI-BP-100",
      idempotency_key: "idem-bp-1"
    )
  end

  test "serializes fee payment attributes and associations" do
    json = FeePaymentBlueprint.render_as_hash(@payment)

    assert_equal @payment.id, json[:id]
    assert_equal "4000.0", json[:amount].to_s
    assert_equal "INR", json[:currency]
    assert_equal "upi", json[:payment_method]
    assert_equal "completed", json[:status]
    assert_equal "UPI-BP-100", json[:payment_reference]
    assert_equal "idem-bp-1", json[:idempotency_key]
    assert_equal "Emma", json[:student][:first_name]
  end
end
