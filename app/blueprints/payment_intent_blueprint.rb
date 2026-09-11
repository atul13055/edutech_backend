class PaymentIntentBlueprint < Blueprinter::Base
  identifier :id

  fields :tenant_id, :student_id, :student_fee_assignment_id, :fee_payment_id,
         :fee_installment_id, :created_by_id, :amount, :currency, :payment_method,
         :provider_name, :provider_order_id, :provider_transaction_id,
         :client_reference, :idempotency_key, :status, :failure_code, :failure_message,
         :provider_status, :expires_at, :succeeded_at, :failed_at, :unknown_at,
         :reconciled_at, :metadata, :created_at, :updated_at

  field :amount do |intent|
    intent.amount.to_s
  end
end
