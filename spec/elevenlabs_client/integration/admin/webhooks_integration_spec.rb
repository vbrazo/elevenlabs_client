# frozen_string_literal: true

RSpec.describe "Admin::Webhooks Integration", :integration do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:webhooks) { client.webhooks }

  let(:webhooks_response) do
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

  describe "#list_webhooks" do
    context "when retrieving workspace webhooks" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: webhooks_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "successfully retrieves webhooks" do
        result = webhooks.list_webhooks
        
        expect(result).to be_a(Hash)
        expect(result).to have_key("webhooks")
        expect(result["webhooks"]).to be_an(Array)
      end

      it "returns webhooks with expected structure" do
        result = webhooks.list_webhooks
        
        webhooks_list = result["webhooks"]
        
        if webhooks_list.any?
          webhook = webhooks_list.first
          
          expect(webhook).to have_key("name")
          expect(webhook).to have_key("webhook_id")
          expect(webhook).to have_key("webhook_url")
          expect(webhook).to have_key("is_disabled")
          expect(webhook).to have_key("is_auto_disabled")
          expect(webhook).to have_key("created_at_unix")
          expect(webhook).to have_key("auth_type")
          expect(webhook).to have_key("usage")
          
          expect(webhook["name"]).to be_a(String)
          expect(webhook["webhook_id"]).to be_a(String)
          expect(webhook["webhook_url"]).to be_a(String)
          expect([true, false]).to include(webhook["is_disabled"])
          expect([true, false]).to include(webhook["is_auto_disabled"])
          expect(webhook["created_at_unix"]).to be_a(Integer)
          expect(webhook["auth_type"]).to be_a(String)
          expect(webhook["usage"]).to be_an(Array)
          
          # Optional fields that may be nil
          if webhook["most_recent_failure_error_code"]
            expect(webhook["most_recent_failure_error_code"]).to be_a(Integer)
          end
          
          if webhook["most_recent_failure_timestamp"]
            expect(webhook["most_recent_failure_timestamp"]).to be_a(Integer)
          end
          
          # Validate usage array structure if present
          if webhook["usage"].any?
            usage = webhook["usage"].first
            expect(usage).to have_key("usage_type")
            expect(usage["usage_type"]).to be_a(String)
          end
        end
      end
    end

    context "when include_usages parameter is provided" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(
            headers: { "xi-api-key" => api_key },
            query: { include_usages: true }
          )
          .to_return(
            status: 200,
            body: webhooks_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "successfully retrieves webhooks with usage information" do
        result = webhooks.list_webhooks(include_usages: true)
        
        expect(result).to be_a(Hash)
        expect(result).to have_key("webhooks")
        expect(result["webhooks"]).to be_an(Array)
        
        # If webhooks exist, they should have usage information
        webhooks_list = result["webhooks"]
        if webhooks_list.any?
          webhook = webhooks_list.first
          expect(webhook).to have_key("usage")
          expect(webhook["usage"]).to be_an(Array)
        end
      end
    end

    context "when include_usages is false" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(
            headers: { "xi-api-key" => api_key },
            query: { include_usages: false }
          )
          .to_return(
            status: 200,
            body: webhooks_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "successfully retrieves webhooks without detailed usage information" do
        result = webhooks.list_webhooks(include_usages: false)
        
        expect(result).to be_a(Hash)
        expect(result).to have_key("webhooks")
        expect(result["webhooks"]).to be_an(Array)
      end
    end

    context "when authentication fails" do
      let(:client_with_invalid_key) { ElevenlabsClient::Client.new(api_key: "invalid_key") }
      let(:webhooks_with_invalid_key) { client_with_invalid_key.webhooks }

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(headers: { "xi-api-key" => "invalid_key" })
          .to_return(
            status: 401,
            body: { detail: "Unauthorized" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises an AuthenticationError" do
        expect {
          webhooks_with_invalid_key.list_webhooks
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end
  end

  describe "aliases" do
    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
        .with(headers: { "xi-api-key" => api_key })
        .to_return(
          status: 200,
          body: webhooks_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    context "when using get_webhooks alias" do
      it "successfully retrieves webhooks" do
        result = webhooks.get_webhooks
        
        expect(result).to be_a(Hash)
        expect(result).to have_key("webhooks")
        expect(result["webhooks"]).to be_an(Array)
      end
    end

    context "when using all alias" do
      it "successfully retrieves webhooks" do
        result = webhooks.all
        
        expect(result).to be_a(Hash)
        expect(result).to have_key("webhooks")
        expect(result["webhooks"]).to be_an(Array)
      end
    end

    context "when using webhooks alias" do
      it "successfully retrieves webhooks" do
        result = webhooks.webhooks
        
        expect(result).to be_a(Hash)
        expect(result).to have_key("webhooks")
        expect(result["webhooks"]).to be_an(Array)
      end
    end
  end

  describe "response structure validation" do
    context "when webhooks exist" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(
            headers: { "xi-api-key" => api_key },
            query: { include_usages: true }
          )
          .to_return(
            status: 200,
            body: webhooks_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "validates complete response structure" do
        result = webhooks.list_webhooks(include_usages: true)
        
        expect(result).to be_a(Hash)
        expect(result.keys).to include("webhooks")
        
        webhooks_array = result["webhooks"]
        expect(webhooks_array).to be_an(Array)
        
        # If webhooks exist, validate their structure
        webhooks_array.each do |webhook|
          expect(webhook).to be_a(Hash)
          
          # Required fields
          expect(webhook).to have_key("name")
          expect(webhook).to have_key("webhook_id")
          expect(webhook).to have_key("webhook_url")
          expect(webhook).to have_key("is_disabled")
          expect(webhook).to have_key("is_auto_disabled")
          expect(webhook).to have_key("created_at_unix")
          expect(webhook).to have_key("auth_type")
          expect(webhook).to have_key("usage")
          
          # Field types
          expect(webhook["name"]).to be_a(String)
          expect(webhook["webhook_id"]).to be_a(String)
          expect(webhook["webhook_url"]).to be_a(String)
          expect([true, false]).to include(webhook["is_disabled"])
          expect([true, false]).to include(webhook["is_auto_disabled"])
          expect(webhook["created_at_unix"]).to be_a(Integer)
          expect(webhook["auth_type"]).to be_a(String)
          expect(webhook["usage"]).to be_an(Array)
          
          # Validate webhook URL format
          expect(webhook["webhook_url"]).to match(/\Ahttps?:\/\//)
          
          # Validate auth type is one of expected values
          expect(webhook["auth_type"]).to match(/\A(hmac|bearer|none)\z/i)
          
          # Validate usage array structure
          webhook["usage"].each do |usage|
            expect(usage).to be_a(Hash)
            expect(usage).to have_key("usage_type")
            expect(usage["usage_type"]).to be_a(String)
            expect(usage["usage_type"]).not_to be_empty
          end
          
          # Validate timestamps are reasonable (after 2020)
          expect(webhook["created_at_unix"]).to be > 1577836800 # 2020-01-01
          
          if webhook["most_recent_failure_timestamp"]
            expect(webhook["most_recent_failure_timestamp"]).to be > 1577836800
          end
          
          # Validate error codes are valid HTTP status codes
          if webhook["most_recent_failure_error_code"]
            expect(webhook["most_recent_failure_error_code"]).to be_between(100, 599)
          end
        end
      end
    end
  end

  describe "parameter handling" do
    context "when testing different parameter combinations" do
      it "handles include_usages true correctly" do
        stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(
            headers: { "xi-api-key" => api_key },
            query: { include_usages: true }
          )
          .to_return(
            status: 200,
            body: webhooks_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = webhooks.list_webhooks(include_usages: true)
        
        expect(result).to be_a(Hash)
        expect(result).to have_key("webhooks")
        
        # Should include detailed usage information when available
        webhooks_list = result["webhooks"]
        if webhooks_list.any?
          webhook = webhooks_list.first
          expect(webhook).to have_key("usage")
          expect(webhook["usage"]).to be_an(Array)
        end
      end

      it "handles include_usages false correctly" do
        stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(
            headers: { "xi-api-key" => api_key },
            query: { include_usages: false }
          )
          .to_return(
            status: 200,
            body: webhooks_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = webhooks.list_webhooks(include_usages: false)
        
        expect(result).to be_a(Hash)
        expect(result).to have_key("webhooks")
        
        # Should still have usage field but may be less detailed
        webhooks_list = result["webhooks"]
        if webhooks_list.any?
          webhook = webhooks_list.first
          expect(webhook).to have_key("usage")
          expect(webhook["usage"]).to be_an(Array)
        end
      end

      it "handles no parameters correctly" do
        stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: webhooks_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = webhooks.list_webhooks
        
        expect(result).to be_a(Hash)
        expect(result).to have_key("webhooks")
        expect(result["webhooks"]).to be_an(Array)
      end
    end
  end

  describe "error handling" do
    context "when there are no webhooks" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: { "webhooks" => [] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns empty array without errors" do
        result = webhooks.list_webhooks
        
        expect(result).to be_a(Hash)
        expect(result).to have_key("webhooks")
        
        # Should be an array, even if empty
        expect(result["webhooks"]).to be_an(Array)
      end
    end
  end

  describe "webhook status analysis" do
    context "when analyzing webhook health" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/workspace/webhooks")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: webhooks_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "can identify webhook statuses" do
        result = webhooks.list_webhooks
        
        webhooks_list = result["webhooks"]
        
        if webhooks_list.any?
          active_webhooks = webhooks_list.count { |w| !w["is_disabled"] }
          disabled_webhooks = webhooks_list.count { |w| w["is_disabled"] }
          auto_disabled_webhooks = webhooks_list.count { |w| w["is_auto_disabled"] }
          
          expect(active_webhooks).to be >= 0
          expect(disabled_webhooks).to be >= 0
          expect(auto_disabled_webhooks).to be >= 0
          expect(active_webhooks + disabled_webhooks).to eq(webhooks_list.length)
          
          # Webhooks with recent failures
          failed_webhooks = webhooks_list.count { |w| w["most_recent_failure_error_code"] }
          expect(failed_webhooks).to be >= 0
        end
      end
    end
  end
end