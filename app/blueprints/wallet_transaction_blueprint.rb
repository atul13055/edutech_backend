class WalletTransactionBlueprint < Blueprinter::Base
  identifier :id

  fields :wallet_id, :tenant_id, :transaction_type, :reference, :idempotency_key, :metadata, :created_at, :updated_at

  field :amount do |tx|
    tx.amount.to_s("F")
  end

  field :balance_before do |tx|
    tx.balance_before.to_s("F")
  end

  field :balance_after do |tx|
    tx.balance_after.to_s("F")
  end
end
