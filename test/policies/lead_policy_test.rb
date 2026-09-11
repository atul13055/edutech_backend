require "test_helper"

class LeadPolicyTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "T1 LeadPol", subdomain: "t1-lpol", code: "T1LPOL-1", status: "active")
    @tenant2 = Tenant.create!(name: "T2 LeadPol", subdomain: "t2-lpol", code: "T2LPOL-1", status: "active")

    @counselor_role = Role.create!(name: "Counselor", key: "counselor", tenant: @tenant1)
    @student_role = Role.create!(name: "Student", key: "student", tenant: @tenant1)

    @counselor = User.create!(tenant: @tenant1, role: @counselor_role, first_name: "C1", email: "c1_lpol@example.com", password: "password123")
    @student_user = User.create!(tenant: @tenant1, role: @student_role, first_name: "S1", email: "s1_lpol@example.com", password: "password123")

    @lead1 = Lead.create!(tenant: @tenant1, name: "Lead 1")
    @lead2 = Lead.create!(tenant: @tenant2, name: "Lead 2")
  end

  test "counselor can manage own tenant leads" do
    policy1 = LeadPolicy.new(@counselor, @lead1)
    assert policy1.show?
    assert policy1.create?
    assert policy1.update?

    policy2 = LeadPolicy.new(@counselor, @lead2)
    assert_not policy2.show?
    assert_not policy2.update?
  end

  test "student user is denied lead access" do
    policy = LeadPolicy.new(@student_user, @lead1)
    assert_not policy.show?
    assert_not policy.create?
    assert_not policy.update?
  end
end
