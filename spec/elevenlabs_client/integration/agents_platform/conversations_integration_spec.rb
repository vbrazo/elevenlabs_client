# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Conversations Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }

  describe "client.conversations accessor" do
    it "provides access to conversations endpoint" do
      expect(client.conversations).to be_an_instance_of(ElevenlabsClient::Endpoints::AgentsPlatform::Conversations)
    end
  end

  describe "conversation management functionality via client" do
    let(:conversation_id) { "conv123" }
    let(:agent_id) { "agent123" }

    describe "listing conversations" do
      let(:conversations_response) do
        {
          "conversations" => [
            {
              "agent_id" => agent_id,
              "conversation_id" => conversation_id,
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
          stub_request(:get, "https://api.elevenlabs.io/v1/convai/conversations")
            .with(headers: { "xi-api-key" => api_key })
            .to_return(
              status: 200,
              body: conversations_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "lists conversations through client interface" do
          result = client.conversations.list

          expect(result).to eq(conversations_response)
          expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/conversations")
            .with(headers: { "xi-api-key" => api_key })
        end
      end

      context "with query parameters" do
        let(:query_params) { "agent_id=agent123&page_size=10&call_successful=success&summary_mode=include" }

        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/convai/conversations?#{query_params}")
            .with(headers: { "xi-api-key" => api_key })
            .to_return(
              status: 200,
              body: conversations_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "lists conversations with filters through client interface" do
          result = client.conversations.list(
            agent_id: "agent123",
            page_size: 10,
            call_successful: "success",
            summary_mode: "include"
          )

          expect(result).to eq(conversations_response)
          expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/conversations?#{query_params}")
            .with(headers: { "xi-api-key" => api_key })
        end
      end
    end

    describe "getting conversation details" do
      let(:conversation_response) do
        {
          "agent_id" => agent_id,
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
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: conversation_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "gets conversation details through client interface" do
        result = client.conversations.get(conversation_id)

        expect(result).to eq(conversation_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "deleting conversation" do
      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: "{}",
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "deletes conversation through client interface" do
        result = client.conversations.delete(conversation_id)

        expect(result).to eq({})
        expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "getting conversation audio" do
      let(:audio_data) { "binary_audio_data_content" }

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}/audio")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "gets conversation audio through client interface" do
        result = client.conversations.get_audio(conversation_id)

        expect(result).to eq(audio_data)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}/audio")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "getting signed URL" do
      let(:signed_url_response) do
        {
          "signed_url" => "https://example.com/conversation/signed_url_token"
        }
      end

      context "without optional parameters" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/convai/conversation/get-signed-url?agent_id=#{agent_id}")
            .with(headers: { "xi-api-key" => api_key })
            .to_return(
              status: 200,
              body: signed_url_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "gets signed URL through client interface" do
          result = client.conversations.get_signed_url(agent_id)

          expect(result).to eq(signed_url_response)
          expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/conversation/get-signed-url?agent_id=#{agent_id}")
            .with(headers: { "xi-api-key" => api_key })
        end
      end

      context "with include_conversation_id parameter" do
        let(:signed_url_response_with_id) do
          {
            "signed_url" => "https://example.com/conversation/signed_url_token",
            "conversation_id" => "conv456"
          }
        end

        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/convai/conversation/get-signed-url?agent_id=#{agent_id}&include_conversation_id=true")
            .with(headers: { "xi-api-key" => api_key })
            .to_return(
              status: 200,
              body: signed_url_response_with_id.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "gets signed URL with conversation ID through client interface" do
          result = client.conversations.get_signed_url(agent_id, include_conversation_id: true)

          expect(result).to eq(signed_url_response_with_id)
          expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/conversation/get-signed-url?agent_id=#{agent_id}&include_conversation_id=true")
            .with(headers: { "xi-api-key" => api_key })
        end
      end
    end

    describe "getting WebRTC token" do
      let(:token_response) do
        {
          "token" => "webrtc_session_token_here"
        }
      end

      context "without optional parameters" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/convai/conversation/token?agent_id=#{agent_id}")
            .with(headers: { "xi-api-key" => api_key })
            .to_return(
              status: 200,
              body: token_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "gets WebRTC token through client interface" do
          result = client.conversations.get_token(agent_id)

          expect(result).to eq(token_response)
          expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/conversation/token?agent_id=#{agent_id}")
            .with(headers: { "xi-api-key" => api_key })
        end
      end

      context "with participant_name parameter" do
        let(:participant_name) { "John Doe" }

        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/convai/conversation/token?agent_id=#{agent_id}&participant_name=John+Doe")
            .with(headers: { "xi-api-key" => api_key })
            .to_return(
              status: 200,
              body: token_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "gets WebRTC token with participant name through client interface" do
          result = client.conversations.get_token(agent_id, participant_name: participant_name)

          expect(result).to eq(token_response)
          expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/conversation/token?agent_id=#{agent_id}&participant_name=John+Doe")
            .with(headers: { "xi-api-key" => api_key })
        end
      end
    end

    describe "sending conversation feedback" do
      context "with like feedback" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}/feedback")
            .with(
              body: { feedback: "like" }.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
            .to_return(
              status: 200,
              body: "{}",
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "sends like feedback through client interface" do
          result = client.conversations.send_feedback(conversation_id, "like")

          expect(result).to eq({})
          expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}/feedback")
            .with(
              body: { feedback: "like" }.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
        end
      end

      context "with dislike feedback" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}/feedback")
            .with(
              body: { feedback: "dislike" }.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
            .to_return(
              status: 200,
              body: "{}",
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "sends dislike feedback through client interface" do
          result = client.conversations.send_feedback(conversation_id, "dislike")

          expect(result).to eq({})
          expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}/feedback")
            .with(
              body: { feedback: "dislike" }.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
        end
      end
    end
  end

  describe "error handling integration" do
    let(:conversation_id) { "nonexistent_conversation" }
    let(:agent_id) { "nonexistent_agent" }

    describe "handling 404 errors" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 404,
            body: { "detail" => "Conversation not found" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises NotFoundError for missing conversation" do
        expect { client.conversations.get(conversation_id) }.to raise_error(ElevenlabsClient::NotFoundError)
      end
    end

    describe "handling 401 authentication errors" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/conversations")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 401,
            body: { "detail" => "Invalid API key" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises AuthenticationError for invalid API key" do
        expect { client.conversations.list }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    describe "handling 422 validation errors" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}/feedback")
          .with(
            body: { feedback: "invalid" }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 422,
            body: { "detail" => "Invalid feedback value" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises UnprocessableEntityError for invalid feedback" do
        expect { client.conversations.send_feedback(conversation_id, "invalid") }
          .to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end

    describe "handling agent not found for signed URL" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/conversation/get-signed-url?agent_id=#{agent_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 404,
            body: { "detail" => "Agent not found" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises NotFoundError for missing agent" do
        expect { client.conversations.get_signed_url(agent_id) }.to raise_error(ElevenlabsClient::NotFoundError)
      end
    end
  end

  describe "URL encoding integration" do
    let(:agent_id) { "agent with spaces" }
    let(:participant_name) { "John & Jane Doe" }

    describe "signed URL with special characters" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/conversation/get-signed-url?agent_id=agent+with+spaces")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: { "signed_url" => "test_url" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "properly URL encodes agent_id with spaces" do
        client.conversations.get_signed_url(agent_id)

        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/conversation/get-signed-url?agent_id=agent+with+spaces")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "WebRTC token with special characters" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/conversation/token?agent_id=agent+with+spaces&participant_name=John+%26+Jane+Doe")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: { "token" => "test_token" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "properly URL encodes parameters with special characters" do
        client.conversations.get_token(agent_id, participant_name: participant_name)

        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/conversation/token?agent_id=agent+with+spaces&participant_name=John+%26+Jane+Doe")
          .with(headers: { "xi-api-key" => api_key })
      end
    end
  end

  describe "full workflow integration" do
    let(:agent_id) { "agent123" }
    let(:conversation_id) { "conv123" }

    it "supports complete conversation lifecycle" do
      # List conversations
      stub_request(:get, "https://api.elevenlabs.io/v1/convai/conversations?agent_id=#{agent_id}")
        .to_return(
          status: 200,
          body: {
            "conversations" => [{ "conversation_id" => conversation_id, "agent_id" => agent_id }],
            "has_more" => false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Get conversation details
      stub_request(:get, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}")
        .to_return(
          status: 200,
          body: {
            "conversation_id" => conversation_id,
            "agent_id" => agent_id,
            "status" => "done"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Get audio
      stub_request(:get, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}/audio")
        .to_return(
          status: 200,
          body: "audio_data",
          headers: { "Content-Type" => "audio/mpeg" }
        )

      # Send feedback
      stub_request(:post, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}/feedback")
        .to_return(
          status: 200,
          body: "{}",
          headers: { "Content-Type" => "application/json" }
        )

      # Get signed URL
      stub_request(:get, "https://api.elevenlabs.io/v1/convai/conversation/get-signed-url?agent_id=#{agent_id}")
        .to_return(
          status: 200,
          body: { "signed_url" => "test_url" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Get token
      stub_request(:get, "https://api.elevenlabs.io/v1/convai/conversation/token?agent_id=#{agent_id}")
        .to_return(
          status: 200,
          body: { "token" => "test_token" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Delete conversation
      stub_request(:delete, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}")
        .to_return(
          status: 200,
          body: "{}",
          headers: { "Content-Type" => "application/json" }
        )

      # Execute workflow
      list_result = client.conversations.list(agent_id: agent_id)
      expect(list_result["conversations"].first["conversation_id"]).to eq(conversation_id)

      get_result = client.conversations.get(conversation_id)
      expect(get_result["conversation_id"]).to eq(conversation_id)

      audio_result = client.conversations.get_audio(conversation_id)
      expect(audio_result).to eq("audio_data")

      feedback_result = client.conversations.send_feedback(conversation_id, "like")
      expect(feedback_result).to eq({})

      signed_url_result = client.conversations.get_signed_url(agent_id)
      expect(signed_url_result["signed_url"]).to eq("test_url")

      token_result = client.conversations.get_token(agent_id)
      expect(token_result["token"]).to eq("test_token")

      delete_result = client.conversations.delete(conversation_id)
      expect(delete_result).to eq({})

      # Verify all requests were made
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/conversations?agent_id=#{agent_id}")
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}")
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}/audio")
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}/feedback")
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/conversation/get-signed-url?agent_id=#{agent_id}")
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/conversation/token?agent_id=#{agent_id}")
      expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/convai/conversations/#{conversation_id}")
    end
  end
end
