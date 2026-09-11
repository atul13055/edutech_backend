class ApplicationController < ActionController::API
  include Pundit::Authorization
  include ApiResponseHandler
  include ErrorHandler
  include Authenticatable
  include TenantScoped

  after_action :verify_authorized, if: :perform_verify_authorized?

  private

  def perform_verify_authorized?
    true
  end
end
