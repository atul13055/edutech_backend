require "test_helper"

class LeadFollowUpTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create!(name: "Branch FollowUp", subdomain: "b-flw", code: "BFLW-100", status: "active")
    @role = Role.create!(name: "Counselor", key: "counselor", tenant: @tenant)
    @user = User.create!(tenant: @tenant, role: @role, first_name: "Carol", email: "carol_flw@example.com", password: "password123")
    @lead = Lead.create!(tenant: @tenant, name: "Lead Alpha")
  end

  test "validates presence of follow_up_at and user" do
    flw = LeadFollowUp.new
    assert_not flw.valid?
    assert_includes flw.errors[:follow_up_at], "can't be blank"
    assert_includes flw.errors[:user], "must exist"
  end

  test "valid follow up creates record with defaults" do
    flw = LeadFollowUp.create!(
      tenant: @tenant,
      lead: @lead,
      user: @user,
      follow_up_at: 1.day.from_now,
      notes: "Called candidate"
    )

    assert_equal "pending", flw.status
    assert_equal "Called candidate", flw.notes
  end
end
