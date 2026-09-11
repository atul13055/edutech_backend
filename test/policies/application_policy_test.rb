require "test_helper"

class ApplicationPolicyTest < ActiveSupport::TestCase
  setup do
    @tenant = Tenant.create!(name: "Branch A", subdomain: "branch-a", code: "BA-001")
    @role = Role.create!(name: "User", key: "user", tenant: @tenant)
    @user = User.create!(
      first_name: "John",
      email: "john@example.com",
      password: "password123",
      role: @role,
      tenant: @tenant
    )
    @policy = ApplicationPolicy.new(@user, @tenant)
  end

  test "default actions fail closed" do
    assert_not @policy.index?
    assert_not @policy.show?
    assert_not @policy.create?
    assert_not @policy.new?
    assert_not @policy.update?
    assert_not @policy.edit?
    assert_not @policy.destroy?
  end

  test "unauthenticated user fails closed" do
    nil_policy = ApplicationPolicy.new(nil, @tenant)

    assert_not nil_policy.index?
    assert_not nil_policy.show?
    assert_not nil_policy.create?
    assert_not nil_policy.update?
    assert_not nil_policy.destroy?
  end
end
