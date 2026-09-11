class AdmissionBlueprint < Blueprinter::Base
  identifier :id

  fields :tenant_id,
         :lead_id,
         :student_id,
         :course_id,
         :batch_id,
         :counselor_id,
         :admission_number,
         :admission_date,
         :status,
         :notes,
         :created_at,
         :updated_at

  association :student, blueprint: StudentBlueprint
  association :course, blueprint: CourseBlueprint
  association :batch, blueprint: BatchBlueprint

  field :counselor_name do |admission|
    admission.counselor ? "#{admission.counselor.first_name} #{admission.counselor.last_name}".strip : nil
  end
end
