require "test_helper"

class FeePlanBlueprintTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create!(name: "Branch Fee Blueprint", subdomain: "b-fbp", code: "BFBP-100", status: "active")
    @course = Course.create!(tenant: @tenant, name: "Web Engineering", code: "WE-101")

    @plan = FeePlan.create!(
      tenant: @tenant,
      course: @course,
      name: "Engineering Plan",
      description: "Full degree fee",
      total_amount: 4000.0,
      currency: "INR",
      installment_count: 2
    )

    @inst1 = FeeInstallment.create!(tenant: @tenant, fee_plan: @plan, installment_number: 1, amount: 2000.0)
    @inst2 = FeeInstallment.create!(tenant: @tenant, fee_plan: @plan, installment_number: 2, amount: 2000.0)
  end

  test "serializes fee plan attributes, course, and installments" do
    json = FeePlanBlueprint.render_as_hash(@plan)

    assert_equal @plan.id, json[:id]
    assert_equal "Engineering Plan", json[:name]
    assert_equal "4000.0", json[:total_amount].to_s
    assert_equal "WE-101", json[:course][:code]
    assert_equal 2, json[:fee_installments].length
  end
end
