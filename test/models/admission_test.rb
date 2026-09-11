require "test_helper"

class AdmissionTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "Branch 1 Adm", subdomain: "b1-adm", code: "B1ADM-1", status: "active")
    @tenant2 = Tenant.create!(name: "Branch 2 Adm", subdomain: "b2-adm", code: "B2ADM-1", status: "active")

    @student1 = Student.create!(tenant: @tenant1, first_name: "Sam", roll_number: "S101", status: "active")
    @student2 = Student.create!(tenant: @tenant2, first_name: "Sue", roll_number: "S102", status: "active")

    @course1 = Course.create!(tenant: @tenant1, name: "Web Dev 1", code: "WD-101")
  end

  test "generates admission number automatically on creation" do
    adm = Admission.create!(
      tenant: @tenant1,
      student: @student1,
      course: @course1,
      admission_date: Date.today
    )

    assert adm.admission_number.start_with?("ADM-")
    assert_equal "applied", adm.status
  end

  test "prevents student from another tenant" do
    adm = Admission.new(
      tenant: @tenant1,
      student: @student2,
      course: @course1,
      admission_date: Date.today
    )

    assert_not adm.valid?
    assert_includes adm.errors[:student], "must belong to your tenant"
  end
end
