require "test_helper"

class TenantScopedTest < ActionDispatch::IntegrationTest
  class TestTenantController < Api::V1::BaseController
    skip_after_action :verify_authorized

    def tenant_info
      render_success(data: {
                       tenant_id: Current.tenant&.id,
                       tenant_name: Current.tenant&.name,
                       acts_as_tenant_id: ActsAsTenant.current_tenant&.id
                     })
    end
  end

  setup do
    @tenant_a = Tenant.create!(name: "Branch A", subdomain: "branch-a", code: "BA-001")
    @tenant_b = Tenant.create!(name: "Branch B", subdomain: "branch-b", code: "BB-001")

    @role_branch = Role.create!(name: "Branch User", key: "branch_user", tenant: @tenant_a)
    @user_a = User.create!(
      first_name: "UserA",
      email: "usera@example.com",
      password: "password123",
      role: @role_branch,
      tenant: @tenant_a
    )
    @token_a = Authentication::JwtService.issue_access_token(@user_a)

    @role_super = Role.create!(name: "Super Admin", key: "super_admin")
    @super_admin = User.create!(
      first_name: "Super",
      email: "superadmin@example.com",
      password: "password123",
      role: @role_super,
      tenant: nil
    )
    @token_super = Authentication::JwtService.issue_access_token(@super_admin)

    Rails.application.routes.draw do
      get "test_tenant" => "tenant_scoped_test/test_tenant#tenant_info"
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test "normal tenant user gets own tenant context automatically" do
    get "/test_tenant", headers: { "Authorization" => "Bearer #{@token_a}" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @tenant_a.id, json["data"]["tenant_id"]
    assert_equal @tenant_a.id, json["data"]["acts_as_tenant_id"]

    # Verify Current is reset after request
    assert_nil Current.tenant
    assert_nil Current.user
  end

  test "normal tenant user cannot switch tenant using X-Tenant-ID header" do
    get "/test_tenant", headers: {
      "Authorization" => "Bearer #{@token_a}",
      "X-Tenant-ID" => @tenant_b.id
    }

    assert_response :forbidden
    json = JSON.parse(response.body)
    assert_equal false, json["success"]
    assert_equal [ "You are not authorized to perform this action" ], json["errors"]
  end

  test "normal tenant user sending matching X-Tenant-ID is accepted" do
    get "/test_tenant", headers: {
      "Authorization" => "Bearer #{@token_a}",
      "X-Tenant-ID" => @tenant_a.id
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @tenant_a.id, json["data"]["tenant_id"]
  end

  test "super admin can resolve an explicitly requested tenant via X-Tenant-ID" do
    get "/test_tenant", headers: {
      "Authorization" => "Bearer #{@token_super}",
      "X-Tenant-ID" => @tenant_b.id
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @tenant_b.id, json["data"]["tenant_id"]
  end

  test "super admin without X-Tenant-ID header remains tenantless" do
    get "/test_tenant", headers: { "Authorization" => "Bearer #{@token_super}" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_nil json["data"]["tenant_id"]
  end

  test "invalid UUID format in X-Tenant-ID is rejected with 400" do
    get "/test_tenant", headers: {
      "Authorization" => "Bearer #{@token_super}",
      "X-Tenant-ID" => "invalid-uuid-format"
    }

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_equal false, json["success"]
    assert_equal [ "Invalid X-Tenant-ID header format" ], json["errors"]
  end

  test "nonexistent tenant ID in X-Tenant-ID is rejected with 404" do
    non_existent_uuid = SecureRandom.uuid

    get "/test_tenant", headers: {
      "Authorization" => "Bearer #{@token_super}",
      "X-Tenant-ID" => non_existent_uuid
    }

    assert_response :not_found
    json = JSON.parse(response.body)
    assert_equal false, json["success"]
    assert_equal [ "Resource not found" ], json["errors"]
  end
end
