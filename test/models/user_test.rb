require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @role = Role.create!(name: "Student Role", key: "student_role")
    @tenant = Tenant.create!(name: "Branch X", subdomain: "branch-x", code: "BX-001")
  end

  test "valid user creation with password hashing" do
    user = User.new(
      first_name: "Alice",
      last_name: "Smith",
      email: "alice@example.com",
      password: "securepassword123",
      role: @role,
      tenant: @tenant
    )
    assert user.valid?
    assert user.save
    assert_not_nil user.password_digest
    assert user.authenticate("securepassword123")
    assert_not user.authenticate("wrongpassword")
  end

  test "validates required fields" do
    user = User.new
    assert_not user.valid?
    assert_includes user.errors[:first_name], "can't be blank"
    assert_includes user.errors[:email], "can't be blank"
    assert_includes user.errors[:password], "can't be blank"
    assert_includes user.errors[:role], "must exist"
  end

  test "enforces email uniqueness and format" do
    User.create!(
      first_name: "Bob",
      email: "bob@example.com",
      password: "password123",
      role: @role
    )

    duplicate = User.new(
      first_name: "Bobby",
      email: "BOB@example.com",
      password: "password123",
      role: @role
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"

    invalid_email = User.new(
      first_name: "Bob",
      email: "invalid-email",
      password: "password123",
      role: @role
    )
    assert_not invalid_email.valid?
    assert_includes invalid_email.errors[:email], "is invalid"
  end

  test "enforces password minimum length" do
    user = User.new(
      first_name: "Short",
      email: "short@example.com",
      password: "short",
      role: @role
    )
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end
end
