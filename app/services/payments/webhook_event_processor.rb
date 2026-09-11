module Payments
  class WebhookEventProcessor
    class Error < StandardError; end
    class SignatureVerificationError < Error; end
    class MismatchError < Error; end

    attr_reader :provider_name, :provider_event_id, :event_type, :payload,
                :signature_verified, :tenant_id, :provider_order_id,
                :provider_transaction_id

    def initialize(params = {})
      @provider_name = params[:provider_name].to_s.strip.downcase
      @provider_event_id = params[:provider_event_id].to_s.strip
      @event_type = params[:event_type].to_s.strip
      @payload = params[:payload] || params[:raw_payload] || {}
      @signature_verified = ActiveModel::Type::Boolean.new.cast(params[:signature_verified])
      @tenant_id = params[:tenant_id]
      @provider_order_id = params[:provider_order_id] || @payload["provider_order_id"] || @payload["order_id"]
      @provider_transaction_id = params[:provider_transaction_id] || @payload["provider_transaction_id"] || @payload["transaction_id"] || @payload["payment_id"]
    end

    def call
      validate_inputs!

      existing_event = WebhookEvent.find_by(provider_name: provider_name, provider_event_id: provider_event_id)
      return existing_event if existing_event

      payload_hash = Digest::SHA256.hexdigest(payload.to_json)

      event = WebhookEvent.create!(
        provider_name: provider_name,
        provider_event_id: provider_event_id,
        event_type: event_type,
        payload_hash: payload_hash,
        raw_payload: sanitize_payload(payload),
        signature_verified: signature_verified,
        tenant_id: tenant_id,
        processing_status: "received"
      )

      unless signature_verified
        event.update!(processing_status: "ignored", failure_reason: "Unverified webhook signature")
        raise SignatureVerificationError, "Webhook signature verification failed"
      end

      process_event!(event)
      event
    rescue ActiveRecord::RecordNotUnique
      WebhookEvent.find_by!(provider_name: provider_name, provider_event_id: provider_event_id)
    end

    private

    def validate_inputs!
      raise Error, "Provider name is required" if provider_name.blank?
      raise Error, "Provider event ID is required" if provider_event_id.blank?
      raise Error, "Event type is required" if event_type.blank?
    end

    def process_event!(event)
      intent = resolve_intent
      unless intent
        event.update!(processing_status: "failed", failure_reason: "Matching PaymentIntent not found")
        raise Error, "PaymentIntent not found for provider_order_id: #{provider_order_id} or transaction_id: #{provider_transaction_id}"
      end

      event.update!(payment_intent_id: intent.id, tenant_id: intent.tenant_id)

      verify_payload_match!(intent)

      if success_event?
        FinalizePaymentIntentService.new(intent, provider_transaction_id: provider_transaction_id).call
      elsif failure_event?
        intent.transition_to!("failed", failure_code: payload["failure_code"], failure_message: payload["failure_message"])
      end

      event.update!(processing_status: "processed", processed_at: Time.current)
    rescue StandardError => e
      event.update!(processing_status: "failed", failure_reason: e.message) unless event.processing_status == "processed"
      raise
    end

    def resolve_intent
      scope = PaymentIntent.unscoped
      scope = scope.where(tenant_id: tenant_id) if tenant_id.present?

      if provider_order_id.present?
        intent = scope.find_by(provider_name: provider_name, provider_order_id: provider_order_id)
        return intent if intent
      end

      if provider_transaction_id.present?
        intent = scope.find_by(provider_name: provider_name, provider_transaction_id: provider_transaction_id)
        return intent if intent
      end

      intent_id = payload["payment_intent_id"]
      scope.find_by(id: intent_id) if intent_id.present?
    end

    def verify_payload_match!(intent)
      payload_amount = payload["amount"] ? BigDecimal(payload["amount"].to_s) : nil
      if payload_amount && payload_amount != intent.amount
        raise MismatchError, "Webhook amount (#{payload_amount}) mismatch with intent amount (#{intent.amount})"
      end

      payload_currency = payload["currency"] ? payload["currency"].to_s.upcase : nil
      if payload_currency && payload_currency != intent.currency
        raise MismatchError, "Webhook currency (#{payload_currency}) mismatch with intent currency (#{intent.currency})"
      end
    end

    def success_event?
      %w[payment.succeeded payment.captured order.paid succeeded].include?(event_type.downcase) ||
        payload["status"].to_s.downcase == "succeeded"
    end

    def failure_event?
      %w[payment.failed payment.denied failed].include?(event_type.downcase) ||
        payload["status"].to_s.downcase == "failed"
    end

    def sanitize_payload(raw)
      return {} unless raw.is_a?(Hash)
      filtered = raw.deep_dup
      %w[secret key signature password token auth_token].each { |k| filtered.delete(k) }
      filtered
    end
  end
end
