class WebhookEventBlueprint < Blueprinter::Base
  identifier :id

  fields :tenant_id, :payment_intent_id, :provider_name, :provider_event_id,
         :event_type, :payload_hash, :signature_verified, :processing_status,
         :processed_at, :failure_reason, :created_at, :updated_at
end
