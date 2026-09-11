require "test_helper"

module Api
  module V1
    class TenantsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @tenant1 = Tenant.create!(name: "Branch A", subdomain: "branch-a", code: "BA-100", status: "active")
        @tenant2 = Tenant.create!(name: "Branch B", subdomain: "branch-b", code: "BB-100", status: "suspended")
        @tenant3 = Tenant.create!(name: "Branch C", subdomain: "branch-c", code: "BC-100", status: "inactive")

        @super_role = Role.create!(name: "Super Admin", key: "super_admin", tenant_id: nil)
        @super_admin = User.create!(
          first_name: "Super",
          email: "super.tenant@example.com",
          password: "password123",
          role: @super_role,
          tenant: nil
        )
        @super_token = Authentication::JwtService.issue_access_token(@super_admin)

        @admin_role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant1)
        @tenant_admin = User.create!(
          first_name: "AdminA",
          email: "admin.tenant1@example.com",
          password: "password123",
          role: @admin_role,
          tenant: @tenant1
        )
        @tenant_admin_token = Authentication::JwtService.issue_access_token(@tenant_admin)

        @member_role = Role.create!(name: "Member", key: "member", tenant: @tenant1)
        @tenant_member = User.create!(
          first_name: "MemberA",
          email: "member.tenant1@example.com",
          password: "password123",
          role: @member_role,
          tenant: @tenant1
        )
        @tenant_member_token = Authentication::JwtService.issue_access_token(@tenant_member)
      end

      test "unauthenticated request fails with 401" do
        get api_v1_tenants_url
        assert_response :unauthorized
      end

      test "tenant user index access is rejected with 403 forbidden" do
        get api_v1_tenants_url, headers: { "Authorization" => "Bearer #{@tenant_member_token}" }

        assert_response :forbidden
        json = response.parsed_body

        assert_not json["success"]
        assert_equal [ "You are not authorized to perform this action" ], json["errors"]
      end

      test "super admin index returns all tenants with pagination metadata" do
        get api_v1_tenants_url, headers: { "Authorization" => "Bearer #{@super_token}" }

        assert_response :success
        json = response.parsed_body

        assert json["success"]
        assert_equal 3, json["data"].length
        assert_equal 1, json["meta"]["page"]
        assert_equal 25, json["meta"]["per_page"]
        assert_equal 3, json["meta"]["total_count"]
      end

      test "super admin index supports status filtering and search" do
        # Filter by status
        get api_v1_tenants_url, params: { status: "suspended" }, headers: { "Authorization" => "Bearer #{@super_token}" }
        assert_response :success
        json = response.parsed_body
        assert_equal 1, json["data"].length
        assert_equal "Branch B", json["data"].first["name"]

        # Search by query
        get api_v1_tenants_url, params: { search: "BC-100" }, headers: { "Authorization" => "Bearer #{@super_token}" }
        assert_response :success
        json = response.parsed_body
        assert_equal 1, json["data"].length
        assert_equal "Branch C", json["data"].first["name"]
      end

      test "tenant user can view own tenant but not another tenant" do
        get api_v1_tenant_url(@tenant1), headers: { "Authorization" => "Bearer #{@tenant_member_token}" }
        assert_response :success
        json = response.parsed_body
        assert_equal "Branch A", json["data"]["name"]
        assert_equal "BA-100", json["data"]["code"]
        assert_equal "UTC", json["data"]["time_zone"]

        get api_v1_tenant_url(@tenant2), headers: { "Authorization" => "Bearer #{@tenant_member_token}" }
        assert_response :forbidden
      end

      test "tenant admin can update own tenant allowed attributes" do
        patch api_v1_tenant_url(@tenant1),
              params: { tenant: { name: "Branch A Updated", address: "123 Main St", contact_phone: "+91 9999999999" } },
              headers: { "Authorization" => "Bearer #{@tenant_admin_token}" }

        assert_response :success
        json = response.parsed_body

        assert_equal "Branch A Updated", json["data"]["name"]
        assert_equal "123 Main St", json["data"]["address"]
        assert_equal "+91 9999999999", json["data"]["contact_phone"]
      end

      test "tenant admin cannot alter subdomain, code, or status" do
        patch api_v1_tenant_url(@tenant1),
              params: { tenant: { status: "suspended", code: "HACKED", subdomain: "hacked" } },
              headers: { "Authorization" => "Bearer #{@tenant_admin_token}" }

        assert_response :success
        @tenant1.reload
        assert_equal "active", @tenant1.status
        assert_equal "BA-100", @tenant1.code
        assert_equal "branch-a", @tenant1.subdomain
      end

      test "tenant member cannot create or delete tenants" do
        post api_v1_tenants_url,
             params: { tenant: { name: "New Branch", subdomain: "newb", code: "NB-001" } },
             headers: { "Authorization" => "Bearer #{@tenant_member_token}" }
        assert_response :forbidden

        delete api_v1_tenant_url(@tenant1),
               headers: { "Authorization" => "Bearer #{@tenant_member_token}" }
        assert_response :forbidden
      end

      test "super admin can create, suspend, and delete tenant" do
        # Create
        post api_v1_tenants_url,
             params: { tenant: { name: "New Branch", subdomain: "newb", code: "NB-001" } },
             headers: { "Authorization" => "Bearer #{@super_token}" }
        assert_response :created
        json = response.parsed_body
        new_tenant_id = json["data"]["id"]

        # Suspend
        patch api_v1_tenant_url(new_tenant_id),
              params: { tenant: { status: "suspended" } },
              headers: { "Authorization" => "Bearer #{@super_token}" }
        assert_response :success
        assert_equal "suspended", response.parsed_body["data"]["status"]

        # Delete
        delete api_v1_tenant_url(new_tenant_id),
               headers: { "Authorization" => "Bearer #{@super_token}" }
        assert_response :success
      end
    end
  end
end
