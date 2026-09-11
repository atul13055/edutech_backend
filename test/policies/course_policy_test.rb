require "test_helper"

class CoursePolicyTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "Tenant 1", subdomain: "t1-pol-crs", code: "T1POLCRS-1", status: "active")
    @tenant2 = Tenant.create!(name: "Tenant 2", subdomain: "t2-pol-crs", code: "T2POLCRS-1", status: "active")

    @super_admin_role = Role.create!(name: "Super Admin", key: "super_admin", tenant: nil)
    @branch_admin_role1 = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant1)
    @student_role = Role.create!(name: "Student", key: "student", tenant: @tenant1)

    @super_admin = User.create!(
      email: "superadmin_crs_pol@example.com",
      password: "password123",
      first_name: "Super",
      last_name: "Admin",
      role: @super_admin_role,
      tenant: nil
    )

    @branch_admin1 = User.create!(
      email: "admin1_crs_pol@example.com",
      password: "password123",
      first_name: "Admin",
      last_name: "One",
      role: @branch_admin_role1,
      tenant: @tenant1
    )

    @student_user = User.create!(
      email: "student_user_crs_pol@example.com",
      password: "password123",
      first_name: "Student",
      last_name: "User",
      role: @student_role,
      tenant: @tenant1
    )

    @global_course = Course.create!(tenant: nil, name: "Global DCA", code: "GDCA1")
    @branch_course1 = Course.create!(tenant: @tenant1, name: "Branch1 Spoken Eng", code: "B1ENG1")
    @branch_course2 = Course.create!(tenant: @tenant2, name: "Branch2 Tally", code: "B2TAL1")
  end

  test "super admin can manage global and branch courses" do
    policy = CoursePolicy.new(@super_admin, @global_course)
    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
  end

  test "branch admin can view global and own branch courses, but cannot update global courses" do
    global_policy = CoursePolicy.new(@branch_admin1, @global_course)
    assert global_policy.show?
    assert_not global_policy.update?
    assert_not global_policy.destroy?

    branch1_policy = CoursePolicy.new(@branch_admin1, @branch_course1)
    assert branch1_policy.show?
    assert branch1_policy.update?
    assert branch1_policy.destroy?
  end

  test "branch admin cannot view or modify another branch custom course" do
    branch2_policy = CoursePolicy.new(@branch_admin1, @branch_course2)
    assert_not branch2_policy.show?
    assert_not branch2_policy.update?
    assert_not branch2_policy.destroy?
  end

  test "unauthorized user role is denied policy access" do
    policy = CoursePolicy.new(@student_user, @branch_course1)
    assert_not policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "scope returns global courses and own tenant courses for branch admin" do
    scope = CoursePolicy::Scope.new(@branch_admin1, Course.all).resolve
    assert_includes scope, @global_course
    assert_includes scope, @branch_course1
    assert_not_includes scope, @branch_course2
  end
end
