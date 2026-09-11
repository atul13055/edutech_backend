module Payments
  class FinalizePaymentIntentService
    class Error < StandardError; end

    attr_reader :payment_intent, :provider_transaction_id, :user

    def initialize(payment_intent, provider_transaction_id: nil, user: nil)
      @payment_intent = payment_intent
      @provider_transaction_id = provider_transaction_id || payment_intent.provider_transaction_id
      @user = user || payment_intent.created_by
    end

    def call
      raise Error, "Payment Intent required" unless payment_intent

      PaymentIntent.transaction do
        locked_intent = PaymentIntent.lock("FOR UPDATE").find(payment_intent.id)

        if locked_intent.fee_payment_id.present?
          return FeePayment.find(locked_intent.fee_payment_id)
        end

        if locked_intent.status == "failed" || locked_intent.status == "expired"
          raise Error, "Cannot finalize a #{locked_intent.status} payment intent"
        end

        unless %w[created pending processing succeeded unknown].include?(locked_intent.status)
          raise Error, "Cannot finalize payment intent from status #{locked_intent.status}"
        end

        # Ensure tenant context is set for FeePayment collection service
        ActsAsTenant.with_tenant(locked_intent.tenant) do
          Current.tenant = locked_intent.tenant
          fin_key = "intent-fin-#{locked_intent.id}"

          payment = Fees::PaymentCollectionService.new({
            student_fee_assignment_id: locked_intent.student_fee_assignment_id,
            fee_installment_id: locked_intent.fee_installment_id,
            amount: locked_intent.amount,
            currency: locked_intent.currency,
            payment_method: locked_intent.payment_method,
            payment_reference: provider_transaction_id || locked_intent.provider_order_id,
            idempotency_key: fin_key,
            collected_by_id: user&.id,
            tenant_id: locked_intent.tenant_id
          }).call

          updates = {
            fee_payment_id: payment.id,
            status: "succeeded",
            succeeded_at: Time.current
          }
          updates[:provider_transaction_id] = provider_transaction_id if provider_transaction_id.present?

          locked_intent.update!(updates)
          payment
        end
      end
    end
  end
end
