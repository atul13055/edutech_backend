require "test_helper"

class AdmissionPolicyTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "T1 AdmPol", subdomain: "t1-apol", code: "T1APOL-1", status: "active")
    @tenant2 = Tenant.create!(name: "T2 AdmPol", subdomain: "t2-apol", code: "T2APOL-1", status: "active")

    @receptionist_role = Role.create!(name: "Receptionist", key: "receptionist", tenant: @tenant1)
    @receptionist = User.create!(tenant: @tenant1, role: @receptionist_role, first_name: "R1", email: "r1_apol@example.com", password: "password123")

    @student1 = Student.create!(tenant: @tenant1, first_name: "St1", roll_number: "ROLL101")
    @student2 = Student.create!(tenant: @tenant2, first_name: "St2", roll_number: "ROLL102")

    @course1 = Course.create!(tenant: @tenant1, name: "C1", code: "C1")
    @course2 = Course.create!(tenant: @tenant2, name: "C2", code: "C2")

    @adm1 = Admission.create!(tenant: @tenant1, student: @student1, course: @course1, admission_date: Date.today)
    @adm2 = Admission.create!(tenant: @tenant2, student: @student2, course: @course2, admission_date: Date.today)
  end

  test "receptionist can view and manage own tenant admissions" do
    policy1 = AdmissionPolicy.new(@receptionist, @adm1)
    assert policy1.show?
    assert policy1.create?
    assert policy1.update?

    policy2 = AdmissionPolicy.new(@receptionist, @adm2)
    assert_not policy2.show?
    assert_not policy2.update?
  end
end
