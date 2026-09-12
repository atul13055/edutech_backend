require "test_helper"

class FinanceReportPolicyTest < ActiveSupport::TestCase
  setup do
    @tenant = Tenant.create!(name: "Policy Tenant", subdomain: "pol-tenant", code: "POL-100", status: "active")
    @admin_role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant)
    @unauth_role = Role.create!(name: "Student Role", key: "student", tenant: @tenant)

    @admin = User.create!(tenant: @tenant, role: @admin_role, first_name: "Admin", email: "admin_pol@example.com", password: "password123")
    @unauthorized_user = User.create!(tenant: @tenant, role: @unauth_role, first_name: "StudentUser", email: "student_pol@example.com", password: "password123")
  end

  test "admin can view finance reports" do
    policy = FinanceReportPolicy.new(@admin, :finance_report)

    assert policy.collection_summary?
    assert policy.payment_methods?
    assert policy.outstanding_fees?
    assert policy.student_ledger?
    assert policy.refunds?
    assert policy.payment_intents?
    assert policy.daily_collection?
    assert policy.settlement_summary?
  end

  test "unauthorized user is denied finance reports" do
    policy = FinanceReportPolicy.new(@unauthorized_user, :finance_report)

    assert_not policy.collection_summary?
    assert_not policy.settlement_summary?
  end

  test "reports are strictly read-only and block write actions" do
    policy = FinanceReportPolicy.new(@admin, :finance_report)

    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end
end
