require "test_helper"

class BatchScheduleTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create!(name: "Branch Schedule", subdomain: "b-sch-mod", code: "BSCH-100", status: "active")
    @course = Course.create!(tenant: @tenant, name: "Java", code: "JAVA101")
    @batch = Batch.create!(
      tenant: @tenant,
      course: @course,
      name: "Java Morning",
      code: "JM-01",
      start_date: Date.today
    )
  end

  test "validates required schedule fields" do
    schedule = BatchSchedule.new
    assert_not schedule.valid?
    assert_includes schedule.errors[:weekday], "can't be blank"
    assert_includes schedule.errors[:start_time], "can't be blank"
    assert_includes schedule.errors[:end_time], "can't be blank"
  end

  test "validates weekday and time range" do
    invalid_schedule = BatchSchedule.new(
      tenant: @tenant,
      batch: @batch,
      weekday: 7,
      start_time: "10:00",
      end_time: "09:00"
    )
    assert_not invalid_schedule.valid?
    assert_includes invalid_schedule.errors[:weekday], "is not included in the list"
    assert_includes invalid_schedule.errors[:end_time], "must be after start time"
  end

  test "valid schedule is valid" do
    schedule = BatchSchedule.new(
      tenant: @tenant,
      batch: @batch,
      weekday: 1,
      start_time: "09:00",
      end_time: "11:00",
      room_name: "Lab 101"
    )
    assert schedule.valid?
  end
end
