class FeePaymentAllocation < ApplicationRecord
  acts_as_tenant :tenant

  belongs_to :tenant
  belongs_to :fee_payment
  belongs_to :fee_installment

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :fee_installment_id, uniqueness: { scope: :fee_payment_id }

  validate :validate_installment_belongs_to_assignment_plan

  private

  def validate_installment_belongs_to_assignment_plan
    return if fee_payment.blank? || fee_installment.blank?

    assignment = fee_payment.student_fee_assignment
    return if assignment.blank?

    if fee_installment.fee_plan_id != assignment.fee_plan_id
      errors.add(:fee_installment, "must belong to the fee plan of the assignment")
    end
  end
end
