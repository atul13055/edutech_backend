class Batch < ApplicationRecord
  acts_as_tenant :tenant

  belongs_to :tenant
  belongs_to :course, -> { unscope(where: :tenant_id) }
  belongs_to :trainer, class_name: "User", optional: true

  has_many :batch_schedules, dependent: :destroy

  before_validation :normalize_attributes

  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true,
                   length: { maximum: 50 },
                   uniqueness: { scope: :tenant_id, case_sensitive: false }
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }
  validates :start_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[upcoming active completed cancelled] }

  validate :validate_end_date_after_start_date
  validate :validate_course_belongs_to_tenant_or_global
  validate :validate_trainer_belongs_to_tenant

  private

  def normalize_attributes
    self.code = code.to_s.strip.upcase if code.present?
    self.name = name.to_s.strip if name.present?
    self.description = description.to_s.strip if description.present?
    self.capacity = 30 if capacity.blank?
    self.status = "upcoming" if status.blank?
  end

  def validate_end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be on or after start date")
    end
  end

  def validate_course_belongs_to_tenant_or_global
    return if course.blank?

    if course.tenant_id.present? && course.tenant_id != tenant_id
      errors.add(:course, "must belong to your tenant or be a global course")
    end
  end

  def validate_trainer_belongs_to_tenant
    return if trainer.blank?

    if trainer.tenant_id.present? && trainer.tenant_id != tenant_id
      errors.add(:trainer, "must belong to your tenant")
    end
  end
end
