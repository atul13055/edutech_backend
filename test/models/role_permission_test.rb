require "test_helper"

class RolePermissionTest < ActiveSupport::TestCase
  test "valid role_permission assignment" do
    role = Role.create!(name: "Trainer", key: "trainer")
    permission = Permission.create!(name: "Mark Attendance", key: "attendance.mark", module_name: "academics")

    rp = RolePermission.new(role: role, permission: permission)
    assert rp.valid?
  end

  test "enforces uniqueness of permission per role" do
    role = Role.create!(name: "Receptionist", key: "receptionist")
    permission = Permission.create!(name: "Create Lead", key: "leads.create", module_name: "crm")

    RolePermission.create!(role: role, permission: permission)

    duplicate = RolePermission.new(role: role, permission: permission)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:permission_id], "has already been taken"
  end
end
