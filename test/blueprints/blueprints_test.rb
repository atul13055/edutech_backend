require "test_helper"

class BlueprintsTest < ActiveSupport::TestCase
  setup do
    @tenant = Tenant.create!(name: "Branch Alpha", subdomain: "branch-alpha", code: "BA-001")
    @role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant)
    @permission = Permission.create!(name: "View Reports", key: "reports.view", module_name: "reports")
    @role_permission = RolePermission.create!(role: @role, permission: @permission)

    @user = User.create!(
      first_name: "Jane",
      last_name: "Doe",
      email: "jane.doe@example.com",
      password: "password123",
      role: @role,
      tenant: @tenant,
      status: "active"
    )
    @user.refresh_tokens.create!(token_digest: "dummy_digest", expires_at: 1.day.from_now)
  end

  test "TenantBlueprint serializes tenant correctly" do
    json = JSON.parse(TenantBlueprint.render(@tenant))

    assert_equal @tenant.id, json["id"]
    assert_equal "Branch Alpha", json["name"]
    assert_equal "branch-alpha", json["subdomain"]
    assert_equal "BA-001", json["code"]
    assert_equal "active", json["status"]
  end

  test "PermissionBlueprint serializes permission correctly" do
    json = JSON.parse(PermissionBlueprint.render(@permission))

    assert_equal @permission.id, json["id"]
    assert_equal "View Reports", json["name"]
    assert_equal "reports.view", json["key"]
    assert_equal "reports", json["module_name"]
  end

  test "RoleBlueprint serializes role correctly" do
    json = JSON.parse(RoleBlueprint.render(@role, view: :with_permissions))

    assert_equal @role.id, json["id"]
    assert_equal "Branch Admin", json["name"]
    assert_equal "branch_admin", json["key"]
    assert_equal 1, json["permissions"].length
    assert_equal @permission.id, json["permissions"].first["id"]
  end

  test "RolePermissionBlueprint serializes role permission association correctly" do
    json = JSON.parse(RolePermissionBlueprint.render(@role_permission))

    assert_equal @role_permission.id, json["id"]
    assert_equal @role.id, json["role"]["id"]
    assert_equal @permission.id, json["permission"]["id"]
  end

  test "UserBlueprint serializes user safely and excludes sensitive authentication data" do
    json = JSON.parse(UserBlueprint.render(@user, view: :with_associations))

    # Safe fields present
    assert_equal @user.id, json["id"]
    assert_equal "Jane", json["first_name"]
    assert_equal "Doe", json["last_name"]
    assert_equal "jane.doe@example.com", json["email"]
    assert_equal "active", json["status"]
    assert_equal @tenant.id, json["tenant"]["id"]
    assert_equal @role.id, json["role"]["id"]

    # Sensitive fields MUST be absent
    assert_nil json["password_digest"]
    assert_nil json["password"]
    assert_nil json["refresh_tokens"]
    assert_nil json["token_digest"]
    assert_nil json["jwt"]
    assert_nil json["secret_key_base"]
  end
end
