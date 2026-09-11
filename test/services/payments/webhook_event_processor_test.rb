require "test_helper"

module Payments
  class WebhookEventProcessorTest < ActiveSupport::TestCase
    def setup
      @tenant = Tenant.create!(name: "Webhook Branch", subdomain: "wh-intent", code: "WHINT-100", status: "active")
      @student = Student.create!(tenant: @tenant, first_name: "Charlie", roll_number: "SC100")
      @plan = FeePlan.create!(tenant: @tenant, name: "Bronze Plan", total_amount: 5000.0, currency: "INR")
      @asg = StudentFeeAssignment.create!(tenant: @tenant, student: @student, fee_plan: @plan)
      Current.tenant = @tenant

      @intent = PaymentIntent.create!(
        tenant: @tenant,
        student: @student,
        student_fee_assignment: @asg,
        amount: 2500.0,
        currency: "INR",
        payment_method: "upi",
        provider_name: "razorpay",
        provider_order_id: "order_wh_123",
        idempotency_key: "wh-test-intent-1"
      )
    end

    def teardown
      Current.reset
    end

    test "rejects unverified webhook signature" do
      assert_raises(WebhookEventProcessor::SignatureVerificationError) do
        WebhookEventProcessor.new({
          provider_name: "razorpay",
          provider_event_id: "evt_unverified_1",
          event_type: "payment.captured",
          payload: { "order_id" => "order_wh_123", "amount" => 2500.0, "currency" => "INR" },
          signature_verified: false,
          tenant_id: @tenant.id
        }).call
      end

      event = WebhookEvent.find_by(provider_event_id: "evt_unverified_1")
      assert event.persisted?
      assert_equal "ignored", event.processing_status
      assert_includes event.failure_reason, "Unverified webhook signature"
    end

    test "processes verified success webhook and finalizes intent into FeePayment" do
      event = WebhookEventProcessor.new({
        provider_name: "razorpay",
        provider_event_id: "evt_verified_1",
        event_type: "payment.captured",
        payload: { "provider_order_id" => "order_wh_123", "transaction_id" => "TXN-WH-999", "amount" => 2500.0, "currency" => "INR" },
        signature_verified: true,
        tenant_id: @tenant.id
      }).call

      assert_equal "processed", event.processing_status
      assert_equal @intent.id, event.payment_intent_id

      @intent.reload
      assert_equal "succeeded", @intent.status
      assert_not_nil @intent.fee_payment_id
      assert_equal BigDecimal("2500.0"), @asg.reload.total_paid_amount
    end

    test "duplicate webhook event is deduplicated safely without double collection" do
      processor_params = {
        provider_name: "razorpay",
        provider_event_id: "evt_duplicate_1",
        event_type: "payment.captured",
        payload: { "provider_order_id" => "order_wh_123", "transaction_id" => "TXN-WH-888", "amount" => 2500.0, "currency" => "INR" },
        signature_verified: true,
        tenant_id: @tenant.id
      }

      e1 = WebhookEventProcessor.new(processor_params).call
      e2 = WebhookEventProcessor.new(processor_params).call

      assert_equal e1.id, e2.id
      assert_equal 1, FeePayment.where(student_fee_assignment_id: @asg.id).count
    end
  end
end
