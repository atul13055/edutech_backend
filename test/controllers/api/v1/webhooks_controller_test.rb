require "test_helper"

module Api
  module V1
    class WebhooksControllerTest < ActionDispatch::IntegrationTest
      def setup
        @tenant = Tenant.create!(name: "Webhook Ctrl Branch", subdomain: "whctrl-intent", code: "WHCTRL-100", status: "active")
        @student = Student.create!(tenant: @tenant, first_name: "George", roll_number: "SG100")
        @plan = FeePlan.create!(tenant: @tenant, name: "Plan WH", total_amount: 4000.0, currency: "INR")
        @asg = StudentFeeAssignment.create!(tenant: @tenant, student: @student, fee_plan: @plan)

        @intent = PaymentIntent.create!(
          tenant: @tenant,
          student: @student,
          student_fee_assignment: @asg,
          amount: 2000.0,
          currency: "INR",
          payment_method: "upi",
          provider_name: "phonepe",
          provider_order_id: "order_phonepe_99",
          idempotency_key: "whctrl-intent-key"
        )
      end

      test "rejects webhook with missing or unverified signature" do
        post api_v1_webhooks_payments_url,
             params: {
               provider_name: "phonepe",
               provider_event_id: "evt_phonepe_1",
               event_type: "payment.succeeded",
               provider_order_id: "order_phonepe_99"
             },
             as: :json

        assert_response :bad_request
        json = JSON.parse(response.body)
        assert_not json["success"]
        assert_includes json["errors"], "Unverified webhook event signature"
      end

      test "accepts verified webhook signature and processes finalization" do
        post api_v1_webhooks_payments_url,
             params: {
               provider_name: "phonepe",
               provider_event_id: "evt_phonepe_2",
               event_type: "payment.succeeded",
               provider_order_id: "order_phonepe_99",
               provider_transaction_id: "TXN-PHONEPE-777",
               amount: 2000.0,
               currency: "INR"
             },
             headers: {
               "X-Webhook-Signature-Verified" => "true",
               "X-Tenant-ID" => @tenant.id
             },
             as: :json

        assert_response :success
        json = JSON.parse(response.body)
        assert json["success"]
        assert_equal "processed", json["data"]["processing_status"]

        @intent.reload
        assert_equal "succeeded", @intent.status
        assert_equal BigDecimal("2000.0"), @asg.reload.total_paid_amount
      end
    end
  end
end
