require "test_helper"

module Api
  module V1
    class UsersControllerTest < ActionDispatch::IntegrationTest
      setup do
        @tenant1 = Tenant.create!(name: "Branch A", subdomain: "branch-a", code: "BA-200")
        @tenant2 = Tenant.create!(name: "Branch B", subdomain: "branch-b", code: "BB-200")

        @super_role = Role.create!(name: "Super Admin", key: "super_admin", tenant_id: nil)
        @super_admin = User.create!(
          first_name: "Super",
          email: "super.users@example.com",
          password: "password123",
          role: @super_role,
          tenant: nil
        )
        @super_token = Authentication::JwtService.issue_access_token(@super_admin)

        @admin_role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant1)
        @user1 = User.create!(
          first_name: "User1",
          email: "user1.users@example.com",
          password: "password123",
          role: @admin_role,
          tenant: @tenant1
        )
        @user1_token = Authentication::JwtService.issue_access_token(@user1)

        @user2 = User.create!(
          first_name: "User2",
          email: "user2.users@example.com",
          password: "password123",
          role: @admin_role,
          tenant: @tenant2
        )
        @user2_token = Authentication::JwtService.issue_access_token(@user2)
      end

      test "tenant user index returns only users from own tenant" do
        get api_v1_users_url, headers: { "Authorization" => "Bearer #{@user1_token}" }

        assert_response :success
        json = response.parsed_body

        assert json["success"]
        user_ids = json["data"].map { |u| u["id"] }
        assert_includes user_ids, @user1.id
        assert_not_includes user_ids, @user2.id
      end

      test "super admin index returns users across all tenants" do
        get api_v1_users_url, headers: { "Authorization" => "Bearer #{@super_token}" }

        assert_response :success
        json = response.parsed_body

        assert json["success"]
        user_ids = json["data"].map { |u| u["id"] }
        assert_includes user_ids, @user1.id
        assert_includes user_ids, @user2.id
      end

      test "cross-tenant user access is rejected with 403" do
        get api_v1_user_url(@user2), headers: { "Authorization" => "Bearer #{@user1_token}" }
        assert_response :forbidden

        patch api_v1_user_url(@user2),
              params: { user: { first_name: "HackedName" } },
              headers: { "Authorization" => "Bearer #{@user1_token}" }
        assert_response :forbidden

        delete api_v1_user_url(@user2), headers: { "Authorization" => "Bearer #{@user1_token}" }
        assert_response :forbidden
      end

      test "tenant user can create user in own tenant but cannot assign another tenant_id" do
        post api_v1_users_url,
             params: {
               user: {
                 first_name: "NewMember",
                 email: "newmember@example.com",
                 password: "password123",
                 role_id: @admin_role.id,
                 tenant_id: @tenant2.id
               }
             },
             headers: { "Authorization" => "Bearer #{@user1_token}" }

        assert_response :created
        json = response.parsed_body

        # Verified tenant_id was locked to user1's tenant (@tenant1), ignoring attempt to pass @tenant2
        assert_equal @tenant1.id, json["data"]["tenant_id"]
      end

      test "normal user cannot create super_admin user" do
        post api_v1_users_url,
             params: {
               user: {
                 first_name: "SneakyAdmin",
                 email: "sneaky@example.com",
                 password: "password123",
                 role_id: @super_role.id
               }
             },
             headers: { "Authorization" => "Bearer #{@user1_token}" }

        assert_response :forbidden
      end

      test "normal user cannot update self or another user to super_admin" do
        patch api_v1_user_url(@user1),
              params: { user: { role_id: @super_role.id } },
              headers: { "Authorization" => "Bearer #{@user1_token}" }

        assert_response :forbidden
        assert_equal "branch_admin", @user1.reload.role.key
      end

      test "tenant user update cannot alter tenant_id" do
        patch api_v1_user_url(@user1),
              params: { user: { first_name: "User1Updated", tenant_id: @tenant2.id } },
              headers: { "Authorization" => "Bearer #{@user1_token}" }

        assert_response :success
        json = response.parsed_body

        assert_equal "User1Updated", json["data"]["first_name"]
        assert_equal @tenant1.id, json["data"]["tenant_id"]
      end

      test "user cannot delete self" do
        delete api_v1_user_url(@user1), headers: { "Authorization" => "Bearer #{@user1_token}" }
        assert_response :forbidden
        assert User.exists?(@user1.id)
      end

      test "password_digest cannot be directly injected via user parameters" do
        original_digest = @user1.password_digest

        post api_v1_users_url,
             params: {
               user: {
                 first_name: "DirectDigestUser",
                 email: "digest.user@example.com",
                 password: "password123",
                 password_digest: "malicious_injected_digest",
                 role_id: @admin_role.id
               }
             },
             headers: { "Authorization" => "Bearer #{@user1_token}" }

        assert_response :created
        created_user = User.find_by!(email: "digest.user@example.com")
        assert_not_equal "malicious_injected_digest", created_user.password_digest

        patch api_v1_user_url(@user1),
              params: { user: { password_digest: "malicious_injected_digest" } },
              headers: { "Authorization" => "Bearer #{@user1_token}" }

        assert_response :success
        assert_equal original_digest, @user1.reload.password_digest
      end

      test "user API response never serializes password or password_digest" do
        get api_v1_user_url(@user1), headers: { "Authorization" => "Bearer #{@user1_token}" }
        assert_response :success
        json = response.parsed_body

        assert json["success"]
        assert_nil json["data"]["password"]
        assert_nil json["data"]["password_digest"]
        assert_nil json["data"]["refresh_tokens"]
      end

      test "super admin can manage any user" do
        get api_v1_user_url(@user1), headers: { "Authorization" => "Bearer #{@super_token}" }
        assert_response :success

        patch api_v1_user_url(@user2),
              params: { user: { first_name: "User2UpdatedBySuper" } },
              headers: { "Authorization" => "Bearer #{@super_token}" }
        assert_response :success

        delete api_v1_user_url(@user2), headers: { "Authorization" => "Bearer #{@super_token}" }
        assert_response :success
      end
    end
  end
end
