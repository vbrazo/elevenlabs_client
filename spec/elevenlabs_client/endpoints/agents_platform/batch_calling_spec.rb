# frozen_string_literal: true

require "spec_helper"

RSpec.describe ElevenlabsClient::Endpoints::AgentsPlatform::BatchCalling do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test-api-key") }
  let(:batch_calling) { described_class.new(client) }

  describe "#submit" do
    let(:endpoint) { "/v1/convai/batch-calling/submit" }
    let(:call_name) { "Customer Survey Campaign" }
    let(:agent_id) { "agent_123" }
    let(:agent_phone_number_id) { "phone_456" }
    let(:scheduled_time_unix) { Time.now.to_i + 3600 }
    let(:recipients) do
      [
        { phone_number: "+1234567890" },
        { phone_number: "+1987654321" },
        { phone_number: "+1555123456" }
      ]
    end

    let(:required_params) do
      {
        call_name: call_name,
        agent_id: agent_id,
        agent_phone_number_id: agent_phone_number_id,
        scheduled_time_unix: scheduled_time_unix,
        recipients: recipients
      }
    end

    context "when successful" do
      let(:response) do
        {
          "id" => "batch_abc123",
          "phone_number_id" => agent_phone_number_id,
          "name" => call_name,
          "agent_id" => agent_id,
          "created_at_unix" => Time.now.to_i,
          "scheduled_time_unix" => scheduled_time_unix,
          "total_calls_dispatched" => 0,
          "total_calls_scheduled" => 3,
          "last_updated_at_unix" => Time.now.to_i,
          "status" => "pending",
          "agent_name" => "Customer Service Agent",
          "phone_provider" => "twilio"
        }
      end

      before do
        allow(client).to receive(:post).with(endpoint, required_params).and_return(response)
      end

      it "submits batch call job successfully" do
        result = batch_calling.submit(**required_params)

        expect(result).to eq(response)
        expect(result["id"]).to eq("batch_abc123")
        expect(result["name"]).to eq(call_name)
        expect(result["total_calls_scheduled"]).to eq(3)
        expect(result["status"]).to eq("pending")
      end

      it "calls the correct endpoint" do
        batch_calling.submit(**required_params)
        expect(client).to have_received(:post).with(endpoint, required_params)
      end
    end

    context "when submission fails" do
      before do
        allow(client).to receive(:post).and_raise(ElevenlabsClient::ValidationError, "Invalid recipients")
      end

      it "propagates validation errors" do
        expect {
          batch_calling.submit(**required_params)
        }.to raise_error(ElevenlabsClient::ValidationError, "Invalid recipients")
      end
    end

    context "with complex recipients" do
      let(:complex_recipients) do
        [
          {
            phone_number: "+1234567890",
            conversation_initiation_client_data: {
              user_id: "user_001",
              dynamic_variables: { customer_name: "John Doe" }
            }
          },
          {
            phone_number: "+1987654321",
            conversation_initiation_client_data: {
              user_id: "user_002",
              dynamic_variables: { customer_name: "Jane Smith" }
            }
          }
        ]
      end

      let(:complex_params) do
        required_params.merge(recipients: complex_recipients)
      end

      before do
        allow(client).to receive(:post).and_return({})
      end

      it "handles recipients with conversation data" do
        batch_calling.submit(**complex_params)
        expect(client).to have_received(:post).with(endpoint, complex_params)
      end
    end
  end

  describe "#list" do
    let(:endpoint) { "/v1/convai/batch-calling/workspace" }

    context "without parameters" do
      let(:response) do
        {
          "batch_calls" => [
            {
              "id" => "batch_001",
              "phone_number_id" => "phone_001",
              "name" => "Survey Campaign 1",
              "agent_id" => "agent_001",
              "created_at_unix" => Time.now.to_i - 3600,
              "scheduled_time_unix" => Time.now.to_i - 1800,
              "total_calls_dispatched" => 50,
              "total_calls_scheduled" => 100,
              "last_updated_at_unix" => Time.now.to_i - 300,
              "status" => "in_progress",
              "agent_name" => "Survey Agent",
              "phone_provider" => "twilio"
            },
            {
              "id" => "batch_002",
              "phone_number_id" => "phone_002",
              "name" => "Reminder Campaign",
              "agent_id" => "agent_002",
              "created_at_unix" => Time.now.to_i - 7200,
              "scheduled_time_unix" => Time.now.to_i - 3600,
              "total_calls_dispatched" => 25,
              "total_calls_scheduled" => 25,
              "last_updated_at_unix" => Time.now.to_i - 1800,
              "status" => "completed",
              "agent_name" => "Reminder Agent",
              "phone_provider" => "sip_trunk"
            }
          ],
          "next_doc" => nil,
          "has_more" => false
        }
      end

      before do
        allow(client).to receive(:get).with(endpoint).and_return(response)
      end

      it "lists batch call jobs" do
        result = batch_calling.list

        expect(result).to eq(response)
        expect(result["batch_calls"].size).to eq(2)
        expect(result["batch_calls"].first["id"]).to eq("batch_001")
        expect(result["has_more"]).to be false
      end

      it "calls the correct endpoint" do
        batch_calling.list
        expect(client).to have_received(:get).with(endpoint)
      end
    end

    context "with pagination parameters" do
      let(:limit) { 50 }
      let(:last_doc) { "last_document_id_123" }
      let(:endpoint_with_params) { "#{endpoint}?limit=#{limit}&last_doc=#{last_doc}" }

      before do
        allow(client).to receive(:get).with(endpoint_with_params).and_return({})
      end

      it "includes pagination parameters" do
        batch_calling.list(limit: limit, last_doc: last_doc)
        expect(client).to have_received(:get).with(endpoint_with_params)
      end
    end

    context "with nil parameters" do
      before do
        allow(client).to receive(:get).and_return({})
      end

      it "excludes nil parameters" do
        batch_calling.list(limit: 10, last_doc: nil)
        expect(client).to have_received(:get).with("#{endpoint}?limit=10")
      end
    end

    context "when API error occurs" do
      before do
        allow(client).to receive(:get).and_raise(ElevenlabsClient::APIError, "Service unavailable")
      end

      it "propagates API errors" do
        expect { batch_calling.list }.to raise_error(ElevenlabsClient::APIError, "Service unavailable")
      end
    end
  end

  describe "#get" do
    let(:batch_id) { "batch_abc123" }
    let(:endpoint) { "/v1/convai/batch-calling/#{batch_id}" }

    context "when successful" do
      let(:response) do
        {
          "id" => batch_id,
          "phone_number_id" => "phone_001",
          "name" => "Customer Survey Campaign",
          "agent_id" => "agent_001",
          "created_at_unix" => Time.now.to_i - 3600,
          "scheduled_time_unix" => Time.now.to_i - 1800,
          "total_calls_dispatched" => 8,
          "total_calls_scheduled" => 10,
          "last_updated_at_unix" => Time.now.to_i - 300,
          "status" => "in_progress",
          "agent_name" => "Survey Agent",
          "recipients" => [
            {
              "id" => "rec_001",
              "phone_number" => "+1234567890",
              "status" => "completed",
              "created_at_unix" => Time.now.to_i - 3600,
              "updated_at_unix" => Time.now.to_i - 1800,
              "conversation_id" => "conv_001",
              "conversation_initiation_client_data" => {
                "user_id" => "user_001",
                "source_info" => { "source" => "survey_campaign" }
              }
            },
            {
              "id" => "rec_002",
              "phone_number" => "+1987654321",
              "status" => "failed",
              "created_at_unix" => Time.now.to_i - 3600,
              "updated_at_unix" => Time.now.to_i - 1800,
              "conversation_id" => nil
            }
          ],
          "phone_provider" => "twilio"
        }
      end

      before do
        allow(client).to receive(:get).with(endpoint).and_return(response)
      end

      it "returns batch call details" do
        result = batch_calling.get(batch_id)

        expect(result).to eq(response)
        expect(result["id"]).to eq(batch_id)
        expect(result["recipients"].size).to eq(2)
        expect(result["recipients"].first["phone_number"]).to eq("+1234567890")
      end

      it "calls the correct endpoint" do
        batch_calling.get(batch_id)
        expect(client).to have_received(:get).with(endpoint)
      end
    end

    context "when batch not found" do
      before do
        allow(client).to receive(:get).and_raise(ElevenlabsClient::NotFoundError, "Batch not found")
      end

      it "propagates not found errors" do
        expect {
          batch_calling.get(batch_id)
        }.to raise_error(ElevenlabsClient::NotFoundError, "Batch not found")
      end
    end
  end

  describe "#cancel" do
    let(:batch_id) { "batch_abc123" }
    let(:endpoint) { "/v1/convai/batch-calling/#{batch_id}/cancel" }

    context "when successful" do
      let(:response) do
        {
          "id" => batch_id,
          "phone_number_id" => "phone_001",
          "name" => "Cancelled Campaign",
          "agent_id" => "agent_001",
          "created_at_unix" => Time.now.to_i - 3600,
          "scheduled_time_unix" => Time.now.to_i - 1800,
          "total_calls_dispatched" => 25,
          "total_calls_scheduled" => 100,
          "last_updated_at_unix" => Time.now.to_i,
          "status" => "cancelled",
          "agent_name" => "Campaign Agent",
          "phone_provider" => "twilio"
        }
      end

      before do
        allow(client).to receive(:post).with(endpoint, {}).and_return(response)
      end

      it "cancels batch job successfully" do
        result = batch_calling.cancel(batch_id)

        expect(result).to eq(response)
        expect(result["id"]).to eq(batch_id)
        expect(result["status"]).to eq("cancelled")
      end

      it "calls the correct endpoint with empty body" do
        batch_calling.cancel(batch_id)
        expect(client).to have_received(:post).with(endpoint, {})
      end
    end

    context "when cancellation fails" do
      before do
        allow(client).to receive(:post).and_raise(ElevenlabsClient::APIError, "Cannot cancel completed job")
      end

      it "propagates API errors" do
        expect {
          batch_calling.cancel(batch_id)
        }.to raise_error(ElevenlabsClient::APIError, "Cannot cancel completed job")
      end
    end
  end

  describe "#retry" do
    let(:batch_id) { "batch_abc123" }
    let(:endpoint) { "/v1/convai/batch-calling/#{batch_id}/retry" }

    context "when successful" do
      let(:response) do
        {
          "id" => batch_id,
          "phone_number_id" => "phone_001",
          "name" => "Retried Campaign",
          "agent_id" => "agent_001",
          "created_at_unix" => Time.now.to_i - 7200,
          "scheduled_time_unix" => Time.now.to_i - 3600,
          "total_calls_dispatched" => 15,
          "total_calls_scheduled" => 50,
          "last_updated_at_unix" => Time.now.to_i,
          "status" => "in_progress",
          "agent_name" => "Retry Agent",
          "phone_provider" => "sip_trunk"
        }
      end

      before do
        allow(client).to receive(:post).with(endpoint, {}).and_return(response)
      end

      it "retries batch job successfully" do
        result = batch_calling.retry(batch_id)

        expect(result).to eq(response)
        expect(result["id"]).to eq(batch_id)
        expect(result["status"]).to eq("in_progress")
      end

      it "calls the correct endpoint with empty body" do
        batch_calling.retry(batch_id)
        expect(client).to have_received(:post).with(endpoint, {})
      end
    end

    context "when retry fails" do
      before do
        allow(client).to receive(:post).and_raise(ElevenlabsClient::ValidationError, "No failed calls to retry")
      end

      it "propagates validation errors" do
        expect {
          batch_calling.retry(batch_id)
        }.to raise_error(ElevenlabsClient::ValidationError, "No failed calls to retry")
      end
    end
  end

  describe "error handling" do
    let(:batch_id) { "batch_123" }

    context "when authentication fails" do
      before do
        allow(client).to receive(:get).and_raise(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end

      it "propagates authentication errors" do
        expect {
          batch_calling.get(batch_id)
        }.to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end
    end

    context "when rate limited" do
      before do
        allow(client).to receive(:post).and_raise(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end

      it "propagates rate limit errors for submit" do
        expect {
          batch_calling.submit(
            call_name: "Test",
            agent_id: "agent",
            agent_phone_number_id: "phone",
            scheduled_time_unix: Time.now.to_i,
            recipients: []
          )
        }.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end

      it "propagates rate limit errors for cancel" do
        expect {
          batch_calling.cancel(batch_id)
        }.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end

      it "propagates rate limit errors for retry" do
        expect {
          batch_calling.retry(batch_id)
        }.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end
    end
  end

  describe "parameter validation" do
    context "submit method with missing parameters" do
      it "requires call_name parameter" do
        expect {
          batch_calling.submit(
            agent_id: "agent_123",
            agent_phone_number_id: "phone_456",
            scheduled_time_unix: Time.now.to_i,
            recipients: []
          )
        }.to raise_error(ArgumentError)
      end

      it "requires agent_id parameter" do
        expect {
          batch_calling.submit(
            call_name: "Test Campaign",
            agent_phone_number_id: "phone_456",
            scheduled_time_unix: Time.now.to_i,
            recipients: []
          )
        }.to raise_error(ArgumentError)
      end

      it "requires recipients parameter" do
        expect {
          batch_calling.submit(
            call_name: "Test Campaign",
            agent_id: "agent_123",
            agent_phone_number_id: "phone_456",
            scheduled_time_unix: Time.now.to_i
          )
        }.to raise_error(ArgumentError)
      end
    end

    context "with nil batch_id" do
      before do
        allow(client).to receive(:get).and_return({})
        allow(client).to receive(:post).and_return({})
      end

      it "handles nil batch_id gracefully for get" do
        expect { batch_calling.get(nil) }.not_to raise_error
      end

      it "handles nil batch_id gracefully for cancel" do
        expect { batch_calling.cancel(nil) }.not_to raise_error
      end

      it "handles nil batch_id gracefully for retry" do
        expect { batch_calling.retry(nil) }.not_to raise_error
      end
    end
  end

  describe "query parameter encoding in list" do
    before do
      allow(client).to receive(:get).and_return({})
    end

    context "with special characters in parameters" do
      let(:special_last_doc) { "doc_with spaces & symbols" }
      
      it "properly encodes query parameters" do
        batch_calling.list(last_doc: special_last_doc, limit: 10)
        
        expect(client).to have_received(:get) do |endpoint|
          expect(endpoint).to include(URI.encode_www_form_component(special_last_doc))
          expect(endpoint).to include("limit=10")
        end
      end
    end

    context "with only some parameters" do
      it "includes only provided parameters" do
        batch_calling.list(limit: 25)
        
        expect(client).to have_received(:get).with("/v1/convai/batch-calling/workspace?limit=25")
      end
    end
  end

  describe "complex recipient configurations" do
    let(:base_params) do
      {
        call_name: "Complex Campaign",
        agent_id: "agent_123",
        agent_phone_number_id: "phone_456",
        scheduled_time_unix: Time.now.to_i + 3600
      }
    end

    context "with comprehensive recipient data" do
      let(:comprehensive_recipients) do
        [
          {
            phone_number: "+1234567890",
            conversation_initiation_client_data: {
              conversation_config_override: {
                tts: {
                  voice_id: "voice_001",
                  stability: 0.8,
                  speed: 1.0,
                  similarity_boost: 0.7
                },
                conversation: {
                  text_only: false
                },
                agent: {
                  first_message: "Hello John! This is a personalized call.",
                  language: "en",
                  prompt: {
                    prompt: "You are calling John about his premium account.",
                    native_mcp_server_ids: ["server1"]
                  }
                }
              },
              custom_llm_extra_body: {
                temperature: 0.7,
                max_tokens: 200
              },
              user_id: "user_john_001",
              source_info: {
                source: "premium_campaign",
                version: "2.0"
              },
              dynamic_variables: {
                customer_name: "John Doe",
                account_type: "premium",
                last_purchase: "Enterprise Package",
                personalization: {
                  preferred_greeting: "formal",
                  communication_style: "professional"
                }
              }
            }
          }
        ]
      end

      let(:comprehensive_params) do
        base_params.merge(recipients: comprehensive_recipients)
      end

      before do
        allow(client).to receive(:post).and_return({})
      end

      it "handles comprehensive recipient configuration" do
        batch_calling.submit(**comprehensive_params)
        
        expect(client).to have_received(:post) do |endpoint, body|
          recipient = body[:recipients].first
          config = recipient[:conversation_initiation_client_data]
          
          # Verify TTS configuration
          expect(config[:conversation_config_override][:tts][:voice_id]).to eq("voice_001")
          expect(config[:conversation_config_override][:tts][:stability]).to eq(0.8)
          
          # Verify agent configuration
          expect(config[:conversation_config_override][:agent][:first_message]).to include("John")
          expect(config[:conversation_config_override][:agent][:prompt][:native_mcp_server_ids]).to include("server1")
          
          # Verify custom LLM configuration
          expect(config[:custom_llm_extra_body][:temperature]).to eq(0.7)
          
          # Verify dynamic variables with nested data
          expect(config[:dynamic_variables][:account_type]).to eq("premium")
          expect(config[:dynamic_variables][:personalization][:preferred_greeting]).to eq("formal")
        end
      end
    end
  end
end
