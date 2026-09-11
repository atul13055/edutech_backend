class StudentFeeAssignmentBlueprint < Blueprinter::Base
  identifier :id

  fields :tenant_id,
         :student_id,
         :admission_id,
         :fee_plan_id,
         :total_amount,
         :currency,
         :assigned_at,
         :status,
         :notes,
         :created_at,
         :updated_at

  association :student, blueprint: StudentBlueprint
  association :admission, blueprint: AdmissionBlueprint
  association :fee_plan, blueprint: FeePlanBlueprint
end
