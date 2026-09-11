class User < ApplicationRecord
  has_secure_password

  belongs_to :tenant, optional: true
  belongs_to :role
  has_many :permissions, through: :role
  has_many :refresh_tokens, dependent: :destroy

  validates :first_name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, presence: true, inclusion: { in: %w[active suspended inactive] }
  validates :password, presence: true, length: { minimum: 8 }, allow_nil: true
end
