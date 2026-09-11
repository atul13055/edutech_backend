require "test_helper"

class WalletPolicyTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "Branch 1 Policy", subdomain: "b1-policy", code: "B1POL-100", status: "active")
    @tenant2 = Tenant.create!(name: "Branch 2 Policy", subdomain: "b2-policy", code: "B2POL-100", status: "active")

    @super_admin_role = Role.create!(name: "Super Admin", key: "super_admin", tenant_id: nil)
    @branch_admin_role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant1)
    @student_role = Role.create!(name: "Student", key: "student", tenant: @tenant1)

    @super_admin = User.create!(
      email: "superadmin_policy@example.com",
      password: "password123",
      first_name: "Super",
      last_name: "Admin",
      role: @super_admin_role,
      tenant: nil
    )

    @branch_admin1 = User.create!(
      email: "branchadmin1_policy@example.com",
      password: "password123",
      first_name: "Branch",
      last_name: "Admin1",
      role: @branch_admin_role,
      tenant: @tenant1
    )

    @student1 = User.create!(
      email: "student1_policy@example.com",
      password: "password123",
      first_name: "Student",
      last_name: "One",
      role: @student_role,
      tenant: @tenant1
    )

    @wallet1 = Wallet.find_or_create_by!(tenant_id: @tenant1.id)
    @wallet2 = Wallet.find_or_create_by!(tenant_id: @tenant2.id)
  end

  test "super admin can show, credit, and debit any wallet" do
    policy = WalletPolicy.new(@super_admin, @wallet1)
    assert policy.show?
    assert policy.credit?
    assert policy.debit?
  end

  test "branch admin can show and debit own wallet but cannot credit" do
    policy1 = WalletPolicy.new(@branch_admin1, @wallet1)
    assert policy1.show?
    assert_not policy1.credit?
    assert policy1.debit?

    policy2 = WalletPolicy.new(@branch_admin1, @wallet2)
    assert_not policy2.show?
    assert_not policy2.credit?
    assert_not policy2.debit?
  end

  test "member without wallet permission is denied all actions" do
    policy = WalletPolicy.new(@student1, @wallet1)
    assert_not policy.show?
    assert_not policy.credit?
    assert_not policy.debit?
  end
end
