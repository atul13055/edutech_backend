require "test_helper"

module Api
  module V1
    module Admin
      class FeeInstallmentsControllerTest < ActionDispatch::IntegrationTest
        def setup
          @tenant1 = Tenant.create!(name: "Branch 1 InstCtrl", subdomain: "b1-ictrl", code: "B1ICTRL-100", status: "active")
          @admin_role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant1)
          @admin = User.create!(tenant: @tenant1, role: @admin_role, first_name: "Admin1", email: "admin1_ictrl@example.com", password: "password123")
          @token = Authentication::JwtService.issue_access_token(@admin)

          @fee_plan = FeePlan.create!(tenant: @tenant1, name: "Plan X", total_amount: 2000.0, installment_count: 2)
          @inst = FeeInstallment.create!(tenant: @tenant1, fee_plan: @fee_plan, installment_number: 1, amount: 1000.0)
        end

        test "admin can list and create fee installments" do
          get api_v1_admin_fee_plan_installments_url(@fee_plan.id),
              headers: { "Authorization" => "Bearer #{@token}", "Accept" => "application/json" }

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal 1, json["data"].length

          post api_v1_admin_fee_plan_installments_url(@fee_plan.id),
               params: {
                 installment: {
                   installment_number: 2,
                   amount: 1000.0
                 }
               },
               headers: { "Authorization" => "Bearer #{@token}" },
               as: :json

          assert_response :created
          json2 = JSON.parse(response.body)
          assert json2["success"]
          assert_equal 2, json2["data"]["installment_number"]
        end
      end
    end
  end
end
