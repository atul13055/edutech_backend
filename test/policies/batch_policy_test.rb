require "test_helper"

class BatchPolicyTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "Tenant 1 BatchPol", subdomain: "t1-bpol", code: "T1BPOL-1", status: "active")
    @tenant2 = Tenant.create!(name: "Tenant 2 BatchPol", subdomain: "t2-bpol", code: "T2BPOL-1", status: "active")

    @super_admin_role = Role.create!(name: "Super Admin", key: "super_admin", tenant: nil)
    @branch_admin_role1 = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant1)
    @student_role = Role.create!(name: "Student", key: "student", tenant: @tenant1)

    @super_admin = User.create!(
      email: "super_batchpol@example.com",
      password: "password123",
      first_name: "Super",
      last_name: "Admin",
      role: @super_admin_role,
      tenant: nil
    )

    @branch_admin1 = User.create!(
      email: "admin1_batchpol@example.com",
      password: "password123",
      first_name: "Admin",
      last_name: "One",
      role: @branch_admin_role1,
      tenant: @tenant1
    )

    @student_user = User.create!(
      email: "student_batchpol@example.com",
      password: "password123",
      first_name: "Student",
      last_name: "User",
      role: @student_role,
      tenant: @tenant1
    )

    @course1 = Course.create!(tenant: @tenant1, name: "Web Dev 1", code: "WD1")
    @course2 = Course.create!(tenant: @tenant2, name: "Web Dev 2", code: "WD2")

    @batch1 = Batch.create!(tenant: @tenant1, course: @course1, name: "Batch 1", code: "B1", start_date: Date.today)
    @batch2 = Batch.create!(tenant: @tenant2, course: @course2, name: "Batch 2", code: "B2", start_date: Date.today)
  end

  test "super admin can manage all batches" do
    policy = BatchPolicy.new(@super_admin, @batch1)
    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
  end

  test "branch admin can manage own tenant batches" do
    policy1 = BatchPolicy.new(@branch_admin1, @batch1)
    assert policy1.show?
    assert policy1.create?
    assert policy1.update?
    assert policy1.destroy?

    policy2 = BatchPolicy.new(@branch_admin1, @batch2)
    assert_not policy2.show?
    assert_not policy2.update?
    assert_not policy2.destroy?
  end

  test "unauthorized student cannot manage batches" do
    policy = BatchPolicy.new(@student_user, @batch1)
    assert_not policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "scope returns only own tenant batches for branch admin" do
    scope = BatchPolicy::Scope.new(@branch_admin1, Batch.all).resolve
    assert_includes scope, @batch1
    assert_not_includes scope, @batch2
  end
end
