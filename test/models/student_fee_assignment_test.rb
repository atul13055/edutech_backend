require "test_helper"

class StudentFeeAssignmentTest < ActiveSupport::TestCase
  def setup
    @tenant1 = Tenant.create!(name: "Branch Assign 1", subdomain: "b-asg1", code: "BASG-100", status: "active")
    @tenant2 = Tenant.create!(name: "Branch Assign 2", subdomain: "b-asg2", code: "BASG-200", status: "active")

    @student1 = Student.create!(tenant: @tenant1, first_name: "Alice", roll_number: "STU-A1")
    @student2 = Student.create!(tenant: @tenant2, first_name: "Bob", roll_number: "STU-B1")

    @course1 = Course.create!(tenant: @tenant1, name: "Course A", code: "CA")
    @admission1 = Admission.create!(tenant: @tenant1, student: @student1, course: @course1, admission_date: Date.today)

    @fee_plan1 = FeePlan.create!(tenant: @tenant1, name: "Annual Plan A", total_amount: 5000.0, currency: "INR")
    @fee_plan2 = FeePlan.create!(tenant: @tenant2, name: "Annual Plan B", total_amount: 6000.0, currency: "INR")
  end

  test "creates assignment preserving immutable snapshot of fee plan" do
    assignment = StudentFeeAssignment.create!(
      tenant: @tenant1,
      student: @student1,
      admission: @admission1,
      fee_plan: @fee_plan1
    )

    assert_equal 5000.0, assignment.total_amount
    assert_equal "INR", assignment.currency
    assert_equal "active", assignment.status
    assert_not_nil assignment.assigned_at
  end

  test "prevents cross tenant student or fee plan assignment" do
    cross_student = StudentFeeAssignment.new(
      tenant: @tenant1,
      student: @student2,
      fee_plan: @fee_plan1
    )
    assert_not cross_student.valid?
    assert_includes cross_student.errors[:student], "must belong to your tenant"

    cross_plan = StudentFeeAssignment.new(
      tenant: @tenant1,
      student: @student1,
      fee_plan: @fee_plan2
    )
    assert_not cross_plan.valid?
    assert_includes cross_plan.errors[:fee_plan], "must belong to your tenant"
  end

  test "prevents duplicate active fee plan assignment to same student" do
    StudentFeeAssignment.create!(
      tenant: @tenant1,
      student: @student1,
      admission: @admission1,
      fee_plan: @fee_plan1
    )

    duplicate = StudentFeeAssignment.new(
      tenant: @tenant1,
      student: @student1,
      admission: @admission1,
      fee_plan: @fee_plan1
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:base], "Fee plan has already been assigned to this student"
  end
end
