require "test_helper"

class BatchTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "Branch 1 Batch", subdomain: "b1-bt-mod", code: "B1BT-100", status: "active")
    @tenant2 = Tenant.create!(name: "Branch 2 Batch", subdomain: "b2-bt-mod", code: "B2BT-100", status: "active")

    @course1 = Course.create!(tenant: @tenant1, name: "Python 101", code: "PY101")
    @global_course = Course.create!(tenant: nil, name: "Global DCA", code: "GDCA1")

    @role = Role.create!(name: "Trainer Role", key: "trainer", tenant: @tenant1)
    @trainer = User.create!(
      tenant: @tenant1,
      role: @role,
      first_name: "John",
      last_name: "Doe",
      email: "trainer_bt@example.com",
      password: "password123"
    )
  end

  test "validates required fields" do
    batch = Batch.new
    assert_not batch.valid?
    assert_includes batch.errors[:name], "can't be blank"
    assert_includes batch.errors[:code], "can't be blank"
    assert_includes batch.errors[:course], "must exist"
  end

  test "enforces batch code uniqueness per tenant" do
    Batch.create!(
      tenant: @tenant1,
      course: @course1,
      name: "Morning Batch",
      code: "MORNING-01",
      start_date: Date.today
    )

    duplicate = Batch.new(
      tenant: @tenant1,
      course: @course1,
      name: "Another Batch",
      code: "MORNING-01",
      start_date: Date.today
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:code], "has already been taken"

    other_tenant_batch = Batch.new(
      tenant: @tenant2,
      course: @global_course,
      name: "Morning Batch T2",
      code: "MORNING-01",
      start_date: Date.today
    )
    assert other_tenant_batch.valid?
  end

  test "allows linking to global courses and tenant courses" do
    batch_global = Batch.create!(
      tenant: @tenant1,
      course: @global_course,
      name: "Global Course Batch",
      code: "GCB-01",
      start_date: Date.today
    )
    assert batch_global.valid?

    other_tenant_course = Course.create!(tenant: @tenant2, name: "Branch 2 Course", code: "B2CRS-01")
    invalid_cross_batch = Batch.new(
      tenant: @tenant1,
      course: other_tenant_course,
      name: "Invalid Cross Batch",
      code: "ICB-01",
      start_date: Date.today
    )
    assert_not invalid_cross_batch.valid?
    assert_includes invalid_cross_batch.errors[:course], "must belong to your tenant or be a global course"
  end

  test "validates capacity and dates" do
    invalid_batch = Batch.new(
      tenant: @tenant1,
      course: @course1,
      name: "Bad Dates Batch",
      code: "BDB-01",
      capacity: 0,
      start_date: Date.today,
      end_date: Date.yesterday
    )
    assert_not invalid_batch.valid?
    assert_includes invalid_batch.errors[:capacity], "must be greater than 0"
    assert_includes invalid_batch.errors[:end_date], "must be on or after start date"
  end

  test "normalizes code and defaults" do
    batch = Batch.create!(
      tenant: @tenant1,
      course: @course1,
      name: "  Evening Batch  ",
      code: "  eve-01  ",
      start_date: Date.today
    )

    assert_equal "EVE-01", batch.code
    assert_equal "Evening Batch", batch.name
    assert_equal 30, batch.capacity
    assert_equal "upcoming", batch.status
  end
end
