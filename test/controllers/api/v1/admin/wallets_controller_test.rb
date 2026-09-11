require "test_helper"

module Api
  module V1
    module Admin
      class WalletsControllerTest < ActionDispatch::IntegrationTest
        def setup
          @tenant1 = Tenant.create!(name: "Branch 1 Ctrl", subdomain: "b1-ctrl-w", code: "B1CTRLW-100", status: "active")
          @tenant2 = Tenant.create!(name: "Branch 2 Ctrl", subdomain: "b2-ctrl-w", code: "B2CTRLW-100", status: "active")

          @super_role = Role.create!(name: "Super Admin", key: "super_admin", tenant_id: nil)
          @admin_role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant1)

          @super_admin = User.create!(
            email: "super_admin_wallets_ctrl@example.com",
            password: "password123",
            first_name: "Super",
            last_name: "Admin",
            role: @super_role,
            tenant: nil
          )

          @branch_admin = User.create!(
            email: "branch_admin_wallets_ctrl@example.com",
            password: "password123",
            first_name: "Branch",
            last_name: "Admin",
            role: @admin_role,
            tenant: @tenant1
          )

          @super_token = Authentication::JwtService.issue_access_token(@super_admin)
          @branch_token = Authentication::JwtService.issue_access_token(@branch_admin)

          @wallet1 = Wallet.find_or_create_by!(tenant_id: @tenant1.id)
          @wallet1.update!(balance: 1000.00)
        end

        test "branch admin can view own wallet balance" do
          get api_v1_admin_wallet_url,
              headers: { "Authorization" => "Bearer #{@branch_token}" },
              as: :json

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal @tenant1.id, json["data"]["tenant_id"]
          assert_equal "1000.0", json["data"]["balance"]
        end

        test "super admin can credit tenant wallet via credit action" do
          post credit_api_v1_admin_wallet_url,
               params: { tenant_id: @tenant1.id, amount: "500.00", reference: "GRANT_500" },
               headers: { "Authorization" => "Bearer #{@super_token}" },
               as: :json

          assert_response :created
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal "1500.0", json["data"]["wallet"]["balance"]
          assert_equal "500.0", json["data"]["transaction"]["amount"]
        end

        test "branch admin cannot credit wallet" do
          post credit_api_v1_admin_wallet_url,
               params: { amount: "500.00" },
               headers: { "Authorization" => "Bearer #{@branch_token}" },
               as: :json

          assert_response :forbidden
        end

        test "branch admin can debit own wallet" do
          post debit_api_v1_admin_wallet_url,
               params: { amount: "200.00", reference: "ROYALTY_FEE" },
               headers: { "Authorization" => "Bearer #{@branch_token}" },
               as: :json

          assert_response :created
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal "800.0", json["data"]["wallet"]["balance"]
          assert_equal "200.0", json["data"]["transaction"]["amount"]
        end

        test "debit returns 422 unprocessable_entity when balance is insufficient" do
          post debit_api_v1_admin_wallet_url,
               params: { amount: "5000.00" },
               headers: { "Authorization" => "Bearer #{@branch_token}" },
               as: :json

          assert_response :unprocessable_entity
          json = JSON.parse(response.body)
          assert_not json["success"]
          assert_includes json["errors"].first, "Insufficient wallet balance"
        end
      end
    end
  end
end
