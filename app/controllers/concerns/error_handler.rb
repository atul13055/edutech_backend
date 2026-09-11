module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
    rescue_from "Authentication::AuthenticationError", with: :handle_authentication_error
    rescue_from "Pundit::NotAuthorizedError", with: :handle_not_authorized
    rescue_from ActionController::ParameterMissing, with: :handle_bad_request
    rescue_from ActionController::BadRequest, with: :handle_bad_request
    rescue_from "WalletManagement::InsufficientBalanceError", with: :handle_unprocessable_entity
    rescue_from "WalletManagement::InvalidAmountError", with: :handle_unprocessable_entity
    rescue_from "Fees::PaymentCollectionService::IdempotencyConflictError", with: :handle_conflict
    rescue_from "Fees::PaymentCollectionService::Error", with: :handle_unprocessable_entity
  end

  private

  def handle_record_not_found(_exception)
    render_error(errors: [ "Resource not found" ], status: :not_found)
  end

  def handle_record_invalid(exception)
    render_error(errors: exception.record.errors.full_messages, status: :unprocessable_entity)
  end

  def handle_authentication_error(exception)
    render_error(errors: [ exception.message ], status: :unauthorized)
  end

  def handle_not_authorized(_exception)
    render_error(errors: [ "You are not authorized to perform this action" ], status: :forbidden)
  end

  def handle_bad_request(exception)
    render_error(errors: [ exception.message ], status: :bad_request)
  end

  def handle_unprocessable_entity(exception)
    render_error(errors: [ exception.message ], status: :unprocessable_entity)
  end

  def handle_conflict(exception)
    render_error(errors: [ exception.message ], status: :conflict)
  end
end
