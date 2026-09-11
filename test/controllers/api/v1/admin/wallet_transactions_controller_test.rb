require "test_helper"

module Api
  module V1
    module Admin
      class WalletTransactionsControllerTest < ActionDispatch::IntegrationTest
        def setup
          @tenant1 = Tenant.create!(name: "Branch 1 WTx", subdomain: "b1-wtx-ctrl", code: "B1WTXCTRL-100", status: "active")
          @tenant2 = Tenant.create!(name: "Branch 2 WTx", subdomain: "b2-wtx-ctrl", code: "B2WTXCTRL-100", status: "active")

          @admin_role1 = Role.create!(name: "Branch Admin 1", key: "branch_admin", tenant: @tenant1)
          @admin_role2 = Role.create!(name: "Branch Admin 2", key: "branch_admin", tenant: @tenant2)

          @branch_admin1 = User.create!(
            email: "branch_admin1_txs@example.com",
            password: "password123",
            first_name: "Branch",
            last_name: "Admin1",
            role: @admin_role1,
            tenant: @tenant1
          )

          @branch_admin2 = User.create!(
            email: "branch_admin2_txs@example.com",
            password: "password123",
            first_name: "Branch",
            last_name: "Admin2",
            role: @admin_role2,
            tenant: @tenant2
          )

          @token1 = Authentication::JwtService.issue_access_token(@branch_admin1)
          @token2 = Authentication::JwtService.issue_access_token(@branch_admin2)

          @tx1 = WalletManagement::TransactionService.credit(tenant: @tenant1, amount: 1000.00, reference: "CR1")
          @tx2 = WalletManagement::TransactionService.debit(tenant: @tenant1, amount: 200.00, reference: "DB1")
          @tx_other = WalletManagement::TransactionService.credit(tenant: @tenant2, amount: 500.00, reference: "CR2")
        end

        test "branch admin can list ledger transactions with pagination" do
          get api_v1_admin_wallet_transactions_url,
              headers: { "Authorization" => "Bearer #{@token1}" },
              as: :json

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal 2, json["data"].length
          assert_equal 2, json["meta"]["total_count"]
        end

        test "branch admin can filter ledger transactions by transaction_type" do
          get api_v1_admin_wallet_transactions_url,
              params: { transaction_type: "debit" },
              headers: { "Authorization" => "Bearer #{@token1}", "Accept" => "application/json" }

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal 1, json["data"].length
          assert_equal "debit", json["data"].first["transaction_type"]
        end

        test "branch admin can view specific transaction details" do
          get api_v1_admin_wallet_transaction_url(@tx1.id),
              headers: { "Authorization" => "Bearer #{@token1}" },
              as: :json

          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal @tx1.id, json["data"]["id"]
        end

        test "branch admin cannot view transaction belonging to another tenant" do
          get api_v1_admin_wallet_transaction_url(@tx_other.id),
              headers: { "Authorization" => "Bearer #{@token1}" },
              as: :json

          assert_response :not_found
        end
      end
    end
  end
end
