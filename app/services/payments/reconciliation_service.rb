module Payments
  class ReconciliationService
    class Error < StandardError; end

    attr_reader :payment_intent_id, :result_status, :provider_transaction_id,
                :failure_code, :failure_message, :notes, :user

    def initialize(payment_intent_id, result_status:, provider_transaction_id: nil, failure_code: nil, failure_message: nil, notes: nil, user: nil)
      @payment_intent_id = payment_intent_id
      @result_status = result_status.to_s.strip.downcase
      @provider_transaction_id = provider_transaction_id
      @failure_code = failure_code
      @failure_message = failure_message
      @notes = notes
      @user = user
    end

    def call
      validate_inputs!

      PaymentIntent.transaction do
        intent = PaymentIntent.lock("FOR UPDATE").find(payment_intent_id)

        if intent.status == "reconciled"
          return intent
        end

        case result_status
        when "succeeded"
          FinalizePaymentIntentService.new(
            intent,
            provider_transaction_id: provider_transaction_id,
            user: user
          ).call

          intent.reload
          intent.transition_to!("reconciled", reconciled_at: Time.current)
          intent
        when "failed"
          if intent.status != "failed"
            intent.transition_to!("failed", failure_code: failure_code, failure_message: failure_message)
          end
          intent.transition_to!("reconciled", reconciled_at: Time.current)
          intent
        when "inconclusive", "unknown"
          if intent.status != "unknown"
            intent.transition_to!("unknown", unknown_at: Time.current)
          end
          intent
        else
          raise Error, "Unsupported reconciliation result status: #{result_status}"
        end
      end
    end

    private

    def validate_inputs!
      raise Error, "PaymentIntent ID is required" if payment_intent_id.blank?
      raise Error, "Result status is required" if result_status.blank?
      unless %w[succeeded failed inconclusive unknown].include?(result_status)
        raise Error, "Invalid result_status: #{result_status}. Must be succeeded, failed, or inconclusive."
      end
    end
  end
end
