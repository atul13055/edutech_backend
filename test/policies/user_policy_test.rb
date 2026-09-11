require "test_helper"

class UserPolicyTest < ActiveSupport::TestCase
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
    @user1 = User.create!(
      first_name: "User1",
      email: "user1@example.com",
      password: "password123",
      role: @admin_role,
      tenant: @tenant1
    )

    @user2 = User.create!(
      first_name: "User2",
      email: "user2@example.com",
      password: "password123",
      role: @admin_role,
      tenant: @tenant2
    )
  end

  test "super admin can manage users across all tenants" do
    policy = UserPolicy.new(@super_admin, @user1)

    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
  end

  test "tenant user can view and update users within own tenant" do
    target_user = User.new(tenant: @tenant1, role: @admin_role)
    policy = UserPolicy.new(@user1, target_user)

    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert policy.update?
  end

  test "tenant user cannot access or modify users from another tenant" do
    policy = UserPolicy.new(@user1, @user2)

    assert_not policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "tenant user cannot promote user to super_admin" do
    promoted_user = User.new(tenant: @tenant1, role: @super_role)

    create_policy = UserPolicy.new(@user1, promoted_user)
    assert_not create_policy.create?

    existing_user = User.create!(
      first_name: "PromoteTest",
      email: "promote@example.com",
      password: "password123",
      role: @admin_role,
      tenant: @tenant1
    )
    existing_user.role = @super_role

    update_policy = UserPolicy.new(@user1, existing_user)
    assert_not update_policy.update?
  end

  test "user cannot delete self" do
    policy = UserPolicy.new(@user1, @user1)
    assert_not policy.destroy?
  end

  test "scope returns only own tenant users for normal user" do
    scope = UserPolicy::Scope.new(@user1, User.all).resolve
    assert_includes scope, @user1
    assert_not_includes scope, @user2
  end
end
