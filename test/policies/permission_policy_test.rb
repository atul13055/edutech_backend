require "test_helper"

class PermissionPolicyTest < ActiveSupport::TestCase
  setup do
    @tenant = Tenant.create!(name: "Branch A", subdomain: "branch-a", code: "BA-001")

    @super_role = Role.create!(name: "Super Admin", key: "super_admin")
    @super_admin = User.create!(
      first_name: "Super",
      email: "super@example.com",
      password: "password123",
      role: @super_role,
      tenant: nil
    )

    @user_role = Role.create!(name: "User", key: "user", tenant: @tenant)
    @user = User.create!(
      first_name: "User",
      email: "user@example.com",
      password: "password123",
      role: @user_role,
      tenant: @tenant
    )

    @permission = Permission.create!(
      name: "Manage Users",
      key: "users.manage",
      module_name: "users"
    )
  end

  test "super admin can manage permission definitions" do
    policy = PermissionPolicy.new(@super_admin, @permission)

    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
  end

  test "normal tenant user can view permissions dictionary but not alter it" do
    policy = PermissionPolicy.new(@user, @permission)

    assert policy.index?
    assert policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "unauthenticated user cannot access permissions" do
    policy = PermissionPolicy.new(nil, @permission)

    assert_not policy.index?
    assert_not policy.show?
    assert_not policy.create?
  end
end
