module Payments
  class CreatePaymentIntentService
    class Error < StandardError; end
    class IdempotencyConflictError < Error; end

    attr_reader :assignment_id, :amount, :currency, :payment_method,
                :provider_name, :provider_order_id, :fee_installment_id,
                :client_reference, :idempotency_key, :metadata, :user

    def initialize(params = {}, user: nil)
      @assignment_id = params[:student_fee_assignment_id] || params[:assignment_id]
      @amount = parse_decimal(params[:amount])
      @currency = (params[:currency] || "INR").to_s.strip.upcase
      @payment_method = params[:payment_method].to_s.strip.downcase
      @provider_name = params[:provider_name]
      @provider_order_id = params[:provider_order_id]
      @fee_installment_id = params[:fee_installment_id]
      @client_reference = params[:client_reference]
      @idempotency_key = params[:idempotency_key].to_s.strip
      @metadata = params[:metadata] || {}
      @user = user
    end

    def call
      validate_inputs!

      existing_intent = PaymentIntent.find_by(idempotency_key: idempotency_key)
      return verify_idempotent_replay!(existing_intent) if existing_intent

      target_tenant_id = Current.tenant&.id || user&.tenant_id
      raise Error, "Tenant context required to create payment intent" unless target_tenant_id

      assignment = StudentFeeAssignment.find_by!(id: assignment_id)

      if assignment.tenant_id != target_tenant_id
        raise Fees::PaymentCollectionService::CrossTenantError, "Assignment does not belong to user tenant"
      end

      if currency != assignment.currency
        raise Fees::PaymentCollectionService::CurrencyMismatchError, "Currency #{currency} does not match assignment currency #{assignment.currency}"
      end

      outstanding = assignment.outstanding_amount
      if amount > outstanding
        raise Fees::PaymentCollectionService::OverpaymentError, "Intent amount (#{amount}) exceeds assignment outstanding balance (#{outstanding})"
      end

      payload_hash = compute_payload_hash

      intent = PaymentIntent.create!(
        tenant_id: target_tenant_id,
        student_id: assignment.student_id,
        student_fee_assignment_id: assignment.id,
        fee_installment_id: fee_installment_id,
        created_by_id: user&.id,
        amount: amount,
        currency: currency,
        payment_method: payment_method,
        provider_name: provider_name,
        provider_order_id: provider_order_id,
        client_reference: client_reference,
        idempotency_key: idempotency_key,
        request_hash: payload_hash,
        status: "created",
        metadata: metadata
      )

      intent
    rescue ActiveRecord::RecordNotUnique
      retry_intent = PaymentIntent.find_by(idempotency_key: idempotency_key)
      if retry_intent
        verify_idempotent_replay!(retry_intent)
      else
        raise
      end
    end

    private

    def validate_inputs!
      raise Error, "Idempotency key is required" if idempotency_key.blank?
      raise Error, "Assignment ID is required" if assignment_id.blank?
      raise Error, "Payment amount must be greater than zero" if amount.nil? || amount <= 0
      raise Error, "Payment method is required" if payment_method.blank?
    end

    def compute_payload_hash
      Digest::SHA256.hexdigest("#{assignment_id}:#{amount}:#{currency}:#{payment_method}:#{provider_name}")
    end

    def verify_idempotent_replay!(intent)
      current_hash = compute_payload_hash
      if intent.request_hash.present? && intent.request_hash != current_hash
        raise IdempotencyConflictError, "Idempotency key reused with different payload parameters"
      end
      intent
    end

    def parse_decimal(val)
      return nil if val.nil? || val.to_s.strip.empty?
      BigDecimal(val.to_s)
    rescue ArgumentError
      nil
    end
  end
end
