class Course < ApplicationRecord
  acts_as_tenant :tenant, optional: true

  belongs_to :tenant, optional: true

  has_many :batches, dependent: :restrict_with_error
  has_many :fee_plans, dependent: :nullify

  before_validation :normalize_attributes

  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true,
                   length: { maximum: 50 },
                   uniqueness: { scope: :tenant_id, case_sensitive: false }
  validates :status, presence: true, inclusion: { in: %w[active inactive archived] }
  validates :duration_months, numericality: { only_integer: true, greater_than: 0 }
  validates :base_fee, numericality: { greater_than_or_equal_to: 0 }

  scope :global, -> { where(tenant_id: nil) }
  scope :custom, -> { where.not(tenant_id: nil) }

  private

  def normalize_attributes
    self.code = code.to_s.strip.upcase if code.present?
    self.name = name.to_s.strip if name.present?
    self.description = description.to_s.strip if description.present?
    self.duration_months = 1 if duration_months.blank?
    self.base_fee = 0.0 if base_fee.blank?
    self.status = "active" if status.blank?
  end
end
