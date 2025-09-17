# frozen_string_literal: true

require "spec_helper"

RSpec.describe ElevenlabsClient::Endpoints::AgentsPlatform::OutboundCalling do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test-api-key") }
  let(:outbound_calling) { described_class.new(client) }

  describe "#sip_trunk_call" do
    let(:endpoint) { "/v1/convai/sip-trunk/outbound-call" }
    let(:agent_id) { "agent_123" }
    let(:agent_phone_number_id) { "phone_456" }
    let(:to_number) { "+1234567890" }

    let(:required_params) do
      {
        agent_id: agent_id,
        agent_phone_number_id: agent_phone_number_id,
        to_number: to_number
      }
    end

    context "when successful" do
      let(:response) do
        {
          "success" => true,
          "message" => "Call initiated successfully",
          "conversation_id" => "conv_abc123",
          "sip_call_id" => "sip_xyz789"
        }
      end

      before do
        allow(client).to receive(:post).with(endpoint, required_params).and_return(response)
      end

      it "initiates SIP trunk call successfully" do
        result = outbound_calling.sip_trunk_call(**required_params)

        expect(result).to eq(response)
        expect(result["success"]).to be true
        expect(result["conversation_id"]).to eq("conv_abc123")
        expect(result["sip_call_id"]).to eq("sip_xyz789")
      end

      it "calls the correct endpoint" do
        outbound_calling.sip_trunk_call(**required_params)
        expect(client).to have_received(:post).with(endpoint, required_params)
      end
    end

    context "with additional conversation data" do
      let(:conversation_initiation_client_data) do
        {
          conversation_config_override: {
            agent: {
              first_message: "Hello! This is an automated call.",
              language: "en"
            },
            tts: {
              voice_id: "custom_voice",
              stability: 0.8,
              speed: 1.0
            }
          },
          user_id: "user_123",
          source_info: {
            source: "outbound_campaign",
            version: "1.0"
          },
          dynamic_variables: {
            customer_name: "John Doe",
            account_balance: "$150.00"
          }
        }
      end

      let(:params_with_data) do
        required_params.merge(conversation_initiation_client_data: conversation_initiation_client_data)
      end

      before do
        allow(client).to receive(:post).with(endpoint, params_with_data).and_return({})
      end

      it "includes conversation initiation data" do
        outbound_calling.sip_trunk_call(**params_with_data)
        expect(client).to have_received(:post).with(endpoint, params_with_data)
      end
    end

    context "when call fails" do
      let(:error_response) do
        {
          "success" => false,
          "message" => "Invalid phone number format",
          "conversation_id" => nil,
          "sip_call_id" => nil
        }
      end

      before do
        allow(client).to receive(:post).with(endpoint, required_params).and_return(error_response)
      end

      it "returns failure response" do
        result = outbound_calling.sip_trunk_call(**required_params)

        expect(result["success"]).to be false
        expect(result["message"]).to eq("Invalid phone number format")
        expect(result["conversation_id"]).to be_nil
        expect(result["sip_call_id"]).to be_nil
      end
    end

    context "when client raises an error" do
      before do
        allow(client).to receive(:post).and_raise(ElevenlabsClient::ValidationError, "Invalid parameters")
      end

      it "propagates validation errors" do
        expect {
          outbound_calling.sip_trunk_call(**required_params)
        }.to raise_error(ElevenlabsClient::ValidationError, "Invalid parameters")
      end
    end
  end

  describe "#twilio_call" do
    let(:endpoint) { "/v1/convai/twilio/outbound-call" }
    let(:agent_id) { "agent_123" }
    let(:agent_phone_number_id) { "phone_456" }
    let(:to_number) { "+1987654321" }

    let(:required_params) do
      {
        agent_id: agent_id,
        agent_phone_number_id: agent_phone_number_id,
        to_number: to_number
      }
    end

    context "when successful" do
      let(:response) do
        {
          "success" => true,
          "message" => "Call initiated via Twilio",
          "conversation_id" => "conv_def456",
          "callSid" => "CA1234567890abcdef1234567890abcdef"
        }
      end

      before do
        allow(client).to receive(:post).with(endpoint, required_params).and_return(response)
      end

      it "initiates Twilio call successfully" do
        result = outbound_calling.twilio_call(**required_params)

        expect(result).to eq(response)
        expect(result["success"]).to be true
        expect(result["conversation_id"]).to eq("conv_def456")
        expect(result["callSid"]).to start_with("CA")
      end

      it "calls the correct endpoint" do
        outbound_calling.twilio_call(**required_params)
        expect(client).to have_received(:post).with(endpoint, required_params)
      end
    end

    context "with enhanced configuration" do
      let(:conversation_data) do
        {
          conversation_config_override: {
            agent: {
              first_message: "Hello! This is a Twilio call.",
              prompt: {
                prompt: "You are a professional customer service representative.",
                native_mcp_server_ids: ["server1", "server2"]
              }
            }
          },
          user_id: "customer_456",
          dynamic_variables: {
            inquiry_type: "billing_question",
            priority: "high"
          }
        }
      end

      let(:enhanced_params) do
        required_params.merge(conversation_initiation_client_data: conversation_data)
      end

      before do
        allow(client).to receive(:post).with(endpoint, enhanced_params).and_return({})
      end

      it "includes enhanced conversation configuration" do
        outbound_calling.twilio_call(**enhanced_params)
        expect(client).to have_received(:post).with(endpoint, enhanced_params)
      end
    end

    context "when Twilio call fails" do
      let(:twilio_error_response) do
        {
          "success" => false,
          "message" => "Twilio authentication failed",
          "conversation_id" => nil,
          "callSid" => nil
        }
      end

      before do
        allow(client).to receive(:post).with(endpoint, required_params).and_return(twilio_error_response)
      end

      it "returns Twilio error response" do
        result = outbound_calling.twilio_call(**required_params)

        expect(result["success"]).to be false
        expect(result["message"]).to eq("Twilio authentication failed")
        expect(result["callSid"]).to be_nil
      end
    end

    context "when client raises authentication error" do
      before do
        allow(client).to receive(:post).and_raise(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end

      it "propagates authentication errors" do
        expect {
          outbound_calling.twilio_call(**required_params)
        }.to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end
    end
  end

  describe "error handling" do
    let(:params) do
      {
        agent_id: "agent_123",
        agent_phone_number_id: "phone_456",
        to_number: "+1234567890"
      }
    end

    context "when API returns error" do
      before do
        allow(client).to receive(:post).and_raise(ElevenlabsClient::APIError, "Service unavailable")
      end

      it "propagates API errors for SIP trunk calls" do
        expect {
          outbound_calling.sip_trunk_call(**params)
        }.to raise_error(ElevenlabsClient::APIError, "Service unavailable")
      end

      it "propagates API errors for Twilio calls" do
        expect {
          outbound_calling.twilio_call(**params)
        }.to raise_error(ElevenlabsClient::APIError, "Service unavailable")
      end
    end

    context "when rate limited" do
      before do
        allow(client).to receive(:post).and_raise(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end

      it "propagates rate limit errors" do
        expect {
          outbound_calling.sip_trunk_call(**params)
        }.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end
    end

    context "when validation fails" do
      before do
        allow(client).to receive(:post).and_raise(ElevenlabsClient::ValidationError, "Invalid phone number")
      end

      it "propagates validation errors" do
        expect {
          outbound_calling.twilio_call(**params)
        }.to raise_error(ElevenlabsClient::ValidationError, "Invalid phone number")
      end
    end
  end

  describe "parameter validation" do
    context "missing required parameters" do
      it "requires agent_id for SIP trunk calls" do
        expect {
          outbound_calling.sip_trunk_call(
            agent_phone_number_id: "phone_456",
            to_number: "+1234567890"
          )
        }.to raise_error(ArgumentError)
      end

      it "requires agent_phone_number_id for Twilio calls" do
        expect {
          outbound_calling.twilio_call(
            agent_id: "agent_123",
            to_number: "+1234567890"
          )
        }.to raise_error(ArgumentError)
      end

      it "requires to_number for both call types" do
        expect {
          outbound_calling.sip_trunk_call(
            agent_id: "agent_123",
            agent_phone_number_id: "phone_456"
          )
        }.to raise_error(ArgumentError)
      end
    end

    context "with extra parameters" do
      let(:params_with_extra) do
        {
          agent_id: "agent_123",
          agent_phone_number_id: "phone_456",
          to_number: "+1234567890",
          extra_param: "extra_value",
          another_param: 123
        }
      end

      before do
        allow(client).to receive(:post).and_return({})
      end

      it "passes through extra parameters" do
        outbound_calling.sip_trunk_call(**params_with_extra)
        expect(client).to have_received(:post) do |endpoint, body|
          expect(body[:extra_param]).to eq("extra_value")
          expect(body[:another_param]).to eq(123)
        end
      end
    end
  end

  describe "complex conversation configurations" do
    let(:base_params) do
      {
        agent_id: "agent_123",
        agent_phone_number_id: "phone_456",
        to_number: "+1234567890"
      }
    end

    context "with comprehensive conversation data" do
      let(:complex_conversation_data) do
        {
          conversation_config_override: {
            tts: {
              voice_id: "voice_id_123",
              stability: 0.9,
              speed: 1.2,
              similarity_boost: 0.8
            },
            conversation: {
              text_only: false
            },
            agent: {
              first_message: "Hello! This is a comprehensive test call.",
              language: "en",
              prompt: {
                prompt: "You are an advanced AI assistant with specific instructions.",
                native_mcp_server_ids: ["server1", "server2", "server3"]
              }
            }
          },
          custom_llm_extra_body: {
            temperature: 0.7,
            max_tokens: 150
          },
          user_id: "user_comprehensive_test",
          source_info: {
            source: "comprehensive_test",
            version: "2.0"
          },
          dynamic_variables: {
            user_name: "Test User",
            account_type: "premium",
            last_interaction: "2024-01-15",
            preferences: {
              language: "en",
              communication_style: "formal"
            }
          }
        }
      end

      let(:complex_params) do
        base_params.merge(conversation_initiation_client_data: complex_conversation_data)
      end

      before do
        allow(client).to receive(:post).and_return({})
      end

      it "handles complex nested conversation configuration" do
        outbound_calling.sip_trunk_call(**complex_params)
        
        expect(client).to have_received(:post) do |endpoint, body|
          config = body[:conversation_initiation_client_data]
          
          # Verify TTS configuration
          expect(config[:conversation_config_override][:tts][:voice_id]).to eq("voice_id_123")
          expect(config[:conversation_config_override][:tts][:stability]).to eq(0.9)
          
          # Verify agent configuration
          expect(config[:conversation_config_override][:agent][:language]).to eq("en")
          expect(config[:conversation_config_override][:agent][:prompt][:native_mcp_server_ids]).to include("server1")
          
          # Verify custom LLM configuration
          expect(config[:custom_llm_extra_body][:temperature]).to eq(0.7)
          
          # Verify dynamic variables
          expect(config[:dynamic_variables][:account_type]).to eq("premium")
          expect(config[:dynamic_variables][:preferences][:communication_style]).to eq("formal")
        end
      end
    end
  end
end
