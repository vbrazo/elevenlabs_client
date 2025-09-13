# frozen_string_literal: true

RSpec.describe "ElevenlabsClient errors" do
  describe ElevenlabsClient::Error do
    it "is a StandardError" do
      expect(ElevenlabsClient::Error.new).to be_a(StandardError)
    end

    it "can be raised with a message" do
      expect {
        raise ElevenlabsClient::Error, "Test error"
      }.to raise_error(ElevenlabsClient::Error, "Test error")
    end
  end

  describe ElevenlabsClient::APIError do
    it "inherits from Error" do
      expect(ElevenlabsClient::APIError.new).to be_a(ElevenlabsClient::Error)
    end

    it "can be raised with a message" do
      expect {
        raise ElevenlabsClient::APIError, "API error"
      }.to raise_error(ElevenlabsClient::APIError, "API error")
    end
  end

  describe ElevenlabsClient::AuthenticationError do
    it "inherits from Error" do
      expect(ElevenlabsClient::AuthenticationError.new).to be_a(ElevenlabsClient::Error)
    end

    it "can be raised with a message" do
      expect {
        raise ElevenlabsClient::AuthenticationError, "Authentication failed"
      }.to raise_error(ElevenlabsClient::AuthenticationError, "Authentication failed")
    end
  end

  describe ElevenlabsClient::RateLimitError do
    it "inherits from Error" do
      expect(ElevenlabsClient::RateLimitError.new).to be_a(ElevenlabsClient::Error)
    end

    it "can be raised with a message" do
      expect {
        raise ElevenlabsClient::RateLimitError, "Rate limit exceeded"
      }.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
    end
  end

  describe ElevenlabsClient::ValidationError do
    it "inherits from Error" do
      expect(ElevenlabsClient::ValidationError.new).to be_a(ElevenlabsClient::Error)
    end

    it "can be raised with a message" do
      expect {
        raise ElevenlabsClient::ValidationError, "Validation failed"
      }.to raise_error(ElevenlabsClient::ValidationError, "Validation failed")
    end
  end
end
