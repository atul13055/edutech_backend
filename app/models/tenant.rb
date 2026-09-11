class Tenant < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :roles, dependent: :destroy
  has_many :students, dependent: :destroy
  has_many :courses, dependent: :destroy
  has_many :batches, dependent: :destroy
  has_many :batch_schedules, dependent: :destroy
  has_many :leads, dependent: :destroy
  has_many :lead_follow_ups, dependent: :destroy
  has_many :admissions, dependent: :destroy
  has_one :wallet, dependent: :destroy
  has_many :wallet_transactions, dependent: :destroy

  before_validation :normalize_attributes

  validates :name, presence: true, length: { maximum: 255 }
  validates :subdomain, presence: true,
                        length: { maximum: 63 },
                        uniqueness: { case_sensitive: false },
                        format: { with: /\A[a-z0-9\-]+\z/, message: "must contain only lowercase letters, numbers, and hyphens" }
  validates :code, presence: true,
                   length: { maximum: 50 },
                   uniqueness: { case_sensitive: false },
                   format: { with: /\A[A-Z0-9\-]+\z/, message: "must contain only uppercase letters, numbers, and hyphens" }
  validates :status, presence: true, inclusion: { in: %w[active suspended inactive] }
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :time_zone, presence: true

  private

  def normalize_attributes
    self.subdomain = subdomain.to_s.strip.downcase if subdomain.present?
    self.code = code.to_s.strip.upcase if code.present?
    self.contact_email = contact_email.to_s.strip.downcase if contact_email.present?
    self.contact_phone = contact_phone.to_s.strip if contact_phone.present?
    self.time_zone = "UTC" if time_zone.blank?
  end
end
