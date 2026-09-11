class Role < ApplicationRecord
  belongs_to :tenant, optional: true

  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions
  has_many :users, dependent: :restrict_with_error

  validates :name, presence: true
  validates :key, presence: true, uniqueness: { scope: :tenant_id }
end
