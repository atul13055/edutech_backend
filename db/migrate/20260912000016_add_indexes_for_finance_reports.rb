class AddIndexesForFinanceReports < ActiveRecord::Migration[8.1]
  def change
    add_index :fee_payments, [ :tenant_id, :paid_at ], name: "idx_fee_payments_tenant_paid_at"
    add_index :payment_refunds, [ :tenant_id, :completed_at ], name: "idx_payment_refunds_tenant_completed_at"
    add_index :payment_intents, [ :tenant_id, :created_at ], name: "idx_payment_intents_tenant_created_at"
  end
end
