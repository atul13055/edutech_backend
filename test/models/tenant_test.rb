require "test_helper"

class TenantTest < ActiveSupport::TestCase
  test "valid tenant creation" do
    tenant = Tenant.new(name: "Delhi Center", subdomain: "delhi-branch", code: "DEL-001")
    assert tenant.valid?
    assert_equal "active", tenant.status
    assert_equal "UTC", tenant.time_zone
  end

  test "validates required attributes" do
    tenant = Tenant.new
    assert_not tenant.valid?
    assert_includes tenant.errors[:name], "can't be blank"
    assert_includes tenant.errors[:subdomain], "can't be blank"
    assert_includes tenant.errors[:code], "can't be blank"
  end

  test "normalizes subdomain, code, contact_email, and contact_phone before validation" do
    tenant = Tenant.create!(
      name: "  Mumbai Branch  ",
      subdomain: "  MUMBAI-branch  ",
      code: "  mum-001  ",
      contact_email: "  CONTACT@MUMBAI.COM  ",
      contact_phone: "  +91 9876543210  "
    )

    assert_equal "mumbai-branch", tenant.subdomain
    assert_equal "MUM-001", tenant.code
    assert_equal "contact@mumbai.com", tenant.contact_email
    assert_equal "+91 9876543210", tenant.contact_phone
  end

  test "enforces uniqueness on subdomain and code case-insensitively" do
    Tenant.create!(name: "Center A", subdomain: "center-a", code: "C-001")

    duplicate = Tenant.new(name: "Center B", subdomain: "CENTER-A", code: "c-001")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:subdomain], "has already been taken"
    assert_includes duplicate.errors[:code], "has already been taken"
  end

  test "validates status inclusion" do
    tenant = Tenant.new(name: "Center C", subdomain: "center-c", code: "C-003", status: "invalid_status")
    assert_not tenant.valid?
    assert_includes tenant.errors[:status], "is not included in the list"
  end

  test "validates email format when provided" do
    tenant = Tenant.new(name: "Center D", subdomain: "center-d", code: "C-004", contact_email: "invalid-email")
    assert_not tenant.valid?
    assert_includes tenant.errors[:contact_email], "is invalid"
  end

  test "has_many associations clean up dependent records on deletion" do
    tenant = Tenant.create!(name: "Center E", subdomain: "center-e", code: "C-005")
    role = Role.create!(name: "Branch User", key: "branch_user", tenant: tenant)
    user = User.create!(first_name: "Test", email: "test.e@example.com", password: "password123", role: role, tenant: tenant)

    assert_difference "Tenant.count", -1 do
      assert_difference "User.count", -1 do
        assert_difference "Role.count", -1 do
          tenant.destroy!
        end
      end
    end
  end
end
