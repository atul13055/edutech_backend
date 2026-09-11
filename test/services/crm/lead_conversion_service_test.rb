require "test_helper"

module Crm
  class LeadConversionServiceTest < ActiveSupport::TestCase
    def setup
      @tenant = Tenant.create!(name: "Branch Conversion", subdomain: "b-cnv", code: "BCNV-100", status: "active")
      @course = Course.create!(tenant: @tenant, name: "Python Bootcamp", code: "PY-BC")
      @batch = Batch.create!(tenant: @tenant, course: @course, name: "Batch 1", code: "B1", start_date: Date.today)
      @role = Role.create!(name: "Counselor", key: "counselor", tenant: @tenant)
      @counselor = User.create!(tenant: @tenant, role: @role, first_name: "Counselor", email: "counselor_cnv@example.com", password: "password123")

      @lead = Lead.create!(
        tenant: @tenant,
        name: "Jane Doe",
        email: "jane_cnv@example.com",
        phone: "9876543210",
        assigned_to: @counselor
      )
    end

    test "converts lead transactionally creating new student and admission" do
      result = LeadConversionService.call(
        lead: @lead,
        course_id: @course.id,
        batch_id: @batch.id,
        counselor_id: @counselor.id
      )

      assert result.success?
      assert_equal "converted", @lead.reload.status
      assert_not_nil result.student
      assert_equal "Jane", result.student.first_name
      assert_equal "Doe", result.student.last_name
      assert_equal "jane_cnv@example.com", result.student.email

      assert_not_nil result.admission
      assert_equal "confirmed", result.admission.status
      assert_equal @course.id, result.admission.course_id
      assert_equal @batch.id, result.admission.batch_id
    end

    test "prevents double conversion of already converted lead" do
      LeadConversionService.call(
        lead: @lead,
        course_id: @course.id
      )

      second_attempt = LeadConversionService.call(
        lead: @lead,
        course_id: @course.id
      )

      assert_not second_attempt.success?
      assert_includes second_attempt.errors, "Lead has already been converted to an admission"
    end

    test "reuses existing student if email matches" do
      existing_student = Student.create!(
        tenant: @tenant,
        first_name: "Jane",
        last_name: "Doe",
        email: "jane_cnv@example.com",
        roll_number: "EXISTING-101",
        status: "active"
      )

      result = LeadConversionService.call(
        lead: @lead,
        course_id: @course.id
      )

      assert result.success?
      assert_equal existing_student.id, result.student.id
    end
  end
end
