class CreateWalletsAndWalletTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :wallets, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.decimal :balance, precision: 12, scale: 2, default: 0.0, null: false
      t.string :currency, default: "INR", null: false

      t.check_constraint "balance >= 0", name: "wallets_balance_non_negative"
      t.timestamps
    end

    create_table :wallet_transactions, id: :uuid do |t|
      t.references :wallet, type: :uuid, null: false, foreign_key: { on_delete: :restrict }
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :transaction_type, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.decimal :balance_before, precision: 12, scale: 2, null: false
      t.decimal :balance_after, precision: 12, scale: 2, null: false
      t.string :reference
      t.string :idempotency_key
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    add_index :wallet_transactions, :idempotency_key, unique: true
    add_index :wallet_transactions, :created_at
    add_index :wallet_transactions, [ :tenant_id, :created_at ]
  end
end
