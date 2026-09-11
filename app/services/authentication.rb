module Authentication
  class AuthenticationError < StandardError; end
  class ExpiredTokenError < AuthenticationError; end
  class InvalidTokenError < AuthenticationError; end
  class TokenReuseError < AuthenticationError; end
end
