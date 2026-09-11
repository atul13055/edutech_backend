require "test_helper"

class TenantPolicyTest < ActiveSupport::TestCase
  setup do
    @tenant1 = Tenant.create!(name: "Branch A", subdomain: "branch-a", code: "BA-001")
    @tenant2 = Tenant.create!(name: "Branch B", subdomain: "branch-b", code: "BB-001")

    @super_role = Role.create!(name: "Super Admin", key: "super_admin")
    @super_admin = User.create!(
      first_name: "Super",
      email: "super@example.com",
      password: "password123",
      role: @super_role,
      tenant: nil
    )

    @admin_role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant1)
    @tenant_admin = User.create!(
      first_name: "AdminA",
      email: "admina@example.com",
      password: "password123",
      role: @admin_role,
      tenant: @tenant1
    )

    @member_role = Role.create!(name: "Member", key: "member", tenant: @tenant1)
    @tenant_member = User.create!(
      first_name: "MemberA",
      email: "membera@example.com",
      password: "password123",
      role: @member_role,
      tenant: @tenant1
    )
  end

  test "super admin can perform all tenant operations" do
    policy = TenantPolicy.new(@super_admin, @tenant1)

    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
  end

  test "tenant user can view own tenant but not create/destroy" do
    policy = TenantPolicy.new(@tenant_member, @tenant1)

    assert_not policy.index?
    assert policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "tenant admin can update own tenant details" do
    policy = TenantPolicy.new(@tenant_admin, @tenant1)

    assert policy.update?
  end

  test "tenant user cannot view or update another tenant" do
    policy = TenantPolicy.new(@tenant_admin, @tenant2)

    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "scope returns all tenants for super admin and only own tenant for tenant user" do
    super_scope = TenantPolicy::Scope.new(@super_admin, Tenant.all).resolve
    assert_equal 2, super_scope.count

    user_scope = TenantPolicy::Scope.new(@tenant_member, Tenant.all).resolve
    assert_equal 1, user_scope.count
    assert_equal @tenant1.id, user_scope.first.id
  end
end
