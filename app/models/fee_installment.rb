class FeeInstallment < ApplicationRecord
  acts_as_tenant :tenant

  belongs_to :tenant
  belongs_to :fee_plan

  before_validation :normalize_attributes

  validates :installment_number, presence: true,
                                 numericality: { only_integer: true, greater_than: 0 },
                                 uniqueness: { scope: :fee_plan_id }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :due_days_offset, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: %w[active inactive] }

  private

  def normalize_attributes
    self.name = "Installment #{installment_number}" if name.blank? && installment_number.present?
    self.due_days_offset = 0 if due_days_offset.blank?
    self.status = "active" if status.blank?
  end
end
