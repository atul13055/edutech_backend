module Fees
  class ProcessRefundService
    class Error < StandardError; end

    attr_reader :payment_refund_id, :refund_reference, :user

    def initialize(payment_refund_id, refund_reference: nil, user: nil)
      @payment_refund_id = payment_refund_id
      @refund_reference = refund_reference
      @user = user
    end

    def call
      PaymentRefund.transaction do
        refund = PaymentRefund.lock("FOR UPDATE").find(payment_refund_id)

        return refund if refund.status == "completed"

        if refund.status == "rejected" || refund.status == "cancelled"
          raise Error, "Cannot process a #{refund.status} refund"
        end

        fee_payment = FeePayment.lock("FOR UPDATE").find(refund.fee_payment_id)

        completed_refunds = fee_payment.refunds.where(status: "completed").where.not(id: refund.id).sum(:amount)
        max_refundable = [ fee_payment.amount - completed_refunds, BigDecimal("0.0") ].max

        if refund.amount > max_refundable
          raise CreateRefundService::OverRefundError, "Refund amount (#{refund.amount}) exceeds max available refundable balance (#{max_refundable})"
        end

        updates = {
          processed_at: Time.current,
          completed_at: Time.current
        }
        updates[:refund_reference] = refund_reference if refund_reference.present?
        updates[:approved_by_id] ||= user.id if user.present? && refund.approved_by_id.blank?

        refund.transition_to!("completed", updates)
        refund
      end
    end
  end
end
