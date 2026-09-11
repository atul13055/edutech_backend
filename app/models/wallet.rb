class Wallet < ApplicationRecord
  acts_as_tenant :tenant

  belongs_to :tenant
  has_many :wallet_transactions, dependent: :restrict_with_error

  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
end
