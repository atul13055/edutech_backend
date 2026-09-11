require "test_helper"

module Api
  module V1
    class RoutingTest < ActionDispatch::IntegrationTest
      setup do
        @tenant = Tenant.create!(name: "Routing Branch", subdomain: "routing-b", code: "ROUT-100")
        @role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant)
        @user = User.create!(
          first_name: "RoutingUser",
          email: "routing@example.com",
          password: "password123",
          role: @role,
          tenant: @tenant
        )
        @token = Authentication::JwtService.issue_access_token(@user)
      end

      test "unsupported HTTP verbs on auth endpoints fail safely" do
        get "/api/v1/auth/login"
        assert_response :not_found

        get "/api/v1/auth/refresh"
        assert_response :not_found
      end

      test "API error response structure and HTTP status code mappings" do
        # 401 Unauthorized
        get api_v1_users_url
        assert_response :unauthorized
        json = response.parsed_body
        assert_equal false, json["success"]
        assert json["errors"].is_a?(Array)
        assert_nil json["backtrace"]
        assert_nil json["sql"]

        # 403 Forbidden
        other_tenant = Tenant.create!(name: "Other", subdomain: "other-r", code: "OTH-R1")
        get api_v1_tenant_url(other_tenant), headers: { "Authorization" => "Bearer #{@token}" }
        assert_response :forbidden
        json = response.parsed_body
        assert_equal false, json["success"]
        assert_equal [ "You are not authorized to perform this action" ], json["errors"]
        assert_nil json["backtrace"]

        # 404 Not Found
        non_existent_uuid = SecureRandom.uuid
        get api_v1_user_url(non_existent_uuid), headers: { "Authorization" => "Bearer #{@token}" }
        assert_response :not_found
        json = response.parsed_body
        assert_equal false, json["success"]
        assert_equal [ "Resource not found" ], json["errors"]
        assert_nil json["backtrace"]

        # 422 Unprocessable Entity (Validation Error)
        post api_v1_users_url,
             params: { user: { first_name: "", email: "invalid-email" } },
             headers: { "Authorization" => "Bearer #{@token}" }
        assert_response :unprocessable_entity
        json = response.parsed_body
        assert_equal false, json["success"]
        assert json["errors"].any? { |e| e.include?("email") || e.include?("First name") }
        assert_nil json["backtrace"]
      end
    end
  end
end
