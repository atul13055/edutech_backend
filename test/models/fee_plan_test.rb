require "test_helper"

class FeePlanTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "Branch Fee 1", subdomain: "b-fee1", code: "BFEE-100", status: "active")
    @tenant2 = Tenant.create!(name: "Branch Fee 2", subdomain: "b-fee2", code: "BFEE-200", status: "active")

    @course1 = Course.create!(tenant: @tenant1, name: "Fullstack Dev", code: "FS-101")
    @course2 = Course.create!(tenant: @tenant2, name: "Data Science", code: "DS-101")
  end

  test "validates required fields, decimal amount, and currency formatting" do
    plan = FeePlan.new
    assert_not plan.valid?
    assert_includes plan.errors[:name], "can't be blank"

    plan = FeePlan.create!(
      tenant: @tenant1,
      name: " Standard Annual Plan ",
      total_amount: 1200.50,
      currency: "INR"
    )

    assert_equal "Standard Annual Plan", plan.name
    assert_equal 1200.50, plan.total_amount
    assert_equal "INR", plan.currency
    assert_equal "active", plan.status
  end

  test "rejects negative total amount" do
    plan = FeePlan.new(tenant: @tenant1, name: "Invalid Plan", total_amount: -500.0)
    assert_not plan.valid?
    assert_includes plan.errors[:total_amount], "must be greater than or equal to 0"
  end

  test "validates tenant boundary on assigned course" do
    invalid_plan = FeePlan.new(
      tenant: @tenant1,
      name: "Cross Tenant Plan",
      course: @course2
    )

    assert_not invalid_plan.valid?
    assert_includes invalid_plan.errors[:course], "must belong to your tenant or be a global course"
  end
end
