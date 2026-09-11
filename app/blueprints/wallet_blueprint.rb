class WalletBlueprint < Blueprinter::Base
  identifier :id

  fields :tenant_id, :balance, :currency, :created_at, :updated_at

  field :balance do |wallet|
    wallet.balance.to_s("F")
  end
end
