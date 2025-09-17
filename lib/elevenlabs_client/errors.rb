# frozen_string_literal: true

module ElevenlabsClient
  class Error < StandardError; end
  class APIError < Error; end
  class AuthenticationError < Error; end
  class RateLimitError < Error; end
  class ValidationError < Error; end
  class NotFoundError < Error; end
  class BadRequestError < Error; end
  class UnprocessableEntityError < Error; end
  class ForbiddenError < Error; end
  class ServiceUnavailableError < Error; end
  class TimeoutError < Error; end
  class PaymentRequiredError < Error; end
end
