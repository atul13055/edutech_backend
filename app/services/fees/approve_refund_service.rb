module Fees
  class ApproveRefundService
    class Error < StandardError; end

    attr_reader :payment_refund_id, :user, :notes

    def initialize(payment_refund_id, user: nil, notes: nil)
      @payment_refund_id = payment_refund_id
      @user = user
      @notes = notes
    end

    def call
      PaymentRefund.transaction do
        refund = PaymentRefund.lock("FOR UPDATE").find(payment_refund_id)

        return refund if refund.status == "approved" || refund.status == "completed"

        unless %w[requested processing].include?(refund.status)
          raise Error, "Cannot approve refund in status '#{refund.status}'"
        end

        updates = { approved_by_id: user&.id, approved_at: Time.current }
        updates[:notes] = notes if notes.present?

        refund.transition_to!("approved", updates)
        refund
      end
    end
  end
end
