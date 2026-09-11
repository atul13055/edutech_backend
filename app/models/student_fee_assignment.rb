class StudentFeeAssignment < ApplicationRecord
  acts_as_tenant :tenant

  belongs_to :tenant
  belongs_to :student
  belongs_to :admission, optional: true
  belongs_to :fee_plan

  before_validation :copy_fee_plan_snapshot, on: :create
  before_validation :normalize_attributes

  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, length: { is: 3 }, format: { with: /\A[A-Z]{3}\z/ }
  validates :assigned_at, presence: true
  validates :status, presence: true, inclusion: { in: %w[active cancelled completed] }

  validate :validate_student_tenant
  validate :validate_admission_tenant
  validate :validate_fee_plan_tenant
  validate :validate_no_duplicate_active_assignment, on: :create

  private

  def copy_fee_plan_snapshot
    target_plan = fee_plan || (fee_plan_id.present? ? FeePlan.unscoped.find_by(id: fee_plan_id) : nil)
    return if target_plan.blank?

    self.total_amount = target_plan.total_amount if total_amount.blank? || total_amount.zero?
    self.currency = target_plan.currency if currency.blank?
    self.assigned_at ||= Time.current
  end

  def normalize_attributes
    self.currency = currency.to_s.strip.upcase if currency.present?
    self.currency = "INR" if currency.blank?
    self.assigned_at ||= Time.current
    self.status = "active" if status.blank?
  end

  def validate_student_tenant
    return if student.blank?

    if student.tenant_id != tenant_id
      errors.add(:student, "must belong to your tenant")
    end
  end

  def validate_admission_tenant
    return if admission.blank?

    if admission.tenant_id != tenant_id
      errors.add(:admission, "must belong to your tenant")
    end
  end

  def validate_fee_plan_tenant
    return if fee_plan.blank?

    if fee_plan.tenant_id != tenant_id
      errors.add(:fee_plan, "must belong to your tenant")
    end
  end

  def validate_no_duplicate_active_assignment
    return if student.blank? || fee_plan.blank?

    scope = StudentFeeAssignment.where(tenant_id: tenant_id, student_id: student_id, fee_plan_id: fee_plan_id, status: "active")
    scope = scope.where(admission_id: admission_id) if admission_id.present?

    if scope.exists?
      errors.add(:base, "Fee plan has already been assigned to this student")
    end
  end
end
