class FeePaymentBlueprint < Blueprinter::Base
  identifier :id

  fields :tenant_id,
         :student_id,
         :student_fee_assignment_id,
         :collected_by_id,
         :amount,
         :currency,
         :payment_method,
         :status,
         :payment_reference,
         :idempotency_key,
         :paid_at,
         :notes,
         :metadata,
         :created_at,
         :updated_at

  association :student, blueprint: StudentBlueprint
  association :student_fee_assignment, blueprint: StudentFeeAssignmentBlueprint
  association :fee_payment_allocations, blueprint: FeePaymentAllocationBlueprint
  association :collected_by, blueprint: UserBlueprint
end
