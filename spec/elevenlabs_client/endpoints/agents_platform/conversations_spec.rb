# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Endpoints::AgentsPlatform::Conversations do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:conversations) { described_class.new(client) }

  describe "#list" do
    let(:list_response) do
      {
        "conversations" => [
          {
            "agent_id" => "agent123",
            "conversation_id" => "conv123",
            "start_time_unix_secs" => 1716153600,
            "call_duration_secs" => 120,
            "message_count" => 5,
            "status" => "done",
            "call_successful" => "success",
            "agent_name" => "Support Agent",
            "transcript_summary" => "Customer inquiry about billing",
            "call_summary_title" => "Billing Question",
            "direction" => "inbound"
          }
        ],
        "has_more" => false,
        "next_cursor" => nil
      }
    end

    context "without parameters" do
      before do
        allow(client).to receive(:get).with("/v1/convai/conversations")
                                     .and_return(list_response)
      end

      it "lists conversations successfully" do
        result = conversations.list
        expect(result).to eq(list_response)
        expect(client).to have_received(:get).with("/v1/convai/conversations")
      end
    end

    context "with parameters" do
      let(:params) do
        {
          agent_id: "agent123",
          page_size: 10,
          call_successful: "success",
          summary_mode: "include"
        }
      end

      before do
        allow(client).to receive(:get).with("/v1/convai/conversations?agent_id=agent123&page_size=10&call_successful=success&summary_mode=include")
                                     .and_return(list_response)
      end

      it "lists conversations with query parameters" do
        result = conversations.list(**params)
        expect(result).to eq(list_response)
        expect(client).to have_received(:get).with("/v1/convai/conversations?agent_id=agent123&page_size=10&call_successful=success&summary_mode=include")
      end
    end

    context "with date range parameters" do
      let(:params) do
        {
          call_start_after_unix: 1716100000,
          call_start_before_unix: 1716200000,
          user_id: "user123"
        }
      end

      before do
        allow(client).to receive(:get).with("/v1/convai/conversations?call_start_after_unix=1716100000&call_start_before_unix=1716200000&user_id=user123")
                                     .and_return(list_response)
      end

      it "lists conversations with date range filters" do
        result = conversations.list(**params)
        expect(result).to eq(list_response)
        expect(client).to have_received(:get).with("/v1/convai/conversations?call_start_after_unix=1716100000&call_start_before_unix=1716200000&user_id=user123")
      end
    end
  end

  describe "#get" do
    let(:conversation_id) { "conv123" }
    let(:conversation_response) do
      {
        "agent_id" => "agent123",
        "conversation_id" => conversation_id,
        "status" => "done",
        "transcript" => [
          {
            "role" => "user",
            "time_in_call_secs" => 10,
            "message" => "Hello, I need help with my billing"
          },
          {
            "role" => "agent",
            "time_in_call_secs" => 12,
            "message" => "I'd be happy to help you with your billing question"
          }
        ],
        "metadata" => {
          "start_time_unix_secs" => 1716153600,
          "call_duration_secs" => 120,
          "message_count" => 2,
          "direction" => "inbound"
        },
        "has_audio" => true,
        "has_user_audio" => true,
        "has_response_audio" => true,
        "user_id" => "user123"
      }
    end

    before do
      allow(client).to receive(:get).with("/v1/convai/conversations/#{conversation_id}")
                                   .and_return(conversation_response)
    end

    it "retrieves conversation details successfully" do
      result = conversations.get(conversation_id)
      expect(result).to eq(conversation_response)
      expect(client).to have_received(:get).with("/v1/convai/conversations/#{conversation_id}")
    end
  end

  describe "#delete" do
    let(:conversation_id) { "conv123" }
    let(:delete_response) { {} }

    before do
      allow(client).to receive(:delete).with("/v1/convai/conversations/#{conversation_id}")
                                      .and_return(delete_response)
    end

    it "deletes conversation successfully" do
      result = conversations.delete(conversation_id)
      expect(result).to eq(delete_response)
      expect(client).to have_received(:delete).with("/v1/convai/conversations/#{conversation_id}")
    end
  end

  describe "#get_audio" do
    let(:conversation_id) { "conv123" }
    let(:audio_data) { "binary_audio_data" }

    before do
      allow(client).to receive(:get_binary).with("/v1/convai/conversations/#{conversation_id}/audio")
                                          .and_return(audio_data)
    end

    it "retrieves conversation audio successfully" do
      result = conversations.get_audio(conversation_id)
      expect(result).to eq(audio_data)
      expect(client).to have_received(:get_binary).with("/v1/convai/conversations/#{conversation_id}/audio")
    end
  end

  describe "#get_signed_url" do
    let(:agent_id) { "agent123" }
    let(:signed_url_response) do
      {
        "signed_url" => "https://example.com/conversation/signed_url_token"
      }
    end

    context "without optional parameters" do
      before do
        allow(client).to receive(:get).with("/v1/convai/conversation/get-signed-url?agent_id=#{agent_id}")
                                     .and_return(signed_url_response)
      end

      it "gets signed URL successfully" do
        result = conversations.get_signed_url(agent_id)
        expect(result).to eq(signed_url_response)
        expect(client).to have_received(:get).with("/v1/convai/conversation/get-signed-url?agent_id=#{agent_id}")
      end
    end

    context "with include_conversation_id parameter" do
      let(:signed_url_response_with_id) do
        {
          "signed_url" => "https://example.com/conversation/signed_url_token",
          "conversation_id" => "conv123"
        }
      end

      before do
        allow(client).to receive(:get).with("/v1/convai/conversation/get-signed-url?agent_id=#{agent_id}&include_conversation_id=true")
                                     .and_return(signed_url_response_with_id)
      end

      it "gets signed URL with conversation ID successfully" do
        result = conversations.get_signed_url(agent_id, include_conversation_id: true)
        expect(result).to eq(signed_url_response_with_id)
        expect(client).to have_received(:get).with("/v1/convai/conversation/get-signed-url?agent_id=#{agent_id}&include_conversation_id=true")
      end
    end
  end

  describe "#get_token" do
    let(:agent_id) { "agent123" }
    let(:token_response) do
      {
        "token" => "webrtc_session_token_here"
      }
    end

    context "without optional parameters" do
      before do
        allow(client).to receive(:get).with("/v1/convai/conversation/token?agent_id=#{agent_id}")
                                     .and_return(token_response)
      end

      it "gets WebRTC token successfully" do
        result = conversations.get_token(agent_id)
        expect(result).to eq(token_response)
        expect(client).to have_received(:get).with("/v1/convai/conversation/token?agent_id=#{agent_id}")
      end
    end

    context "with participant_name parameter" do
      let(:participant_name) { "John Doe" }

      before do
        allow(client).to receive(:get).with("/v1/convai/conversation/token?agent_id=#{agent_id}&participant_name=John+Doe")
                                     .and_return(token_response)
      end

      it "gets WebRTC token with participant name successfully" do
        result = conversations.get_token(agent_id, participant_name: participant_name)
        expect(result).to eq(token_response)
        expect(client).to have_received(:get).with("/v1/convai/conversation/token?agent_id=#{agent_id}&participant_name=John+Doe")
      end
    end
  end

  describe "#send_feedback" do
    let(:conversation_id) { "conv123" }
    let(:feedback_response) { {} }

    context "with like feedback" do
      before do
        allow(client).to receive(:post).with("/v1/convai/conversations/#{conversation_id}/feedback", { feedback: "like" })
                                      .and_return(feedback_response)
      end

      it "sends like feedback successfully" do
        result = conversations.send_feedback(conversation_id, "like")
        expect(result).to eq(feedback_response)
        expect(client).to have_received(:post).with("/v1/convai/conversations/#{conversation_id}/feedback", { feedback: "like" })
      end
    end

    context "with dislike feedback" do
      before do
        allow(client).to receive(:post).with("/v1/convai/conversations/#{conversation_id}/feedback", { feedback: "dislike" })
                                      .and_return(feedback_response)
      end

      it "sends dislike feedback successfully" do
        result = conversations.send_feedback(conversation_id, "dislike")
        expect(result).to eq(feedback_response)
        expect(client).to have_received(:post).with("/v1/convai/conversations/#{conversation_id}/feedback", { feedback: "dislike" })
      end
    end
  end

  describe "error handling" do
    let(:conversation_id) { "nonexistent_conversation" }

    context "when conversation is not found" do
      before do
        allow(client).to receive(:get).with("/v1/convai/conversations/#{conversation_id}")
                                     .and_raise(ElevenlabsClient::NotFoundError, "Conversation not found")
      end

      it "raises NotFoundError" do
        expect { conversations.get(conversation_id) }.to raise_error(ElevenlabsClient::NotFoundError, "Conversation not found")
      end
    end

    context "when agent is not found for signed URL" do
      let(:agent_id) { "nonexistent_agent" }

      before do
        allow(client).to receive(:get).with("/v1/convai/conversation/get-signed-url?agent_id=#{agent_id}")
                                     .and_raise(ElevenlabsClient::NotFoundError, "Agent not found")
      end

      it "raises NotFoundError" do
        expect { conversations.get_signed_url(agent_id) }.to raise_error(ElevenlabsClient::NotFoundError, "Agent not found")
      end
    end

    context "when authentication fails" do
      before do
        allow(client).to receive(:get).with("/v1/convai/conversations")
                                     .and_raise(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end

      it "raises AuthenticationError" do
        expect { conversations.list }.to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end
    end

    context "when validation fails for feedback" do
      let(:conversation_id) { "conv123" }

      before do
        allow(client).to receive(:post).with("/v1/convai/conversations/#{conversation_id}/feedback", { feedback: "invalid" })
                                      .and_raise(ElevenlabsClient::UnprocessableEntityError, "Invalid feedback value")
      end

      it "raises UnprocessableEntityError for invalid feedback" do
        expect { conversations.send_feedback(conversation_id, "invalid") }
          .to raise_error(ElevenlabsClient::UnprocessableEntityError, "Invalid feedback value")
      end
    end
  end

  describe "parameter handling" do
    describe "#list" do
      context "with nil parameters" do
        let(:params) { { agent_id: "agent123", page_size: nil, call_successful: "success" } }
        let(:expected_query) { "agent_id=agent123&call_successful=success" }

        before do
          allow(client).to receive(:get).with("/v1/convai/conversations?#{expected_query}")
                                       .and_return({ "conversations" => [], "has_more" => false })
        end

        it "filters out nil parameters" do
          conversations.list(**params)
          expect(client).to have_received(:get).with("/v1/convai/conversations?#{expected_query}")
        end
      end

      context "with empty parameters" do
        before do
          allow(client).to receive(:get).with("/v1/convai/conversations")
                                       .and_return({ "conversations" => [], "has_more" => false })
        end

        it "makes request without query parameters" do
          conversations.list
          expect(client).to have_received(:get).with("/v1/convai/conversations")
        end
      end
    end

    describe "#get_signed_url" do
      let(:agent_id) { "agent123" }

      context "with nil optional parameters" do
        let(:params) { { include_conversation_id: nil } }

        before do
          allow(client).to receive(:get).with("/v1/convai/conversation/get-signed-url?agent_id=#{agent_id}")
                                       .and_return({ "signed_url" => "test_url" })
        end

        it "filters out nil parameters" do
          conversations.get_signed_url(agent_id, **params)
          expect(client).to have_received(:get).with("/v1/convai/conversation/get-signed-url?agent_id=#{agent_id}")
        end
      end
    end

    describe "#get_token" do
      let(:agent_id) { "agent123" }

      context "with nil optional parameters" do
        let(:params) { { participant_name: nil } }

        before do
          allow(client).to receive(:get).with("/v1/convai/conversation/token?agent_id=#{agent_id}")
                                       .and_return({ "token" => "test_token" })
        end

        it "filters out nil parameters" do
          conversations.get_token(agent_id, **params)
          expect(client).to have_received(:get).with("/v1/convai/conversation/token?agent_id=#{agent_id}")
        end
      end
    end
  end

  describe "URL encoding" do
    describe "#get_signed_url" do
      let(:agent_id) { "agent with spaces" }

      before do
        allow(client).to receive(:get).with("/v1/convai/conversation/get-signed-url?agent_id=agent+with+spaces")
                                     .and_return({ "signed_url" => "test_url" })
      end

      it "properly URL encodes parameters" do
        conversations.get_signed_url(agent_id)
        expect(client).to have_received(:get).with("/v1/convai/conversation/get-signed-url?agent_id=agent+with+spaces")
      end
    end

    describe "#get_token" do
      let(:agent_id) { "agent123" }
      let(:participant_name) { "John & Jane Doe" }

      before do
        allow(client).to receive(:get).with("/v1/convai/conversation/token?agent_id=agent123&participant_name=John+%26+Jane+Doe")
                                     .and_return({ "token" => "test_token" })
      end

      it "properly URL encodes special characters" do
        conversations.get_token(agent_id, participant_name: participant_name)
        expect(client).to have_received(:get).with("/v1/convai/conversation/token?agent_id=agent123&participant_name=John+%26+Jane+Doe")
      end
    end
  end
end
