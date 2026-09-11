require "test_helper"

class StudentPolicyTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "Tenant 1", subdomain: "t1-pol-stu", code: "T1POLSTU-1", status: "active")
    @tenant2 = Tenant.create!(name: "Tenant 2", subdomain: "t2-pol-stu", code: "T2POLSTU-1", status: "active")

    @super_admin_role = Role.create!(name: "Super Admin", key: "super_admin", tenant: nil)
    @branch_admin_role1 = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant1)
    @student_role1 = Role.create!(name: "Student Role", key: "student", tenant: @tenant1)

    @super_admin = User.create!(
      email: "superadmin_stu_pol@example.com",
      password: "password123",
      first_name: "Super",
      last_name: "Admin",
      role: @super_admin_role,
      tenant: nil
    )

    @branch_admin1 = User.create!(
      email: "admin1_stu_pol@example.com",
      password: "password123",
      first_name: "Admin",
      last_name: "One",
      role: @branch_admin_role1,
      tenant: @tenant1
    )

    @student_user = User.create!(
      email: "student_user_pol@example.com",
      password: "password123",
      first_name: "Student",
      last_name: "User",
      role: @student_role1,
      tenant: @tenant1
    )

    @student1 = Student.create!(tenant: @tenant1, first_name: "Student1", roll_number: "R1")
    @student2 = Student.create!(tenant: @tenant2, first_name: "Student2", roll_number: "R2")
  end

  test "super admin can access any student" do
    policy = StudentPolicy.new(@super_admin, @student1)
    assert policy.show?
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
  end

  test "tenant admin can access own tenant student but not other tenant student" do
    policy1 = StudentPolicy.new(@branch_admin1, @student1)
    assert policy1.show?
    assert policy1.update?
    assert policy1.destroy?

    policy2 = StudentPolicy.new(@branch_admin1, @student2)
    assert_not policy2.show?
    assert_not policy2.update?
    assert_not policy2.destroy?
  end

  test "unauthorized student role user is denied policy access" do
    policy = StudentPolicy.new(@student_user, @student1)
    assert_not policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "policy scope filters by tenant for normal tenant users" do
    scope = StudentPolicy::Scope.new(@branch_admin1, Student.all).resolve
    assert_includes scope, @student1
    assert_not_includes scope, @student2
  end
end
