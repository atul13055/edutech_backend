class Permission < ApplicationRecord
  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  validates :name, presence: true
  validates :key, presence: true, uniqueness: true
  validates :module_name, presence: true
end
