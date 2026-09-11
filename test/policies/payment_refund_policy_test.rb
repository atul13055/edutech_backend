require "test_helper"

class PaymentRefundPolicyTest < ActiveSupport::TestCase
  setup do
    @tenant = Tenant.create!(name: "Test Tenant POL", subdomain: "test-pol", code: "TT-POL-1", status: "active")
    @admin_role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant)
    @counselor_role = Role.create!(name: "Counselor", key: "counselor", tenant: @tenant)

    @admin = User.create!(tenant: @tenant, role: @admin_role, first_name: "Admin", email: "admin_pol@example.com", password: "password123")
    @counselor = User.create!(tenant: @tenant, role: @counselor_role, first_name: "Counselor", email: "counselor_pol@example.com", password: "password123")

    @refund = PaymentRefund.new(tenant: @tenant)
    Current.tenant = @tenant
  end

  test "admin can create and approve refund" do
    policy = PaymentRefundPolicy.new(@admin, @refund)
    assert policy.create?
    assert policy.approve?
    assert policy.process_refund?
  end

  test "counselor cannot approve or process refund" do
    policy = PaymentRefundPolicy.new(@counselor, @refund)
    assert_not policy.approve?
    assert_not policy.process_refund?
  end

  test "update and destroy are always denied" do
    policy = PaymentRefundPolicy.new(@admin, @refund)
    assert_not policy.update?
    assert_not policy.destroy?
  end
end
