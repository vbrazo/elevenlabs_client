# frozen_string_literal: true

require "spec_helper"

RSpec.describe ElevenlabsClient::Endpoints::AgentsPlatform::Workspace do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test-api-key") }
  let(:workspace) { described_class.new(client) }

  describe "#get_settings" do
    let(:endpoint) { "/v1/convai/settings" }
    let(:response) do
      {
        "conversation_initiation_client_data_webhook" => {
          "url" => "https://example.com/webhook",
          "request_headers" => { "Authorization" => "Bearer token" }
        },
        "webhooks" => {
          "post_call_webhook_id" => "webhook_123",
          "send_audio" => false
        },
        "can_use_mcp_servers" => false,
        "rag_retention_period_days" => 10,
        "default_livekit_stack" => "standard"
      }
    end

    before do
      allow(client).to receive(:get).with(endpoint).and_return(response)
    end

    it "retrieves workspace settings successfully" do
      result = workspace.get_settings

      expect(result).to eq(response)
      expect(result["can_use_mcp_servers"]).to be false
      expect(result["rag_retention_period_days"]).to eq(10)
      expect(result["default_livekit_stack"]).to eq("standard")
    end

    it "calls the correct endpoint" do
      workspace.get_settings

      expect(client).to have_received(:get).with(endpoint)
    end
  end

  describe "#update_settings" do
    let(:endpoint) { "/v1/convai/settings" }
    let(:options) do
      {
        can_use_mcp_servers: true,
        rag_retention_period_days: 15,
        default_livekit_stack: "static"
      }
    end
    let(:response) do
      {
        "can_use_mcp_servers" => true,
        "rag_retention_period_days" => 15,
        "default_livekit_stack" => "static"
      }
    end

    before do
      allow(client).to receive(:patch).with(endpoint, options).and_return(response)
    end

    it "updates workspace settings successfully" do
      result = workspace.update_settings(**options)

      expect(result).to eq(response)
      expect(result["can_use_mcp_servers"]).to be true
      expect(result["rag_retention_period_days"]).to eq(15)
    end

    it "calls the correct endpoint with correct payload" do
      workspace.update_settings(**options)

      expect(client).to have_received(:patch).with(endpoint, options)
    end

    it "filters out nil values" do
      options_with_nil = options.merge(webhooks: nil)
      expected_body = options

      allow(client).to receive(:patch).with(endpoint, expected_body).and_return(response)

      workspace.update_settings(**options_with_nil)

      expect(client).to have_received(:patch).with(endpoint, expected_body)
    end
  end

  describe "#get_secrets" do
    let(:endpoint) { "/v1/convai/secrets" }
    let(:response) do
      {
        "secrets" => [
          {
            "type" => "stored",
            "secret_id" => "secret_123",
            "name" => "api_key",
            "used_by" => {
              "tools" => [],
              "agents" => [],
              "others" => [],
              "phone_numbers" => []
            }
          }
        ]
      }
    end

    before do
      allow(client).to receive(:get).with(endpoint).and_return(response)
    end

    it "retrieves workspace secrets successfully" do
      result = workspace.get_secrets

      expect(result).to eq(response)
      expect(result["secrets"].size).to eq(1)
      expect(result["secrets"].first["name"]).to eq("api_key")
    end

    it "calls the correct endpoint" do
      workspace.get_secrets

      expect(client).to have_received(:get).with(endpoint)
    end
  end

  describe "#create_secret" do
    let(:endpoint) { "/v1/convai/secrets" }
    let(:name) { "test_secret" }
    let(:value) { "secret_value_123" }
    let(:response) do
      {
        "type" => "stored",
        "secret_id" => "secret_456",
        "name" => name
      }
    end

    before do
      allow(client).to receive(:post).with(endpoint, any_args).and_return(response)
    end

    it "creates a secret successfully" do
      result = workspace.create_secret(name: name, value: value)

      expect(result).to eq(response)
      expect(result["secret_id"]).to eq("secret_456")
      expect(result["name"]).to eq(name)
    end

    it "calls the correct endpoint with correct payload" do
      workspace.create_secret(name: name, value: value)

      expected_body = {
        type: "new",
        name: name,
        value: value
      }

      expect(client).to have_received(:post).with(endpoint, expected_body)
    end

    it "allows custom type" do
      workspace.create_secret(name: name, value: value, type: "custom")

      expected_body = {
        type: "custom",
        name: name,
        value: value
      }

      expect(client).to have_received(:post).with(endpoint, expected_body)
    end

    it "requires name parameter" do
      expect {
        workspace.create_secret(name: "", value: value)
      }.to raise_error(ArgumentError, "name is required")

      expect {
        workspace.create_secret(name: nil, value: value)
      }.to raise_error(ArgumentError, "name is required")
    end

    it "requires value parameter" do
      expect {
        workspace.create_secret(name: name, value: "")
      }.to raise_error(ArgumentError, "value is required")

      expect {
        workspace.create_secret(name: name, value: nil)
      }.to raise_error(ArgumentError, "value is required")
    end
  end

  describe "#update_secret" do
    let(:secret_id) { "secret_123" }
    let(:endpoint) { "/v1/convai/secrets/#{secret_id}" }
    let(:name) { "updated_secret" }
    let(:value) { "updated_value_456" }
    let(:response) do
      {
        "type" => "stored",
        "secret_id" => secret_id,
        "name" => name
      }
    end

    before do
      allow(client).to receive(:patch).with(endpoint, any_args).and_return(response)
    end

    it "updates a secret successfully" do
      result = workspace.update_secret(secret_id, name: name, value: value)

      expect(result).to eq(response)
      expect(result["secret_id"]).to eq(secret_id)
      expect(result["name"]).to eq(name)
    end

    it "calls the correct endpoint with correct payload" do
      workspace.update_secret(secret_id, name: name, value: value)

      expected_body = {
        type: "update",
        name: name,
        value: value
      }

      expect(client).to have_received(:patch).with(endpoint, expected_body)
    end

    it "allows custom type" do
      workspace.update_secret(secret_id, name: name, value: value, type: "custom")

      expected_body = {
        type: "custom",
        name: name,
        value: value
      }

      expect(client).to have_received(:patch).with(endpoint, expected_body)
    end

    it "requires secret_id parameter" do
      expect {
        workspace.update_secret("", name: name, value: value)
      }.to raise_error(ArgumentError, "secret_id is required")

      expect {
        workspace.update_secret(nil, name: name, value: value)
      }.to raise_error(ArgumentError, "secret_id is required")
    end

    it "requires name parameter" do
      expect {
        workspace.update_secret(secret_id, name: "", value: value)
      }.to raise_error(ArgumentError, "name is required")

      expect {
        workspace.update_secret(secret_id, name: nil, value: value)
      }.to raise_error(ArgumentError, "name is required")
    end

    it "requires value parameter" do
      expect {
        workspace.update_secret(secret_id, name: name, value: "")
      }.to raise_error(ArgumentError, "value is required")

      expect {
        workspace.update_secret(secret_id, name: name, value: nil)
      }.to raise_error(ArgumentError, "value is required")
    end
  end

  describe "#delete_secret" do
    let(:secret_id) { "secret_123" }
    let(:endpoint) { "/v1/convai/secrets/#{secret_id}" }
    let(:response) { {} }

    before do
      allow(client).to receive(:delete).with(endpoint).and_return(response)
    end

    it "deletes a secret successfully" do
      result = workspace.delete_secret(secret_id)

      expect(result).to eq(response)
    end

    it "calls the correct endpoint" do
      workspace.delete_secret(secret_id)

      expect(client).to have_received(:delete).with(endpoint)
    end

    it "requires secret_id parameter" do
      expect {
        workspace.delete_secret("")
      }.to raise_error(ArgumentError, "secret_id is required")

      expect {
        workspace.delete_secret(nil)
      }.to raise_error(ArgumentError, "secret_id is required")
    end
  end

  describe "#get_dashboard_settings" do
    let(:endpoint) { "/v1/convai/settings/dashboard" }
    let(:response) do
      {
        "charts" => [
          {
            "name" => "Call Success Rate",
            "type" => "call_success"
          },
          {
            "name" => "Daily Volume",
            "type" => "daily_volume"
          }
        ]
      }
    end

    before do
      allow(client).to receive(:get).with(endpoint).and_return(response)
    end

    it "retrieves dashboard settings successfully" do
      result = workspace.get_dashboard_settings

      expect(result).to eq(response)
      expect(result["charts"].size).to eq(2)
      expect(result["charts"].first["name"]).to eq("Call Success Rate")
    end

    it "calls the correct endpoint" do
      workspace.get_dashboard_settings

      expect(client).to have_received(:get).with(endpoint)
    end
  end

  describe "#update_dashboard_settings" do
    let(:endpoint) { "/v1/convai/settings/dashboard" }
    let(:charts) do
      [
        { "name" => "Success Rate", "type" => "call_success" },
        { "name" => "Duration", "type" => "conversation_duration" }
      ]
    end
    let(:response) do
      {
        "charts" => charts
      }
    end

    before do
      allow(client).to receive(:patch).with(endpoint, any_args).and_return(response)
    end

    it "updates dashboard settings successfully" do
      result = workspace.update_dashboard_settings(charts: charts)

      expect(result).to eq(response)
      expect(result["charts"].size).to eq(2)
    end

    it "calls the correct endpoint with correct payload" do
      workspace.update_dashboard_settings(charts: charts)

      expected_body = { charts: charts }

      expect(client).to have_received(:patch).with(endpoint, expected_body)
    end

    it "handles nil charts parameter" do
      workspace.update_dashboard_settings

      expected_body = {}

      expect(client).to have_received(:patch).with(endpoint, expected_body)
    end
  end

  describe "convenience method aliases" do
    before do
      allow(client).to receive(:get).and_return({})
    end

    it "provides settings alias for get_settings" do
      workspace.settings

      expect(client).to have_received(:get).with("/v1/convai/settings")
    end

    it "provides secrets alias for get_secrets" do
      workspace.secrets

      expect(client).to have_received(:get).with("/v1/convai/secrets")
    end

    it "provides dashboard_settings alias for get_dashboard_settings" do
      workspace.dashboard_settings

      expect(client).to have_received(:get).with("/v1/convai/settings/dashboard")
    end
  end

  describe "error scenarios" do
    context "when client raises an error" do
      before do
        allow(client).to receive(:get).and_raise(ElevenlabsClient::APIError, "API Error")
      end

      it "propagates the error" do
        expect {
          workspace.get_settings
        }.to raise_error(ElevenlabsClient::APIError, "API Error")
      end
    end

    context "when authentication fails" do
      before do
        allow(client).to receive(:get).and_raise(ElevenlabsClient::AuthenticationError, "Unauthorized")
      end

      it "raises AuthenticationError" do
        expect {
          workspace.get_settings
        }.to raise_error(ElevenlabsClient::AuthenticationError, "Unauthorized")
      end
    end

    context "when access is forbidden" do
      before do
        allow(client).to receive(:patch).and_raise(ElevenlabsClient::ForbiddenError, "Access denied")
      end

      it "raises ForbiddenError" do
        expect {
          workspace.update_settings(can_use_mcp_servers: true)
        }.to raise_error(ElevenlabsClient::ForbiddenError, "Access denied")
      end
    end

    context "when validation fails" do
      before do
        allow(client).to receive(:patch).and_raise(ElevenlabsClient::UnprocessableEntityError, "Invalid parameters")
      end

      it "raises UnprocessableEntityError" do
        expect {
          workspace.update_settings(rag_retention_period_days: 35) # Invalid: >30
        }.to raise_error(ElevenlabsClient::UnprocessableEntityError, "Invalid parameters")
      end
    end

    context "when secret is in use" do
      before do
        allow(client).to receive(:delete).and_raise(ElevenlabsClient::UnprocessableEntityError, "Secret is in use")
      end

      it "raises UnprocessableEntityError" do
        expect {
          workspace.delete_secret("secret_123")
        }.to raise_error(ElevenlabsClient::UnprocessableEntityError, "Secret is in use")
      end
    end

    context "when secret not found" do
      before do
        allow(client).to receive(:patch).and_raise(ElevenlabsClient::NotFoundError, "Secret not found")
      end

      it "raises NotFoundError" do
        expect {
          workspace.update_secret("nonexistent", name: "test", value: "test")
        }.to raise_error(ElevenlabsClient::NotFoundError, "Secret not found")
      end
    end
  end
end
