class User < ApplicationRecord
  has_secure_password

  belongs_to :tenant, optional: true
  belongs_to :role
  has_many :permissions, through: :role
  has_many :refresh_tokens, dependent: :destroy
  has_many :trained_batches, class_name: "Batch", foreign_key: "trainer_id", dependent: :nullify
  has_many :assigned_leads, class_name: "Lead", foreign_key: "assigned_to_id", dependent: :nullify
  has_many :lead_follow_ups, dependent: :destroy
  has_many :counseled_admissions, class_name: "Admission", foreign_key: "counselor_id", dependent: :nullify

  validates :first_name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, presence: true, inclusion: { in: %w[active suspended inactive] }
  validates :password, presence: true, length: { minimum: 8 }, allow_nil: true
end
