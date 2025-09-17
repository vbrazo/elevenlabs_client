# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe "Widgets Integration" do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test-api-key") }
  let(:agent_id) { "agent_test_123" }
  let(:base_url) { "https://api.elevenlabs.io" }

  describe "Widget Configuration Management" do
    describe "GET /v1/convai/agents/{agent_id}/widget" do
      let(:endpoint) { "#{base_url}/v1/convai/agents/#{agent_id}/widget" }

      context "successful widget configuration retrieval" do
        let(:widget_response) do
          {
            agent_id: agent_id,
            widget_config: {
              language: "en",
              variant: "tiny",
              placement: "bottom-right",
              expandable: "never",
              avatar: {
                type: "orb",
                color_1: "#2792dc",
                color_2: "#9ce6e6"
              },
              feedback_mode: "none",
              bg_color: "#ffffff",
              text_color: "#000000",
              btn_color: "#000000",
              btn_text_color: "#ffffff",
              border_color: "#e1e1e1",
              focus_color: "#000000",
              border_radius: 1,
              btn_radius: 1,
              action_text: "Talk to our AI",
              start_call_text: "Start Call",
              end_call_text: "End Call",
              expand_text: "Expand",
              listening_text: "Listening...",
              speaking_text: "Speaking...",
              shareable_page_text: "Share this conversation",
              shareable_page_show_terms: true,
              terms_text: "Terms and Conditions",
              terms_html: "<p>Terms and conditions content</p>",
              terms_key: "terms_key_123",
              show_avatar_when_collapsed: true,
              disable_banner: false,
              override_link: "https://custom-link.com",
              mic_muting_enabled: false,
              transcript_enabled: false,
              text_input_enabled: true,
              default_expanded: false,
              always_expanded: false,
              text_contents: {
                main_label: "AI Assistant",
                start_call: "Start talking",
                start_chat: "Start chatting",
                new_call: "New conversation",
                end_call: "End conversation",
                mute_microphone: "Mute",
                change_language: "Change language",
                collapse: "Minimize",
                expand: "Expand",
                copied: "Copied!",
                accept_terms: "Accept Terms",
                dismiss_terms: "Dismiss",
                listening_status: "Listening...",
                speaking_status: "Speaking...",
                connecting_status: "Connecting...",
                chatting_status: "Chatting...",
                input_label: "Type your message",
                input_placeholder: "Type here...",
                input_placeholder_text_only: "Text only mode",
                input_placeholder_new_conversation: "Start a new conversation",
                user_ended_conversation: "You ended the conversation",
                agent_ended_conversation: "Agent ended the conversation",
                conversation_id: "Conversation ID",
                error_occurred: "An error occurred",
                copy_id: "Copy ID"
              },
              styles: {
                base: "#ffffff",
                base_hover: "#f8f9fa",
                base_active: "#e9ecef",
                base_border: "#dee2e6",
                base_subtle: "#6c757d",
                base_primary: "#007bff",
                base_error: "#dc3545",
                accent: "#28a745",
                accent_hover: "#218838",
                accent_active: "#1e7e34",
                accent_border: "#1e7e34",
                accent_subtle: "#d4edda",
                accent_primary: "#155724",
                overlay_padding: 1.1,
                button_radius: 1.1,
                input_radius: 1.1,
                bubble_radius: 1.1,
                sheet_radius: 1.1,
                compact_sheet_radius: 1.1,
                dropdown_sheet_radius: 1.1
              },
              supported_language_overrides: ["en", "es", "fr"],
              language_presets: {},
              text_only: false,
              supports_text_only: true,
              first_message: "Hello! How can I help you today?",
              use_rtc: true
            }
          }
        end

        before do
          stub_request(:get, endpoint)
            .with(headers: { "xi-api-key" => "test-api-key" })
            .to_return(
              status: 200,
              body: widget_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "retrieves widget configuration successfully" do
          result = client.widgets.get(agent_id)

          expect(result["agent_id"]).to eq(agent_id)
          expect(result["widget_config"]["variant"]).to eq("tiny")
          expect(result["widget_config"]["placement"]).to eq("bottom-right")
          expect(result["widget_config"]["avatar"]["type"]).to eq("orb")
          expect(result["widget_config"]["text_input_enabled"]).to be true
          expect(result["widget_config"]["supported_language_overrides"]).to include("en", "es", "fr")
        end

        it "includes comprehensive widget configuration" do
          result = client.widgets.get(agent_id)
          widget_config = result["widget_config"]

          # Verify core settings
          expect(widget_config["language"]).to eq("en")
          expect(widget_config["feedback_mode"]).to eq("none")
          expect(widget_config["use_rtc"]).to be true

          # Verify colors
          expect(widget_config["bg_color"]).to eq("#ffffff")
          expect(widget_config["text_color"]).to eq("#000000")
          expect(widget_config["btn_color"]).to eq("#000000")

          # Verify text content customization
          text_contents = widget_config["text_contents"]
          expect(text_contents["main_label"]).to eq("AI Assistant")
          expect(text_contents["start_call"]).to eq("Start talking")
          expect(text_contents["input_placeholder"]).to eq("Type here...")

          # Verify advanced styling
          styles = widget_config["styles"]
          expect(styles["base"]).to eq("#ffffff")
          expect(styles["accent"]).to eq("#28a745")
          expect(styles["button_radius"]).to eq(1.1)
        end
      end

      context "with conversation signature parameter" do
        let(:conversation_signature) { "signature_token_abc123" }
        let(:endpoint_with_signature) { "#{endpoint}?conversation_signature=#{conversation_signature}" }

        before do
          stub_request(:get, endpoint_with_signature)
            .with(headers: { "xi-api-key" => "test-api-key" })
            .to_return(
              status: 200,
              body: { agent_id: agent_id, widget_config: {} }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "includes conversation signature in request" do
          client.widgets.get(agent_id, conversation_signature: conversation_signature)

          expect(WebMock).to have_requested(:get, endpoint_with_signature)
            .with(headers: { "xi-api-key" => "test-api-key" })
        end
      end

      context "error scenarios" do
        context "when agent not found" do
          before do
            stub_request(:get, endpoint)
              .with(headers: { "xi-api-key" => "test-api-key" })
              .to_return(
                status: 404,
                body: { detail: "Agent not found" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "raises NotFoundError" do
            expect {
              client.widgets.get(agent_id)
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
              client.widgets.get(agent_id)
            }.to raise_error(ElevenlabsClient::AuthenticationError)
          end
        end

        context "when validation fails" do
          before do
            stub_request(:get, endpoint)
              .with(headers: { "xi-api-key" => "test-api-key" })
              .to_return(
                status: 422,
                body: { detail: "Invalid agent ID format" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "raises UnprocessableEntityError" do
            expect {
              client.widgets.get(agent_id)
            }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
          end
        end
      end
    end

    describe "POST /v1/convai/agents/{agent_id}/avatar" do
      let(:endpoint) { "#{base_url}/v1/convai/agents/#{agent_id}/avatar" }
      let(:avatar_file_content) { "fake_image_binary_data" }
      let(:filename) { "test_avatar.png" }

      context "successful avatar upload" do
        let(:upload_response) do
          {
            agent_id: agent_id,
            avatar_url: "https://storage.googleapis.com/elevenlabs-avatars/#{agent_id}/avatar.png"
          }
        end

        before do
          stub_request(:post, endpoint)
            .with(
              headers: { 
                "xi-api-key" => "test-api-key",
                "Content-Type" => /multipart\/form-data/
              }
            )
            .to_return(
              status: 200,
              body: upload_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "uploads avatar successfully" do
          avatar_file = StringIO.new(avatar_file_content)
          
          result = client.widgets.create_avatar(
            agent_id,
            avatar_file_io: avatar_file,
            filename: filename
          )

          expect(result["agent_id"]).to eq(agent_id)
          expect(result["avatar_url"]).to include("avatars")
          expect(result["avatar_url"]).to include(agent_id)
        end

        it "sends multipart form data with correct structure" do
          avatar_file = StringIO.new(avatar_file_content)
          
          client.widgets.create_avatar(
            agent_id,
            avatar_file_io: avatar_file,
            filename: filename
          )

          expect(WebMock).to have_requested(:post, endpoint)
            .with(
              headers: { 
                "xi-api-key" => "test-api-key",
                "Content-Type" => /multipart\/form-data/
              }
            )
        end
      end

      context "different file types" do
        let(:jpg_response) do
          {
            agent_id: agent_id,
            avatar_url: "https://storage.googleapis.com/elevenlabs-avatars/#{agent_id}/avatar.jpg"
          }
        end

        before do
          stub_request(:post, endpoint)
            .to_return(
              status: 200,
              body: jpg_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "handles JPG uploads" do
          avatar_file = StringIO.new(avatar_file_content)
          
          result = client.widgets.create_avatar(
            agent_id,
            avatar_file_io: avatar_file,
            filename: "avatar.jpg"
          )

          expect(result["avatar_url"]).to include(".jpg")
        end

        it "handles GIF uploads" do
          avatar_file = StringIO.new(avatar_file_content)
          
          client.widgets.create_avatar(
            agent_id,
            avatar_file_io: avatar_file,
            filename: "avatar.gif"
          )

          expect(WebMock).to have_requested(:post, endpoint)
        end
      end

      context "upload error scenarios" do
        context "when file is too large" do
          before do
            stub_request(:post, endpoint)
              .to_return(
                status: 422,
                body: { detail: "File size exceeds maximum limit" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "raises UnprocessableEntityError for oversized files" do
            avatar_file = StringIO.new(avatar_file_content)
            
            expect {
              client.widgets.create_avatar(
                agent_id,
                avatar_file_io: avatar_file,
                filename: filename
              )
            }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
          end
        end

        context "when file format is unsupported" do
          before do
            stub_request(:post, endpoint)
              .to_return(
                status: 422,
                body: { detail: "Unsupported file format" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "raises UnprocessableEntityError for unsupported formats" do
            avatar_file = StringIO.new(avatar_file_content)
            
            expect {
              client.widgets.create_avatar(
                agent_id,
                avatar_file_io: avatar_file,
                filename: "avatar.bmp"
              )
            }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
          end
        end

        context "when upload service is unavailable" do
          before do
            stub_request(:post, endpoint)
              .to_return(
                status: 500,
                body: { detail: "Upload service temporarily unavailable" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "raises APIError for service issues" do
            avatar_file = StringIO.new(avatar_file_content)
            
            expect {
              client.widgets.create_avatar(
                agent_id,
                avatar_file_io: avatar_file,
                filename: filename
              )
            }.to raise_error(ElevenlabsClient::APIError)
          end
        end
      end
    end
  end

  describe "Widget Management Workflow" do
    let(:widget_endpoint) { "#{base_url}/v1/convai/agents/#{agent_id}/widget" }
    let(:avatar_endpoint) { "#{base_url}/v1/convai/agents/#{agent_id}/avatar" }

    context "complete widget customization workflow" do
      let(:initial_config_response) do
        {
          agent_id: agent_id,
          widget_config: {
            variant: "compact",
            placement: "bottom-left",
            avatar: { type: "default" },
            bg_color: "#ffffff",
            text_input_enabled: true
          }
        }
      end

      let(:avatar_upload_response) do
        {
          agent_id: agent_id,
          avatar_url: "https://storage.googleapis.com/elevenlabs-avatars/#{agent_id}/custom.png"
        }
      end

      let(:updated_config_response) do
        {
          agent_id: agent_id,
          widget_config: {
            variant: "compact",
            placement: "bottom-left",
            avatar: { 
              type: "custom",
              url: "https://storage.googleapis.com/elevenlabs-avatars/#{agent_id}/custom.png"
            },
            bg_color: "#ffffff",
            text_input_enabled: true
          }
        }
      end

      before do
        # Configure sequential responses for widget GET endpoint
        stub_request(:get, widget_endpoint)
          .to_return(
            status: 200,
            body: initial_config_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
          .then
          .to_return(
            status: 200,
            body: updated_config_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
          .then
          .to_return(
            status: 200,
            body: updated_config_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Step 2: Upload custom avatar
        stub_request(:post, avatar_endpoint)
          .to_return(
            status: 200,
            body: avatar_upload_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "completes full widget customization workflow" do
        # Step 1: Get current widget configuration
        initial_config = client.widgets.get(agent_id)
        expect(initial_config["widget_config"]["avatar"]["type"]).to eq("default")

        # Step 2: Upload custom avatar
        avatar_file = StringIO.new("fake_image_data")
        avatar_result = client.widgets.create_avatar(
          agent_id,
          avatar_file_io: avatar_file,
          filename: "custom_avatar.png"
        )
        expect(avatar_result["avatar_url"]).to include("custom.png")

        # Step 3: Verify updated configuration
        updated_config = client.widgets.get(agent_id)
        expect(updated_config["widget_config"]["avatar"]["type"]).to eq("custom")
        expect(updated_config["widget_config"]["avatar"]["url"]).to include("custom.png")

        # Verify all requests were made
        expect(WebMock).to have_requested(:get, widget_endpoint).times(2)
        expect(WebMock).to have_requested(:post, avatar_endpoint).once
      end
    end
  end

  describe "Error Recovery and Retry Logic" do
    let(:endpoint) { "#{base_url}/v1/convai/agents/#{agent_id}/widget" }

    context "transient network errors" do
      before do
        # First request fails, second succeeds
        stub_request(:get, endpoint)
          .to_return(status: 500)
          .then
          .to_return(
            status: 200,
            body: { agent_id: agent_id, widget_config: {} }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "handles transient failures gracefully" do
        # First attempt should fail
        expect {
          client.widgets.get(agent_id)
        }.to raise_error(ElevenlabsClient::APIError)

        # Second attempt should succeed
        result = client.widgets.get(agent_id)
        expect(result["agent_id"]).to eq(agent_id)
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
          client.widgets.get(agent_id)
        }.to raise_error(ElevenlabsClient::RateLimitError)
      end
    end
  end
end
