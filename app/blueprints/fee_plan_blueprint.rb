class FeePlanBlueprint < Blueprinter::Base
  identifier :id

  fields :tenant_id,
         :course_id,
         :name,
         :description,
         :total_amount,
         :currency,
         :installment_count,
         :status,
         :created_at,
         :updated_at

  association :course, blueprint: CourseBlueprint
  association :fee_installments, blueprint: FeeInstallmentBlueprint
end
