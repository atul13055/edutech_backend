require "test_helper"

module Api
  module V1
    module Auth
      class SessionsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @tenant = Tenant.create!(name: "Branch Auth", subdomain: "branch-auth", code: "BAUTH-001")
          @role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant)

          @user = User.create!(
            first_name: "Active",
            last_name: "User",
            email: "active.user@example.com",
            password: "password123",
            role: @role,
            tenant: @tenant,
            status: "active"
          )

          @inactive_user = User.create!(
            first_name: "Inactive",
            last_name: "User",
            email: "inactive.user@example.com",
            password: "password123",
            role: @role,
            tenant: @tenant,
            status: "inactive"
          )
        end

        test "successful login returns access token, refresh token, and user blueprint" do
          post api_v1_auth_login_url, params: { email: "active.user@example.com", password: "password123" }

          assert_response :success
          json = response.parsed_body

          assert json["success"]
          assert_not_nil json["data"]["access_token"]
          assert_not_nil json["data"]["refresh_token"]
          assert_equal @user.id, json["data"]["user"]["id"]

          # Verify sensitive security fields are completely absent from response
          assert_nil json["data"]["user"]["password_digest"]
          assert_nil json["data"]["user"]["password"]
          assert_nil json["data"]["token_digest"]
          assert_nil json["data"]["user"]["refresh_tokens"]

          # Verify decoded JWT payload attributes
          decoded = Authentication::JwtService.decode_access_token(json["data"]["access_token"])
          assert_equal @user.id, decoded[:sub]
          assert_equal @tenant.id, decoded[:tenant_id]
          assert_equal "branch_admin", decoded[:role]
          assert_not_nil decoded[:exp]
          assert_not_nil decoded[:iat]
          assert_not_nil decoded[:jti]
        end

        test "login ignores client-supplied tenant_id override attempt" do
          other_tenant = Tenant.create!(name: "Other Tenant", subdomain: "other", code: "OTH-001")

          post api_v1_auth_login_url, params: {
            email: "active.user@example.com",
            password: "password123",
            tenant_id: other_tenant.id
          }

          assert_response :success
          json = response.parsed_body

          decoded = Authentication::JwtService.decode_access_token(json["data"]["access_token"])
          # Token tenant_id remains user's true tenant, ignoring payload tenant_id
          assert_equal @tenant.id, decoded[:tenant_id]
          assert_not_equal other_tenant.id, decoded[:tenant_id]
        end

        test "login with invalid password fails with 401 generic error" do
          post api_v1_auth_login_url, params: { email: "active.user@example.com", password: "wrongpassword" }

          assert_response :unauthorized
          json = response.parsed_body

          assert_not json["success"]
          assert_equal [ "Invalid email or password" ], json["errors"]
        end

        test "login with non-existent email fails with 401 generic error" do
          post api_v1_auth_login_url, params: { email: "nonexistent@example.com", password: "password123" }

          assert_response :unauthorized
          json = response.parsed_body

          assert_not json["success"]
          assert_equal [ "Invalid email or password" ], json["errors"]
        end

        test "login with missing email or missing password fails safely" do
          post api_v1_auth_login_url, params: { email: "", password: "password123" }
          assert_response :unauthorized
          assert_equal [ "Invalid email or password" ], response.parsed_body["errors"]

          post api_v1_auth_login_url, params: { email: "active.user@example.com", password: "" }
          assert_response :unauthorized
          assert_equal [ "Invalid email or password" ], response.parsed_body["errors"]
        end

        test "login with inactive account fails with 401" do
          post api_v1_auth_login_url, params: { email: "inactive.user@example.com", password: "password123" }

          assert_response :unauthorized
          json = response.parsed_body

          assert_not json["success"]
          assert_equal [ "Invalid email or password" ], json["errors"]
        end

        test "refresh endpoint rotates refresh token and returns new tokens" do
          login_res = Authentication::JwtService.issue_refresh_token(@user)

          post api_v1_auth_refresh_url, params: { refresh_token: login_res[:raw_token] }

          assert_response :success
          json = response.parsed_body

          assert json["success"]
          assert_not_nil json["data"]["access_token"]
          assert_not_nil json["data"]["refresh_token"]
          assert_not_equal login_res[:raw_token], json["data"]["refresh_token"]

          # Verify old token is revoked
          assert login_res[:refresh_token].reload.revoked_at.present?

          # Verify token_digest is never returned in response payload
          assert_nil json["data"]["token_digest"]
        end

        test "refresh token reuse triggers automatic revocation of all user sessions" do
          # Create active session 1 and session 2
          res1 = Authentication::JwtService.issue_refresh_token(@user)
          res2 = Authentication::JwtService.issue_refresh_token(@user)

          # Rotate session 1
          post api_v1_auth_refresh_url, params: { refresh_token: res1[:raw_token] }
          assert_response :success

          # Attempt to reuse old session 1 token
          post api_v1_auth_refresh_url, params: { refresh_token: res1[:raw_token] }

          assert_response :unauthorized
          json = response.parsed_body
          assert_not json["success"]

          # Verify session 2 has been automatically revoked as part of reuse protection
          assert res2[:refresh_token].reload.revoked_at.present?
        end

        test "refresh endpoint rejects missing or invalid refresh token" do
          post api_v1_auth_refresh_url, params: { refresh_token: "invalid_token_str" }

          assert_response :unauthorized
          json = response.parsed_body

          assert_not json["success"]
        end

        test "logout revokes refresh token" do
          refresh_res = Authentication::JwtService.issue_refresh_token(@user)

          delete api_v1_auth_logout_url, params: { refresh_token: refresh_res[:raw_token] }

          assert_response :success
          json = response.parsed_body

          assert json["success"]
          assert_equal "Logged out successfully", json["data"]["message"]

          assert refresh_res[:refresh_token].reload.revoked_at.present?

          # Subsequent attempt to refresh using logged out token is rejected
          post api_v1_auth_refresh_url, params: { refresh_token: refresh_res[:raw_token] }
          assert_response :unauthorized
        end
      end
    end
  end
end
