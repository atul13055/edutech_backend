require "test_helper"

class ApiV1BaseControllerTest < ActionDispatch::IntegrationTest
  class TestUnprotectedActionController < Api::V1::BaseController
    # Does not call authorize or skip_after_action :verify_authorized
    def index
      render_success(data: { status: "ok" })
    end
  end

  class TestAuthorizedActionController < Api::V1::BaseController
    skip_after_action :verify_authorized

    def index
      render_success(data: { status: "authorized_skipped_explicitly" })
    end
  end

  setup do
    @role = Role.create!(name: "Standard", key: "standard")
    @user = User.create!(
      first_name: "BaseTest",
      email: "basetest@example.com",
      password: "password123",
      role: @role
    )
    @token = Authentication::JwtService.issue_access_token(@user)

    Rails.application.routes.draw do
      get "test_unprotected" => "api_v1_base_controller_test/test_unprotected_action#index"
      get "test_authorized" => "api_v1_base_controller_test/test_authorized_action#index"
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test "base controller requires authentication" do
    get "/test_authorized"
    assert_response :unauthorized
  end

  test "base controller enforces Pundit verify_authorized when not skipped" do
    assert_raises(Pundit::AuthorizationNotPerformedError) do
      get "/test_unprotected", headers: { "Authorization" => "Bearer #{@token}" }
    end
  end

  test "base controller passes when verify_authorized is explicitly skipped or authorized" do
    get "/test_authorized", headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal true, json["success"]
  end
end
