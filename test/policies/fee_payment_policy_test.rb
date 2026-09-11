require "test_helper"

class FeePaymentPolicyTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "Branch Policy 1", subdomain: "b-pol1", code: "BPOL-100", status: "active")
    @tenant2 = Tenant.create!(name: "Branch Policy 2", subdomain: "b-pol2", code: "BPOL-200", status: "active")

    @super_admin_role = Role.create!(name: "Super Admin", key: "super_admin")
    @branch_admin_role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant1)
    @receptionist_role = Role.create!(name: "Receptionist", key: "receptionist", tenant: @tenant1)
    @trainer_role = Role.create!(name: "Trainer", key: "trainer", tenant: @tenant1)
    @student_role = Role.create!(name: "Student", key: "student", tenant: @tenant1)

    @super_admin = User.create!(role: @super_admin_role, first_name: "Super", email: "super_pol@example.com", password: "password123")
    @branch_admin = User.create!(tenant: @tenant1, role: @branch_admin_role, first_name: "BAdmin", email: "badmin_pol@example.com", password: "password123")
    @receptionist = User.create!(tenant: @tenant1, role: @receptionist_role, first_name: "Recept", email: "recept_pol@example.com", password: "password123")
    @trainer = User.create!(tenant: @tenant1, role: @trainer_role, first_name: "Trainer", email: "trainer_pol@example.com", password: "password123")
    @student_user = User.create!(tenant: @tenant1, role: @student_role, first_name: "Student", email: "student_pol@example.com", password: "password123")

    @student1 = Student.create!(tenant: @tenant1, first_name: "David", roll_number: "STU-POL1")
    @plan1 = FeePlan.create!(tenant: @tenant1, name: "Policy Plan", total_amount: 5000.0, currency: "INR")
    @asg1 = StudentFeeAssignment.create!(tenant: @tenant1, student: @student1, fee_plan: @plan1)

    @payment1 = FeePayment.create!(
      tenant: @tenant1,
      student: @student1,
      student_fee_assignment: @asg1,
      amount: 2000.0,
      payment_method: "cash",
      idempotency_key: "pol-idem-1"
    )
  end

  test "super admin has full index, show, create access" do
    policy = FeePaymentPolicy.new(@super_admin, @payment1)
    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "branch admin and receptionist can index, show, and create payments for own tenant" do
    b_policy = FeePaymentPolicy.new(@branch_admin, @payment1)
    assert b_policy.index?
    assert b_policy.show?
    assert b_policy.create?

    r_policy = FeePaymentPolicy.new(@receptionist, @payment1)
    assert r_policy.index?
    assert r_policy.show?
    assert r_policy.create?
  end

  test "trainer and student are denied payment collection" do
    t_policy = FeePaymentPolicy.new(@trainer, @payment1)
    assert_not t_policy.create?

    s_policy = FeePaymentPolicy.new(@student_user, @payment1)
    assert_not s_policy.create?
  end

  test "completed payments are immutable for update and destroy" do
    b_policy = FeePaymentPolicy.new(@branch_admin, @payment1)
    assert_not b_policy.update?
    assert_not b_policy.destroy?
  end
end
