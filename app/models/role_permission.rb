class RolePermission < ApplicationRecord
  belongs_to :role
  belongs_to :permission

  validates :role_id, presence: true
  validates :permission_id, presence: true, uniqueness: { scope: :role_id }
end
