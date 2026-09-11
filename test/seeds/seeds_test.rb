require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_seed
  end

  test "canonical system roles exist and are global" do
    expected_role_keys = %w[super_admin branch_admin trainer receptionist student]

    expected_role_keys.each do |role_key|
      role = Role.find_by(key: role_key, tenant_id: nil)
      assert_not_nil role, "Expected global role '#{role_key}' to exist with tenant_id: nil"
      assert_nil role.tenant_id, "System role '#{role_key}' must be global (tenant_id == nil)"
    end

    assert_equal 5, Role.where(tenant_id: nil).count
  end

  test "canonical global permissions exist" do
    expected_permission_keys = %w[
      tenants.manage
      users.manage
      roles.manage
      cms.manage
      wallet.manage
      fees.collect
      fees.view
      courses.manage
      students.manage
      enrollments.manage
      attendance.mark
      assets.manage
      exams.manage
      typing.manage
      certificates.issue
      certificates.revoke
    ]

    expected_permission_keys.each do |perm_key|
      perm = Permission.find_by(key: perm_key)
      assert_not_nil perm, "Expected permission '#{perm_key}' to exist"
      assert perm.module_name.present?, "Permission '#{perm_key}' must have module_name"
    end

    assert_equal 16, Permission.count
  end

  test "role-permission mappings are correct" do
    super_admin = Role.find_by!(key: "super_admin", tenant_id: nil)
    branch_admin = Role.find_by!(key: "branch_admin", tenant_id: nil)
    trainer = Role.find_by!(key: "trainer", tenant_id: nil)
    receptionist = Role.find_by!(key: "receptionist", tenant_id: nil)
    student = Role.find_by!(key: "student", tenant_id: nil)

    assert_equal 16, super_admin.permissions.count
    assert_equal 13, branch_admin.permissions.count
    assert_equal 7, trainer.permissions.count
    assert_equal 5, receptionist.permissions.count
    assert_equal 0, student.permissions.count
  end

  test "seed execution is idempotent and creates no duplicates when executed twice" do
    initial_roles_count = Role.count
    initial_permissions_count = Permission.count
    initial_mappings_count = RolePermission.count

    # Execute load_seed a second time
    Rails.application.load_seed

    assert_equal initial_roles_count, Role.count, "Role count changed after second seed run"
    assert_equal initial_permissions_count, Permission.count, "Permission count changed after second seed run"
    assert_equal initial_mappings_count, RolePermission.count, "RolePermission count changed after second seed run"
  end

  test "seed does not create tenants, users, or business data" do
    assert_equal 0, Tenant.count, "Seed must not create tenant records"
    assert_equal 0, User.count, "Seed must not create user records"
    assert_equal 0, RefreshToken.count, "Seed must not create refresh tokens"
  end

  test "seed file contains no secrets or credentials" do
    seed_content = File.read(Rails.root.join("db/seeds.rb"))

    refute_includes seed_content, "password"
    refute_includes seed_content, "secret"
    refute_includes seed_content, "jwt"
    refute_includes seed_content, "token"
  end
end
