class Admission < ApplicationRecord
  acts_as_tenant :tenant

  belongs_to :tenant
  belongs_to :lead, optional: true
  belongs_to :student
  belongs_to :course, -> { unscope(where: :tenant_id) }
  belongs_to :batch, optional: true
  belongs_to :counselor, class_name: "User", optional: true

  before_validation :generate_admission_number, on: :create
  before_validation :normalize_attributes

  validates :admission_number, presence: true, uniqueness: { scope: :tenant_id, case_sensitive: false }
  validates :admission_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[applied confirmed rejected cancelled] }

  validate :validate_course_tenant
  validate :validate_batch_tenant
  validate :validate_student_tenant
  validate :validate_counselor_tenant

  private

  def generate_admission_number
    return if admission_number.present?

    prefix = "ADM-#{Time.current.strftime('%Y%m')}"
    random_suffix = SecureRandom.alphanumeric(4).upcase
    self.admission_number = "#{prefix}-#{random_suffix}"
  end

  def normalize_attributes
    self.admission_number = admission_number.to_s.strip.upcase if admission_number.present?
    self.admission_date = Date.today if admission_date.blank?
    self.status = "applied" if status.blank?
  end

  def validate_course_tenant
    return if course.blank?

    if course.tenant_id.present? && course.tenant_id != tenant_id
      errors.add(:course, "must belong to your tenant or be a global course")
    end
  end

  def validate_batch_tenant
    return if batch.blank?

    if batch.tenant_id != tenant_id
      errors.add(:batch, "must belong to your tenant")
    end
  end

  def validate_student_tenant
    return if student.blank?

    if student.tenant_id != tenant_id
      errors.add(:student, "must belong to your tenant")
    end
  end

  def validate_counselor_tenant
    return if counselor.blank?

    if counselor.tenant_id.present? && counselor.tenant_id != tenant_id
      errors.add(:counselor, "must belong to your tenant")
    end
  end
end
