require "test_helper"

class ErrorHandlerTest < ActionDispatch::IntegrationTest
  class TestErrorController < ApplicationController
    skip_after_action :verify_authorized

    def raise_not_found
      raise ActiveRecord::RecordNotFound, "Tenant not found"
    end

    def raise_invalid
      tenant = Tenant.new
      tenant.validate
      raise ActiveRecord::RecordInvalid, tenant
    end

    def raise_auth_error
      raise Authentication::AuthenticationError, "Invalid credentials"
    end

    def raise_expired_token
      raise Authentication::ExpiredTokenError, "Access token has expired"
    end

    def raise_invalid_token
      raise Authentication::InvalidTokenError, "Invalid access token"
    end

    def raise_forbidden
      raise Pundit::NotAuthorizedError, "Not allowed"
    end

    def raise_bad_request
      raise ActionController::ParameterMissing, :email
    end
  end

  setup do
    Rails.application.routes.draw do
      get "test_not_found" => "error_handler_test/test_error#raise_not_found"
      get "test_invalid" => "error_handler_test/test_error#raise_invalid"
      get "test_auth_error" => "error_handler_test/test_error#raise_auth_error"
      get "test_expired_token" => "error_handler_test/test_error#raise_expired_token"
      get "test_invalid_token" => "error_handler_test/test_error#raise_invalid_token"
      get "test_forbidden" => "error_handler_test/test_error#raise_forbidden"
      get "test_bad_request" => "error_handler_test/test_error#raise_bad_request"
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test "rescues RecordNotFound with 404" do
    get "/test_not_found"
    assert_response :not_found
    json = JSON.parse(response.body)
    assert_equal false, json["success"]
    assert_equal [ "Resource not found" ], json["errors"]
  end

  test "rescues RecordInvalid with 422" do
    get "/test_invalid"
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal false, json["success"]
    assert_kind_of Array, json["errors"]
  end

  test "rescues AuthenticationError with 401" do
    get "/test_auth_error"
    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal false, json["success"]
    assert_equal [ "Invalid credentials" ], json["errors"]
  end

  test "rescues ExpiredTokenError with 401" do
    get "/test_expired_token"
    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal false, json["success"]
    assert_equal [ "Access token has expired" ], json["errors"]
  end

  test "rescues InvalidTokenError with 401" do
    get "/test_invalid_token"
    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal false, json["success"]
    assert_equal [ "Invalid access token" ], json["errors"]
  end

  test "rescues NotAuthorizedError with 403" do
    get "/test_forbidden"
    assert_response :forbidden
    json = JSON.parse(response.body)
    assert_equal false, json["success"]
    assert_equal [ "You are not authorized to perform this action" ], json["errors"]
  end

  test "rescues ParameterMissing with 400" do
    get "/test_bad_request"
    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_equal false, json["success"]
    assert_includes json["errors"].first, "param is missing"
  end
end
