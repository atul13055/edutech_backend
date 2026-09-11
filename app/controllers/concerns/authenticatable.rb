module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :set_current_user
  end

  private

  def set_current_user
    header = request.headers["Authorization"]
    return if header.blank?

    token = extract_bearer_token(header)
    return unless token

    payload = Authentication::JwtService.decode_access_token(token)
    user = User.find_by(id: payload[:sub])

    unless user && user.status == "active"
      raise Authentication::InvalidTokenError, "User account is inactive or invalid"
    end

    Current.user = user
  end

  def extract_bearer_token(header)
    parts = header.split(" ")
    return nil unless parts.length == 2 && parts.first.casecmp("bearer").zero?

    parts.last
  end

  def authenticate_user!
    return if Current.user.present?

    raise Authentication::InvalidTokenError, "Authentication required"
  end

  def current_user
    Current.user
  end
end
