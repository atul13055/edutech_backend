class FeePayment < ApplicationRecord
  acts_as_tenant :tenant

  ALLOWED_PAYMENT_METHODS = %w[cash upi bank_transfer cheque online].freeze
  ALLOWED_STATUSES = %w[pending completed failed].freeze

  belongs_to :tenant
  belongs_to :student
  belongs_to :student_fee_assignment
  belongs_to :collected_by, class_name: "User", optional: true

  has_many :fee_payment_allocations, dependent: :destroy
  has_one :payment_intent, dependent: :nullify
  has_many :refunds, class_name: "PaymentRefund", dependent: :restrict_with_error

  def total_refunded_amount
    refunds.where(status: "completed").sum(:amount)
  end

  def refundable_amount
    return BigDecimal("0.0") unless status == "completed"

    [ amount - total_refunded_amount, BigDecimal("0.0") ].max
  end

  before_validation :normalize_attributes

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true, length: { is: 3 }, format: { with: /\A[A-Z]{3}\z/ }
  validates :payment_method, presence: true, inclusion: { in: ALLOWED_PAYMENT_METHODS }
  validates :status, presence: true, inclusion: { in: ALLOWED_STATUSES }
  validates :idempotency_key, presence: true, uniqueness: { scope: :tenant_id }
  validates :paid_at, presence: true

  validate :validate_student_tenant
  validate :validate_assignment_tenant
  validate :validate_collected_by_tenant
  validate :validate_currency_matches_assignment
  validate :prevent_immutable_modification, on: :update
  before_destroy :prevent_destruction

  private

  def normalize_attributes
    self.payment_method = payment_method.to_s.strip.downcase if payment_method.present?
    self.currency = currency.to_s.strip.upcase if currency.present?
    self.currency = "INR" if currency.blank?
    self.payment_reference = payment_reference.to_s.strip if payment_reference.present?
    self.status = "completed" if status.blank?
    self.paid_at ||= Time.current
  end

  def validate_student_tenant
    return if student.blank?

    if student.tenant_id != tenant_id
      errors.add(:student, "must belong to your tenant")
    end
  end

  def validate_assignment_tenant
    return if student_fee_assignment.blank?

    if student_fee_assignment.tenant_id != tenant_id
      errors.add(:student_fee_assignment, "must belong to your tenant")
    end
  end

  def validate_collected_by_tenant
    return if collected_by.blank?

    if collected_by.tenant_id.present? && collected_by.tenant_id != tenant_id
      errors.add(:collected_by, "must belong to your tenant")
    end
  end

  def validate_currency_matches_assignment
    return if student_fee_assignment.blank? || currency.blank?

    if currency != student_fee_assignment.currency
      errors.add(:currency, "must match assignment currency (#{student_fee_assignment.currency})")
    end
  end

  def prevent_immutable_modification
    if status_was == "completed"
      immutable_fields = %w[amount currency student_fee_assignment_id student_id payment_method payment_reference paid_at idempotency_key]
      changed_immutable = immutable_fields & changed
      if changed_immutable.any?
        errors.add(:base, "Completed fee payments are immutable and cannot be modified")
      end
    end
  end

  def prevent_destruction
    if status == "completed"
      errors.add(:base, "Completed fee payments cannot be deleted")
      throw :abort
    end
  end
end
