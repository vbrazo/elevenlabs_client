# frozen_string_literal: true

require "spec_helper"

RSpec.describe ElevenlabsClient::Admin::ServiceAccountApiKeys do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test-api-key") }
  let(:service_account_api_keys) { described_class.new(client) }
  let(:service_account_user_id) { "service_account_123" }

  describe "#list" do
    let(:endpoint) { "/v1/service-accounts/#{service_account_user_id}/api-keys" }

    context "when successful" do
      let(:response) do
        {
          "api-keys" => [
            {
              "name" => "Production Key",
              "hint" => "****abcd",
              "key_id" => "key_123",
              "service_account_user_id" => service_account_user_id,
              "created_at_unix" => 1640995200,
              "is_disabled" => false,
              "permissions" => ["text_to_speech", "voices"],
              "character_limit" => 1000000,
              "character_count" => 50000
            },
            {
              "name" => "Development Key",
              "hint" => "****efgh",
              "key_id" => "key_456",
              "service_account_user_id" => service_account_user_id,
              "created_at_unix" => 1640995300,
              "is_disabled" => true,
              "permissions" => ["text_to_speech"],
              "character_limit" => 100000,
              "character_count" => 25000
            }
          ]
        }
      end

      before do
        allow(client).to receive(:get).with(endpoint).and_return(response)
      end

      it "lists API keys successfully" do
        result = service_account_api_keys.list(service_account_user_id)

        expect(result).to eq(response)
        expect(result["api-keys"].size).to eq(2)
        expect(result["api-keys"].first["name"]).to eq("Production Key")
        expect(result["api-keys"].first["key_id"]).to eq("key_123")
        expect(result["api-keys"].first["is_disabled"]).to be false
      end

      it "calls the correct endpoint" do
        service_account_api_keys.list(service_account_user_id)
        expect(client).to have_received(:get).with(endpoint)
      end
    end

    context "when service account not found" do
      before do
        allow(client).to receive(:get).and_raise(ElevenlabsClient::NotFoundError, "Service account not found")
      end

      it "raises NotFoundError" do
        expect {
          service_account_api_keys.list(service_account_user_id)
        }.to raise_error(ElevenlabsClient::NotFoundError, "Service account not found")
      end
    end

    context "when authentication fails" do
      before do
        allow(client).to receive(:get).and_raise(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end

      it "raises AuthenticationError" do
        expect {
          service_account_api_keys.list(service_account_user_id)
        }.to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end
    end
  end

  describe "#create" do
    let(:endpoint) { "/v1/service-accounts/#{service_account_user_id}/api-keys" }
    let(:name) { "Test API Key" }
    let(:permissions) { ["text_to_speech", "voices"] }

    context "when successful" do
      let(:request_body) do
        {
          name: name,
          permissions: permissions
        }
      end

      let(:response) do
        {
          "xi-api-key" => "sk_1234567890abcdef1234567890abcdef"
        }
      end

      before do
        allow(client).to receive(:post).with(endpoint, request_body).and_return(response)
      end

      it "creates API key successfully" do
        result = service_account_api_keys.create(
          service_account_user_id,
          name: name,
          permissions: permissions
        )

        expect(result).to eq(response)
        expect(result["xi-api-key"]).to start_with("sk_")
      end

      it "calls the correct endpoint with correct payload" do
        service_account_api_keys.create(
          service_account_user_id,
          name: name,
          permissions: permissions
        )
        expect(client).to have_received(:post).with(endpoint, request_body)
      end
    end

    context "with character limit" do
      let(:character_limit) { 500000 }
      let(:request_body) do
        {
          name: name,
          permissions: permissions,
          character_limit: character_limit
        }
      end

      before do
        allow(client).to receive(:post).with(endpoint, request_body).and_return({})
      end

      it "includes character limit in request" do
        service_account_api_keys.create(
          service_account_user_id,
          name: name,
          permissions: permissions,
          character_limit: character_limit
        )
        expect(client).to have_received(:post).with(endpoint, request_body)
      end
    end

    context "with all permissions" do
      let(:all_permissions) { "all" }
      let(:request_body) do
        {
          name: name,
          permissions: all_permissions
        }
      end

      before do
        allow(client).to receive(:post).with(endpoint, request_body).and_return({})
      end

      it "handles 'all' permissions string" do
        service_account_api_keys.create(
          service_account_user_id,
          name: name,
          permissions: all_permissions
        )
        expect(client).to have_received(:post).with(endpoint, request_body)
      end
    end

    context "when validation fails" do
      before do
        allow(client).to receive(:post).and_raise(ElevenlabsClient::ValidationError, "Invalid permissions")
      end

      it "raises ValidationError" do
        expect {
          service_account_api_keys.create(
            service_account_user_id,
            name: name,
            permissions: permissions
          )
        }.to raise_error(ElevenlabsClient::ValidationError, "Invalid permissions")
      end
    end

    context "missing required parameters" do
      it "requires name parameter" do
        expect {
          service_account_api_keys.create(
            service_account_user_id,
            permissions: permissions
          )
        }.to raise_error(ArgumentError)
      end

      it "requires permissions parameter" do
        expect {
          service_account_api_keys.create(
            service_account_user_id,
            name: name
          )
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#update" do
    let(:api_key_id) { "key_123" }
    let(:endpoint) { "/v1/service-accounts/#{service_account_user_id}/api-keys/#{api_key_id}" }
    let(:is_enabled) { true }
    let(:name) { "Updated API Key" }
    let(:permissions) { ["text_to_speech", "voices", "models"] }

    context "when successful" do
      let(:request_body) do
        {
          is_enabled: is_enabled,
          name: name,
          permissions: permissions
        }
      end

      let(:response) { {} }

      before do
        allow(client).to receive(:patch).with(endpoint, request_body).and_return(response)
      end

      it "updates API key successfully" do
        result = service_account_api_keys.update(
          service_account_user_id,
          api_key_id,
          is_enabled: is_enabled,
          name: name,
          permissions: permissions
        )

        expect(result).to eq(response)
      end

      it "calls the correct endpoint with correct payload" do
        service_account_api_keys.update(
          service_account_user_id,
          api_key_id,
          is_enabled: is_enabled,
          name: name,
          permissions: permissions
        )
        expect(client).to have_received(:patch).with(endpoint, request_body)
      end
    end

    context "with character limit update" do
      let(:character_limit) { 750000 }
      let(:request_body) do
        {
          is_enabled: is_enabled,
          name: name,
          permissions: permissions,
          character_limit: character_limit
        }
      end

      before do
        allow(client).to receive(:patch).with(endpoint, request_body).and_return({})
      end

      it "includes character limit in update" do
        service_account_api_keys.update(
          service_account_user_id,
          api_key_id,
          is_enabled: is_enabled,
          name: name,
          permissions: permissions,
          character_limit: character_limit
        )
        expect(client).to have_received(:patch).with(endpoint, request_body)
      end
    end

    context "disabling API key" do
      let(:is_enabled) { false }
      let(:request_body) do
        {
          is_enabled: false,
          name: name,
          permissions: permissions
        }
      end

      before do
        allow(client).to receive(:patch).with(endpoint, request_body).and_return({})
      end

      it "handles disabling API key" do
        service_account_api_keys.update(
          service_account_user_id,
          api_key_id,
          is_enabled: false,
          name: name,
          permissions: permissions
        )
        expect(client).to have_received(:patch).with(endpoint, request_body)
      end
    end

    context "when API key not found" do
      before do
        allow(client).to receive(:patch).and_raise(ElevenlabsClient::NotFoundError, "API key not found")
      end

      it "raises NotFoundError" do
        expect {
          service_account_api_keys.update(
            service_account_user_id,
            api_key_id,
            is_enabled: is_enabled,
            name: name,
            permissions: permissions
          )
        }.to raise_error(ElevenlabsClient::NotFoundError, "API key not found")
      end
    end

    context "missing required parameters" do
      it "requires is_enabled parameter" do
        expect {
          service_account_api_keys.update(
            service_account_user_id,
            api_key_id,
            name: name,
            permissions: permissions
          )
        }.to raise_error(ArgumentError)
      end

      it "requires name parameter" do
        expect {
          service_account_api_keys.update(
            service_account_user_id,
            api_key_id,
            is_enabled: is_enabled,
            permissions: permissions
          )
        }.to raise_error(ArgumentError)
      end

      it "requires permissions parameter" do
        expect {
          service_account_api_keys.update(
            service_account_user_id,
            api_key_id,
            is_enabled: is_enabled,
            name: name
          )
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#delete" do
    let(:api_key_id) { "key_123" }
    let(:endpoint) { "/v1/service-accounts/#{service_account_user_id}/api-keys/#{api_key_id}" }

    context "when successful" do
      let(:response) { {} }

      before do
        allow(client).to receive(:delete).with(endpoint).and_return(response)
      end

      it "deletes API key successfully" do
        result = service_account_api_keys.delete(service_account_user_id, api_key_id)

        expect(result).to eq(response)
      end

      it "calls the correct endpoint" do
        service_account_api_keys.delete(service_account_user_id, api_key_id)
        expect(client).to have_received(:delete).with(endpoint)
      end
    end

    context "when API key not found" do
      before do
        allow(client).to receive(:delete).and_raise(ElevenlabsClient::NotFoundError, "API key not found")
      end

      it "raises NotFoundError" do
        expect {
          service_account_api_keys.delete(service_account_user_id, api_key_id)
        }.to raise_error(ElevenlabsClient::NotFoundError, "API key not found")
      end
    end

    context "when access forbidden" do
      before do
        allow(client).to receive(:delete).and_raise(ElevenlabsClient::ForbiddenError, "Access denied")
      end

      it "raises ForbiddenError" do
        expect {
          service_account_api_keys.delete(service_account_user_id, api_key_id)
        }.to raise_error(ElevenlabsClient::ForbiddenError, "Access denied")
      end
    end
  end

  describe "error handling" do
    let(:api_key_id) { "key_123" }

    context "when rate limited" do
      before do
        allow(client).to receive(:get).and_raise(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end

      it "propagates rate limit errors for list" do
        expect {
          service_account_api_keys.list(service_account_user_id)
        }.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end
    end

    context "when service unavailable" do
      before do
        allow(client).to receive(:post).and_raise(ElevenlabsClient::ServiceUnavailableError, "Service unavailable")
      end

      it "propagates service unavailable errors for create" do
        expect {
          service_account_api_keys.create(
            service_account_user_id,
            name: "Test",
            permissions: ["text_to_speech"]
          )
        }.to raise_error(ElevenlabsClient::ServiceUnavailableError, "Service unavailable")
      end
    end

    context "when payment required" do
      before do
        allow(client).to receive(:post).and_raise(ElevenlabsClient::PaymentRequiredError, "Payment required")
      end

      it "propagates payment required errors for create" do
        expect {
          service_account_api_keys.create(
            service_account_user_id,
            name: "Test",
            permissions: ["text_to_speech"]
          )
        }.to raise_error(ElevenlabsClient::PaymentRequiredError, "Payment required")
      end
    end
  end

  describe "parameter validation" do
    context "with nil service account ID" do
      before do
        allow(client).to receive(:get).and_return({})
        allow(client).to receive(:post).and_return({})
        allow(client).to receive(:patch).and_return({})
        allow(client).to receive(:delete).and_return({})
      end

      it "handles nil service account ID gracefully for list" do
        expect { service_account_api_keys.list(nil) }.not_to raise_error
      end

      it "handles nil service account ID gracefully for create" do
        expect {
          service_account_api_keys.create(nil, name: "Test", permissions: ["text_to_speech"])
        }.not_to raise_error
      end

      it "handles nil service account ID gracefully for update" do
        expect {
          service_account_api_keys.update(
            nil,
            "key_id",
            is_enabled: true,
            name: "Test",
            permissions: ["text_to_speech"]
          )
        }.not_to raise_error
      end

      it "handles nil service account ID gracefully for delete" do
        expect { service_account_api_keys.delete(nil, "key_id") }.not_to raise_error
      end
    end

    context "with empty service account ID" do
      before do
        allow(client).to receive(:get).and_return({})
      end

      it "handles empty service account ID gracefully" do
        expect { service_account_api_keys.list("") }.not_to raise_error
      end
    end

    context "with nil API key ID" do
      before do
        allow(client).to receive(:patch).and_return({})
        allow(client).to receive(:delete).and_return({})
      end

      it "handles nil API key ID gracefully for update" do
        expect {
          service_account_api_keys.update(
            service_account_user_id,
            nil,
            is_enabled: true,
            name: "Test",
            permissions: ["text_to_speech"]
          )
        }.not_to raise_error
      end

      it "handles nil API key ID gracefully for delete" do
        expect { service_account_api_keys.delete(service_account_user_id, nil) }.not_to raise_error
      end
    end
  end

  describe "permissions handling" do
    let(:endpoint) { "/v1/service-accounts/#{service_account_user_id}/api-keys" }

    context "with array of permissions" do
      let(:permissions) { ["text_to_speech", "voices", "models"] }
      let(:request_body) do
        {
          name: "Test Key",
          permissions: permissions
        }
      end

      before do
        allow(client).to receive(:post).with(endpoint, request_body).and_return({})
      end

      it "handles array of permissions" do
        service_account_api_keys.create(
          service_account_user_id,
          name: "Test Key",
          permissions: permissions
        )
        expect(client).to have_received(:post).with(endpoint, request_body)
      end
    end

    context "with single permission string" do
      let(:permissions) { "text_to_speech" }
      let(:request_body) do
        {
          name: "Test Key",
          permissions: permissions
        }
      end

      before do
        allow(client).to receive(:post).with(endpoint, request_body).and_return({})
      end

      it "handles single permission string" do
        service_account_api_keys.create(
          service_account_user_id,
          name: "Test Key",
          permissions: permissions
        )
        expect(client).to have_received(:post).with(endpoint, request_body)
      end
    end

    context "with 'all' permissions" do
      let(:permissions) { "all" }
      let(:request_body) do
        {
          name: "Test Key",
          permissions: permissions
        }
      end

      before do
        allow(client).to receive(:post).with(endpoint, request_body).and_return({})
      end

      it "handles 'all' permissions" do
        service_account_api_keys.create(
          service_account_user_id,
          name: "Test Key",
          permissions: permissions
        )
        expect(client).to have_received(:post).with(endpoint, request_body)
      end
    end
  end

  describe "optional parameters handling" do
    let(:endpoint) { "/v1/service-accounts/#{service_account_user_id}/api-keys" }

    context "create with extra options" do
      let(:extra_options) do
        {
          character_limit: 1000000,
          custom_field: "custom_value"
        }
      end

      let(:request_body) do
        {
          name: "Test Key",
          permissions: ["text_to_speech"],
          character_limit: 1000000,
          custom_field: "custom_value"
        }
      end

      before do
        allow(client).to receive(:post).with(endpoint, request_body).and_return({})
      end

      it "passes through extra options" do
        service_account_api_keys.create(
          service_account_user_id,
          name: "Test Key",
          permissions: ["text_to_speech"],
          **extra_options
        )
        expect(client).to have_received(:post).with(endpoint, request_body)
      end
    end

    context "update with extra options" do
      let(:api_key_id) { "key_123" }
      let(:endpoint) { "/v1/service-accounts/#{service_account_user_id}/api-keys/#{api_key_id}" }
      
      let(:extra_options) do
        {
          character_limit: 500000,
          metadata: { environment: "production" }
        }
      end

      let(:request_body) do
        {
          is_enabled: true,
          name: "Test Key",
          permissions: ["text_to_speech"],
          character_limit: 500000,
          metadata: { environment: "production" }
        }
      end

      before do
        allow(client).to receive(:patch).with(endpoint, request_body).and_return({})
      end

      it "passes through extra options" do
        service_account_api_keys.update(
          service_account_user_id,
          api_key_id,
          is_enabled: true,
          name: "Test Key",
          permissions: ["text_to_speech"],
          **extra_options
        )
        expect(client).to have_received(:patch).with(endpoint, request_body)
      end
    end
  end
end
