class Student < ApplicationRecord
  acts_as_tenant :tenant

  belongs_to :tenant
  belongs_to :user, optional: true
  has_many :admissions, dependent: :destroy

  before_validation :normalize_attributes

  validates :first_name, presence: true, length: { maximum: 100 }
  validates :last_name, length: { maximum: 100 }, allow_blank: true
  validates :roll_number, presence: true,
                          length: { maximum: 50 },
                          uniqueness: { scope: :tenant_id, case_sensitive: false }
  validates :status, presence: true, inclusion: { in: %w[active inactive graduated dropped] }
  validates :gender, inclusion: { in: %w[male female other] }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  private

  def normalize_attributes
    self.roll_number = roll_number.to_s.strip.upcase if roll_number.present?
    self.email = email.to_s.strip.downcase if email.present?
    self.first_name = first_name.to_s.strip if first_name.present?
    self.last_name = last_name.to_s.strip if last_name.present?
    self.phone = phone.to_s.strip if phone.present?
    self.guardian_name = guardian_name.to_s.strip if guardian_name.present?
    self.guardian_phone = guardian_phone.to_s.strip if guardian_phone.present?
    self.gender = gender.to_s.strip.downcase if gender.present?
    self.status = "active" if status.blank?
  end
end
