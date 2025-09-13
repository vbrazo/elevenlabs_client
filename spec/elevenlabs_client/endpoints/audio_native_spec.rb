# frozen_string_literal: true

RSpec.describe ElevenlabsClient::AudioNative do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:audio_native) { described_class.new(client) }
  let(:project_name) { "Test Project" }
  let(:project_id) { "JBFqnCBsd6RMkjVDRZzb" }

  describe "#create" do
    let(:response_data) do
      {
        "project_id" => project_id,
        "converting" => false,
        "html_snippet" => "<div id='audio-native-player'></div>"
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/audio-native")
        .to_return(
          status: 200,
          body: response_data.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    context "with required parameters only" do
      it "creates audio native project successfully" do
        result = audio_native.create(project_name)

        expect(result).to eq(response_data)
      end

      it "sends the correct multipart request" do
        audio_native.create(project_name)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-native")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with optional parameters" do
      let(:options) do
        {
          author: "John Doe",
          title: "My Article",
          small: false,
          text_color: "#000000",
          background_color: "#FFFFFF",
          sessionization: 1,
          voice_id: "21m00Tcm4TlvDq8ikWAM",
          model_id: "eleven_multilingual_v1",
          auto_convert: true,
          apply_text_normalization: "auto"
        }
      end

      it "includes optional parameters in the request" do
        audio_native.create(project_name, **options)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-native")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with file upload" do
      let(:file_content) { StringIO.new("<html><body><p>Test content</p></body></html>") }
      let(:filename) { "test_article.html" }

      it "includes file in the multipart request" do
        audio_native.create(project_name, file: file_content, filename: filename)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-native")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with deprecated parameters" do
      let(:deprecated_options) do
        {
          image: "https://example.com/image.jpg",
          small: true,
          sessionization: 5
        }
      end

      it "includes deprecated parameters in the request" do
        audio_native.create(project_name, **deprecated_options)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-native")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "when API returns an error" do
      context "with authentication error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/audio-native")
            .to_return(status: 401, body: "Unauthorized")
        end

        it "raises AuthenticationError" do
          expect {
            audio_native.create(project_name)
          }.to raise_error(ElevenlabsClient::AuthenticationError)
        end
      end

      context "with unprocessable entity error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/audio-native")
            .to_return(
              status: 422,
              body: {
                detail: [
                  {
                    loc: ["name"],
                    msg: "Project name is required",
                    type: "value_error"
                  }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "raises UnprocessableEntityError" do
          expect {
            audio_native.create(project_name)
          }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
        end
      end
    end
  end

  describe "#update_content" do
    let(:response_data) do
      {
        "project_id" => project_id,
        "converting" => false,
        "publishing" => false,
        "html_snippet" => "<div id='audio-native-player'></div>"
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/content")
        .to_return(
          status: 200,
          body: response_data.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    context "with required parameters only" do
      it "updates project content successfully" do
        result = audio_native.update_content(project_id)

        expect(result).to eq(response_data)
      end

      it "sends the correct multipart request" do
        audio_native.update_content(project_id)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/content")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with optional parameters" do
      let(:options) do
        {
          auto_convert: true,
          auto_publish: false
        }
      end

      it "includes optional parameters in the request" do
        audio_native.update_content(project_id, **options)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/content")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with file upload" do
      let(:file_content) { StringIO.new("Updated article content") }
      let(:filename) { "updated_article.txt" }

      it "includes file in the multipart request" do
        audio_native.update_content(project_id, file: file_content, filename: filename)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/content")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "when API returns an error" do
      context "with not found error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/content")
            .to_return(status: 404, body: "Project not found")
        end

        it "raises NotFoundError" do
          expect {
            audio_native.update_content(project_id)
          }.to raise_error(ElevenlabsClient::NotFoundError)
        end
      end
    end
  end

  describe "#get_settings" do
    let(:settings_data) do
      {
        "enabled" => true,
        "snapshot_id" => "JBFqnCBsd6RMkjVDRZzb",
        "settings" => {
          "title" => "My Project",
          "image" => "https://example.com/image.jpg",
          "author" => "John Doe",
          "small" => false,
          "text_color" => "#000000",
          "background_color" => "#FFFFFF",
          "sessionization" => 1,
          "audio_path" => "audio/my_project.mp3",
          "audio_url" => "https://example.com/audio/my_project.mp3",
          "status" => "ready"
        }
      }
    end

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/settings")
        .to_return(
          status: 200,
          body: settings_data.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    context "with valid project_id" do
      it "retrieves project settings successfully" do
        result = audio_native.get_settings(project_id)

        expect(result).to eq(settings_data)
      end

      it "sends the correct GET request" do
        audio_native.get_settings(project_id)

        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/settings")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "when API returns an error" do
      context "with not found error" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/settings")
            .to_return(status: 404, body: "Project not found")
        end

        it "raises NotFoundError" do
          expect {
            audio_native.get_settings(project_id)
          }.to raise_error(ElevenlabsClient::NotFoundError)
        end
      end

      context "with unprocessable entity error" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/settings")
            .to_return(
              status: 422,
              body: {
                detail: [
                  {
                    loc: ["project_id"],
                    msg: "Invalid project ID format",
                    type: "value_error"
                  }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "raises UnprocessableEntityError" do
          expect {
            audio_native.get_settings(project_id)
          }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
        end
      end
    end
  end

  describe "alias methods" do
    let(:response_data) do
      {
        "project_id" => project_id,
        "converting" => false,
        "html_snippet" => "<div id='audio-native-player'></div>"
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/audio-native")
        .to_return(
          status: 200,
          body: response_data.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      stub_request(:post, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/content")
        .to_return(
          status: 200,
          body: response_data.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      stub_request(:get, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/settings")
        .to_return(
          status: 200,
          body: { "enabled" => true }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    describe "#create_project" do
      it "is an alias for create method" do
        result = audio_native.create_project(project_name)

        expect(result).to eq(response_data)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-native")
      end
    end

    describe "#update_project_content" do
      it "is an alias for update_content method" do
        result = audio_native.update_project_content(project_id)

        expect(result).to eq(response_data)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/content")
      end
    end

    describe "#project_settings" do
      it "is an alias for get_settings method" do
        result = audio_native.project_settings(project_id)

        expect(result).to eq({ "enabled" => true })
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/settings")
      end
    end
  end
end
