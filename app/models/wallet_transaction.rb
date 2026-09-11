class WalletTransaction < ApplicationRecord
  acts_as_tenant :tenant

  belongs_to :wallet
  belongs_to :tenant

  validates :transaction_type, presence: true, inclusion: { in: %w[credit debit] }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :balance_before, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :balance_after, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :idempotency_key, uniqueness: { scope: :tenant_id }, allow_nil: true, allow_blank: true

  before_update :prevent_mutation
  before_destroy :prevent_mutation

  private

  def prevent_mutation(*_args)
    errors.add(:base, "Wallet transactions are immutable financial ledger entries and cannot be modified or deleted")
    throw :abort
  end
end
