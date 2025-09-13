# frozen_string_literal: true

module ElevenlabsClient
  class Error < StandardError; end
  class APIError < Error; end
  class AuthenticationError < Error; end
  class RateLimitError < Error; end
  class ValidationError < Error; end
end
