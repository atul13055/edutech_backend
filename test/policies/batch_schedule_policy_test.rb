require "test_helper"

class BatchSchedulePolicyTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "Tenant 1 SchPol", subdomain: "t1-spol", code: "T1SPOL-1", status: "active")
    @tenant2 = Tenant.create!(name: "Tenant 2 SchPol", subdomain: "t2-spol", code: "T2SPOL-1", status: "active")

    @admin_role1 = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant1)
    @admin1 = User.create!(tenant: @tenant1, role: @admin_role1, first_name: "Admin", email: "admin_spol@example.com", password: "password123")

    @course1 = Course.create!(tenant: @tenant1, name: "C1", code: "C1")
    @course2 = Course.create!(tenant: @tenant2, name: "C2", code: "C2")

    @batch1 = Batch.create!(tenant: @tenant1, course: @course1, name: "B1", code: "B1", start_date: Date.today)
    @batch2 = Batch.create!(tenant: @tenant2, course: @course2, name: "B2", code: "B2", start_date: Date.today)

    @sch1 = BatchSchedule.create!(tenant: @tenant1, batch: @batch1, weekday: 1, start_time: "09:00", end_time: "10:00")
    @sch2 = BatchSchedule.create!(tenant: @tenant2, batch: @batch2, weekday: 1, start_time: "09:00", end_time: "10:00")
  end

  test "admin can manage own tenant schedule" do
    policy1 = BatchSchedulePolicy.new(@admin1, @sch1)
    assert policy1.show?
    assert policy1.create?
    assert policy1.update?
    assert policy1.destroy?

    policy2 = BatchSchedulePolicy.new(@admin1, @sch2)
    assert_not policy2.show?
    assert_not policy2.update?
    assert_not policy2.destroy?
  end
end
