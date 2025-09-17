# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe "Outbound Calling Integration" do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test-api-key") }
  let(:agent_id) { "agent_test_123" }
  let(:agent_phone_number_id) { "phone_test_456" }
  let(:to_number) { "+1234567890" }
  let(:base_url) { "https://api.elevenlabs.io" }

  describe "SIP Trunk Outbound Calling" do
    describe "POST /v1/convai/sip-trunk/outbound-call" do
      let(:endpoint) { "#{base_url}/v1/convai/sip-trunk/outbound-call" }

      context "successful SIP trunk call initiation" do
        let(:request_body) do
          {
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            to_number: to_number
          }
        end

        let(:success_response) do
          {
            success: true,
            message: "SIP trunk call initiated successfully",
            conversation_id: "conv_sip_abc123",
            sip_call_id: "sip_call_xyz789"
          }
        end

        before do
          stub_request(:post, endpoint)
            .with(
              body: request_body.to_json,
              headers: {
                "xi-api-key" => "test-api-key",
                "Content-Type" => "application/json"
              }
            )
            .to_return(
              status: 200,
              body: success_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "initiates SIP trunk call successfully" do
          result = client.outbound_calling.sip_trunk_call(
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            to_number: to_number
          )

          expect(result["success"]).to be true
          expect(result["message"]).to eq("SIP trunk call initiated successfully")
          expect(result["conversation_id"]).to eq("conv_sip_abc123")
          expect(result["sip_call_id"]).to eq("sip_call_xyz789")
        end

        it "sends correct request format" do
          client.outbound_calling.sip_trunk_call(
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            to_number: to_number
          )

          expect(WebMock).to have_requested(:post, endpoint)
            .with(
              body: request_body.to_json,
              headers: {
                "xi-api-key" => "test-api-key",
                "Content-Type" => "application/json"
              }
            )
        end
      end

      context "SIP trunk call with conversation configuration" do
        let(:conversation_initiation_client_data) do
          {
            conversation_config_override: {
              agent: {
                first_message: "Hello! This is an automated SIP trunk call from our customer service team.",
                language: "en",
                prompt: {
                  prompt: "You are a professional customer service representative calling via SIP trunk.",
                  native_mcp_server_ids: ["sip_server_1"]
                }
              },
              tts: {
                voice_id: "sip_voice_001",
                stability: 0.8,
                speed: 1.0,
                similarity_boost: 0.7
              },
              conversation: {
                text_only: false
              }
            },
            custom_llm_extra_body: {
              temperature: 0.7,
              max_tokens: 200
            },
            user_id: "sip_customer_789",
            source_info: {
              source: "sip_outbound_campaign",
              version: "1.0"
            },
            dynamic_variables: {
              customer_name: "John Doe",
              call_reason: "account_update",
              priority: "high"
            }
          }
        end

        let(:enhanced_request_body) do
          {
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            to_number: to_number,
            conversation_initiation_client_data: conversation_initiation_client_data
          }
        end

        let(:enhanced_response) do
          {
            success: true,
            message: "Enhanced SIP trunk call initiated",
            conversation_id: "conv_sip_enhanced_456",
            sip_call_id: "sip_enhanced_call_123"
          }
        end

        before do
          stub_request(:post, endpoint)
            .with(
              body: enhanced_request_body.to_json,
              headers: {
                "xi-api-key" => "test-api-key",
                "Content-Type" => "application/json"
              }
            )
            .to_return(
              status: 200,
              body: enhanced_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "initiates enhanced SIP trunk call with configuration" do
          result = client.outbound_calling.sip_trunk_call(
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            to_number: to_number,
            conversation_initiation_client_data: conversation_initiation_client_data
          )

          expect(result["success"]).to be true
          expect(result["conversation_id"]).to eq("conv_sip_enhanced_456")
          expect(result["sip_call_id"]).to eq("sip_enhanced_call_123")
        end

        it "includes comprehensive conversation configuration in request" do
          client.outbound_calling.sip_trunk_call(
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            to_number: to_number,
            conversation_initiation_client_data: conversation_initiation_client_data
          )

          expect(WebMock).to have_requested(:post, endpoint)
            .with(body: enhanced_request_body.to_json)
        end
      end

      context "SIP trunk call failure scenarios" do
        let(:request_body) do
          {
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            to_number: to_number
          }
        end

        context "when SIP trunk configuration is invalid" do
          let(:error_response) do
            {
              success: false,
              message: "SIP trunk configuration error: Invalid credentials",
              conversation_id: nil,
              sip_call_id: nil
            }
          end

          before do
            stub_request(:post, endpoint)
              .with(body: request_body.to_json)
              .to_return(
                status: 422,
                body: error_response.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "returns SIP trunk configuration error" do
            expect {
              client.outbound_calling.sip_trunk_call(
                agent_id: agent_id,
                agent_phone_number_id: agent_phone_number_id,
                to_number: to_number
              )
            }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
          end
        end

        context "when destination number is unreachable" do
          let(:unreachable_response) do
            {
              success: false,
              message: "Destination unreachable via SIP trunk",
              conversation_id: nil,
              sip_call_id: nil
            }
          end

          before do
            stub_request(:post, endpoint)
              .to_return(
                status: 200,
                body: unreachable_response.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "returns unreachable response without raising error" do
            result = client.outbound_calling.sip_trunk_call(
              agent_id: agent_id,
              agent_phone_number_id: agent_phone_number_id,
              to_number: to_number
            )

            expect(result["success"]).to be false
            expect(result["message"]).to include("unreachable")
            expect(result["conversation_id"]).to be_nil
            expect(result["sip_call_id"]).to be_nil
          end
        end
      end
    end
  end

  describe "Twilio Outbound Calling" do
    describe "POST /v1/convai/twilio/outbound-call" do
      let(:endpoint) { "#{base_url}/v1/convai/twilio/outbound-call" }

      context "successful Twilio call initiation" do
        let(:request_body) do
          {
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            to_number: to_number
          }
        end

        let(:twilio_success_response) do
          {
            success: true,
            message: "Twilio call initiated successfully",
            conversation_id: "conv_twilio_def456",
            callSid: "CA1234567890abcdef1234567890abcdef"
          }
        end

        before do
          stub_request(:post, endpoint)
            .with(
              body: request_body.to_json,
              headers: {
                "xi-api-key" => "test-api-key",
                "Content-Type" => "application/json"
              }
            )
            .to_return(
              status: 200,
              body: twilio_success_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "initiates Twilio call successfully" do
          result = client.outbound_calling.twilio_call(
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            to_number: to_number
          )

          expect(result["success"]).to be true
          expect(result["message"]).to eq("Twilio call initiated successfully")
          expect(result["conversation_id"]).to eq("conv_twilio_def456")
          expect(result["callSid"]).to start_with("CA")
        end

        it "sends correct Twilio request format" do
          client.outbound_calling.twilio_call(
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            to_number: to_number
          )

          expect(WebMock).to have_requested(:post, endpoint)
            .with(
              body: request_body.to_json,
              headers: {
                "xi-api-key" => "test-api-key",
                "Content-Type" => "application/json"
              }
            )
        end
      end

      context "Twilio call with advanced configuration" do
        let(:advanced_conversation_data) do
          {
            conversation_config_override: {
              agent: {
                first_message: "Hello! This is a Twilio call from our premium support team.",
                language: "en",
                prompt: {
                  prompt: "You are a premium support representative calling via Twilio. Provide exceptional service.",
                  native_mcp_server_ids: ["twilio_server_1", "premium_support"]
                }
              },
              tts: {
                voice_id: "premium_voice_001",
                stability: 0.9,
                speed: 1.1,
                similarity_boost: 0.8
              },
              conversation: {
                text_only: false
              }
            },
            custom_llm_extra_body: {
              temperature: 0.6,
              max_tokens: 250,
              presence_penalty: 0.1
            },
            user_id: "premium_customer_456",
            source_info: {
              source: "premium_outbound",
              version: "2.0"
            },
            dynamic_variables: {
              customer_name: "Jane Smith",
              account_tier: "premium",
              last_interaction: "2024-01-15",
              issue_priority: "critical",
              agent_instructions: {
                tone: "professional",
                approach: "consultative"
              }
            }
          }
        end

        let(:advanced_request_body) do
          {
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            to_number: to_number,
            conversation_initiation_client_data: advanced_conversation_data
          }
        end

        let(:advanced_twilio_response) do
          {
            success: true,
            message: "Premium Twilio call initiated with advanced configuration",
            conversation_id: "conv_twilio_premium_789",
            callSid: "CA9876543210fedcba9876543210fedcba"
          }
        end

        before do
          stub_request(:post, endpoint)
            .with(
              body: advanced_request_body.to_json,
              headers: {
                "xi-api-key" => "test-api-key",
                "Content-Type" => "application/json"
              }
            )
            .to_return(
              status: 200,
              body: advanced_twilio_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "initiates advanced Twilio call with comprehensive configuration" do
          result = client.outbound_calling.twilio_call(
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            to_number: to_number,
            conversation_initiation_client_data: advanced_conversation_data
          )

          expect(result["success"]).to be true
          expect(result["conversation_id"]).to eq("conv_twilio_premium_789")
          expect(result["callSid"]).to start_with("CA")
        end

        it "includes all advanced configuration in request" do
          client.outbound_calling.twilio_call(
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            to_number: to_number,
            conversation_initiation_client_data: advanced_conversation_data
          )

          expect(WebMock).to have_requested(:post, endpoint)
            .with(body: advanced_request_body.to_json)
        end
      end

      context "Twilio call failure scenarios" do
        context "when Twilio authentication fails" do
          before do
            stub_request(:post, endpoint)
              .to_return(
                status: 401,
                body: { detail: "Twilio authentication failed: Invalid credentials" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "raises AuthenticationError for Twilio auth failure" do
            expect {
              client.outbound_calling.twilio_call(
                agent_id: agent_id,
                agent_phone_number_id: agent_phone_number_id,
                to_number: to_number
              )
            }.to raise_error(ElevenlabsClient::AuthenticationError)
          end
        end

        context "when phone number format is invalid" do
          let(:invalid_number_response) do
            {
              success: false,
              message: "Invalid phone number format for Twilio",
              conversation_id: nil,
              callSid: nil
            }
          end

          before do
            stub_request(:post, endpoint)
              .to_return(
                status: 200,
                body: invalid_number_response.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "returns invalid number response without raising error" do
            result = client.outbound_calling.twilio_call(
              agent_id: agent_id,
              agent_phone_number_id: agent_phone_number_id,
              to_number: "invalid_number"
            )

            expect(result["success"]).to be false
            expect(result["message"]).to include("Invalid phone number")
            expect(result["conversation_id"]).to be_nil
            expect(result["callSid"]).to be_nil
          end
        end

        context "when Twilio account has insufficient funds" do
          let(:insufficient_funds_response) do
            {
              success: false,
              message: "Twilio account has insufficient funds",
              conversation_id: nil,
              callSid: nil
            }
          end

          before do
            stub_request(:post, endpoint)
              .to_return(
                status: 402,
                body: insufficient_funds_response.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "raises PaymentRequiredError for insufficient funds" do
            expect {
              client.outbound_calling.twilio_call(
                agent_id: agent_id,
                agent_phone_number_id: agent_phone_number_id,
                to_number: to_number
              )
            }.to raise_error(ElevenlabsClient::PaymentRequiredError)
          end
        end
      end
    end
  end

  describe "Multi-Provider Outbound Calling Workflow" do
    let(:sip_endpoint) { "#{base_url}/v1/convai/sip-trunk/outbound-call" }
    let(:twilio_endpoint) { "#{base_url}/v1/convai/twilio/outbound-call" }

    context "intelligent provider selection based on destination" do
      let(:domestic_number) { "+1555123456" }
      let(:international_number) { "+44123456789" }

      let(:sip_success_response) do
        {
          success: true,
          message: "SIP trunk call for international number",
          conversation_id: "conv_sip_intl_001",
          sip_call_id: "sip_intl_123"
        }
      end

      let(:twilio_success_response) do
        {
          success: true,
          message: "Twilio call for domestic number",
          conversation_id: "conv_twilio_dom_001",
          callSid: "CA_domestic_123456789"
        }
      end

      before do
        # Mock SIP trunk for international calls
        stub_request(:post, sip_endpoint)
          .with(body: hash_including(to_number: international_number))
          .to_return(
            status: 200,
            body: sip_success_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Mock Twilio for domestic calls
        stub_request(:post, twilio_endpoint)
          .with(body: hash_including(to_number: domestic_number))
          .to_return(
            status: 200,
            body: twilio_success_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "demonstrates intelligent provider selection workflow" do
        # International call via SIP trunk (cost-effective)
        intl_result = client.outbound_calling.sip_trunk_call(
          agent_id: agent_id,
          agent_phone_number_id: agent_phone_number_id,
          to_number: international_number
        )

        expect(intl_result["success"]).to be true
        expect(intl_result["sip_call_id"]).to eq("sip_intl_123")

        # Domestic call via Twilio (high reliability)
        domestic_result = client.outbound_calling.twilio_call(
          agent_id: agent_id,
          agent_phone_number_id: agent_phone_number_id,
          to_number: domestic_number
        )

        expect(domestic_result["success"]).to be true
        expect(domestic_result["callSid"]).to include("domestic")

        # Verify correct endpoints were called
        expect(WebMock).to have_requested(:post, sip_endpoint).with(
          body: hash_including(to_number: international_number)
        )
        expect(WebMock).to have_requested(:post, twilio_endpoint).with(
          body: hash_including(to_number: domestic_number)
        )
      end
    end

    context "provider failover scenario" do
      let(:primary_number) { "+1555987654" }

      before do
        # Primary provider (Twilio) fails
        stub_request(:post, twilio_endpoint)
          .to_return(status: 503, body: { detail: "Service temporarily unavailable" }.to_json)

        # Fallback provider (SIP) succeeds
        stub_request(:post, sip_endpoint)
          .to_return(
            status: 200,
            body: {
              success: true,
              message: "Fallback SIP trunk call successful",
              conversation_id: "conv_fallback_001",
              sip_call_id: "sip_fallback_456"
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "demonstrates provider failover workflow" do
        # Primary provider fails
        expect {
          client.outbound_calling.twilio_call(
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            to_number: primary_number
          )
        }.to raise_error(ElevenlabsClient::ServiceUnavailableError)

        # Fallback to secondary provider
        fallback_result = client.outbound_calling.sip_trunk_call(
          agent_id: agent_id,
          agent_phone_number_id: agent_phone_number_id,
          to_number: primary_number
        )

        expect(fallback_result["success"]).to be true
        expect(fallback_result["message"]).to include("Fallback")
        expect(fallback_result["sip_call_id"]).to eq("sip_fallback_456")
      end
    end
  end

  describe "Error Handling and Recovery" do
    let(:sip_endpoint) { "#{base_url}/v1/convai/sip-trunk/outbound-call" }
    let(:twilio_endpoint) { "#{base_url}/v1/convai/twilio/outbound-call" }

    context "network timeout scenarios" do
      before do
        stub_request(:post, sip_endpoint)
          .to_timeout
      end

      it "handles network timeouts appropriately" do
        expect {
          client.outbound_calling.sip_trunk_call(
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            to_number: to_number
          )
        }.to raise_error(Faraday::ConnectionFailed)
      end
    end

    context "rate limiting scenarios" do
      before do
        stub_request(:post, twilio_endpoint)
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
          client.outbound_calling.twilio_call(
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            to_number: to_number
          )
        }.to raise_error(ElevenlabsClient::RateLimitError)
      end
    end

    context "malformed response scenarios" do
      before do
        stub_request(:post, sip_endpoint)
          .to_return(
            status: 200,
            body: "Invalid JSON response",
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "handles malformed JSON responses" do
        expect {
          client.outbound_calling.sip_trunk_call(
            agent_id: agent_id,
            agent_phone_number_id: agent_phone_number_id,
            to_number: to_number
          )
        }.to raise_error(Faraday::ParsingError)
      end
    end
  end
end
