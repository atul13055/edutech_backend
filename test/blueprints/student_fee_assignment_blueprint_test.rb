require "test_helper"

class StudentFeeAssignmentBlueprintTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create!(name: "Branch Asg Blueprint", subdomain: "b-abp", code: "BABP-200", status: "active")
    @student = Student.create!(tenant: @tenant, first_name: "Diana", roll_number: "ROLL-D1")
    @plan = FeePlan.create!(tenant: @tenant, name: "Degree Plan", total_amount: 8000.0, currency: "INR")

    @asg = StudentFeeAssignment.create!(
      tenant: @tenant,
      student: @student,
      fee_plan: @plan,
      notes: "Assigned during orientation"
    )
  end

  test "serializes assignment attributes and associations" do
    json = StudentFeeAssignmentBlueprint.render_as_hash(@asg)

    assert_equal @asg.id, json[:id]
    assert_equal "8000.0", json[:total_amount].to_s
    assert_equal "Diana", json[:student][:first_name]
    assert_equal "Degree Plan", json[:fee_plan][:name]
    assert_equal "Assigned during orientation", json[:notes]
  end
end
