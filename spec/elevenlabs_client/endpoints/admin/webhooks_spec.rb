# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Admin::Webhooks do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test_api_key") }
  let(:webhooks) { client.webhooks }

  describe "#list_webhooks" do
    let(:expected_response) do
      {
        "webhooks" => [
          {
            "name" => "My Test Webhook",
            "webhook_id" => "webhook_123",
            "webhook_url" => "https://example.com/webhook",
            "is_disabled" => false,
            "is_auto_disabled" => false,
            "created_at_unix" => 1609459200,
            "auth_type" => "hmac",
            "usage" => [
              {
                "usage_type" => "ConvAI Settings"
              }
            ],
            "most_recent_failure_error_code" => 404,
            "most_recent_failure_timestamp" => 1609459799
          }
        ]
      }
    end

    context "when request is successful without parameters" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(
            status: 200,
            body: expected_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "retrieves webhooks successfully" do
        result = webhooks.list_webhooks
        expect(result).to eq(expected_response)
      end

      it "makes a GET request to the correct endpoint" do
        webhooks.list_webhooks
        
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(headers: { "xi-api-key" => "test_api_key" })
      end

      it "returns webhooks with expected structure" do
        result = webhooks.list_webhooks
        
        expect(result).to have_key("webhooks")
        expect(result["webhooks"]).to be_an(Array)
        
        webhook = result["webhooks"].first
        expect(webhook).to have_key("name")
        expect(webhook).to have_key("webhook_id")
        expect(webhook).to have_key("webhook_url")
        expect(webhook).to have_key("is_disabled")
        expect(webhook).to have_key("is_auto_disabled")
        expect(webhook).to have_key("created_at_unix")
        expect(webhook).to have_key("auth_type")
        expect(webhook).to have_key("usage")
        expect(webhook).to have_key("most_recent_failure_error_code")
        expect(webhook).to have_key("most_recent_failure_timestamp")
      end
    end

    context "when include_usages parameter is provided" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(
            headers: { "xi-api-key" => "test_api_key" },
            query: { include_usages: true }
          )
          .to_return(
            status: 200,
            body: expected_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "includes the include_usages parameter in the request" do
        webhooks.list_webhooks(include_usages: true)
        
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(
            headers: { "xi-api-key" => "test_api_key" },
            query: { include_usages: true }
          )
      end

      it "retrieves webhooks with usage information" do
        result = webhooks.list_webhooks(include_usages: true)
        expect(result).to eq(expected_response)
        
        webhook = result["webhooks"].first
        expect(webhook["usage"]).to be_an(Array)
        expect(webhook["usage"].first).to have_key("usage_type")
      end
    end

    context "when include_usages is false" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(
            headers: { "xi-api-key" => "test_api_key" },
            query: { include_usages: false }
          )
          .to_return(
            status: 200,
            body: expected_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "includes the include_usages parameter as false" do
        webhooks.list_webhooks(include_usages: false)
        
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(
            headers: { "xi-api-key" => "test_api_key" },
            query: { include_usages: false }
          )
      end
    end

    context "when authentication fails" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(
            status: 401,
            body: { detail: "Unauthorized" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises an AuthenticationError" do
        expect {
          webhooks.list_webhooks
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    context "when there's a validation error" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(
            status: 422,
            body: { detail: "Invalid request parameters" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises an UnprocessableEntityError" do
        expect {
          webhooks.list_webhooks
        }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end

    context "when rate limit is exceeded" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(
            status: 429,
            body: { detail: "Rate limit exceeded" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises a RateLimitError" do
        expect {
          webhooks.list_webhooks
        }.to raise_error(ElevenlabsClient::RateLimitError)
      end
    end

    context "when there's a server error" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(
            status: 500,
            body: { detail: "Internal server error" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises an APIError" do
        expect {
          webhooks.list_webhooks
        }.to raise_error(ElevenlabsClient::APIError)
      end
    end

    context "when no webhooks exist" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(
            status: 200,
            body: { "webhooks" => [] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns empty webhooks array" do
        result = webhooks.list_webhooks
        expect(result["webhooks"]).to eq([])
      end
    end
  end

  describe "aliases" do
    let(:expected_response) do
      {
        "webhooks" => [
          {
            "name" => "Test Webhook",
            "webhook_id" => "webhook_123",
            "webhook_url" => "https://example.com/webhook",
            "is_disabled" => false,
            "is_auto_disabled" => false,
            "created_at_unix" => 1609459200,
            "auth_type" => "hmac",
            "usage" => [],
            "most_recent_failure_error_code" => nil,
            "most_recent_failure_timestamp" => nil
          }
        ]
      }
    end

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
        .with(headers: { "xi-api-key" => "test_api_key" })
        .to_return(
          status: 200,
          body: expected_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    describe "#get_webhooks" do
      it "works as an alias for list_webhooks" do
        result = webhooks.get_webhooks
        expect(result).to eq(expected_response)
      end
    end

    describe "#all" do
      it "works as an alias for list_webhooks" do
        result = webhooks.all
        expect(result).to eq(expected_response)
      end
    end

    describe "#webhooks" do
      it "works as an alias for list_webhooks" do
        result = webhooks.webhooks
        expect(result).to eq(expected_response)
      end
    end
  end
end
