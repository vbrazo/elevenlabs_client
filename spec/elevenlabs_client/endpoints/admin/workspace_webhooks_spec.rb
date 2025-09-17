# frozen_string_literal: true

require "spec_helper"

RSpec.describe ElevenlabsClient::Admin::WorkspaceWebhooks do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test-api-key") }
  let(:workspace_webhooks) { described_class.new(client) }

  describe "#list" do
    let(:endpoint) { "/v1/workspace/webhooks" }

    context "when successful" do
      let(:response) do
        {
          "webhooks" => [
            {
              "name" => "My Webhook",
              "webhook_id" => "123",
              "webhook_url" => "https://elevenlabs.io/example-callback-url",
              "is_disabled" => false,
              "is_auto_disabled" => false,
              "created_at_unix" => 123456789,
              "auth_type" => "hmac",
              "usage" => [
                {
                  "usage_type" => "ConvAI Settings"
                }
              ],
              "most_recent_failure_error_code" => 404,
              "most_recent_failure_timestamp" => 123456799
            }
          ]
        }
      end

      before do
        allow(client).to receive(:get).and_return(response)
      end

      it "lists webhooks successfully" do
        result = workspace_webhooks.list

        expect(result).to eq(response)
        expect(result["webhooks"].size).to eq(1)
        expect(result["webhooks"].first["name"]).to eq("My Webhook")
        expect(result["webhooks"].first["webhook_id"]).to eq("123")
        expect(result["webhooks"].first["is_disabled"]).to be false
      end

      it "calls the correct endpoint" do
        workspace_webhooks.list
        expect(client).to have_received(:get).with(endpoint)
      end
    end

    context "with include_usages parameter" do
      let(:include_usages) { true }
      let(:endpoint_with_params) { "#{endpoint}?include_usages=true" }

      before do
        allow(client).to receive(:get).with(endpoint_with_params).and_return({})
      end

      it "includes usage parameter in query string" do
        workspace_webhooks.list(include_usages: include_usages)
        expect(client).to have_received(:get).with(endpoint_with_params)
      end
    end

    context "with multiple query parameters" do
      let(:params) { { include_usages: true, custom_param: "value" } }
      
      before do
        allow(client).to receive(:get).and_return({})
      end

      it "includes all parameters in query string" do
        workspace_webhooks.list(**params)
        
        expect(client).to have_received(:get) do |called_endpoint|
          expect(called_endpoint).to start_with(endpoint)
          expect(called_endpoint).to include("include_usages=true")
          expect(called_endpoint).to include("custom_param=value")
        end
      end
    end

    context "with nil parameters" do
      before do
        allow(client).to receive(:get).and_return({})
      end

      it "excludes nil parameters from query string" do
        workspace_webhooks.list(include_usages: nil, valid_param: "value")
        
        expect(client).to have_received(:get) do |called_endpoint|
          expect(called_endpoint).not_to include("include_usages")
          expect(called_endpoint).to include("valid_param=value")
        end
      end
    end

    context "when client raises an error" do
      before do
        allow(client).to receive(:get).and_raise(ElevenlabsClient::APIError, "API Error")
      end

      it "propagates the error" do
        expect { workspace_webhooks.list }.to raise_error(ElevenlabsClient::APIError, "API Error")
      end
    end

    context "when authentication fails" do
      before do
        allow(client).to receive(:get).and_raise(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end

      it "raises AuthenticationError" do
        expect { workspace_webhooks.list }.to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end
    end

    context "when access is forbidden" do
      before do
        allow(client).to receive(:get).and_raise(ElevenlabsClient::ForbiddenError, "Access denied")
      end

      it "raises ForbiddenError" do
        expect { workspace_webhooks.list }.to raise_error(ElevenlabsClient::ForbiddenError, "Access denied")
      end
    end

    context "when validation fails" do
      before do
        allow(client).to receive(:get).and_raise(ElevenlabsClient::ValidationError, "Invalid parameters")
      end

      it "raises ValidationError" do
        expect { workspace_webhooks.list }.to raise_error(ElevenlabsClient::ValidationError, "Invalid parameters")
      end
    end
  end

  describe "parameter encoding" do
    before do
      allow(client).to receive(:get).and_return({})
    end

    context "with special characters in parameters" do
      let(:special_value) { "value with spaces & symbols" }
      
      it "properly encodes query parameters" do
        workspace_webhooks.list(custom_param: special_value)
        
        expect(client).to have_received(:get) do |endpoint|
          expect(endpoint).to include(URI.encode_www_form_component(special_value))
        end
      end
    end

    context "with boolean parameters" do
      it "converts boolean to string" do
        workspace_webhooks.list(include_usages: false)
        
        expect(client).to have_received(:get) do |endpoint|
          expect(endpoint).to include("include_usages=false")
        end
      end
    end

    context "with numeric parameters" do
      it "converts numbers to strings" do
        workspace_webhooks.list(limit: 10)
        
        expect(client).to have_received(:get) do |endpoint|
          expect(endpoint).to include("limit=10")
        end
      end
    end
  end

  describe "webhook response structure validation" do
    let(:endpoint) { "/v1/workspace/webhooks" }

    context "with complete webhook data" do
      let(:complete_webhook_response) do
        {
          "webhooks" => [
            {
              "name" => "Complete Webhook",
              "webhook_id" => "webhook_123",
              "webhook_url" => "https://example.com/webhook",
              "is_disabled" => false,
              "is_auto_disabled" => false,
              "created_at_unix" => 1640995200,
              "auth_type" => "hmac",
              "usage" => [
                { "usage_type" => "ConvAI Settings" },
                { "usage_type" => "Voice Library" }
              ],
              "most_recent_failure_error_code" => nil,
              "most_recent_failure_timestamp" => nil
            }
          ]
        }
      end

      before do
        allow(client).to receive(:get).with(endpoint).and_return(complete_webhook_response)
      end

      it "handles complete webhook data structure" do
        result = workspace_webhooks.list

        webhook = result["webhooks"].first
        expect(webhook["name"]).to eq("Complete Webhook")
        expect(webhook["webhook_id"]).to eq("webhook_123")
        expect(webhook["webhook_url"]).to eq("https://example.com/webhook")
        expect(webhook["is_disabled"]).to be false
        expect(webhook["is_auto_disabled"]).to be false
        expect(webhook["created_at_unix"]).to eq(1640995200)
        expect(webhook["auth_type"]).to eq("hmac")
        expect(webhook["usage"].size).to eq(2)
        expect(webhook["most_recent_failure_error_code"]).to be_nil
        expect(webhook["most_recent_failure_timestamp"]).to be_nil
      end
    end

    context "with minimal webhook data" do
      let(:minimal_webhook_response) do
        {
          "webhooks" => [
            {
              "name" => "Minimal Webhook",
              "webhook_id" => "webhook_456",
              "webhook_url" => "https://minimal.example.com/webhook",
              "is_disabled" => true,
              "is_auto_disabled" => true,
              "created_at_unix" => 1640995200,
              "auth_type" => "none"
            }
          ]
        }
      end

      before do
        allow(client).to receive(:get).with(endpoint).and_return(minimal_webhook_response)
      end

      it "handles minimal webhook data structure" do
        result = workspace_webhooks.list

        webhook = result["webhooks"].first
        expect(webhook["name"]).to eq("Minimal Webhook")
        expect(webhook["is_disabled"]).to be true
        expect(webhook["is_auto_disabled"]).to be true
        expect(webhook["auth_type"]).to eq("none")
        expect(webhook.key?("usage")).to be false
        expect(webhook.key?("most_recent_failure_error_code")).to be false
      end
    end

    context "with empty webhooks list" do
      let(:empty_response) do
        { "webhooks" => [] }
      end

      before do
        allow(client).to receive(:get).with(endpoint).and_return(empty_response)
      end

      it "handles empty webhooks list" do
        result = workspace_webhooks.list

        expect(result["webhooks"]).to be_empty
      end
    end
  end

  describe "error scenarios" do
    let(:endpoint) { "/v1/workspace/webhooks" }

    context "when rate limited" do
      before do
        allow(client).to receive(:get).and_raise(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end

      it "raises RateLimitError" do
        expect {
          workspace_webhooks.list
        }.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end
    end

    context "when service unavailable" do
      before do
        allow(client).to receive(:get).and_raise(ElevenlabsClient::ServiceUnavailableError, "Service unavailable")
      end

      it "raises ServiceUnavailableError" do
        expect {
          workspace_webhooks.list
        }.to raise_error(ElevenlabsClient::ServiceUnavailableError, "Service unavailable")
      end
    end

    context "when network timeout" do
      before do
        allow(client).to receive(:get).and_raise(Timeout::Error, "Timeout")
      end

      it "raises TimeoutError" do
        expect {
          workspace_webhooks.list
        }.to raise_error(Timeout::Error, "Timeout")
      end
    end
  end
end
