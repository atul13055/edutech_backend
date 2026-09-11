module Fees
  class CreateRefundService
    class Error < StandardError; end
    class IdempotencyConflictError < Error; end
    class PaymentNotFoundError < Error; end
    class InvalidPaymentStatusError < Error; end
    class CurrencyMismatchError < Error; end
    class OverRefundError < Error; end

    attr_reader :fee_payment_id, :amount, :currency, :reason,
                :idempotency_key, :notes, :auto_process, :user

    def initialize(params = {}, user: nil)
      @fee_payment_id = params[:fee_payment_id]
      @amount = parse_decimal(params[:amount])
      @currency = (params[:currency] || "INR").to_s.strip.upcase
      @reason = params[:reason].to_s.strip
      @idempotency_key = params[:idempotency_key].to_s.strip
      @notes = params[:notes]
      @auto_process = params[:auto_process] == true || params[:auto_process] == "true"
      @user = user
    end

    def call
      validate_inputs!

      existing_refund = PaymentRefund.find_by(idempotency_key: idempotency_key)
      return verify_idempotent_replay!(existing_refund) if existing_refund

      target_tenant_id = Current.tenant&.id || user&.tenant_id
      raise Error, "Tenant context required to process refund" unless target_tenant_id

      PaymentRefund.transaction do
        fee_payment = FeePayment.lock("FOR UPDATE").find_by(id: fee_payment_id)
        raise PaymentNotFoundError, "Fee payment not found" unless fee_payment

        if fee_payment.tenant_id != target_tenant_id
          raise PaymentCollectionService::CrossTenantError, "Fee payment does not belong to user tenant"
        end

        unless fee_payment.status == "completed"
          raise InvalidPaymentStatusError, "Cannot refund payment with status '#{fee_payment.status}'"
        end

        if currency != fee_payment.currency
          raise CurrencyMismatchError, "Refund currency '#{currency}' does not match payment currency '#{fee_payment.currency}'"
        end

        max_refundable = fee_payment.refundable_amount
        if amount > max_refundable
          raise OverRefundError, "Refund amount (#{amount}) exceeds refundable balance (#{max_refundable})"
        end

        payload_hash = compute_payload_hash

        initial_status = auto_process ? "completed" : "requested"
        now = Time.current

        refund = PaymentRefund.create!(
          tenant_id: target_tenant_id,
          fee_payment_id: fee_payment.id,
          student_id: fee_payment.student_id,
          student_fee_assignment_id: fee_payment.student_fee_assignment_id,
          requested_by_id: user&.id,
          approved_by_id: auto_process ? user&.id : nil,
          amount: amount,
          currency: currency,
          reason: reason,
          status: initial_status,
          idempotency_key: idempotency_key,
          request_hash: payload_hash,
          notes: notes,
          requested_at: now,
          approved_at: auto_process ? now : nil,
          processed_at: auto_process ? now : nil,
          completed_at: auto_process ? now : nil
        )

        refund
      end
    rescue ActiveRecord::RecordNotUnique
      retry_refund = PaymentRefund.find_by(idempotency_key: idempotency_key)
      if retry_refund
        verify_idempotent_replay!(retry_refund)
      else
        raise
      end
    end

    private

    def validate_inputs!
      raise Error, "Fee payment ID is required" if fee_payment_id.blank?
      raise Error, "Idempotency key is required" if idempotency_key.blank?
      raise Error, "Refund amount must be greater than zero" if amount.nil? || amount <= 0
      raise Error, "Refund reason is required" if reason.blank?
    end

    def compute_payload_hash
      Digest::SHA256.hexdigest("#{fee_payment_id}:#{amount}:#{currency}:#{reason}")
    end

    def verify_idempotent_replay!(refund)
      current_hash = compute_payload_hash
      if refund.request_hash.present? && refund.request_hash != current_hash
        raise IdempotencyConflictError, "Idempotency key reused with different refund parameters"
      end
      refund
    end

    def parse_decimal(val)
      return nil if val.nil? || val.to_s.strip.empty?
      BigDecimal(val.to_s)
    rescue ArgumentError
      nil
    end
  end
end
