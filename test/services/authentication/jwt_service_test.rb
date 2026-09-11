require "test_helper"

class JwtServiceTest < ActiveSupport::TestCase
  setup do
    @tenant = Tenant.create!(name: "Branch Alpha", subdomain: "branch-alpha", code: "BA-001")
    @role = Role.create!(name: "Branch Admin", key: "branch_admin", tenant: @tenant)
    @user = User.create!(
      first_name: "John",
      email: "john.doe@example.com",
      password: "password123",
      role: @role,
      tenant: @tenant
    )

    @super_admin_role = Role.create!(name: "Super Admin", key: "super_admin")
    @super_admin = User.create!(
      first_name: "Super",
      email: "super.admin@example.com",
      password: "password123",
      role: @super_admin_role,
      tenant: nil
    )
  end

  # Access Token Tests

  test "issues valid access token with required claims" do
    token = Authentication::JwtService.issue_access_token(@user)
    assert_kind_of String, token

    payload = Authentication::JwtService.decode_access_token(token)
    assert_equal @user.id, payload[:sub]
    assert_equal @tenant.id, payload[:tenant_id]
    assert_equal "branch_admin", payload[:role]
    assert_not_nil payload[:jti]
    assert_not_nil payload[:iat]
    assert_not_nil payload[:exp]
  end

  test "decodes valid access token" do
    token = Authentication::JwtService.issue_access_token(@user)
    payload = Authentication::JwtService.decode_access_token(token)

    assert_equal @user.id, payload[:sub]
  end

  test "rejects invalid signature" do
    token = Authentication::JwtService.issue_access_token(@user)
    invalid_token = token + "tampered"

    assert_raises(Authentication::InvalidTokenError) do
      Authentication::JwtService.decode_access_token(invalid_token)
    end
  end

  test "rejects malformed token" do
    assert_raises(Authentication::InvalidTokenError) do
      Authentication::JwtService.decode_access_token("not.a.valid.jwt.string")
    end
  end

  test "rejects expired access token" do
    travel_to 25.hours.ago do
      @expired_token = Authentication::JwtService.issue_access_token(@user)
    end

    assert_raises(Authentication::ExpiredTokenError) do
      Authentication::JwtService.decode_access_token(@expired_token)
    end
  end

  # Refresh Token Tests

  test "issues refresh token and persists digest" do
    result = Authentication::JwtService.issue_refresh_token(@user)
    raw_token = result[:raw_token]
    refresh_token = result[:refresh_token]

    assert_kind_of String, raw_token
    assert_equal 64, raw_token.length # 32 bytes hex string
    assert_equal RefreshToken.digest(raw_token), refresh_token.token_digest
    assert_equal @user, refresh_token.user
    assert refresh_token.active?
  end

  test "verifies valid refresh token" do
    result = Authentication::JwtService.issue_refresh_token(@user)
    raw_token = result[:raw_token]

    verified_token = Authentication::JwtService.verify_refresh_token(raw_token)
    assert_equal result[:refresh_token].id, verified_token.id
  end

  test "rejects expired refresh token" do
    result = Authentication::JwtService.issue_refresh_token(@user)
    result[:refresh_token].update!(expires_at: 1.hour.ago)

    assert_raises(Authentication::ExpiredTokenError) do
      Authentication::JwtService.verify_refresh_token(result[:raw_token])
    end
  end

  test "rotates refresh token and invalidates old token" do
    result = Authentication::JwtService.issue_refresh_token(@user)
    old_raw_token = result[:raw_token]
    old_token_record = result[:refresh_token]

    rotation_result = Authentication::JwtService.rotate_refresh_token(old_raw_token)

    assert_kind_of String, rotation_result[:access_token]
    assert_kind_of String, rotation_result[:raw_refresh_token]
    assert_not_equal old_raw_token, rotation_result[:raw_refresh_token]

    old_token_record.reload
    assert_not_nil old_token_record.revoked_at
    assert_not old_token_record.active?
  end

  test "detects token reuse and revokes all sessions" do
    result1 = Authentication::JwtService.issue_refresh_token(@user)
    result2 = Authentication::JwtService.issue_refresh_token(@user)

    old_raw_token = result1[:raw_token]

    # First rotation succeeds
    Authentication::JwtService.rotate_refresh_token(old_raw_token)

    # Attempting to reuse old_raw_token triggers reuse protection
    assert_raises(Authentication::TokenReuseError) do
      Authentication::JwtService.verify_refresh_token(old_raw_token)
    end

    # Verify all tokens for the user are now revoked
    result2[:refresh_token].reload
    assert_not_nil result2[:refresh_token].revoked_at
  end

  # Tenant Security Tests

  test "derives tenant_id from server-side user record" do
    token = Authentication::JwtService.issue_access_token(@user)
    payload = Authentication::JwtService.decode_access_token(token)

    assert_equal @tenant.id, payload[:tenant_id]
  end

  test "supports null tenant_id for super admin" do
    token = Authentication::JwtService.issue_access_token(@super_admin)
    payload = Authentication::JwtService.decode_access_token(token)

    assert_nil payload[:tenant_id]
    assert_equal @super_admin.id, payload[:sub]
    assert_equal "super_admin", payload[:role]
  end
end
