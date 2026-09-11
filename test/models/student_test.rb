require "test_helper"

class StudentTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "Branch 1", subdomain: "b1-stu-mod", code: "B1STUM-100", status: "active")
    @tenant2 = Tenant.create!(name: "Branch 2", subdomain: "b2-stu-mod", code: "B2STUM-100", status: "active")
  end

  test "validates required fields" do
    student = Student.new(tenant: @tenant1)
    assert_not student.valid?
    assert_includes student.errors[:first_name], "can't be blank"
    assert_includes student.errors[:roll_number], "can't be blank"
  end

  test "enforces roll_number uniqueness per tenant" do
    Student.create!(tenant: @tenant1, first_name: "John", roll_number: "ROLL001")

    duplicate = Student.new(tenant: @tenant1, first_name: "Jane", roll_number: "ROLL001")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:roll_number], "has already been taken"

    other_tenant_student = Student.new(tenant: @tenant2, first_name: "Jane", roll_number: "ROLL001")
    assert other_tenant_student.valid?
  end

  test "normalizes attributes on validation" do
    student = Student.create!(
      tenant: @tenant1,
      first_name: "  John  ",
      last_name: "  Doe  ",
      roll_number: "  roll002  ",
      email: "  JOHN.DOE@EXAMPLE.COM  ",
      gender: " MALE "
    )

    assert_equal "John", student.first_name
    assert_equal "Doe", student.last_name
    assert_equal "ROLL002", student.roll_number
    assert_equal "john.doe@example.com", student.email
    assert_equal "male", student.gender
    assert_equal "active", student.status
  end

  test "validates status inclusion" do
    student = Student.new(tenant: @tenant1, first_name: "Test", roll_number: "R1", status: "invalid_status")
    assert_not student.valid?
    assert_includes student.errors[:status], "is not included in the list"
  end
end
