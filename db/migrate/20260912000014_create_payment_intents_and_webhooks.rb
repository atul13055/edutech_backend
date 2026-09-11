class CreatePaymentIntentsAndWebhooks < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_intents, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :student, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :student_fee_assignment, type: :uuid, null: false, foreign_key: { on_delete: :restrict }
      t.references :fee_payment, type: :uuid, null: true, foreign_key: { on_delete: :restrict }
      t.references :fee_installment, type: :uuid, null: true, foreign_key: { on_delete: :restrict }
      t.references :created_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }

      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :currency, null: false, default: "INR"
      t.string :payment_method, null: false
      t.string :provider_name
      t.string :provider_order_id
      t.string :provider_transaction_id
      t.string :client_reference
      t.string :idempotency_key, null: false
      t.string :request_hash
      t.string :status, null: false, default: "created"
      t.string :failure_code
      t.text :failure_message
      t.string :provider_status
      t.datetime :expires_at
      t.datetime :succeeded_at
      t.datetime :failed_at
      t.datetime :unknown_at
      t.datetime :reconciled_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :payment_intents, [ :tenant_id, :idempotency_key ], unique: true, name: "idx_payment_intents_tenant_idempotency"
    add_index :payment_intents, [ :tenant_id, :student_id ], name: "idx_payment_intents_tenant_student"
    add_index :payment_intents, [ :tenant_id, :student_fee_assignment_id ], name: "idx_payment_intents_tenant_assignment"
    add_index :payment_intents, [ :tenant_id, :status ], name: "idx_payment_intents_tenant_status"
    add_index :payment_intents, [ :provider_name, :provider_order_id ], name: "idx_payment_intents_provider_order"
    add_index :payment_intents, [ :provider_name, :provider_transaction_id ], name: "idx_payment_intents_provider_tx"

    create_table :webhook_events, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: true, foreign_key: { on_delete: :cascade }
      t.references :payment_intent, type: :uuid, null: true, foreign_key: { on_delete: :nullify }

      t.string :provider_name, null: false
      t.string :provider_event_id, null: false
      t.string :event_type, null: false
      t.string :payload_hash, null: false
      t.jsonb :raw_payload, default: {}
      t.boolean :signature_verified, null: false, default: false
      t.string :processing_status, null: false, default: "received"
      t.datetime :processed_at
      t.text :failure_reason

      t.timestamps
    end

    add_index :webhook_events, [ :provider_name, :provider_event_id ], unique: true, name: "idx_webhook_events_provider_event"
    add_index :webhook_events, [ :tenant_id, :processing_status ], name: "idx_webhook_events_tenant_status"
  end
end
