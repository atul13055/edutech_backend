require "test_helper"

module Api
  module V1
    module Admin
      class PaymentRefundsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @tenant = Tenant.create!(name: "Test Tenant API", subdomain: "test-api", code: "TT-API-1", status: "active")
          @other_tenant = Tenant.create!(name: "Other Tenant API", subdomain: "other-api", code: "OT-API-1", status: "active")

          @admin_role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant)
          @counselor_role = Role.create!(name: "Counselor", key: "counselor", tenant: @tenant)
          @other_role = Role.create!(name: "Other Admin", key: "branch_admin", tenant: @other_tenant)

          @admin = User.create!(tenant: @tenant, role: @admin_role, first_name: "Admin", email: "admin_api@example.com", password: "password123")
          @counselor = User.create!(tenant: @tenant, role: @counselor_role, first_name: "Counselor", email: "counselor_api@example.com", password: "password123")
          @other_user = User.create!(tenant: @other_tenant, role: @other_role, first_name: "Other", email: "other_api@example.com", password: "password123")

          @student = Student.create!(tenant: @tenant, first_name: "Eve", roll_number: "STU-API-1")
          @fee_plan = FeePlan.create!(tenant: @tenant, name: "Plan API", total_amount: 10000.0, currency: "INR")
          @assignment = StudentFeeAssignment.create!(tenant: @tenant, student: @student, fee_plan: @fee_plan)

          @fee_payment = FeePayment.create!(
            tenant: @tenant,
            student: @student,
            student_fee_assignment: @assignment,
            amount: 5000.0,
            currency: "INR",
            payment_method: "upi",
            status: "completed",
            idempotency_key: "fp-api-1",
            paid_at: Time.current
          )

          @token = Authentication::JwtService.issue_access_token(@admin)
          @headers = { "Authorization" => "Bearer #{@token}", "Accept" => "application/json" }
        end

        test "admin can create refund request" do
          post api_v1_admin_payment_refunds_url,
               headers: @headers,
               params: {
                 payment_refund: {
                   fee_payment_id: @fee_payment.id,
                   amount: "1500.00",
                   currency: "INR",
                   reason: "Discount adjustment",
                   idempotency_key: "api-ref-1"
                 }
               },
               as: :json

          assert_response :created
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal "requested", json["data"]["status"]
          assert_equal "1500.0", json["data"]["amount"].to_s
        end

        test "admin can approve and process refund" do
          refund = Fees::CreateRefundService.new({
            fee_payment_id: @fee_payment.id,
            amount: "1000.00",
            currency: "INR",
            reason: "Admin approved refund",
            idempotency_key: "api-ref-approve-1"
          }, user: @admin).call

          post approve_api_v1_admin_payment_refund_url(refund.id),
               headers: @headers,
               as: :json

          assert_response :success
          json = JSON.parse(response.body)
          assert_equal "approved", json["data"]["status"]

          post process_refund_api_v1_admin_payment_refund_url(refund.id),
               headers: @headers,
               params: { refund_reference: "REF-GW-999" },
               as: :json

          assert_response :success
          json2 = JSON.parse(response.body)
          assert_equal "completed", json2["data"]["status"]
          assert_equal "REF-GW-999", json2["data"]["refund_reference"]
        end

        test "unauthorized user cannot process refund" do
          counselor_token = Authentication::JwtService.issue_access_token(@counselor)
          counselor_headers = { "Authorization" => "Bearer #{counselor_token}", "Accept" => "application/json" }

          refund = Fees::CreateRefundService.new({
            fee_payment_id: @fee_payment.id,
            amount: "500.00",
            currency: "INR",
            reason: "Unauthorized attempt",
            idempotency_key: "api-ref-unauth-1"
          }, user: @admin).call

          post process_refund_api_v1_admin_payment_refund_url(refund.id),
               headers: counselor_headers,
               as: :json

          assert_response :forbidden
        end

        test "cross-tenant refund lookup returns 404" do
          other_token = Authentication::JwtService.issue_access_token(@other_user)
          other_headers = { "Authorization" => "Bearer #{other_token}", "Accept" => "application/json" }

          refund = Fees::CreateRefundService.new({
            fee_payment_id: @fee_payment.id,
            amount: "500.00",
            currency: "INR",
            reason: "Cross tenant check",
            idempotency_key: "api-ref-xtenant-1"
          }, user: @admin).call

          get api_v1_admin_payment_refund_url(refund.id),
              headers: other_headers

          assert_response :not_found
        end
      end
    end
  end
end
