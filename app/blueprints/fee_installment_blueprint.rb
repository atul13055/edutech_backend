class FeeInstallmentBlueprint < Blueprinter::Base
  identifier :id

  fields :tenant_id,
         :fee_plan_id,
         :installment_number,
         :name,
         :amount,
         :due_days_offset,
         :status,
         :created_at,
         :updated_at
end
