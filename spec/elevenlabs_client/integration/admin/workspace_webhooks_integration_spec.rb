# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe "Workspace Webhooks Integration" do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test-api-key") }
  let(:base_url) { "https://api.elevenlabs.io" }

  describe "Workspace Webhooks Management" do
    describe "GET /v1/workspace/webhooks" do
      let(:endpoint) { "#{base_url}/v1/workspace/webhooks" }

      context "successful webhook listing" do
        let(:webhook_response) do
          {
            webhooks: [
              {
                name: "Production Webhook",
                webhook_id: "wh_prod_123",
                webhook_url: "https://api.mycompany.com/webhooks/elevenlabs",
                is_disabled: false,
                is_auto_disabled: false,
                created_at_unix: 1640995200,
                auth_type: "hmac",
                usage: [
                  { usage_type: "ConvAI Settings" },
                  { usage_type: "Voice Library" }
                ],
                most_recent_failure_error_code: nil,
                most_recent_failure_timestamp: nil
              },
              {
                name: "Development Webhook",
                webhook_id: "wh_dev_456",
                webhook_url: "https://dev.mycompany.com/webhooks/elevenlabs",
                is_disabled: false,
                is_auto_disabled: false,
                created_at_unix: 1640995300,
                auth_type: "hmac",
                usage: [
                  { usage_type: "ConvAI Settings" }
                ],
                most_recent_failure_error_code: 404,
                most_recent_failure_timestamp: 1640995400
              },
              {
                name: "Legacy Webhook",
                webhook_id: "wh_legacy_789",
                webhook_url: "http://old.mycompany.com/webhooks/elevenlabs",
                is_disabled: true,
                is_auto_disabled: true,
                created_at_unix: 1640990000,
                auth_type: "none",
                usage: [],
                most_recent_failure_error_code: 500,
                most_recent_failure_timestamp: 1640994000
              }
            ]
          }
        end

        before do
          stub_request(:get, endpoint)
            .with(headers: { "xi-api-key" => "test-api-key" })
            .to_return(
              status: 200,
              body: webhook_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "retrieves workspace webhooks successfully" do
          result = client.workspace_webhooks.list

          expect(result["webhooks"].size).to eq(3)
          
          # Production webhook verification
          prod_webhook = result["webhooks"].find { |w| w["name"] == "Production Webhook" }
          expect(prod_webhook["webhook_id"]).to eq("wh_prod_123")
          expect(prod_webhook["webhook_url"]).to eq("https://api.mycompany.com/webhooks/elevenlabs")
          expect(prod_webhook["is_disabled"]).to be false
          expect(prod_webhook["is_auto_disabled"]).to be false
          expect(prod_webhook["auth_type"]).to eq("hmac")
          expect(prod_webhook["usage"].size).to eq(2)
          expect(prod_webhook["most_recent_failure_error_code"]).to be_nil
          
          # Development webhook with failures
          dev_webhook = result["webhooks"].find { |w| w["name"] == "Development Webhook" }
          expect(dev_webhook["webhook_id"]).to eq("wh_dev_456")
          expect(dev_webhook["most_recent_failure_error_code"]).to eq(404)
          expect(dev_webhook["most_recent_failure_timestamp"]).to eq(1640995400)
          
          # Legacy webhook (disabled)
          legacy_webhook = result["webhooks"].find { |w| w["name"] == "Legacy Webhook" }
          expect(legacy_webhook["is_disabled"]).to be true
          expect(legacy_webhook["is_auto_disabled"]).to be true
          expect(legacy_webhook["auth_type"]).to eq("none")
          expect(legacy_webhook["webhook_url"]).to start_with("http://") # Insecure
        end

        it "provides comprehensive webhook information" do
          result = client.workspace_webhooks.list

          result["webhooks"].each do |webhook|
            # Verify required fields
            expect(webhook["name"]).to be_a(String)
            expect(webhook["webhook_id"]).to be_a(String)
            expect(webhook["webhook_url"]).to be_a(String)
            expect(webhook["created_at_unix"]).to be_a(Integer)
            expect(webhook["auth_type"]).to be_a(String)
            
            # Verify boolean fields
            expect([true, false]).to include(webhook["is_disabled"])
            expect([true, false]).to include(webhook["is_auto_disabled"])
            
            # Verify usage array
            expect(webhook["usage"]).to be_an(Array)
            if webhook["usage"].any?
              webhook["usage"].each do |usage|
                expect(usage["usage_type"]).to be_a(String)
              end
            end
          end
        end
      end

      context "with include_usages parameter (admin access)" do
        let(:endpoint_with_usage) { "#{endpoint}?include_usages=true" }

        let(:admin_response) do
          {
            webhooks: [
              {
                name: "Admin Webhook",
                webhook_id: "wh_admin_001",
                webhook_url: "https://admin.mycompany.com/webhooks",
                is_disabled: false,
                is_auto_disabled: false,
                created_at_unix: 1640995200,
                auth_type: "hmac",
                usage: [
                  { usage_type: "ConvAI Settings" },
                  { usage_type: "Voice Library" },
                  { usage_type: "Workspace Management" }
                ]
              }
            ]
          }
        end

        before do
          stub_request(:get, endpoint_with_usage)
            .with(headers: { "xi-api-key" => "test-api-key" })
            .to_return(
              status: 200,
              body: admin_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "includes usage information with admin access" do
          result = client.workspace_webhooks.list(include_usages: true)

          expect(result["webhooks"].size).to eq(1)
          
          webhook = result["webhooks"].first
          expect(webhook["name"]).to eq("Admin Webhook")
          expect(webhook["usage"].size).to eq(3)
          expect(webhook["usage"].map { |u| u["usage_type"] }).to include(
            "ConvAI Settings",
            "Voice Library", 
            "Workspace Management"
          )
        end

        it "sends correct request with usage parameter" do
          client.workspace_webhooks.list(include_usages: true)

          expect(WebMock).to have_requested(:get, endpoint_with_usage)
            .with(headers: { "xi-api-key" => "test-api-key" })
        end
      end

      context "access denied for usage information" do
        let(:endpoint_with_usage) { "#{endpoint}?include_usages=true" }

        before do
          stub_request(:get, endpoint_with_usage)
            .with(headers: { "xi-api-key" => "test-api-key" })
            .to_return(
              status: 403,
              body: { detail: "Admin access required for usage information" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "raises ForbiddenError for non-admin access to usage info" do
          expect {
            client.workspace_webhooks.list(include_usages: true)
          }.to raise_error(ElevenlabsClient::ForbiddenError)
        end
      end

      context "empty webhooks list" do
        let(:empty_response) do
          { webhooks: [] }
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

        it "handles empty webhook list gracefully" do
          result = client.workspace_webhooks.list

          expect(result["webhooks"]).to be_empty
        end
      end

      context "error scenarios" do
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
              client.workspace_webhooks.list
            }.to raise_error(ElevenlabsClient::AuthenticationError)
          end
        end

        context "when access is forbidden" do
          before do
            stub_request(:get, endpoint)
              .with(headers: { "xi-api-key" => "test-api-key" })
              .to_return(
                status: 403,
                body: { detail: "Access denied to workspace webhooks" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "raises ForbiddenError" do
            expect {
              client.workspace_webhooks.list
            }.to raise_error(ElevenlabsClient::ForbiddenError)
          end
        end

        context "when validation fails" do
          before do
            stub_request(:get, endpoint)
              .with(headers: { "xi-api-key" => "test-api-key" })
              .to_return(
                status: 422,
                body: { detail: "Invalid parameters" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "raises ValidationError" do
            expect {
              client.workspace_webhooks.list
            }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
          end
        end
      end
    end
  end

  describe "Webhook Health Monitoring Workflow" do
    let(:endpoint) { "#{base_url}/v1/workspace/webhooks" }

    context "comprehensive health monitoring" do
      let(:mixed_health_response) do
        {
          webhooks: [
            {
              name: "Healthy Production Webhook",
              webhook_id: "wh_healthy_001",
              webhook_url: "https://api.example.com/webhook",
              is_disabled: false,
              is_auto_disabled: false,
              created_at_unix: 1640995200,
              auth_type: "hmac",
              usage: [{ usage_type: "ConvAI Settings" }],
              most_recent_failure_error_code: nil,
              most_recent_failure_timestamp: nil
            },
            {
              name: "Webhook with Recent Failures",
              webhook_id: "wh_failing_002",
              webhook_url: "https://api.example.com/failing-webhook",
              is_disabled: false,
              is_auto_disabled: false,
              created_at_unix: 1640995200,
              auth_type: "hmac",
              usage: [{ usage_type: "ConvAI Settings" }],
              most_recent_failure_error_code: 500,
              most_recent_failure_timestamp: 1640999000
            },
            {
              name: "Auto-disabled Webhook",
              webhook_id: "wh_autodisabled_003",
              webhook_url: "https://api.example.com/broken-webhook",
              is_disabled: false,
              is_auto_disabled: true,
              created_at_unix: 1640995200,
              auth_type: "hmac",
              usage: [{ usage_type: "ConvAI Settings" }],
              most_recent_failure_error_code: 404,
              most_recent_failure_timestamp: 1640998000
            },
            {
              name: "Manually Disabled Webhook",
              webhook_id: "wh_disabled_004",
              webhook_url: "https://api.example.com/disabled-webhook",
              is_disabled: true,
              is_auto_disabled: false,
              created_at_unix: 1640995200,
              auth_type: "hmac",
              usage: [],
              most_recent_failure_error_code: nil,
              most_recent_failure_timestamp: nil
            },
            {
              name: "Insecure HTTP Webhook",
              webhook_id: "wh_insecure_005",
              webhook_url: "http://api.example.com/insecure",
              is_disabled: false,
              is_auto_disabled: false,
              created_at_unix: 1640990000,
              auth_type: "none",
              usage: [{ usage_type: "ConvAI Settings" }],
              most_recent_failure_error_code: nil,
              most_recent_failure_timestamp: nil
            }
          ]
        }
      end

      before do
        stub_request(:get, endpoint)
          .with(headers: { "xi-api-key" => "test-api-key" })
          .to_return(
            status: 200,
            body: mixed_health_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "provides comprehensive health assessment" do
        result = client.workspace_webhooks.list

        webhooks = result["webhooks"]
        expect(webhooks.size).to eq(5)

        # Health categorization
        healthy_webhooks = webhooks.select do |w|
          !w["is_disabled"] && !w["is_auto_disabled"] && 
          w["most_recent_failure_error_code"].nil? &&
          w["webhook_url"].start_with?("https://") &&
          w["auth_type"] != "none"
        end

        webhooks_with_failures = webhooks.select do |w|
          !w["is_disabled"] && !w["is_auto_disabled"] && 
          w["most_recent_failure_error_code"]
        end

        auto_disabled_webhooks = webhooks.select { |w| w["is_auto_disabled"] }
        manually_disabled_webhooks = webhooks.select { |w| w["is_disabled"] }
        insecure_webhooks = webhooks.select { |w| w["webhook_url"].start_with?("http://") }
        unauthenticated_webhooks = webhooks.select { |w| w["auth_type"] == "none" }

        # Verify health distribution
        expect(healthy_webhooks.size).to eq(1)
        expect(webhooks_with_failures.size).to eq(1)
        expect(auto_disabled_webhooks.size).to eq(1)
        expect(manually_disabled_webhooks.size).to eq(1)
        expect(insecure_webhooks.size).to eq(1)
        expect(unauthenticated_webhooks.size).to eq(1)

        # Verify specific webhook states
        healthy_webhook = healthy_webhooks.first
        expect(healthy_webhook["name"]).to eq("Healthy Production Webhook")
        expect(healthy_webhook["webhook_url"]).to start_with("https://")
        expect(healthy_webhook["auth_type"]).to eq("hmac")

        failing_webhook = webhooks_with_failures.first
        expect(failing_webhook["name"]).to eq("Webhook with Recent Failures")
        expect(failing_webhook["most_recent_failure_error_code"]).to eq(500)

        auto_disabled_webhook = auto_disabled_webhooks.first
        expect(auto_disabled_webhook["name"]).to eq("Auto-disabled Webhook")
        expect(auto_disabled_webhook["is_auto_disabled"]).to be true

        insecure_webhook = insecure_webhooks.first
        expect(insecure_webhook["name"]).to eq("Insecure HTTP Webhook")
        expect(insecure_webhook["webhook_url"]).to start_with("http://")
        expect(insecure_webhook["auth_type"]).to eq("none")
      end

      it "enables health metrics calculation" do
        result = client.workspace_webhooks.list

        webhooks = result["webhooks"]
        total_webhooks = webhooks.length

        # Calculate health metrics
        healthy_count = webhooks.count do |w|
          !w["is_disabled"] && !w["is_auto_disabled"] && 
          w["most_recent_failure_error_code"].nil?
        end

        health_percentage = (healthy_count.to_f / total_webhooks * 100).round(1)

        expect(total_webhooks).to eq(5)
        expect(healthy_count).to eq(2) # Healthy + Insecure (but working)
        expect(health_percentage).to eq(40.0)

        # Security metrics
        secure_webhooks = webhooks.count { |w| w["webhook_url"].start_with?("https://") }
        security_percentage = (secure_webhooks.to_f / total_webhooks * 100).round(1)

        expect(secure_webhooks).to eq(4)
        expect(security_percentage).to eq(80.0)

        # Authentication metrics
        authenticated_webhooks = webhooks.count { |w| w["auth_type"] != "none" }
        auth_percentage = (authenticated_webhooks.to_f / total_webhooks * 100).round(1)

        expect(authenticated_webhooks).to eq(4)
        expect(auth_percentage).to eq(80.0)
      end
    end
  end

  describe "Query Parameter Handling" do
    let(:endpoint) { "#{base_url}/v1/workspace/webhooks" }

    context "with multiple query parameters" do
      let(:endpoint_with_params) { "#{endpoint}?include_usages=true&custom_filter=active" }

      before do
        stub_request(:get, endpoint_with_params)
          .with(headers: { "xi-api-key" => "test-api-key" })
          .to_return(
            status: 200,
            body: { webhooks: [] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "handles multiple query parameters correctly" do
        client.workspace_webhooks.list(include_usages: true, custom_filter: "active")

        expect(WebMock).to have_requested(:get, endpoint_with_params)
          .with(headers: { "xi-api-key" => "test-api-key" })
      end
    end

    context "with special characters in parameters" do
      let(:special_value) { "value with spaces & symbols" }
      let(:encoded_value) { URI.encode_www_form_component(special_value) }
      
      before do
        stub_request(:get, /#{Regexp.escape(base_url)}\/v1\/workspace\/webhooks\?.*/)
          .to_return(
            status: 200,
            body: { webhooks: [] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "properly encodes special characters in query parameters" do
        client.workspace_webhooks.list(custom_param: special_value)

        expect(WebMock).to have_requested(:get, /custom_param=value%20with%20spaces%20%26%20symbols/)
      end
    end
  end

  describe "Error Recovery and Resilience" do
    let(:endpoint) { "#{base_url}/v1/workspace/webhooks" }

    context "transient network errors" do
      before do
        # First request fails, second succeeds
        stub_request(:get, endpoint)
          .to_return(status: 500)
          .then
          .to_return(
            status: 200,
            body: { webhooks: [] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "handles transient failures gracefully" do
        # First attempt should fail
        expect {
          client.workspace_webhooks.list
        }.to raise_error(ElevenlabsClient::APIError)

        # Second attempt should succeed
        result = client.workspace_webhooks.list
        expect(result["webhooks"]).to be_empty
      end
    end

    context "rate limiting scenarios" do
      before do
        stub_request(:get, endpoint)
          .to_return(
            status: 429,
            body: { detail: "Rate limit exceeded" }.to_json,
            headers: { 
              "Content-Type" => "application/json",
              "Retry-After" => "60"
            }
          )
      end

      it "handles rate limiting appropriately" do
        expect {
          client.workspace_webhooks.list
        }.to raise_error(ElevenlabsClient::RateLimitError)
      end
    end

    context "malformed response handling" do
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
          client.workspace_webhooks.list
        }.to raise_error(Faraday::ParsingError)
      end
    end

    context "service unavailable" do
      before do
        stub_request(:get, endpoint)
          .to_return(
            status: 503,
            body: { detail: "Service temporarily unavailable" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "handles service unavailability" do
        expect {
          client.workspace_webhooks.list
        }.to raise_error(ElevenlabsClient::ServiceUnavailableError)
      end
    end
  end
end
