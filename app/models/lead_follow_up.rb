class LeadFollowUp < ApplicationRecord
  acts_as_tenant :tenant

  belongs_to :tenant
  belongs_to :lead
  belongs_to :user

  before_validation :normalize_attributes

  validates :follow_up_at, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending completed cancelled] }

  validate :validate_user_belongs_to_tenant

  private

  def normalize_attributes
    self.status = "pending" if status.blank?
  end

  def validate_user_belongs_to_tenant
    return if user.blank?

    if user.tenant_id.present? && user.tenant_id != tenant_id
      errors.add(:user, "must belong to your tenant")
    end
  end
end
