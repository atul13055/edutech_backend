module Fees
  class PaymentCollectionService
    class Error < StandardError; end
    class ValidationError < Error; end
    class OverpaymentError < Error; end
    class CurrencyMismatchError < Error; end
    class IdempotencyConflictError < Error; end
    class CrossTenantError < Error; end

    attr_reader :assignment_id, :amount, :currency, :payment_method,
                :payment_reference, :idempotency_key, :paid_at, :notes,
                :fee_installment_id, :collected_by, :request_tenant_id, :metadata

    def self.call(params, collector: nil, tenant_id: nil)
      new(params, collector: collector, tenant_id: tenant_id).call
    end

    def initialize(params, collector: nil, tenant_id: nil)
      @assignment_id = params[:student_fee_assignment_id] || params[:assignment_id]
      @amount = parse_decimal(params[:amount])
      @currency = params[:currency].to_s.strip.upcase
      @payment_method = params[:payment_method].to_s.strip.downcase
      @payment_reference = params[:payment_reference].to_s.strip.presence
      @idempotency_key = params[:idempotency_key].to_s.strip
      @paid_at = params[:paid_at].present? ? Time.zone.parse(params[:paid_at].to_s) : Time.current
      @notes = params[:notes].to_s.strip.presence
      @fee_installment_id = params[:fee_installment_id]
      @metadata = params[:metadata] || {}

      @collected_by = collector || Current.user
      @request_tenant_id = tenant_id || Current.tenant&.id || @collected_by&.tenant_id
    end

    def call
      validate_inputs!

      existing = FeePayment.unscoped.find_by(tenant_id: target_tenant_id, idempotency_key: idempotency_key)
      if existing.present?
        return verify_idempotent_replay!(existing)
      end

      StudentFeeAssignment.transaction do
        assignment = StudentFeeAssignment.unscoped.lock("FOR UPDATE").find_by(id: assignment_id)
        raise ValidationError, "Student fee assignment not found" if assignment.blank?

        if assignment.tenant_id != target_tenant_id
          raise CrossTenantError, "Cross tenant access denied"
        end

        existing_locked = FeePayment.unscoped.find_by(tenant_id: target_tenant_id, idempotency_key: idempotency_key)
        if existing_locked.present?
          return verify_idempotent_replay!(existing_locked)
        end

        effective_currency = currency.presence || assignment.currency
        if effective_currency != assignment.currency
          raise CurrencyMismatchError, "Payment currency (#{effective_currency}) does not match assignment currency (#{assignment.currency})"
        end

        completed_payments_total = FeePayment.unscoped
                                            .where(student_fee_assignment_id: assignment.id, status: "completed")
                                            .sum(:amount)

        outstanding = assignment.total_amount - completed_payments_total

        if amount > outstanding
          raise OverpaymentError, "Payment amount (#{amount}) exceeds outstanding assignment balance (#{outstanding})"
        end

        installment = nil
        if fee_installment_id.present?
          installment = FeeInstallment.unscoped.find_by(id: fee_installment_id)
          if installment.blank? || installment.tenant_id != target_tenant_id || installment.fee_plan_id != assignment.fee_plan_id
            raise ValidationError, "Invalid fee installment provided for this assignment"
          end
        end

        req_hash = compute_payload_hash(assignment.id, amount, effective_currency, payment_method)

        payment = FeePayment.create!(
          tenant_id: assignment.tenant_id,
          student_id: assignment.student_id,
          student_fee_assignment_id: assignment.id,
          collected_by_id: collected_by&.id,
          amount: amount,
          currency: effective_currency,
          payment_method: payment_method,
          status: "completed",
          payment_reference: payment_reference,
          idempotency_key: idempotency_key,
          request_hash: req_hash,
          paid_at: paid_at,
          notes: notes,
          metadata: metadata
        )

        if installment.present?
          FeePaymentAllocation.create!(
            tenant_id: assignment.tenant_id,
            fee_payment_id: payment.id,
            fee_installment_id: installment.id,
            amount: amount
          )
        end

        new_total_paid = completed_payments_total + amount
        if new_total_paid >= assignment.total_amount && assignment.status == "active"
          assignment.update!(status: "completed")
        end

        payment
      end
    rescue ActiveRecord::RecordNotUnique
      existing = FeePayment.unscoped.find_by!(tenant_id: target_tenant_id, idempotency_key: idempotency_key)
      verify_idempotent_replay!(existing)
    end

    private

    def target_tenant_id
      @target_tenant_id ||= request_tenant_id
    end

    def validate_inputs!
      raise ValidationError, "Idempotency key is required" if idempotency_key.blank?
      raise ValidationError, "Student fee assignment ID is required" if assignment_id.blank?
      raise ValidationError, "Payment amount must be greater than 0" if amount.blank? || amount <= 0
      raise ValidationError, "Invalid payment method" unless FeePayment::ALLOWED_PAYMENT_METHODS.include?(payment_method)
    end

    def parse_decimal(val)
      return nil if val.blank?
      BigDecimal(val.to_s)
    rescue ArgumentError
      raise ValidationError, "Invalid decimal amount format"
    end

    def compute_payload_hash(asg_id, amt, curr, method)
      Digest::SHA256.hexdigest("#{asg_id}:#{amt.to_s('F')}:#{curr}:#{method}")
    end

    def verify_idempotent_replay!(payment)
      current_hash = compute_payload_hash(
        assignment_id || payment.student_fee_assignment_id,
        amount || payment.amount,
        currency.presence || payment.currency,
        payment_method.presence || payment.payment_method
      )
      if payment.request_hash.present? && payment.request_hash != current_hash
        raise IdempotencyConflictError, "Idempotency key reused with different payload parameters"
      end
      payment
    end
  end
end
