# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Agents Platform Workspace Integration" do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test-api-key") }
  let(:base_url) { "https://api.elevenlabs.io" }

  describe "Workspace Settings Management" do
    describe "GET /v1/convai/settings" do
      context "successful settings retrieval" do
        before do
          stub_request(:get, "#{base_url}/v1/convai/settings")
            .to_return(
              status: 200,
              body: {
                conversation_initiation_client_data_webhook: {
                  url: "https://example.com/webhook",
                  request_headers: { "Authorization" => "Bearer token" }
                },
                webhooks: {
                  post_call_webhook_id: "webhook_123",
                  send_audio: false
                },
                can_use_mcp_servers: false,
                rag_retention_period_days: 10,
                default_livekit_stack: "standard"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "retrieves workspace settings successfully" do
          result = client.workspace.get_settings

          expect(result["can_use_mcp_servers"]).to be false
          expect(result["rag_retention_period_days"]).to eq(10)
          expect(result["default_livekit_stack"]).to eq("standard")
          expect(result["conversation_initiation_client_data_webhook"]["url"]).to eq("https://example.com/webhook")
          expect(result["webhooks"]["post_call_webhook_id"]).to eq("webhook_123")
        end

        it "provides workspace configuration insights" do
          result = client.workspace.get_settings

          # Analyze current configuration
          has_webhook = !result["conversation_initiation_client_data_webhook"].nil?
          has_post_call = !result["webhooks"]["post_call_webhook_id"].nil?
          mcp_enabled = result["can_use_mcp_servers"]
          retention_days = result["rag_retention_period_days"]

          expect(has_webhook).to be true
          expect(has_post_call).to be true
          expect(mcp_enabled).to be false
          expect(retention_days).to be <= 30
        end
      end

      context "error scenarios" do
        context "when authentication fails" do
          before do
            stub_request(:get, "#{base_url}/v1/convai/settings")
              .to_return(status: 401, body: { detail: "Authentication failed" }.to_json)
          end

          it "raises AuthenticationError" do
            expect {
              client.workspace.get_settings
            }.to raise_error(ElevenlabsClient::AuthenticationError)
          end
        end

        context "when access is forbidden" do
          before do
            stub_request(:get, "#{base_url}/v1/convai/settings")
              .to_return(status: 403, body: { detail: "Access forbidden" }.to_json)
          end

          it "raises ForbiddenError" do
            expect {
              client.workspace.get_settings
            }.to raise_error(ElevenlabsClient::ForbiddenError)
          end
        end
      end
    end

    describe "PATCH /v1/convai/settings" do
      context "successful settings update" do
        before do
          stub_request(:patch, "#{base_url}/v1/convai/settings")
            .with(
              body: {
                can_use_mcp_servers: true,
                rag_retention_period_days: 15,
                default_livekit_stack: "static"
              }.to_json
            )
            .to_return(
              status: 200,
              body: {
                can_use_mcp_servers: true,
                rag_retention_period_days: 15,
                default_livekit_stack: "static"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "updates workspace settings successfully" do
          result = client.workspace.update_settings(
            can_use_mcp_servers: true,
            rag_retention_period_days: 15,
            default_livekit_stack: "static"
          )

          expect(result["can_use_mcp_servers"]).to be true
          expect(result["rag_retention_period_days"]).to eq(15)
          expect(result["default_livekit_stack"]).to eq("static")
        end

        it "sends correct request format" do
          client.workspace.update_settings(
            can_use_mcp_servers: true,
            rag_retention_period_days: 15,
            default_livekit_stack: "static"
          )

          expect(WebMock).to have_requested(:patch, "#{base_url}/v1/convai/settings")
            .with(headers: { "xi-api-key" => "test-api-key" })
        end
      end

      context "webhook configuration" do
        before do
          stub_request(:patch, "#{base_url}/v1/convai/settings")
            .with(
              body: {
                conversation_initiation_client_data_webhook: {
                  url: "https://myapp.com/webhook",
                  request_headers: { "Authorization" => "Bearer my-token" }
                },
                webhooks: {
                  post_call_webhook_id: "webhook_456",
                  send_audio: true
                }
              }.to_json
            )
            .to_return(
              status: 200,
              body: {
                conversation_initiation_client_data_webhook: {
                  url: "https://myapp.com/webhook",
                  request_headers: { "Authorization" => "Bearer my-token" }
                },
                webhooks: {
                  post_call_webhook_id: "webhook_456",
                  send_audio: true
                }
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "configures webhooks successfully" do
          result = client.workspace.update_settings(
            conversation_initiation_client_data_webhook: {
              url: "https://myapp.com/webhook",
              request_headers: { "Authorization" => "Bearer my-token" }
            },
            webhooks: {
              post_call_webhook_id: "webhook_456",
              send_audio: true
            }
          )

          webhook_config = result["conversation_initiation_client_data_webhook"]
          expect(webhook_config["url"]).to eq("https://myapp.com/webhook")
          expect(webhook_config["request_headers"]["Authorization"]).to eq("Bearer my-token")

          post_call_config = result["webhooks"]
          expect(post_call_config["post_call_webhook_id"]).to eq("webhook_456")
          expect(post_call_config["send_audio"]).to be true
        end
      end

      context "validation error scenarios" do
        context "when retention period exceeds maximum" do
          before do
            stub_request(:patch, "#{base_url}/v1/convai/settings")
              .to_return(status: 422, body: { detail: "rag_retention_period_days must be <= 30" }.to_json)
          end

          it "raises UnprocessableEntityError" do
            expect {
              client.workspace.update_settings(rag_retention_period_days: 35)
            }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
          end
        end

        context "when invalid livekit stack" do
          before do
            stub_request(:patch, "#{base_url}/v1/convai/settings")
              .to_return(status: 422, body: { detail: "Invalid livekit stack" }.to_json)
          end

          it "raises UnprocessableEntityError" do
            expect {
              client.workspace.update_settings(default_livekit_stack: "invalid")
            }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
          end
        end
      end
    end
  end

  describe "Secrets Management" do
    describe "GET /v1/convai/secrets" do
      context "successful secrets listing" do
        before do
          stub_request(:get, "#{base_url}/v1/convai/secrets")
            .to_return(
              status: 200,
              body: {
                secrets: [
                  {
                    type: "stored",
                    secret_id: "secret_123",
                    name: "api_key",
                    used_by: {
                      tools: [{ type: "function_calling" }],
                      agents: [{ type: "conversational" }],
                      others: [],
                      phone_numbers: []
                    }
                  },
                  {
                    type: "stored",
                    secret_id: "secret_456",
                    name: "webhook_token",
                    used_by: {
                      tools: [],
                      agents: [],
                      others: ["conversation_initiation_webhook"],
                      phone_numbers: []
                    }
                  }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "retrieves workspace secrets successfully" do
          result = client.workspace.get_secrets

          expect(result["secrets"].size).to eq(2)
          
          api_key_secret = result["secrets"].find { |s| s["name"] == "api_key" }
          expect(api_key_secret["secret_id"]).to eq("secret_123")
          expect(api_key_secret["used_by"]["tools"].size).to eq(1)
          expect(api_key_secret["used_by"]["agents"].size).to eq(1)

          webhook_secret = result["secrets"].find { |s| s["name"] == "webhook_token" }
          expect(webhook_secret["secret_id"]).to eq("secret_456")
          expect(webhook_secret["used_by"]["others"]).to include("conversation_initiation_webhook")
        end

        it "enables usage analysis" do
          result = client.workspace.get_secrets

          result["secrets"].each do |secret|
            usage = secret["used_by"]
            total_usage = usage["tools"].length + usage["agents"].length + 
                         usage["phone_numbers"].length + usage["others"].length
            
            can_delete = total_usage == 0
            expect([true, false]).to include(can_delete)
          end
        end
      end

      context "empty secrets list" do
        before do
          stub_request(:get, "#{base_url}/v1/convai/secrets")
            .to_return(
              status: 200,
              body: { secrets: [] }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "handles empty secrets list gracefully" do
          result = client.workspace.get_secrets

          expect(result["secrets"]).to be_empty
        end
      end
    end

    describe "POST /v1/convai/secrets" do
      context "successful secret creation" do
        before do
          stub_request(:post, "#{base_url}/v1/convai/secrets")
            .with(
              body: {
                type: "new",
                name: "test_api_key",
                value: "sk-1234567890abcdef"
              }.to_json
            )
            .to_return(
              status: 200,
              body: {
                type: "stored",
                secret_id: "secret_789",
                name: "test_api_key"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "creates secret successfully" do
          result = client.workspace.create_secret(
            name: "test_api_key",
            value: "sk-1234567890abcdef"
          )

          expect(result["type"]).to eq("stored")
          expect(result["secret_id"]).to eq("secret_789")
          expect(result["name"]).to eq("test_api_key")
        end

        it "sends correct request format" do
          client.workspace.create_secret(
            name: "test_api_key",
            value: "sk-1234567890abcdef"
          )

          expect(WebMock).to have_requested(:post, "#{base_url}/v1/convai/secrets")
            .with(headers: { "xi-api-key" => "test-api-key" })
        end
      end

      context "creation error scenarios" do
        context "when validation fails" do
          before do
            stub_request(:post, "#{base_url}/v1/convai/secrets")
              .to_return(status: 422, body: { detail: "Invalid secret parameters" }.to_json)
          end

          it "raises UnprocessableEntityError" do
            expect {
              client.workspace.create_secret(name: "valid_name", value: "test")
            }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
          end
        end
      end
    end

    describe "PATCH /v1/convai/secrets/:secret_id" do
      let(:secret_id) { "secret_123" }

      context "successful secret update" do
        before do
          stub_request(:patch, "#{base_url}/v1/convai/secrets/#{secret_id}")
            .with(
              body: {
                type: "update",
                name: "updated_api_key",
                value: "sk-newvalue1234567890"
              }.to_json
            )
            .to_return(
              status: 200,
              body: {
                type: "stored",
                secret_id: secret_id,
                name: "updated_api_key"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "updates secret successfully" do
          result = client.workspace.update_secret(
            secret_id,
            name: "updated_api_key",
            value: "sk-newvalue1234567890"
          )

          expect(result["type"]).to eq("stored")
          expect(result["secret_id"]).to eq(secret_id)
          expect(result["name"]).to eq("updated_api_key")
        end

        it "sends correct update request" do
          client.workspace.update_secret(
            secret_id,
            name: "updated_api_key",
            value: "sk-newvalue1234567890"
          )

          expect(WebMock).to have_requested(:patch, "#{base_url}/v1/convai/secrets/#{secret_id}")
            .with(headers: { "xi-api-key" => "test-api-key" })
        end
      end

      context "update error scenarios" do
        context "when secret not found" do
          before do
            stub_request(:patch, "#{base_url}/v1/convai/secrets/nonexistent")
              .to_return(status: 404, body: { detail: "Secret not found" }.to_json)
          end

          it "raises NotFoundError" do
            expect {
              client.workspace.update_secret("nonexistent", name: "test", value: "test")
            }.to raise_error(ElevenlabsClient::NotFoundError)
          end
        end
      end
    end

    describe "DELETE /v1/convai/secrets/:secret_id" do
      let(:secret_id) { "secret_123" }

      context "successful secret deletion" do
        before do
          stub_request(:delete, "#{base_url}/v1/convai/secrets/#{secret_id}")
            .to_return(status: 204, body: "{}")
        end

        it "deletes secret successfully" do
          result = client.workspace.delete_secret(secret_id)

          expect(result).to eq("")
        end

        it "sends correct delete request" do
          client.workspace.delete_secret(secret_id)

          expect(WebMock).to have_requested(:delete, "#{base_url}/v1/convai/secrets/#{secret_id}")
            .with(headers: { "xi-api-key" => "test-api-key" })
        end
      end

      context "deletion error scenarios" do
        context "when secret is in use" do
          before do
            stub_request(:delete, "#{base_url}/v1/convai/secrets/#{secret_id}")
              .to_return(status: 422, body: { detail: "Secret is currently in use" }.to_json)
          end

          it "raises UnprocessableEntityError" do
            expect {
              client.workspace.delete_secret(secret_id)
            }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
          end
        end

        context "when secret not found" do
          before do
            stub_request(:delete, "#{base_url}/v1/convai/secrets/nonexistent")
              .to_return(status: 404, body: { detail: "Secret not found" }.to_json)
          end

          it "raises NotFoundError" do
            expect {
              client.workspace.delete_secret("nonexistent")
            }.to raise_error(ElevenlabsClient::NotFoundError)
          end
        end
      end
    end
  end

  describe "Dashboard Management" do
    describe "GET /v1/convai/settings/dashboard" do
      context "successful dashboard settings retrieval" do
        before do
          stub_request(:get, "#{base_url}/v1/convai/settings/dashboard")
            .to_return(
              status: 200,
              body: {
                charts: [
                  { name: "Call Success Rate", type: "call_success" },
                  { name: "Daily Volume", type: "daily_volume" },
                  { name: "Cost Analysis", type: "cost_analysis" }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "retrieves dashboard settings successfully" do
          result = client.workspace.get_dashboard_settings

          expect(result["charts"].size).to eq(3)
          expect(result["charts"].first["name"]).to eq("Call Success Rate")
          expect(result["charts"].first["type"]).to eq("call_success")
        end

        it "provides dashboard configuration insights" do
          result = client.workspace.get_dashboard_settings

          chart_types = result["charts"].map { |chart| chart["type"] }
          expect(chart_types).to include("call_success", "daily_volume", "cost_analysis")
        end
      end
    end

    describe "PATCH /v1/convai/settings/dashboard" do
      context "successful dashboard update" do
        let(:charts) do
          [
            { name: "Success Rate", type: "call_success" },
            { name: "Duration", type: "conversation_duration" }
          ]
        end

        before do
          stub_request(:patch, "#{base_url}/v1/convai/settings/dashboard")
            .with(body: { charts: charts }.to_json)
            .to_return(
              status: 200,
              body: { charts: charts }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "updates dashboard settings successfully" do
          result = client.workspace.update_dashboard_settings(charts: charts)

          expect(result["charts"].size).to eq(2)
          expect(result["charts"].first["name"]).to eq("Success Rate")
          expect(result["charts"].first["type"]).to eq("call_success")
        end

        it "sends correct update request" do
          client.workspace.update_dashboard_settings(charts: charts)

          expect(WebMock).to have_requested(:patch, "#{base_url}/v1/convai/settings/dashboard")
            .with(headers: { "xi-api-key" => "test-api-key" })
        end
      end

      context "clear dashboard configuration" do
        before do
          stub_request(:patch, "#{base_url}/v1/convai/settings/dashboard")
            .with(body: {}.to_json)
            .to_return(
              status: 200,
              body: { charts: [] }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "clears dashboard configuration" do
          result = client.workspace.update_dashboard_settings

          expect(result["charts"]).to be_empty
        end
      end
    end
  end

  describe "Complete Workspace Management Workflow" do
    context "workspace configuration and secret management" do
      before do
        # Get initial settings
        stub_request(:get, "#{base_url}/v1/convai/settings")
          .to_return(
            status: 200,
            body: {
              "can_use_mcp_servers" => false,
              "rag_retention_period_days" => 10,
              "default_livekit_stack" => "standard"
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Create secret
        stub_request(:post, "#{base_url}/v1/convai/secrets")
          .to_return(
            status: 200,
            body: {
              "type" => "stored",
              "secret_id" => "secret_new",
              "name" => "workflow_secret"
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Update settings
        stub_request(:patch, "#{base_url}/v1/convai/settings")
          .to_return(
            status: 200,
            body: {
              "can_use_mcp_servers" => true,
              "rag_retention_period_days" => 20,
              "default_livekit_stack" => "static"
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Update dashboard
        stub_request(:patch, "#{base_url}/v1/convai/settings/dashboard")
          .to_return(
            status: 200,
            body: {
              "charts" => [{ "name" => "Complete Setup", "type" => "call_success" }]
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "completes full workspace configuration workflow" do
        # 1. Get current settings
        current_settings = client.workspace.get_settings
        expect(current_settings["can_use_mcp_servers"]).to be false

        # 2. Create a secret
        secret = client.workspace.create_secret(
          name: "workflow_secret",
          value: "secret_value_123"
        )
        expect(secret["secret_id"]).to eq("secret_new")

        # 3. Update workspace settings
        updated_settings = client.workspace.update_settings(
          can_use_mcp_servers: true,
          rag_retention_period_days: 20,
          default_livekit_stack: "static"
        )
        expect(updated_settings["can_use_mcp_servers"]).to be true

        # 4. Configure dashboard
        dashboard = client.workspace.update_dashboard_settings(
          charts: [{ name: "Complete Setup", type: "call_success" }]
        )
        expect(dashboard["charts"].size).to eq(1)
      end
    end
  end

  describe "Error Handling and Recovery" do
    context "network timeout scenarios" do
      before do
        stub_request(:get, "#{base_url}/v1/convai/settings")
          .to_timeout
      end

      it "handles network timeouts appropriately" do
        expect {
          client.workspace.get_settings
        }.to raise_error(Faraday::ConnectionFailed)
      end
    end

    context "rate limiting scenarios" do
      before do
        stub_request(:patch, "#{base_url}/v1/convai/settings")
          .to_return(status: 429, body: { detail: "Rate limit exceeded" }.to_json)
      end

      it "handles rate limiting with proper error" do
        expect {
          client.workspace.update_settings(can_use_mcp_servers: true)
        }.to raise_error(ElevenlabsClient::RateLimitError)
      end
    end

    context "malformed response scenarios" do
      before do
        stub_request(:get, "#{base_url}/v1/convai/secrets")
          .to_return(
            status: 200,
            body: "Invalid JSON response",
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "handles malformed JSON responses" do
        expect {
          client.workspace.get_secrets
        }.to raise_error(Faraday::ParsingError)
      end
    end
  end
end
