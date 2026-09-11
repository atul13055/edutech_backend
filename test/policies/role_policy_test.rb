require "test_helper"

class RolePolicyTest < ActiveSupport::TestCase
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

    @global_role = Role.create!(name: "Global Observer", key: "global_observer", tenant_id: nil)
    @tenant1_role = Role.create!(name: "Tenant 1 Custom", key: "t1_custom", tenant: @tenant1)
    @tenant2_role = Role.create!(name: "Tenant 2 Custom", key: "t2_custom", tenant: @tenant2)

    @user1 = User.create!(
      first_name: "User1",
      email: "user1@example.com",
      password: "password123",
      role: @tenant1_role,
      tenant: @tenant1
    )
  end

  test "super admin can manage custom tenant roles" do
    policy = RolePolicy.new(@super_admin, @tenant1_role)

    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
  end

  test "global roles cannot be modified or destroyed by anyone" do
    policy_super = RolePolicy.new(@super_admin, @super_role)
    assert_not policy_super.update?
    assert_not policy_super.destroy?

    policy_user = RolePolicy.new(@user1, @super_role)
    assert_not policy_user.update?
    assert_not policy_user.destroy?
  end

  test "tenant user can view global roles and own tenant roles" do
    policy_global = RolePolicy.new(@user1, @global_role)
    assert policy_global.show?
    assert_not policy_global.update?
    assert_not policy_global.destroy?

    policy_own = RolePolicy.new(@user1, @tenant1_role)
    assert policy_own.show?
    assert policy_own.update?
    assert policy_own.destroy?
  end

  test "tenant user cannot access or modify another tenant roles" do
    policy_other = RolePolicy.new(@user1, @tenant2_role)

    assert_not policy_other.show?
    assert_not policy_other.update?
    assert_not policy_other.destroy?
  end

  test "scope returns global roles and own tenant roles for tenant user" do
    scope = RolePolicy::Scope.new(@user1, Role.all).resolve

    assert_includes scope, @global_role
    assert_includes scope, @tenant1_role
    assert_not_includes scope, @tenant2_role
  end
end
