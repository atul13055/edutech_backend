require "test_helper"

class PaymentIntentPolicyTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "Branch 1 Policy", subdomain: "b1-intent-pol", code: "B1INTPOL-100", status: "active")
    @tenant2 = Tenant.create!(name: "Branch 2 Policy", subdomain: "b2-intent-pol", code: "B2INTPOL-100", status: "active")

    @admin_role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant1)
    @student_role = Role.create!(name: "Student", key: "student", tenant: @tenant1)

    @admin = User.create!(tenant: @tenant1, role: @admin_role, first_name: "Admin", email: "admin_intpol@example.com", password: "password123")
    @student_user = User.create!(tenant: @tenant1, role: @student_role, first_name: "Student", email: "stu_intpol@example.com", password: "password123")

    @student = Student.create!(tenant: @tenant1, first_name: "Eve", roll_number: "SE100")
    @plan = FeePlan.create!(tenant: @tenant1, name: "Plan", total_amount: 5000.0, currency: "INR")
    @asg = StudentFeeAssignment.create!(tenant: @tenant1, student: @student, fee_plan: @plan)

    @intent = PaymentIntent.create!(
      tenant: @tenant1,
      student: @student,
      student_fee_assignment: @asg,
      amount: 2000.0,
      currency: "INR",
      payment_method: "cash",
      idempotency_key: "pol-intent-1"
    )
  end

  test "admin can create, view, and reconcile payment intent" do
    policy = PaymentIntentPolicy.new(@admin, @intent)
    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert policy.reconcile?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "student user cannot create or reconcile payment intent" do
    policy = PaymentIntentPolicy.new(@student_user, @intent)
    assert_not policy.create?
    assert_not policy.reconcile?
    assert_not policy.update?
    assert_not policy.destroy?
  end
end
