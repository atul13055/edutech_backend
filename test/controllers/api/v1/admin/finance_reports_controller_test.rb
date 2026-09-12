require "test_helper"

module Api
  module V1
    module Admin
      class FinanceReportsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @tenant = Tenant.create!(name: "API Fin Tenant", subdomain: "api-fin", code: "API-FIN-100", status: "active")
          @other_tenant = Tenant.create!(name: "Other API Tenant", subdomain: "oth-api-fin", code: "OTH-FIN-100", status: "active")

          @admin_role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant)
          @student_role = Role.create!(name: "Student Role", key: "student", tenant: @tenant)
          @other_admin_role = Role.create!(name: "Other Admin", key: "branch_admin", tenant: @other_tenant)

          @admin = User.create!(tenant: @tenant, role: @admin_role, first_name: "Admin", email: "admin_apifin@example.com", password: "password123")
          @student_user = User.create!(tenant: @tenant, role: @student_role, first_name: "Stu", email: "stu_apifin@example.com", password: "password123")
          @other_admin = User.create!(tenant: @other_tenant, role: @other_admin_role, first_name: "OthAdmin", email: "othadmin_apifin@example.com", password: "password123")

          @admin_token = Authentication::JwtService.issue_access_token(@admin)
          @student_token = Authentication::JwtService.issue_access_token(@student_user)
          @other_admin_token = Authentication::JwtService.issue_access_token(@other_admin)

          @headers = { "Authorization" => "Bearer #{@admin_token}", "Accept" => "application/json" }

          @student = Student.create!(tenant: @tenant, first_name: "Grace", roll_number: "STU-API-FIN-1")
          @fee_plan = FeePlan.create!(tenant: @tenant, name: "Plan API Fin", total_amount: 10000.0, currency: "INR")
          @assignment = StudentFeeAssignment.create!(tenant: @tenant, student: @student, fee_plan: @fee_plan)

          @payment = FeePayment.create!(
            tenant: @tenant,
            student: @student,
            student_fee_assignment: @assignment,
            amount: 4000.0,
            currency: "INR",
            payment_method: "upi",
            status: "completed",
            idempotency_key: "fp-api-fin-1",
            paid_at: Time.current
          )

          @refund = PaymentRefund.create!(
            tenant: @tenant,
            fee_payment: @payment,
            student: @student,
            student_fee_assignment: @assignment,
            requested_by: @admin,
            approved_by: @admin,
            amount: 1000.0,
            currency: "INR",
            reason: "API Refund test",
            status: "completed",
            idempotency_key: "pr-api-fin-1",
            completed_at: Time.current
          )
        end

        test "admin can fetch collection summary report" do
          get "/api/v1/admin/finance/reports/collection_summary", headers: @headers

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal "collection_summary", json["data"]["report_type"]
          assert_equal "4000.0", json["data"]["gross_collection"].to_s
          assert_equal "1000.0", json["data"]["completed_refunds"].to_s
          assert_equal "3000.0", json["data"]["net_collection"].to_s
        end

        test "admin can fetch payment methods breakdown report" do
          get "/api/v1/admin/finance/reports/payment_methods", headers: @headers

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal "payment_methods", json["data"]["report_type"]
          assert_equal 5, json["data"]["methods"].length
        end

        test "admin can fetch outstanding fees report" do
          get "/api/v1/admin/finance/reports/outstanding_fees", headers: @headers

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal "outstanding_fees", json["data"]["report_type"]
          assert_equal 1, json["data"]["assignments"].length
        end

        test "admin can fetch student ledger report" do
          get "/api/v1/admin/finance/reports/student_ledger", params: { student_id: @student.id }, headers: @headers

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal "student_ledger", json["data"]["report_type"]
          assert_equal 1, json["data"]["ledgers"].length
        end

        test "admin can fetch refunds summary report" do
          get "/api/v1/admin/finance/reports/refunds", headers: @headers

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal "refunds_summary", json["data"]["report_type"]
          assert_equal "1000.0", json["data"]["totals"]["completed_refunds_amount"].to_s
        end

        test "admin can fetch payment intents summary report" do
          get "/api/v1/admin/finance/reports/payment_intents", headers: @headers

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal "payment_intents_summary", json["data"]["report_type"]
        end

        test "admin can fetch daily collection report" do
          get "/api/v1/admin/finance/reports/daily_collection", headers: @headers

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal "daily_collection", json["data"]["report_type"]
        end

        test "admin can fetch settlement summary report" do
          get "/api/v1/admin/finance/reports/settlement_summary", headers: @headers

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal "settlement_summary", json["data"]["report_type"]
          assert_equal "3000.0", json["data"]["net_settlement_amount"].to_s
        end

        test "invalid date range returns 422 unprocessable entity" do
          get "/api/v1/admin/finance/reports/collection_summary", params: { from: "2026-09-10", to: "2026-09-01" }, headers: @headers

          assert_response :unprocessable_entity
          json = JSON.parse(response.body)
          assert_not json["success"]
          assert json["errors"].first.include?("cannot be after")
        end

        test "unauthorized user is denied access with 403 forbidden" do
          student_headers = { "Authorization" => "Bearer #{@student_token}", "Accept" => "application/json" }
          get "/api/v1/admin/finance/reports/collection_summary", headers: student_headers

          assert_response :forbidden
        end

        test "other tenant admin receives isolated report with zero data from first tenant" do
          other_headers = { "Authorization" => "Bearer #{@other_admin_token}", "Accept" => "application/json" }
          get "/api/v1/admin/finance/reports/collection_summary", headers: other_headers

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal "0.0", json["data"]["gross_collection"].to_s
          assert_equal "0.0", json["data"]["net_collection"].to_s
        end
      end
    end
  end
end
