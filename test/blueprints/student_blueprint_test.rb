require "test_helper"

class StudentBlueprintTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create!(name: "Branch Blueprint", subdomain: "b-bp-stu", code: "BBPSTU-100", status: "active")
    @student = Student.create!(
      tenant: @tenant,
      first_name: "Alice",
      last_name: "Smith",
      roll_number: "BP001",
      email: "alice@example.com",
      phone: "1234567890",
      status: "active"
    )
  end

  test "serializes expected fields and excludes sensitive data" do
    json = StudentBlueprint.render_as_hash(@student)

    assert_equal @student.id, json[:id]
    assert_equal @tenant.id, json[:tenant_id]
    assert_equal "BP001", json[:roll_number]
    assert_equal "Alice", json[:first_name]
    assert_equal "Smith", json[:last_name]
    assert_equal "Alice Smith", json[:full_name]
    assert_equal "alice@example.com", json[:email]
    assert_equal "active", json[:status]

    assert_nil json[:password_digest]
    assert_nil json[:token]
  end
end
