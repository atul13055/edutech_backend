require "test_helper"

class RefreshTokenTest < ActiveSupport::TestCase
  setup do
    @role = Role.create!(name: "User Role", key: "user_role")
    @user = User.create!(
      first_name: "Test",
      email: "user_token@example.com",
      password: "password123",
      role: @role
    )
  end

  test "valid refresh token creation and digest helper" do
    raw_token = "raw_sample_token_string_123"
    token_digest = RefreshToken.digest(raw_token)

    refresh_token = RefreshToken.new(
      user: @user,
      token_digest: token_digest,
      expires_at: 7.days.from_now
    )
    assert refresh_token.valid?
    assert refresh_token.save
    assert refresh_token.active?
  end

  test "validates required attributes" do
    token = RefreshToken.new
    assert_not token.valid?
    assert_includes token.errors[:user], "must exist"
    assert_includes token.errors[:token_digest], "can't be blank"
    assert_includes token.errors[:expires_at], "can't be blank"
  end

  test "active? returns false when revoked or expired" do
    expired_token = RefreshToken.create!(
      user: @user,
      token_digest: RefreshToken.digest("expired"),
      expires_at: 1.day.ago
    )
    assert_not expired_token.active?

    revoked_token = RefreshToken.create!(
      user: @user,
      token_digest: RefreshToken.digest("revoked"),
      expires_at: 7.days.from_now
    )
    assert revoked_token.active?

    revoked_token.revoke!
    assert_not revoked_token.active?
  end
end
