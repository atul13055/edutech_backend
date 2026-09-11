class FeePlan < ApplicationRecord
  acts_as_tenant :tenant

  belongs_to :tenant
  belongs_to :course, -> { unscope(where: :tenant_id) }, optional: true

  has_many :fee_installments, dependent: :destroy
  has_many :student_fee_assignments, dependent: :restrict_with_error

  before_validation :normalize_attributes

  validates :name, presence: true, length: { maximum: 255 }
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, length: { is: 3 }, format: { with: /\A[A-Z]{3}\z/ }
  validates :installment_count, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[active inactive archived] }

  validate :validate_course_belongs_to_tenant_or_global

  private

  def normalize_attributes
    self.name = name.to_s.strip if name.present?
    self.currency = currency.to_s.strip.upcase if currency.present?
    self.total_amount = 0.0 if total_amount.blank?
    self.currency = "INR" if currency.blank?
    self.installment_count = 1 if installment_count.blank?
    self.status = "active" if status.blank?
  end

  def validate_course_belongs_to_tenant_or_global
    return if course.blank?

    if course.tenant_id.present? && course.tenant_id != tenant_id
      errors.add(:course, "must belong to your tenant or be a global course")
    end
  end
end
