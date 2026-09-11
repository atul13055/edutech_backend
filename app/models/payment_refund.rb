class PaymentRefund < ApplicationRecord
  acts_as_tenant :tenant

  ALLOWED_STATUSES = %w[requested approved rejected processing completed failed cancelled].freeze

  VALID_TRANSITIONS = {
    "requested" => %w[approved rejected cancelled processing completed],
    "approved" => %w[processing completed failed cancelled],
    "processing" => %w[completed failed],
    "rejected" => [],
    "cancelled" => [],
    "failed" => %w[processing completed cancelled],
    "completed" => []
  }.freeze

  belongs_to :tenant
  belongs_to :fee_payment
  belongs_to :student
  belongs_to :student_fee_assignment
  belongs_to :requested_by, class_name: "User", optional: true
  belongs_to :approved_by, class_name: "User", optional: true

  before_validation :normalize_attributes

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true, length: { is: 3 }, format: { with: /\A[A-Z]{3}\z/ }
  validates :reason, presence: true
  validates :status, presence: true, inclusion: { in: ALLOWED_STATUSES }
  validates :idempotency_key, presence: true, uniqueness: { scope: :tenant_id }

  validate :validate_student_tenant
  validate :validate_assignment_tenant
  validate :validate_payment_tenant
  validate :validate_currency_matches_payment
  validate :validate_status_transition, on: :update

  def can_transition_to?(new_status)
    allowed = VALID_TRANSITIONS[status] || []
    allowed.include?(new_status.to_s)
  end

  def transition_to!(new_status, attributes = {})
    new_status_str = new_status.to_s
    unless can_transition_to?(new_status_str)
      raise ArgumentError, "Invalid status transition from #{status} to #{new_status_str}"
    end

    timestamp_attr = case new_status_str
    when "approved" then :approved_at
    when "rejected" then :rejected_at
    when "processing" then :processed_at
    when "completed" then :completed_at
    when "failed" then :failed_at
    when "cancelled" then :cancelled_at
    end

    updates = attributes.merge(status: new_status_str)
    updates[timestamp_attr] ||= Time.current if timestamp_attr

    update!(updates)
  end

  private

  def normalize_attributes
    self.currency = currency.to_s.strip.upcase if currency.present?
    self.currency = "INR" if currency.blank?
    self.status = "requested" if status.blank?
    self.requested_at ||= Time.current
  end

  def validate_student_tenant
    return if student.blank?
    errors.add(:student, "must belong to your tenant") if student.tenant_id != tenant_id
  end

  def validate_assignment_tenant
    return if student_fee_assignment.blank?
    errors.add(:student_fee_assignment, "must belong to your tenant") if student_fee_assignment.tenant_id != tenant_id
  end

  def validate_payment_tenant
    return if fee_payment.blank?
    errors.add(:fee_payment, "must belong to your tenant") if fee_payment.tenant_id != tenant_id
  end

  def validate_currency_matches_payment
    return if fee_payment.blank? || currency.blank?
    if currency != fee_payment.currency
      errors.add(:currency, "must match payment currency (#{fee_payment.currency})")
    end
  end

  def validate_status_transition
    if status_changed?
      old_status = status_was
      new_status = status
      allowed = VALID_TRANSITIONS[old_status] || []
      unless allowed.include?(new_status)
        errors.add(:status, "cannot transition from #{old_status} to #{new_status}")
      end
    end
  end
end
