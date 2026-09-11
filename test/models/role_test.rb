require "test_helper"

class RoleTest < ActiveSupport::TestCase
  test "valid global role creation" do
    role = Role.new(name: "Super Admin", key: "super_admin")
    assert role.valid?
  end

  test "valid tenant-scoped role creation" do
    tenant = Tenant.create!(name: "Branch 1", subdomain: "branch-1", code: "B-001")
    role = Role.new(name: "Custom Trainer", key: "custom_trainer", tenant: tenant)
    assert role.valid?
  end

  test "validates required attributes" do
    role = Role.new
    assert_not role.valid?
    assert_includes role.errors[:name], "can't be blank"
    assert_includes role.errors[:key], "can't be blank"
  end

  test "enforces global role key uniqueness" do
    Role.create!(name: "Global Admin", key: "global_admin")
    duplicate = Role.new(name: "Duplicate Global Admin", key: "global_admin")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:key], "has already been taken"
  end

  test "enforces tenant-scoped role key uniqueness" do
    tenant = Tenant.create!(name: "Branch 2", subdomain: "branch-2", code: "B-002")
    Role.create!(name: "Branch Staff", key: "staff", tenant: tenant)

    duplicate = Role.new(name: "Duplicate Staff", key: "staff", tenant: tenant)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:key], "has already been taken"
  end
end
