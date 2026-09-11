require "test_helper"

module Api
  module V1
    module Admin
      class PaymentIntentsControllerTest < ActionDispatch::IntegrationTest
        def setup
          @tenant1 = Tenant.create!(name: "Branch 1 PICtrl", subdomain: "b1-pictrl", code: "B1PICTRL-100", status: "active")
          @tenant2 = Tenant.create!(name: "Branch 2 PICtrl", subdomain: "b2-pictrl", code: "B2PICTRL-100", status: "active")

          @admin_role1 = Role.create!(name: "Branch Admin 1", key: "branch_admin", tenant: @tenant1)
          @admin_role2 = Role.create!(name: "Branch Admin 2", key: "branch_admin", tenant: @tenant2)
          @student_role = Role.create!(name: "Student Role", key: "student", tenant: @tenant1)

          @admin1 = User.create!(tenant: @tenant1, role: @admin_role1, first_name: "Admin1", email: "admin1_pictrl@example.com", password: "password123")
          @admin2 = User.create!(tenant: @tenant2, role: @admin_role2, first_name: "Admin2", email: "admin2_pictrl@example.com", password: "password123")
          @student_user = User.create!(tenant: @tenant1, role: @student_role, first_name: "Student1", email: "stu1_pictrl@example.com", password: "password123")

          @token1 = Authentication::JwtService.issue_access_token(@admin1)
          @token2 = Authentication::JwtService.issue_access_token(@admin2)
          @student_token = Authentication::JwtService.issue_access_token(@student_user)

          @student1 = Student.create!(tenant: @tenant1, first_name: "Frank", roll_number: "S101")
          @student2 = Student.create!(tenant: @tenant2, first_name: "Grace", roll_number: "S102")

          @plan1 = FeePlan.create!(tenant: @tenant1, name: "Plan 1", total_amount: 5000.0, currency: "INR")
          @plan2 = FeePlan.create!(tenant: @tenant2, name: "Plan 2", total_amount: 6000.0, currency: "INR")

          @asg1 = StudentFeeAssignment.create!(tenant: @tenant1, student: @student1, fee_plan: @plan1)
          @asg2 = StudentFeeAssignment.create!(tenant: @tenant2, student: @student2, fee_plan: @plan2)

          @intent1 = PaymentIntent.create!(tenant: @tenant1, student: @student1, student_fee_assignment: @asg1, amount: 2000.0, payment_method: "cash", idempotency_key: "pictrl-idem-1")
          @intent2 = PaymentIntent.create!(tenant: @tenant2, student: @student2, student_fee_assignment: @asg2, amount: 3000.0, payment_method: "upi", idempotency_key: "pictrl-idem-2")
        end

        test "admin can list own tenant payment intents" do
          get api_v1_admin_payment_intents_url,
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal 1, json["data"].length
          assert_equal @intent1.id, json["data"].first["id"]
        end

        test "admin can create payment intent" do
          post api_v1_admin_payment_intents_url,
               params: {
                 payment_intent: {
                   student_fee_assignment_id: @asg1.id,
                   amount: 1500.0,
                   currency: "INR",
                   payment_method: "upi",
                   provider_name: "razorpay",
                   provider_order_id: "ord_new_100",
                   idempotency_key: "pictrl-new-intent"
                 }
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :created
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal @tenant1.id, json["data"]["tenant_id"]
          assert_equal "1500.0", json["data"]["amount"].to_s
          assert_equal "created", json["data"]["status"]
        end

        test "admin cannot view another tenant payment intent" do
          get api_v1_admin_payment_intent_url(@intent2.id),
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :not_found
        end

        test "admin can reconcile payment intent" do
          intent_unknown = PaymentIntent.create!(
            tenant: @tenant1,
            student: @student1,
            student_fee_assignment: @asg1,
            amount: 1000.0,
            payment_method: "upi",
            idempotency_key: "rec-ctrl-key",
            status: "unknown"
          )

          post reconcile_api_v1_admin_payment_intent_url(intent_unknown.id),
               params: {
                 result_status: "succeeded",
                 provider_transaction_id: "TXN-RECON-CTRL"
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal "reconciled", json["data"]["status"]
        end

        test "student user is denied payment intent creation" do
          post api_v1_admin_payment_intents_url,
               params: {
                 payment_intent: {
                   student_fee_assignment_id: @asg1.id,
                   amount: 1000.0,
                   payment_method: "cash",
                   idempotency_key: "stu-intent-attempt"
                 }
               },
               headers: { "Authorization" => "Bearer #{@student_token}" },
               as: :json

          assert_response :forbidden
        end
      end
    end
  end
end
