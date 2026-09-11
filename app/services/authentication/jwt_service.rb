require "jwt"
require "securerandom"

module Authentication
  class AuthenticationError < StandardError; end
  class ExpiredTokenError < AuthenticationError; end
  class InvalidTokenError < AuthenticationError; end
  class TokenReuseError < AuthenticationError; end

  class JwtService
    ACCESS_TOKEN_EXPIRATION = 24.hours
    REFRESH_TOKEN_EXPIRATION = 30.days
    ALGORITHM = "HS256".freeze

    class << self
      def issue_access_token(user)
        payload = {
          sub: user.id,
          tenant_id: user.tenant_id,
          role: user.role&.key,
          jti: SecureRandom.uuid,
          iat: Time.current.to_i,
          exp: ACCESS_TOKEN_EXPIRATION.from_now.to_i
        }
        JWT.encode(payload, secret_key, ALGORITHM)
      end

      def decode_access_token(token)
        decoded = JWT.decode(token, secret_key, true, { algorithm: ALGORITHM })
        HashWithIndifferentAccess.new(decoded.first)
      rescue JWT::ExpiredSignature
        raise ExpiredTokenError, "Access token has expired"
      rescue JWT::DecodeError, JWT::VerificationError
        raise InvalidTokenError, "Invalid access token"
      end

      def issue_refresh_token(user, ip_address: nil, user_agent: nil)
        raw_token = SecureRandom.hex(32)
        token_digest = RefreshToken.digest(raw_token)

        refresh_token = user.refresh_tokens.create!(
          token_digest: token_digest,
          expires_at: REFRESH_TOKEN_EXPIRATION.from_now,
          ip_address: ip_address,
          user_agent: user_agent
        )

        { raw_token: raw_token, refresh_token: refresh_token }
      end

      def verify_refresh_token(raw_token)
        token_digest = RefreshToken.digest(raw_token)
        refresh_token = RefreshToken.find_by(token_digest: token_digest)

        unless refresh_token
          raise InvalidTokenError, "Invalid refresh token"
        end

        if refresh_token.revoked_at.present?
          refresh_token.user.refresh_tokens.where(revoked_at: nil).update_all(revoked_at: Time.current)
          raise TokenReuseError, "Refresh token has already been revoked. Revoking all sessions for security."
        end

        if refresh_token.expires_at <= Time.current
          raise ExpiredTokenError, "Refresh token has expired"
        end

        refresh_token
      end

      def rotate_refresh_token(raw_token, ip_address: nil, user_agent: nil)
        old_refresh_token = verify_refresh_token(raw_token)
        user = old_refresh_token.user

        old_refresh_token.revoke!

        new_access_token = issue_access_token(user)
        new_refresh_result = issue_refresh_token(user, ip_address: ip_address, user_agent: user_agent)

        {
          access_token: new_access_token,
          raw_refresh_token: new_refresh_result[:raw_token],
          refresh_token: new_refresh_result[:refresh_token],
          user: user
        }
      end

      private

      def secret_key
        Rails.application.credentials.jwt_secret ||
          ENV["JWT_SECRET"] ||
          Rails.application.secret_key_base
      end
    end
  end
end
