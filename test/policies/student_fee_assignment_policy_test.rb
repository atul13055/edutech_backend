require "test_helper"

class StudentFeeAssignmentPolicyTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "T1 AsgPol", subdomain: "t1-asgpol", code: "T1APOL-100", status: "active")
    @tenant2 = Tenant.create!(name: "T2 AsgPol", subdomain: "t2-asgpol", code: "T2APOL-100", status: "active")

    @receptionist_role = Role.create!(name: "Receptionist", key: "receptionist", tenant: @tenant1)
    @student_role = Role.create!(name: "Student", key: "student", tenant: @tenant1)

    @receptionist = User.create!(tenant: @tenant1, role: @receptionist_role, first_name: "Recep", email: "recep_asgpol@example.com", password: "password123")
    @student_user = User.create!(tenant: @tenant1, role: @student_role, first_name: "Student", email: "stu_asgpol@example.com", password: "password123")

    @student1 = Student.create!(tenant: @tenant1, first_name: "S1", roll_number: "ROLL-1")
    @student2 = Student.create!(tenant: @tenant2, first_name: "S2", roll_number: "ROLL-2")

    @plan1 = FeePlan.create!(tenant: @tenant1, name: "P1", total_amount: 1000.0)
    @plan2 = FeePlan.create!(tenant: @tenant2, name: "P2", total_amount: 2000.0)

    @asg1 = StudentFeeAssignment.create!(tenant: @tenant1, student: @student1, fee_plan: @plan1)
    @asg2 = StudentFeeAssignment.create!(tenant: @tenant2, student: @student2, fee_plan: @plan2)
  end

  test "receptionist can manage own tenant fee assignments" do
    policy1 = StudentFeeAssignmentPolicy.new(@receptionist, @asg1)
    assert policy1.show?
    assert policy1.create?

    policy2 = StudentFeeAssignmentPolicy.new(@receptionist, @asg2)
    assert_not policy2.show?
    assert_not policy2.create?
  end

  test "student user is denied fee assignment access" do
    policy = StudentFeeAssignmentPolicy.new(@student_user, @asg1)
    assert_not policy.show?
    assert_not policy.create?
  end
end
