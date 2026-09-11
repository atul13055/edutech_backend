require "test_helper"

class LeadTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "Branch 1 Lead", subdomain: "b1-lead", code: "B1LEAD-1", status: "active")
    @tenant2 = Tenant.create!(name: "Branch 2 Lead", subdomain: "b2-lead", code: "B2LEAD-1", status: "active")

    @course1 = Course.create!(tenant: @tenant1, name: "Web Dev", code: "WD-1")
    @course2 = Course.create!(tenant: @tenant2, name: "Data Science", code: "DS-2")
    @global_course = Course.create!(tenant: nil, name: "Global DCA", code: "GDCA-1")

    @role = Role.create!(name: "Counselor", key: "counselor", tenant: @tenant1)
    @user1 = User.create!(tenant: @tenant1, role: @role, first_name: "Alice", email: "alice_lead@example.com", password: "password123")
    @user2 = User.create!(tenant: @tenant2, role: @role, first_name: "Bob", email: "bob_lead@example.com", password: "password123")
  end

  test "validates required fields and defaults" do
    lead = Lead.new
    assert_not lead.valid?
    assert_includes lead.errors[:name], "can't be blank"

    lead = Lead.create!(tenant: @tenant1, name: " John Prospect ")
    assert_equal "John Prospect", lead.name
    assert_equal "new", lead.status
    assert_equal "walk_in", lead.source
  end

  test "validates course and counselor tenant bounds" do
    valid_lead = Lead.new(
      tenant: @tenant1,
      name: "Valid Prospect",
      interested_course: @global_course,
      assigned_to: @user1
    )
    assert valid_lead.valid?

    cross_tenant_course_lead = Lead.new(
      tenant: @tenant1,
      name: "Cross Course Prospect",
      interested_course: @course2
    )
    assert_not cross_tenant_course_lead.valid?
    assert_includes cross_tenant_course_lead.errors[:interested_course], "must belong to your tenant or be a global course"

    cross_tenant_user_lead = Lead.new(
      tenant: @tenant1,
      name: "Cross User Prospect",
      assigned_to: @user2
    )
    assert_not cross_tenant_user_lead.valid?
    assert_includes cross_tenant_user_lead.errors[:assigned_to], "must belong to your tenant"
  end
end
