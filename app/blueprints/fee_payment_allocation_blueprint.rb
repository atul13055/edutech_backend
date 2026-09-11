class FeePaymentAllocationBlueprint < Blueprinter::Base
  identifier :id

  fields :tenant_id,
         :fee_payment_id,
         :fee_installment_id,
         :amount,
         :created_at,
         :updated_at

  association :fee_installment, blueprint: FeeInstallmentBlueprint
end
