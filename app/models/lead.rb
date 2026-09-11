class Lead < ApplicationRecord
  acts_as_tenant :tenant

  belongs_to :tenant
  belongs_to :assigned_to, class_name: "User", optional: true
  belongs_to :interested_course, -> { unscope(where: :tenant_id) }, class_name: "Course", optional: true
  belongs_to :interested_batch, class_name: "Batch", optional: true

  has_many :follow_ups, class_name: "LeadFollowUp", dependent: :destroy
  has_many :admissions, dependent: :nullify

  before_validation :normalize_attributes

  validates :name, presence: true, length: { maximum: 255 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :status, presence: true, inclusion: { in: %w[new contacted interested follow_up converted lost] }

  validate :validate_interested_course_tenant
  validate :validate_interested_batch_tenant
  validate :validate_assigned_to_tenant

  private

  def normalize_attributes
    self.name = name.to_s.strip if name.present?
    self.email = email.to_s.strip.downcase if email.present?
    self.phone = phone.to_s.strip if phone.present?
    self.source = "walk_in" if source.blank?
    self.status = "new" if status.blank?
  end

  def validate_interested_course_tenant
    return if interested_course.blank?

    if interested_course.tenant_id.present? && interested_course.tenant_id != tenant_id
      errors.add(:interested_course, "must belong to your tenant or be a global course")
    end
  end

  def validate_interested_batch_tenant
    return if interested_batch.blank?

    if interested_batch.tenant_id != tenant_id
      errors.add(:interested_batch, "must belong to your tenant")
    end
  end

  def validate_assigned_to_tenant
    return if assigned_to.blank?

    if assigned_to.tenant_id.present? && assigned_to.tenant_id != tenant_id
      errors.add(:assigned_to, "must belong to your tenant")
    end
  end
end
