require "test_helper"

class LeadBlueprintTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create!(name: "Branch Lead Blueprint", subdomain: "b-lbp", code: "BLBP-100", status: "active")
    @course = Course.create!(tenant: @tenant, name: "Web Dev", code: "WD-100")
    @role = Role.create!(name: "Counselor", key: "counselor", tenant: @tenant)
    @user = User.create!(tenant: @tenant, role: @role, first_name: "Sarah", last_name: "Connor", email: "sarah_lbp@example.com", password: "password123")

    @lead = Lead.create!(
      tenant: @tenant,
      name: "John Prospect",
      email: "john_lbp@example.com",
      phone: "1234567890",
      interested_course: @course,
      assigned_to: @user
    )

    @flw = LeadFollowUp.create!(
      tenant: @tenant,
      lead: @lead,
      user: @user,
      follow_up_at: 1.day.from_now,
      notes: "First contact"
    )
  end

  test "serializes lead attributes and associations" do
    json = LeadBlueprint.render_as_hash(@lead)

    assert_equal @lead.id, json[:id]
    assert_equal "John Prospect", json[:name]
    assert_equal "john_lbp@example.com", json[:email]
    assert_equal "Sarah Connor", json[:assigned_to_name]
    assert_equal "WD-100", json[:interested_course][:code]
    assert_equal 1, json[:follow_ups].length
  end
end
