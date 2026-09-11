require "test_helper"

module Api
  module V1
    module Admin
      class FeePaymentsControllerTest < ActionDispatch::IntegrationTest
        def setup
          @tenant1 = Tenant.create!(name: "Branch 1 PayCtrl", subdomain: "b1-pctrl", code: "B1PCTRL-100", status: "active")
          @tenant2 = Tenant.create!(name: "Branch 2 PayCtrl", subdomain: "b2-pctrl", code: "B2PCTRL-100", status: "active")

          @admin_role1 = Role.create!(name: "Branch Admin 1", key: "branch_admin", tenant: @tenant1)
          @admin_role2 = Role.create!(name: "Branch Admin 2", key: "branch_admin", tenant: @tenant2)
          @student_role = Role.create!(name: "Student Role", key: "student", tenant: @tenant1)

          @admin1 = User.create!(tenant: @tenant1, role: @admin_role1, first_name: "Admin1", email: "admin1_pctrl@example.com", password: "password123")
          @admin2 = User.create!(tenant: @tenant2, role: @admin_role2, first_name: "Admin2", email: "admin2_pctrl@example.com", password: "password123")
          @student_user = User.create!(tenant: @tenant1, role: @student_role, first_name: "Student1", email: "stu1_pctrl@example.com", password: "password123")

          @token1 = Authentication::JwtService.issue_access_token(@admin1)
          @token2 = Authentication::JwtService.issue_access_token(@admin2)
          @student_token = Authentication::JwtService.issue_access_token(@student_user)

          @student1 = Student.create!(tenant: @tenant1, first_name: "Frank", roll_number: "S101")
          @student2 = Student.create!(tenant: @tenant2, first_name: "Grace", roll_number: "S102")

          @plan1 = FeePlan.create!(tenant: @tenant1, name: "Plan 1", total_amount: 5000.0, currency: "INR")
          @plan2 = FeePlan.create!(tenant: @tenant2, name: "Plan 2", total_amount: 6000.0, currency: "INR")

          @asg1 = StudentFeeAssignment.create!(tenant: @tenant1, student: @student1, fee_plan: @plan1)
          @asg2 = StudentFeeAssignment.create!(tenant: @tenant2, student: @student2, fee_plan: @plan2)

          @pay1 = FeePayment.create!(tenant: @tenant1, student: @student1, student_fee_assignment: @asg1, amount: 2000.0, payment_method: "cash", idempotency_key: "ctrl-idem-1")
          @pay2 = FeePayment.create!(tenant: @tenant2, student: @student2, student_fee_assignment: @asg2, amount: 3000.0, payment_method: "upi", idempotency_key: "ctrl-idem-2")
        end

        test "admin can list own tenant fee payments" do
          get api_v1_admin_fee_payments_url,
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal 1, json["data"].length
          assert_equal @pay1.id, json["data"].first["id"]
        end

        test "admin can create fee payment using payment collection service" do
          post api_v1_admin_fee_payments_url,
               params: {
                 fee_payment: {
                   student_fee_assignment_id: @asg1.id,
                   amount: 2000.0,
                   currency: "INR",
                   payment_method: "upi",
                   payment_reference: "UPI-999",
                   idempotency_key: "ctrl-new-idem"
                 }
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :created
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal @tenant1.id, json["data"]["tenant_id"]
          assert_equal "2000.0", json["data"]["amount"].to_s
          assert_equal "completed", json["data"]["status"]
        end

        test "rejects overpayment request via API" do
          post api_v1_admin_fee_payments_url,
               params: {
                 fee_payment: {
                   student_fee_assignment_id: @asg1.id,
                   amount: 10000.0,
                   currency: "INR",
                   payment_method: "cash",
                   idempotency_key: "ctrl-overpay"
                 }
               },
               headers: { "Authorization" => "Bearer #{@token1}" },
               as: :json

          assert_response :unprocessable_entity
        end

        test "admin cannot view another tenant fee payment" do
          get api_v1_admin_fee_payment_url(@pay2.id),
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :not_found
        end

        test "returns payment summary for student fee assignment" do
          get payment_summary_api_v1_admin_student_fee_assignment_url(@asg1.id),
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal @asg1.id, json["data"]["student_fee_assignment_id"]
          assert_equal "5000.0", json["data"]["total_amount"].to_s
          assert_equal "2000.0", json["data"]["total_paid_amount"].to_s
          assert_equal "3000.0", json["data"]["outstanding_amount"].to_s
        end

        test "student user is denied fee payment collection" do
          post api_v1_admin_fee_payments_url,
               params: {
                 fee_payment: {
                   student_fee_assignment_id: @asg1.id,
                   amount: 1000.0,
                   payment_method: "cash",
                   idempotency_key: "stu-pay-attempt"
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
