require "test_helper"

class CourseTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "Branch 1", subdomain: "b1-crs-mod", code: "B1CRS-100", status: "active")
    @tenant2 = Tenant.create!(name: "Branch 2", subdomain: "b2-crs-mod", code: "B2CRS-100", status: "active")
  end

  test "validates required fields" do
    course = Course.new
    assert_not course.valid?
    assert_includes course.errors[:name], "can't be blank"
    assert_includes course.errors[:code], "can't be blank"
  end

  test "enforces course code uniqueness per tenant" do
    Course.create!(tenant: @tenant1, name: "Web Dev", code: "WEB101", duration_months: 3, base_fee: 500)

    duplicate = Course.new(tenant: @tenant1, name: "Web Dev 2", code: "WEB101")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:code], "has already been taken"

    other_tenant_course = Course.new(tenant: @tenant2, name: "Web Dev 2", code: "WEB101")
    assert other_tenant_course.valid?
  end

  test "supports global courses with null tenant_id" do
    global_course = Course.create!(tenant: nil, name: "DCA", code: "DCA100", duration_months: 6, base_fee: 1000)
    assert global_course.valid?
    assert_nil global_course.tenant_id
    assert_includes Course.global, global_course
  end

  test "normalizes code and default values" do
    course = Course.create!(
      tenant: @tenant1,
      name: "  Python Basics  ",
      code: "  py101  ",
      duration_months: nil,
      base_fee: nil
    )

    assert_equal "PY101", course.code
    assert_equal "Python Basics", course.name
    assert_equal 1, course.duration_months
    assert_equal 0.0, course.base_fee
    assert_equal "active", course.status
  end

  test "validates numeric constraints" do
    course = Course.new(tenant: @tenant1, name: "Java", code: "JAVA101", duration_months: 0, base_fee: -10)
    assert_not course.valid?
    assert_includes course.errors[:duration_months], "must be greater than 0"
    assert_includes course.errors[:base_fee], "must be greater than or equal to 0"
  end
end
