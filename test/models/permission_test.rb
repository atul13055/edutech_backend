require "test_helper"

class PermissionTest < ActiveSupport::TestCase
  test "valid permission creation" do
    permission = Permission.new(name: "Manage Fees", key: "fees.manage", module_name: "finance")
    assert permission.valid?
  end

  test "validates presence of name, key, and module_name" do
    permission = Permission.new
    assert_not permission.valid?
    assert_includes permission.errors[:name], "can't be blank"
    assert_includes permission.errors[:key], "can't be blank"
    assert_includes permission.errors[:module_name], "can't be blank"
  end

  test "enforces permission key uniqueness" do
    Permission.create!(name: "Issue Certificate", key: "certificates.issue", module_name: "certificates")
    duplicate = Permission.new(name: "Issue Certificate Dup", key: "certificates.issue", module_name: "certificates")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:key], "has already been taken"
  end
end
