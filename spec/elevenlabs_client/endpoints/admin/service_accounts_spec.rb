# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Admin::ServiceAccounts do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test_api_key") }
  let(:service_accounts) { client.service_accounts }

  describe "#get_service_accounts" do
    let(:expected_response) do
      {
        "service-accounts" => [
          {
            "service_account_user_id" => "sa_123abc",
            "name" => "Test Service Account",
            "api-keys" => [
              {
                "name" => "Production API Key",
                "hint" => "sk_abc...xyz",
                "key_id" => "key_123",
                "service_account_user_id" => "sa_123abc",
                "created_at_unix" => 1609459200,
                "is_disabled" => false,
                "permissions" => ["text_to_speech", "speech_to_text"],
                "character_limit" => 50000,
                "character_count" => 12500
              }
            ],
            "created_at_unix" => 1609459200
          }
        ]
      }
    end

    context "when request is successful" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/service-accounts")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(
            status: 200,
            body: expected_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "retrieves service accounts successfully" do
        result = service_accounts.get_service_accounts
        expect(result).to eq(expected_response)
      end

      it "makes a GET request to the correct endpoint" do
        service_accounts.get_service_accounts
        
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/service-accounts")
          .with(headers: { "xi-api-key" => "test_api_key" })
      end

      it "returns service accounts with expected structure" do
        result = service_accounts.get_service_accounts
        
        expect(result).to have_key("service-accounts")
        expect(result["service-accounts"]).to be_an(Array)
        
        service_account = result["service-accounts"].first
        expect(service_account).to have_key("service_account_user_id")
        expect(service_account).to have_key("name")
        expect(service_account).to have_key("api-keys")
        expect(service_account).to have_key("created_at_unix")
        
        api_key = service_account["api-keys"].first
        expect(api_key).to have_key("name")
        expect(api_key).to have_key("hint")
        expect(api_key).to have_key("key_id")
        expect(api_key).to have_key("permissions")
        expect(api_key).to have_key("character_limit")
        expect(api_key).to have_key("character_count")
      end
    end

    context "when authentication fails" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/service-accounts")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(
            status: 401,
            body: { detail: "Unauthorized" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises an AuthenticationError" do
        expect {
          service_accounts.get_service_accounts
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    context "when there's a validation error" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/service-accounts")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(
            status: 422,
            body: { detail: "Invalid request parameters" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises an UnprocessableEntityError" do
        expect {
          service_accounts.get_service_accounts
        }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end

    context "when rate limit is exceeded" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/service-accounts")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(
            status: 429,
            body: { detail: "Rate limit exceeded" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises a RateLimitError" do
        expect {
          service_accounts.get_service_accounts
        }.to raise_error(ElevenlabsClient::RateLimitError)
      end
    end

    context "when there's a server error" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/service-accounts")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(
            status: 500,
            body: { detail: "Internal server error" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises an APIError" do
        expect {
          service_accounts.get_service_accounts
        }.to raise_error(ElevenlabsClient::APIError)
      end
    end

    context "when no service accounts exist" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/service-accounts")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(
            status: 200,
            body: { "service-accounts" => [] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns empty service accounts array" do
        result = service_accounts.get_service_accounts
        expect(result["service-accounts"]).to eq([])
      end
    end
  end

  describe "aliases" do
    let(:expected_response) do
      {
        "service-accounts" => [
          {
            "service_account_user_id" => "sa_123abc",
            "name" => "Test Service Account",
            "api-keys" => [],
            "created_at_unix" => 1609459200
          }
        ]
      }
    end

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/service-accounts")
        .with(headers: { "xi-api-key" => "test_api_key" })
        .to_return(
          status: 200,
          body: expected_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    describe "#list" do
      it "works as an alias for get_service_accounts" do
        result = service_accounts.list
        expect(result).to eq(expected_response)
      end
    end

    describe "#all" do
      it "works as an alias for get_service_accounts" do
        result = service_accounts.all
        expect(result).to eq(expected_response)
      end
    end

    describe "#service_accounts" do
      it "works as an alias for get_service_accounts" do
        result = service_accounts.service_accounts
        expect(result).to eq(expected_response)
      end
    end
  end
end
