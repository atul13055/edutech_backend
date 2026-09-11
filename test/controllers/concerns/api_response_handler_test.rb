require "test_helper"

class ApiResponseHandlerTest < ActionDispatch::IntegrationTest
  class TestResponseController < ApplicationController
    skip_after_action :verify_authorized

    def test_success
      render_success(data: { message: "Hello" }, meta: { page: 1 })
    end

    def test_error
      render_error(errors: [ "Something went wrong" ], status: :bad_request)
    end
  end

  setup do
    Rails.application.routes.draw do
      get "test_success" => "api_response_handler_test/test_response#test_success"
      get "test_error" => "api_response_handler_test/test_response#test_error"
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test "render_success formats response correctly with data and meta" do
    get "/test_success"

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal true, json["success"]
    assert_equal "Hello", json["data"]["message"]
    assert_equal 1, json["meta"]["page"]
  end

  test "render_error formats error response correctly" do
    get "/test_error"

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_equal false, json["success"]
    assert_equal [ "Something went wrong" ], json["errors"]
  end
end
