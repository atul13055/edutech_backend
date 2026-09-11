require "test_helper"

class RolePermissionPolicyTest < ActiveSupport::TestCase
  setup do
    @tenant1 = Tenant.create!(name: "Branch A", subdomain: "branch-a", code: "BA-001")
    @tenant2 = Tenant.create!(name: "Branch B", subdomain: "branch-b", code: "BB-001")

    @super_role = Role.create!(name: "Super Admin", key: "super_admin", tenant_id: nil)
    @super_admin = User.create!(
      first_name: "Super",
      email: "super@example.com",
      password: "password123",
      role: @super_role,
      tenant: nil
    )

    @permission = Permission.create!(name: "Read Users", key: "users.read", module_name: "users")

    @tenant1_role = Role.create!(name: "Role 1", key: "role1", tenant: @tenant1)
    @tenant2_role = Role.create!(name: "Role 2", key: "role2", tenant: @tenant2)

    @rp_tenant1 = RolePermission.create!(role: @tenant1_role, permission: @permission)
    @rp_tenant2 = RolePermission.create!(role: @tenant2_role, permission: @permission)

    @user1 = User.create!(
      first_name: "User1",
      email: "user1@example.com",
      password: "password123",
      role: @tenant1_role,
      tenant: @tenant1
    )
  end

  test "super admin can manage role permissions for non-system roles" do
    policy = RolePermissionPolicy.new(@super_admin, @rp_tenant1)

    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
  end

  test "tenant user can manage role permissions for own tenant roles" do
    policy = RolePermissionPolicy.new(@user1, @rp_tenant1)

    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
  end

  test "tenant user cannot manage role permissions for another tenant roles" do
    policy = RolePermissionPolicy.new(@user1, @rp_tenant2)

    assert_not policy.index?
    assert_not policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "global system role permissions cannot be created or destroyed by anyone" do
    rp_system = RolePermission.create!(role: @super_role, permission: @permission)

    policy_super = RolePermissionPolicy.new(@super_admin, rp_system)
    assert_not policy_super.create?
    assert_not policy_super.destroy?

    policy_user = RolePermissionPolicy.new(@user1, rp_system)
    assert_not policy_user.create?
    assert_not policy_user.destroy?
  end
end
