require "test_helper"

class FeePlanPolicyTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "T1 FeePol", subdomain: "t1-fpol", code: "T1FPOL-1", status: "active")
    @tenant2 = Tenant.create!(name: "T2 FeePol", subdomain: "t2-fpol", code: "T2FPOL-1", status: "active")

    @admin_role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant1)
    @student_role = Role.create!(name: "Student", key: "student", tenant: @tenant1)

    @admin = User.create!(tenant: @tenant1, role: @admin_role, first_name: "Admin", email: "admin_fpol@example.com", password: "password123")
    @student_user = User.create!(tenant: @tenant1, role: @student_role, first_name: "Student", email: "stu_fpol@example.com", password: "password123")

    @plan1 = FeePlan.create!(tenant: @tenant1, name: "Plan 1", total_amount: 1000.0)
    @plan2 = FeePlan.create!(tenant: @tenant2, name: "Plan 2", total_amount: 2000.0)
  end

  test "branch admin can manage own tenant fee plans" do
    policy1 = FeePlanPolicy.new(@admin, @plan1)
    assert policy1.show?
    assert policy1.create?
    assert policy1.update?

    policy2 = FeePlanPolicy.new(@admin, @plan2)
    assert_not policy2.show?
    assert_not policy2.update?
  end

  test "student user is denied fee plan management" do
    policy = FeePlanPolicy.new(@student_user, @plan1)
    assert_not policy.show?
    assert_not policy.create?
    assert_not policy.update?
  end
end
