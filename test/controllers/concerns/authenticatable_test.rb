require "test_helper"

class AuthenticatableTest < ActionDispatch::IntegrationTest
  class TestAuthController < Api::V1::BaseController
    skip_after_action :verify_authorized

    def secret_data
      render_success(data: { user_id: current_user.id, email: current_user.email })
    end
  end

  setup do
    @role = Role.create!(name: "Member", key: "member")
    @user = User.create!(
      first_name: "Auth",
      email: "auth.user@example.com",
      password: "password123",
      role: @role,
      status: "active"
    )
    @token = Authentication::JwtService.issue_access_token(@user)

    Rails.application.routes.draw do
      get "test_secret" => "authenticatable_test/test_auth#secret_data"
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test "authenticates valid Bearer token and sets Current.user" do
    get "/test_secret", headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal true, json["success"]
    assert_equal @user.id, json["data"]["user_id"]
  end

  test "rejects request with missing Authorization header" do
    get "/test_secret"

    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal false, json["success"]
    assert_equal [ "Authentication required" ], json["errors"]
  end

  test "rejects malformed Authorization header" do
    get "/test_secret", headers: { "Authorization" => "InvalidHeaderFormat" }

    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal false, json["success"]
  end

  test "rejects invalid token" do
    get "/test_secret", headers: { "Authorization" => "Bearer invalid.jwt.token" }

    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal false, json["success"]
  end

  test "rejects expired token" do
    expired_token = nil
    travel_to 25.hours.ago do
      expired_token = Authentication::JwtService.issue_access_token(@user)
    end

    get "/test_secret", headers: { "Authorization" => "Bearer #{expired_token}" }

    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal false, json["success"]
  end

  test "rejects inactive or suspended user" do
    @user.update!(status: "suspended")

    get "/test_secret", headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal false, json["success"]
    assert_equal [ "User account is inactive or invalid" ], json["errors"]
  end
end
