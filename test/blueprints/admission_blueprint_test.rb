require "test_helper"

class AdmissionBlueprintTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create!(name: "Branch Adm Blueprint", subdomain: "b-abp", code: "BABP-100", status: "active")
    @course = Course.create!(tenant: @tenant, name: "AI & ML", code: "AIML-100")
    @student = Student.create!(tenant: @tenant, first_name: "Mark", roll_number: "ROLL-ABP", status: "active")
    @role = Role.create!(name: "Counselor", key: "counselor", tenant: @tenant)
    @counselor = User.create!(tenant: @tenant, role: @role, first_name: "Emma", last_name: "Watson", email: "emma_abp@example.com", password: "password123")

    @admission = Admission.create!(
      tenant: @tenant,
      student: @student,
      course: @course,
      counselor: @counselor,
      admission_date: Date.today,
      status: "confirmed"
    )
  end

  test "serializes admission attributes and associations" do
    json = AdmissionBlueprint.render_as_hash(@admission)

    assert_equal @admission.id, json[:id]
    assert_equal "confirmed", json[:status]
    assert_equal "Emma Watson", json[:counselor_name]
    assert_equal "AIML-100", json[:course][:code]
    assert_equal "Mark", json[:student][:first_name]
  end
end
