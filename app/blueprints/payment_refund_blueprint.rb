class PaymentRefundBlueprint < Blueprinter::Base
  identifier :id

  fields :tenant_id, :fee_payment_id, :student_id, :student_fee_assignment_id,
         :requested_by_id, :approved_by_id, :amount, :currency, :reason, :status,
         :idempotency_key, :refund_reference, :notes, :requested_at, :approved_at,
         :rejected_at, :processed_at, :completed_at, :failed_at, :cancelled_at,
         :metadata, :created_at, :updated_at
end
