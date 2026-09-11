require "test_helper"

module TenantManagement
  class LifecycleServiceTest < ActiveSupport::TestCase
    setup do
      @tenant = Tenant.create!(name: "Lifecycle Branch", subdomain: "lifecycle-b", code: "LC-100", status: "active")
      @role = Role.create!(name: "Admin", key: "branch_admin", tenant: @tenant)
      @user = User.create!(first_name: "BranchAdmin", email: "lc.admin@example.com", password: "password123", role: @role, tenant: @tenant)

      @token_res = Authentication::JwtService.issue_refresh_token(@user)
      @refresh_token = @token_res[:refresh_token]
    end

    test "suspending tenant revokes all active refresh tokens for tenant users" do
      assert_nil @refresh_token.reload.revoked_at

      LifecycleService.new(@tenant).suspend!

      assert_equal "suspended", @tenant.reload.status
      assert_not_nil @refresh_token.reload.revoked_at
    end

    test "deactivating tenant revokes active refresh tokens" do
      LifecycleService.new(@tenant).deactivate!

      assert_equal "inactive", @tenant.reload.status
      assert_not_nil @refresh_token.reload.revoked_at
    end

    test "activating suspended tenant does not crash" do
      @tenant.update!(status: "suspended")
      LifecycleService.new(@tenant).activate!

      assert_equal "active", @tenant.reload.status
    end
  end
end
