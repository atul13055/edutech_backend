require "test_helper"

class CourseBlueprintTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create!(name: "Branch Blueprint", subdomain: "b-bp-crs", code: "BBPCRS-100", status: "active")
    @course = Course.create!(
      tenant: @tenant,
      name: "Tally Prime",
      code: "TALLY001",
      description: "Complete accounting course",
      duration_months: 3,
      base_fee: 4500.00,
      status: "active"
    )
    @global_course = Course.create!(
      tenant: nil,
      name: "Master DCA",
      code: "DCA001",
      duration_months: 6,
      base_fee: 8000.00
    )
  end

  test "serializes course attributes correctly" do
    json = CourseBlueprint.render_as_hash(@course)

    assert_equal @course.id, json[:id]
    assert_equal @tenant.id, json[:tenant_id]
    assert_equal "Tally Prime", json[:name]
    assert_equal "TALLY001", json[:code]
    assert_equal 3, json[:duration_months]
    assert_equal 4500.00, json[:base_fee]
    assert_equal false, json[:is_global]
  end

  test "correctly marks global course as is_global: true" do
    json = CourseBlueprint.render_as_hash(@global_course)

    assert_nil json[:tenant_id]
    assert_equal true, json[:is_global]
    assert_equal "Master DCA", json[:name]
  end
end
