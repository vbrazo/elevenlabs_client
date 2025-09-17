# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe "Service Account API Keys Integration" do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test-api-key") }
  let(:service_account_user_id) { "service_account_test_123" }
  let(:base_url) { "https://api.elevenlabs.io" }

  describe "Service Account API Keys Management" do
    describe "GET /v1/service-accounts/{service_account_user_id}/api-keys" do
      let(:endpoint) { "#{base_url}/v1/service-accounts/#{service_account_user_id}/api-keys" }

      context "successful API keys listing" do
        let(:api_keys_response) do
          {
            "api-keys": [
              {
                name: "Production TTS Key",
                hint: "****abcd",
                key_id: "key_prod_123",
                service_account_user_id: service_account_user_id,
                created_at_unix: 1640995200,
                is_disabled: false,
                permissions: ["text_to_speech", "voices"],
                character_limit: 1000000,
                character_count: 125000
              },
              {
                name: "Development Key",
                hint: "****efgh",
                key_id: "key_dev_456",
                service_account_user_id: service_account_user_id,
                created_at_unix: 1640995300,
                is_disabled: false,
                permissions: ["text_to_speech"],
                character_limit: 100000,
                character_count: 85000
              },
              {
                name: "Legacy Admin Key",
                hint: "****ijkl",
                key_id: "key_admin_789",
                service_account_user_id: service_account_user_id,
                created_at_unix: 1635804000,
                is_disabled: true,
                permissions: "all",
                character_limit: nil,
                character_count: 2500000
              }
            ]
          }
        end

        before do
          stub_request(:get, endpoint)
            .with(headers: { "xi-api-key" => "test-api-key" })
            .to_return(
              status: 200,
              body: api_keys_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "retrieves service account API keys successfully" do
          result = client.service_account_api_keys.list(service_account_user_id)

          expect(result["api-keys"].size).to eq(3)
          
          # Production key verification
          prod_key = result["api-keys"].find { |k| k["name"] == "Production TTS Key" }
          expect(prod_key["key_id"]).to eq("key_prod_123")
          expect(prod_key["service_account_user_id"]).to eq(service_account_user_id)
          expect(prod_key["hint"]).to eq("****abcd")
          expect(prod_key["is_disabled"]).to be false
          expect(prod_key["permissions"]).to eq(["text_to_speech", "voices"])
          expect(prod_key["character_limit"]).to eq(1000000)
          expect(prod_key["character_count"]).to eq(125000)
          
          # Development key verification
          dev_key = result["api-keys"].find { |k| k["name"] == "Development Key" }
          expect(dev_key["key_id"]).to eq("key_dev_456")
          expect(dev_key["permissions"]).to eq(["text_to_speech"])
          expect(dev_key["character_limit"]).to eq(100000)
          expect(dev_key["character_count"]).to eq(85000)
          
          # Legacy admin key verification
          admin_key = result["api-keys"].find { |k| k["name"] == "Legacy Admin Key" }
          expect(admin_key["is_disabled"]).to be true
          expect(admin_key["permissions"]).to eq("all")
          expect(admin_key["character_limit"]).to be_nil
          expect(admin_key["character_count"]).to eq(2500000)
        end

        it "provides comprehensive API key information" do
          result = client.service_account_api_keys.list(service_account_user_id)

          result["api-keys"].each do |api_key|
            # Verify required fields
            expect(api_key["name"]).to be_a(String)
            expect(api_key["key_id"]).to be_a(String)
            expect(api_key["hint"]).to be_a(String)
            expect(api_key["service_account_user_id"]).to eq(service_account_user_id)
            expect(api_key["created_at_unix"]).to be_a(Integer)
            expect(api_key["character_count"]).to be_a(Integer)
            
            # Verify boolean fields
            expect([true, false]).to include(api_key["is_disabled"])
            
            # Verify permissions (can be array or string)
            expect(api_key["permissions"]).to be_a(Array).or(be_a(String))
            
            # Character limit can be integer or null
            expect(api_key["character_limit"]).to be_a(Integer).or(be_nil)
          end
        end

        it "enables usage analysis" do
          result = client.service_account_api_keys.list(service_account_user_id)

          api_keys = result["api-keys"]
          
          # Calculate usage statistics
          total_usage = api_keys.sum { |k| k["character_count"] }
          limited_keys = api_keys.select { |k| k["character_limit"] }
          unlimited_keys = api_keys.select { |k| k["character_limit"].nil? }
          
          expect(total_usage).to eq(2710000) # Sum of all character counts
          expect(limited_keys.size).to eq(2)
          expect(unlimited_keys.size).to eq(1)
          
          # Usage percentage calculations
          limited_keys.each do |key|
            usage_percent = (key["character_count"].to_f / key["character_limit"] * 100).round(1)
            
            case key["name"]
            when "Production TTS Key"
              expect(usage_percent).to eq(12.5) # 125k / 1M
            when "Development Key"
              expect(usage_percent).to eq(85.0) # 85k / 100k
            end
          end
        end
      end

      context "empty API keys list" do
        let(:empty_response) do
          { "api-keys": [] }
        end

        before do
          stub_request(:get, endpoint)
            .with(headers: { "xi-api-key" => "test-api-key" })
            .to_return(
              status: 200,
              body: empty_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "handles empty API keys list gracefully" do
          result = client.service_account_api_keys.list(service_account_user_id)

          expect(result["api-keys"]).to be_empty
        end
      end

      context "error scenarios" do
        context "when service account not found" do
          before do
            stub_request(:get, endpoint)
              .with(headers: { "xi-api-key" => "test-api-key" })
              .to_return(
                status: 404,
                body: { detail: "Service account not found" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "raises NotFoundError" do
            expect {
              client.service_account_api_keys.list(service_account_user_id)
            }.to raise_error(ElevenlabsClient::NotFoundError)
          end
        end

        context "when authentication fails" do
          before do
            stub_request(:get, endpoint)
              .with(headers: { "xi-api-key" => "test-api-key" })
              .to_return(
                status: 401,
                body: { detail: "Invalid API key" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "raises AuthenticationError" do
            expect {
              client.service_account_api_keys.list(service_account_user_id)
            }.to raise_error(ElevenlabsClient::AuthenticationError)
          end
        end

        context "when access is forbidden" do
          before do
            stub_request(:get, endpoint)
              .with(headers: { "xi-api-key" => "test-api-key" })
              .to_return(
                status: 403,
                body: { detail: "Access denied to service account" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "raises ForbiddenError" do
            expect {
              client.service_account_api_keys.list(service_account_user_id)
            }.to raise_error(ElevenlabsClient::ForbiddenError)
          end
        end
      end
    end

    describe "POST /v1/service-accounts/{service_account_user_id}/api-keys" do
      let(:endpoint) { "#{base_url}/v1/service-accounts/#{service_account_user_id}/api-keys" }

      context "successful API key creation" do
        let(:create_request) do
          {
            name: "Integration Test Key",
            permissions: ["text_to_speech", "voices"],
            character_limit: 50000
          }
        end

        let(:create_response) do
          {
            "xi-api-key": "sk_1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
          }
        end

        before do
          stub_request(:post, endpoint)
            .with(
              body: create_request.to_json,
              headers: {
                "xi-api-key" => "test-api-key",
                "Content-Type" => "application/json"
              }
            )
            .to_return(
              status: 200,
              body: create_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "creates API key successfully" do
          result = client.service_account_api_keys.create(
            service_account_user_id,
            name: "Integration Test Key",
            permissions: ["text_to_speech", "voices"],
            character_limit: 50000
          )

          expect(result["xi-api-key"]).to start_with("sk_")
          expect(result["xi-api-key"].length).to eq(67)
        end

        it "sends correct request format" do
          client.service_account_api_keys.create(
            service_account_user_id,
            name: "Integration Test Key",
            permissions: ["text_to_speech", "voices"],
            character_limit: 50000
          )

          expect(WebMock).to have_requested(:post, endpoint)
            .with(
              body: create_request.to_json,
              headers: {
                "xi-api-key" => "test-api-key",
                "Content-Type" => "application/json"
              }
            )
        end
      end

      context "with all permissions" do
        let(:all_permissions_request) do
          {
            name: "Admin Key",
            permissions: "all"
          }
        end

        let(:admin_key_response) do
          {
            "xi-api-key": "sk_admin1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
          }
        end

        before do
          stub_request(:post, endpoint)
            .with(
              body: all_permissions_request.to_json,
              headers: {
                "xi-api-key" => "test-api-key",
                "Content-Type" => "application/json"
              }
            )
            .to_return(
              status: 200,
              body: admin_key_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "creates API key with all permissions" do
          result = client.service_account_api_keys.create(
            service_account_user_id,
            name: "Admin Key",
            permissions: "all"
          )

          expect(result["xi-api-key"]).to start_with("sk_admin")
        end
      end

      context "creation error scenarios" do
        context "when validation fails" do
          before do
            stub_request(:post, endpoint)
              .to_return(
                status: 422,
                body: { detail: "Invalid permissions specified" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "raises ValidationError" do
            expect {
              client.service_account_api_keys.create(
                service_account_user_id,
                name: "Invalid Key",
                permissions: ["invalid_permission"]
              )
            }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
          end
        end

        context "when limit exceeded" do
          before do
            stub_request(:post, endpoint)
              .to_return(
                status: 429,
                body: { detail: "API key limit exceeded" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "raises RateLimitError" do
            expect {
              client.service_account_api_keys.create(
                service_account_user_id,
                name: "Excess Key",
                permissions: ["text_to_speech"]
              )
            }.to raise_error(ElevenlabsClient::RateLimitError)
          end
        end
      end
    end

    describe "PATCH /v1/service-accounts/{service_account_user_id}/api-keys/{api_key_id}" do
      let(:api_key_id) { "key_update_123" }
      let(:endpoint) { "#{base_url}/v1/service-accounts/#{service_account_user_id}/api-keys/#{api_key_id}" }

      context "successful API key update" do
        let(:update_request) do
          {
            is_enabled: true,
            name: "Updated Integration Key",
            permissions: ["text_to_speech", "voices", "models"],
            character_limit: 75000
          }
        end

        let(:update_response) { {} }

        before do
          stub_request(:patch, endpoint)
            .with(
              body: update_request.to_json,
              headers: {
                "xi-api-key" => "test-api-key",
                "Content-Type" => "application/json"
              }
            )
            .to_return(
              status: 200,
              body: update_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "updates API key successfully" do
          result = client.service_account_api_keys.update(
            service_account_user_id,
            api_key_id,
            is_enabled: true,
            name: "Updated Integration Key",
            permissions: ["text_to_speech", "voices", "models"],
            character_limit: 75000
          )

          expect(result).to eq({})
        end

        it "sends correct update request" do
          client.service_account_api_keys.update(
            service_account_user_id,
            api_key_id,
            is_enabled: true,
            name: "Updated Integration Key",
            permissions: ["text_to_speech", "voices", "models"],
            character_limit: 75000
          )

          expect(WebMock).to have_requested(:patch, endpoint)
            .with(
              body: update_request.to_json,
              headers: {
                "xi-api-key" => "test-api-key",
                "Content-Type" => "application/json"
              }
            )
        end
      end

      context "disabling API key" do
        let(:disable_request) do
          {
            is_enabled: false,
            name: "Disabled Test Key",
            permissions: ["text_to_speech"]
          }
        end

        before do
          stub_request(:patch, endpoint)
            .with(
              body: disable_request.to_json,
              headers: {
                "xi-api-key" => "test-api-key",
                "Content-Type" => "application/json"
              }
            )
            .to_return(
              status: 200,
              body: {}.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "disables API key successfully" do
          result = client.service_account_api_keys.update(
            service_account_user_id,
            api_key_id,
            is_enabled: false,
            name: "Disabled Test Key",
            permissions: ["text_to_speech"]
          )

          expect(result).to eq({})
        end
      end

      context "update error scenarios" do
        context "when API key not found" do
          before do
            stub_request(:patch, endpoint)
              .to_return(
                status: 404,
                body: { detail: "API key not found" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "raises NotFoundError" do
            expect {
              client.service_account_api_keys.update(
                service_account_user_id,
                api_key_id,
                is_enabled: true,
                name: "Non-existent Key",
                permissions: ["text_to_speech"]
              )
            }.to raise_error(ElevenlabsClient::NotFoundError)
          end
        end
      end
    end

    describe "DELETE /v1/service-accounts/{service_account_user_id}/api-keys/{api_key_id}" do
      let(:api_key_id) { "key_delete_123" }
      let(:endpoint) { "#{base_url}/v1/service-accounts/#{service_account_user_id}/api-keys/#{api_key_id}" }

      context "successful API key deletion" do
        before do
          stub_request(:delete, endpoint)
            .with(headers: { "xi-api-key" => "test-api-key" })
            .to_return(
              status: 200,
              body: {}.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "deletes API key successfully" do
          result = client.service_account_api_keys.delete(service_account_user_id, api_key_id)

          expect(result).to eq({})
        end

        it "sends correct delete request" do
          client.service_account_api_keys.delete(service_account_user_id, api_key_id)

          expect(WebMock).to have_requested(:delete, endpoint)
            .with(headers: { "xi-api-key" => "test-api-key" })
        end
      end

      context "deletion error scenarios" do
        context "when API key not found" do
          before do
            stub_request(:delete, endpoint)
              .to_return(
                status: 404,
                body: { detail: "API key not found" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "raises NotFoundError" do
            expect {
              client.service_account_api_keys.delete(service_account_user_id, api_key_id)
            }.to raise_error(ElevenlabsClient::NotFoundError)
          end
        end

        context "when access is forbidden" do
          before do
            stub_request(:delete, endpoint)
              .to_return(
                status: 403,
                body: { detail: "Cannot delete this API key" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "raises ForbiddenError" do
            expect {
              client.service_account_api_keys.delete(service_account_user_id, api_key_id)
            }.to raise_error(ElevenlabsClient::ForbiddenError)
          end
        end
      end
    end
  end

  describe "Complete API Key Management Workflow" do
    let(:list_endpoint) { "#{base_url}/v1/service-accounts/#{service_account_user_id}/api-keys" }
    let(:create_endpoint) { "#{base_url}/v1/service-accounts/#{service_account_user_id}/api-keys" }
    let(:created_key_id) { "key_workflow_123" }
    let(:update_endpoint) { "#{base_url}/v1/service-accounts/#{service_account_user_id}/api-keys/#{created_key_id}" }
    let(:delete_endpoint) { "#{base_url}/v1/service-accounts/#{service_account_user_id}/api-keys/#{created_key_id}" }

    context "end-to-end API key lifecycle" do
      let(:initial_list_response) do
        { "api-keys": [] }
      end

      let(:create_response) do
        { "xi-api-key": "sk_workflow1234567890abcdef1234567890abcdef1234567890abcdef1234" }
      end

      let(:updated_list_response) do
        {
          "api-keys": [
            {
              name: "Workflow Test Key",
              hint: "****1234",
              key_id: created_key_id,
              service_account_user_id: service_account_user_id,
              created_at_unix: 1640995200,
              is_disabled: false,
              permissions: ["text_to_speech"],
              character_limit: 10000,
              character_count: 0
            }
          ]
        }
      end

      let(:final_list_response) do
        {
          "api-keys": [
            {
              name: "Workflow Test Key (Updated)",
              hint: "****1234",
              key_id: created_key_id,
              service_account_user_id: service_account_user_id,
              created_at_unix: 1640995200,
              is_disabled: false,
              permissions: ["text_to_speech", "voices"],
              character_limit: 25000,
              character_count: 0
            }
          ]
        }
      end

      before do
        # Step 1: Initial list (empty)
        stub_request(:get, list_endpoint)
          .to_return(
            status: 200,
            body: initial_list_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
          .then
          .to_return(
            status: 200,
            body: updated_list_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
          .then
          .to_return(
            status: 200,
            body: final_list_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
          .then
          .to_return(
            status: 200,
            body: initial_list_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Step 2: Create API key
        stub_request(:post, create_endpoint)
          .with(
            body: {
              name: "Workflow Test Key",
              permissions: ["text_to_speech"],
              character_limit: 10000
            }.to_json
          )
          .to_return(
            status: 200,
            body: create_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Step 3: Update API key
        stub_request(:patch, update_endpoint)
          .with(
            body: {
              is_enabled: true,
              name: "Workflow Test Key (Updated)",
              permissions: ["text_to_speech", "voices"],
              character_limit: 25000
            }.to_json
          )
          .to_return(
            status: 200,
            body: {}.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Step 4: Delete API key
        stub_request(:delete, delete_endpoint)
          .to_return(
            status: 200,
            body: {}.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "completes full API key lifecycle workflow" do
        # Step 1: Initial state - no API keys
        initial_keys = client.service_account_api_keys.list(service_account_user_id)
        expect(initial_keys["api-keys"]).to be_empty

        # Step 2: Create new API key
        create_result = client.service_account_api_keys.create(
          service_account_user_id,
          name: "Workflow Test Key",
          permissions: ["text_to_speech"],
          character_limit: 10000
        )
        expect(create_result["xi-api-key"]).to start_with("sk_workflow")

        # Step 3: Verify key was created
        after_create_keys = client.service_account_api_keys.list(service_account_user_id)
        expect(after_create_keys["api-keys"].size).to eq(1)
        
        created_key = after_create_keys["api-keys"].first
        expect(created_key["name"]).to eq("Workflow Test Key")
        expect(created_key["permissions"]).to eq(["text_to_speech"])
        expect(created_key["character_limit"]).to eq(10000)
        expect(created_key["is_disabled"]).to be false

        # Step 4: Update the API key
        client.service_account_api_keys.update(
          service_account_user_id,
          created_key_id,
          is_enabled: true,
          name: "Workflow Test Key (Updated)",
          permissions: ["text_to_speech", "voices"],
          character_limit: 25000
        )

        # Step 5: Verify update
        after_update_keys = client.service_account_api_keys.list(service_account_user_id)
        updated_key = after_update_keys["api-keys"].first
        expect(updated_key["name"]).to eq("Workflow Test Key (Updated)")
        expect(updated_key["permissions"]).to eq(["text_to_speech", "voices"])
        expect(updated_key["character_limit"]).to eq(25000)

        # Step 6: Delete the API key
        client.service_account_api_keys.delete(service_account_user_id, created_key_id)

        # Step 7: Verify deletion
        final_keys = client.service_account_api_keys.list(service_account_user_id)
        expect(final_keys["api-keys"]).to be_empty

        # Verify all requests were made
        expect(WebMock).to have_requested(:get, list_endpoint).times(4)
        expect(WebMock).to have_requested(:post, create_endpoint).once
        expect(WebMock).to have_requested(:patch, update_endpoint).once
        expect(WebMock).to have_requested(:delete, delete_endpoint).once
      end
    end
  end

  describe "Error Handling and Recovery" do
    let(:endpoint) { "#{base_url}/v1/service-accounts/#{service_account_user_id}/api-keys" }

    context "network timeout scenarios" do
      before do
        stub_request(:get, endpoint)
          .to_timeout
      end

      it "handles network timeouts appropriately" do
        expect {
          client.service_account_api_keys.list(service_account_user_id)
        }.to raise_error(Faraday::ConnectionFailed)
      end
    end

    context "rate limiting scenarios" do
      before do
        stub_request(:post, endpoint)
          .to_return(
            status: 429,
            body: { detail: "Rate limit exceeded" }.to_json,
            headers: { 
              "Content-Type" => "application/json",
              "Retry-After" => "60"
            }
          )
      end

      it "handles rate limiting with proper error" do
        expect {
          client.service_account_api_keys.create(
            service_account_user_id,
            name: "Rate Limited Key",
            permissions: ["text_to_speech"]
          )
        }.to raise_error(ElevenlabsClient::RateLimitError)
      end
    end

    context "payment required scenarios" do
      before do
        stub_request(:post, endpoint)
          .to_return(
            status: 402,
            body: { detail: "Payment required to create API keys" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "handles payment required errors" do
        expect {
          client.service_account_api_keys.create(
            service_account_user_id,
            name: "Payment Required Key",
            permissions: ["text_to_speech"]
          )
        }.to raise_error(ElevenlabsClient::PaymentRequiredError)
      end
    end

    context "malformed response scenarios" do
      before do
        stub_request(:get, endpoint)
          .to_return(
            status: 200,
            body: "Invalid JSON response",
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "handles malformed JSON responses" do
        expect {
          client.service_account_api_keys.list(service_account_user_id)
        }.to raise_error(Faraday::ParsingError)
      end
    end
  end
end
