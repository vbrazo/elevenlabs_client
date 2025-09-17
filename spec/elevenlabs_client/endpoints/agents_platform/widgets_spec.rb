# frozen_string_literal: true

require "spec_helper"

RSpec.describe ElevenlabsClient::Endpoints::AgentsPlatform::Widgets do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test-api-key") }
  let(:widgets) { described_class.new(client) }

  describe "#get" do
    let(:agent_id) { "agent_123" }
    let(:endpoint) { "/v1/convai/agents/#{agent_id}/widget" }

    context "when successful" do
      let(:response) do
        {
          "agent_id" => agent_id,
          "widget_config" => {
            "language" => "en",
            "variant" => "tiny",
            "placement" => "bottom-right",
            "expandable" => "never",
            "avatar" => {
              "type" => "orb",
              "color_1" => "#2792dc",
              "color_2" => "#9ce6e6"
            },
            "feedback_mode" => "none",
            "bg_color" => "#ffffff",
            "text_color" => "#000000",
            "btn_color" => "#000000",
            "btn_text_color" => "#ffffff",
            "text_input_enabled" => true,
            "transcript_enabled" => false,
            "mic_muting_enabled" => false,
            "use_rtc" => true
          }
        }
      end

      before do
        allow(client).to receive(:get).with(endpoint).and_return(response)
      end

      it "returns widget configuration" do
        result = widgets.get(agent_id)

        expect(result).to eq(response)
        expect(result["agent_id"]).to eq(agent_id)
        expect(result["widget_config"]["variant"]).to eq("tiny")
        expect(result["widget_config"]["placement"]).to eq("bottom-right")
      end

      it "calls the correct endpoint" do
        widgets.get(agent_id)
        expect(client).to have_received(:get).with(endpoint)
      end
    end

    context "with conversation signature" do
      let(:conversation_signature) { "signature_token_123" }
      let(:endpoint_with_params) { "#{endpoint}?conversation_signature=#{conversation_signature}" }

      before do
        allow(client).to receive(:get).with(endpoint_with_params).and_return({})
      end

      it "includes conversation signature in query parameters" do
        widgets.get(agent_id, conversation_signature: conversation_signature)
        expect(client).to have_received(:get).with(endpoint_with_params)
      end
    end

    context "with multiple query parameters" do
      let(:params) { { conversation_signature: "token_123", custom_param: "value" } }
      
      before do
        allow(client).to receive(:get).and_return({})
      end

      it "includes all parameters in query string" do
        widgets.get(agent_id, **params)
        
        # Should call with endpoint containing query parameters
        expect(client).to have_received(:get) do |called_endpoint|
          expect(called_endpoint).to start_with(endpoint)
          expect(called_endpoint).to include("conversation_signature=token_123")
          expect(called_endpoint).to include("custom_param=value")
        end
      end
    end

    context "when client raises an error" do
      before do
        allow(client).to receive(:get).and_raise(ElevenlabsClient::APIError, "API Error")
      end

      it "propagates the error" do
        expect { widgets.get(agent_id) }.to raise_error(ElevenlabsClient::APIError, "API Error")
      end
    end
  end

  describe "#create_avatar" do
    let(:agent_id) { "agent_123" }
    let(:endpoint) { "/v1/convai/agents/#{agent_id}/avatar" }
    let(:avatar_file_io) { StringIO.new("fake_image_data") }
    let(:filename) { "avatar.png" }

    context "when successful" do
      let(:response) do
        {
          "agent_id" => agent_id,
          "avatar_url" => "https://example.com/avatars/agent_123.png"
        }
      end

      let(:file_part_mock) { double("FilePart") }
      let(:expected_form_data) do
        {
          "avatar_file" => file_part_mock
        }
      end

      before do
        allow(client).to receive(:file_part).with(avatar_file_io, filename).and_return(file_part_mock)
        allow(client).to receive(:post_multipart).with(endpoint, expected_form_data).and_return(response)
      end

      it "uploads avatar and returns response" do
        result = widgets.create_avatar(agent_id, avatar_file_io: avatar_file_io, filename: filename)

        expect(result).to eq(response)
        expect(result["agent_id"]).to eq(agent_id)
        expect(result["avatar_url"]).to include("avatars")
      end

      it "calls the correct endpoint with multipart data" do
        widgets.create_avatar(agent_id, avatar_file_io: avatar_file_io, filename: filename)
        expect(client).to have_received(:post_multipart).with(endpoint, expected_form_data)
      end
    end

    context "with different file types" do
      let(:jpg_filename) { "avatar.jpg" }
      let(:jpg_file_part_mock) { double("JPGFilePart") }
      
      before do
        allow(client).to receive(:file_part).with(avatar_file_io, jpg_filename).and_return(jpg_file_part_mock)
        allow(client).to receive(:post_multipart).and_return({})
      end

      it "handles different file extensions" do
        widgets.create_avatar(agent_id, avatar_file_io: avatar_file_io, filename: jpg_filename)
        
        expect(client).to have_received(:file_part).with(avatar_file_io, jpg_filename)
        expect(client).to have_received(:post_multipart).with(endpoint, { "avatar_file" => jpg_file_part_mock })
      end
    end

    context "when upload fails" do
      before do
        allow(client).to receive(:post_multipart).and_raise(ElevenlabsClient::ValidationError, "Invalid file format")
      end

      it "propagates validation errors" do
        expect {
          widgets.create_avatar(agent_id, avatar_file_io: avatar_file_io, filename: filename)
        }.to raise_error(ElevenlabsClient::ValidationError, "Invalid file format")
      end
    end

    context "when client raises API error" do
      before do
        allow(client).to receive(:post_multipart).and_raise(ElevenlabsClient::APIError, "Upload failed")
      end

      it "propagates API errors" do
        expect {
          widgets.create_avatar(agent_id, avatar_file_io: avatar_file_io, filename: filename)
        }.to raise_error(ElevenlabsClient::APIError, "Upload failed")
      end
    end
  end

  describe "error handling" do
    let(:agent_id) { "agent_123" }

    context "when agent not found" do
      before do
        allow(client).to receive(:get).and_raise(ElevenlabsClient::NotFoundError, "Agent not found")
      end

      it "raises NotFoundError for get" do
        expect { widgets.get(agent_id) }.to raise_error(ElevenlabsClient::NotFoundError, "Agent not found")
      end
    end

    context "when authentication fails" do
      before do
        allow(client).to receive(:get).and_raise(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end

      it "raises AuthenticationError" do
        expect { widgets.get(agent_id) }.to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end
    end

    context "when rate limited" do
      before do
        allow(client).to receive(:post_multipart).and_raise(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end

      it "raises RateLimitError for create_avatar" do
        avatar_file_io = StringIO.new("fake_data")
        expect {
          widgets.create_avatar(agent_id, avatar_file_io: avatar_file_io, filename: "test.png")
        }.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end
    end
  end

  describe "parameter validation" do
    let(:agent_id) { "agent_123" }

    context "with nil agent_id" do
      before do
        allow(client).to receive(:get).and_return({})
      end

      it "should handle nil agent_id gracefully" do
        expect { widgets.get(nil) }.not_to raise_error
      end
    end

    context "with empty agent_id" do
      before do
        allow(client).to receive(:get).and_return({})
      end

      it "should handle empty agent_id gracefully" do
        expect { widgets.get("") }.not_to raise_error
      end
    end

    context "create_avatar with missing parameters" do
      it "requires avatar_file_io parameter" do
        expect {
          widgets.create_avatar(agent_id, filename: "test.png")
        }.to raise_error(ArgumentError)
      end

      it "requires filename parameter" do
        avatar_file_io = StringIO.new("fake_data")
        expect {
          widgets.create_avatar(agent_id, avatar_file_io: avatar_file_io)
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "query parameter encoding" do
    let(:agent_id) { "agent_123" }
    
    before do
      allow(client).to receive(:get).and_return({})
    end

    context "with special characters in parameters" do
      let(:special_signature) { "token with spaces & symbols" }
      
      it "properly encodes query parameters" do
        widgets.get(agent_id, conversation_signature: special_signature)
        
        expect(client).to have_received(:get) do |endpoint|
          expect(endpoint).to include(URI.encode_www_form_component(special_signature))
        end
      end
    end

    context "with nil parameters" do
      it "excludes nil parameters from query string" do
        widgets.get(agent_id, conversation_signature: nil, valid_param: "value")
        
        expect(client).to have_received(:get) do |endpoint|
          expect(endpoint).not_to include("conversation_signature")
          expect(endpoint).to include("valid_param=value")
        end
      end
    end
  end
end
