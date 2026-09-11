require "test_helper"

class CurrentTest < ActiveSupport::TestCase
  test "sets and resets attributes" do
    tenant = Tenant.create!(name: "Test Center", subdomain: "test-center", code: "TC-001")
    role = Role.create!(name: "Admin", key: "admin")
    user = User.create!(first_name: "John", email: "john@example.com", password: "password123", role: role)

    Current.tenant = tenant
    Current.user = user

    assert_equal tenant, Current.tenant
    assert_equal user, Current.user

    Current.reset
    assert_nil Current.tenant
    assert_nil Current.user
  end
end
