require "test_helper"

class BatchBlueprintTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create!(name: "Branch Blueprint Batch", subdomain: "b-bp-bt", code: "BBPBT-100", status: "active")
    @course = Course.create!(tenant: @tenant, name: "Web Dev", code: "WD-100")
    @role = Role.create!(name: "Trainer", key: "trainer", tenant: @tenant)
    @trainer = User.create!(tenant: @tenant, role: @role, first_name: "Jane", last_name: "Smith", email: "jane_bp@example.com", password: "password123")

    @batch = Batch.create!(
      tenant: @tenant,
      course: @course,
      trainer: @trainer,
      name: "Batch Alpha",
      code: "ALPHA-1",
      capacity: 25,
      start_date: Date.today
    )

    @schedule = BatchSchedule.create!(
      tenant: @tenant,
      batch: @batch,
      weekday: 1,
      start_time: "09:00",
      end_time: "11:00",
      room_name: "Room 101"
    )
  end

  test "serializes batch attributes and associations" do
    json = BatchBlueprint.render_as_hash(@batch)

    assert_equal @batch.id, json[:id]
    assert_equal @tenant.id, json[:tenant_id]
    assert_equal "Batch Alpha", json[:name]
    assert_equal "ALPHA-1", json[:code]
    assert_equal 25, json[:capacity]
    assert_equal "Jane Smith", json[:trainer_name]
    assert_equal "WD-100", json[:course][:code]
    assert_equal 1, json[:batch_schedules].length
    assert_equal "Room 101", json[:batch_schedules].first[:room_name]
    assert_equal "Monday", json[:batch_schedules].first[:weekday_name]
  end
end
