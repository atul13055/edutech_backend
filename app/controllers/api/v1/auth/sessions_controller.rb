module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        skip_before_action :set_current_user, only: [ :create, :refresh ]
        skip_after_action :verify_authorized

        def create
          email = auth_params[:email].to_s.strip.downcase
          password = auth_params[:password]

          user = User.find_by(email: email)

          unless user&.authenticate(password) && user.status == "active"
            raise Authentication::InvalidTokenError, "Invalid email or password"
          end

          access_token = Authentication::JwtService.issue_access_token(user)
          refresh_result = Authentication::JwtService.issue_refresh_token(
            user,
            ip_address: request.remote_ip,
            user_agent: request.user_agent
          )

          render_success(
            data: {
              user: UserBlueprint.render_as_hash(user, view: :with_associations),
              access_token: access_token,
              refresh_token: refresh_result[:raw_token]
            }
          )
        end

        def refresh
          raw_refresh_token = params[:refresh_token] || request.headers["X-Refresh-Token"]
          if raw_refresh_token.blank?
            raise Authentication::InvalidTokenError, "Refresh token is required"
          end

          rotation_result = Authentication::JwtService.rotate_refresh_token(
            raw_refresh_token,
            ip_address: request.remote_ip,
            user_agent: request.user_agent
          )

          render_success(
            data: {
              user: UserBlueprint.render_as_hash(rotation_result[:user], view: :with_associations),
              access_token: rotation_result[:access_token],
              refresh_token: rotation_result[:raw_refresh_token]
            }
          )
        end

        def destroy
          raw_refresh_token = params[:refresh_token] || request.headers["X-Refresh-Token"]

          if raw_refresh_token.present?
            token_digest = RefreshToken.digest(raw_refresh_token)
            refresh_token = RefreshToken.find_by(token_digest: token_digest)
            refresh_token&.revoke!
          end

          render_success(data: { message: "Logged out successfully" })
        end

        private

        def auth_params
          if params[:user].present?
            params.require(:user).permit(:email, :password)
          else
            params.permit(:email, :password)
          end
        end
      end
    end
  end
end
