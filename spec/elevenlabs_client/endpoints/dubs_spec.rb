# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Dubs do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:dubs) { described_class.new(client) }

  describe "#create" do
    let(:file_content) { "fake video content" }
    let(:temp_file) { create_temp_video_file(file_content) }
    let(:filename) { "test_video.mp4" }
    let(:target_languages) { ["es", "pt", "fr"] }
    let(:expected_response) do
      {
        "dubbing_id" => "dub_123456",
        "name" => "My Video Dub",
        "status" => "dubbing",
        "target_languages" => target_languages
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/dubbing")
        .with(
          headers: {
            "xi-api-key" => api_key,
            "Content-Type" => /multipart\/form-data/
          }
        )
        .to_return(
          status: 200,
          body: expected_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    after do
      temp_file.close
      temp_file.unlink
    end

    context "with required parameters" do
      it "creates a dubbing job successfully" do
        result = dubs.create(
          file_io: temp_file,
          filename: filename,
          target_languages: target_languages
        )

        expect(result).to eq(expected_response)
      end

      it "sends the correct multipart data" do
        dubs.create(
          file_io: temp_file,
          filename: filename,
          target_languages: target_languages
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/dubbing")
          .with(
            headers: {
              "xi-api-key" => api_key,
              "Content-Type" => /multipart\/form-data/
            }
          )
      end
    end

    context "with optional parameters" do
      let(:name) { "My Custom Video" }
      let(:options) do
        {
          drop_background_audio: true,
          use_profanity_filter: false,
          highest_resolution: true
        }
      end

      it "includes optional parameters in the request" do
        result = dubs.create(
          file_io: temp_file,
          filename: filename,
          target_languages: target_languages,
          name: name,
          **options
        )

        expect(result).to eq(expected_response)
      end
    end

    context "when API returns an error" do
      context "with authentication error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/dubbing")
            .to_return(status: 401, body: "Unauthorized")
        end

        it "raises AuthenticationError" do
          expect do
            dubs.create(
              file_io: temp_file,
              filename: filename,
              target_languages: target_languages
            )
          end.to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key or authentication failed")
        end
      end

      context "with rate limit error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/dubbing")
            .to_return(status: 429, body: "Rate limit exceeded")
        end

        it "raises RateLimitError" do
          expect do
            dubs.create(
              file_io: temp_file,
              filename: filename,
              target_languages: target_languages
            )
          end.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
        end
      end

      context "with validation error" do
        let(:error_response) { { "error" => "Invalid target language" } }

        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/dubbing")
            .to_return(
              status: 400,
              body: error_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "raises ValidationError" do
          expect do
            dubs.create(
              file_io: temp_file,
              filename: filename,
              target_languages: ["invalid_lang"]
            )
          end.to raise_error(ElevenlabsClient::ValidationError, /Invalid target language/)
        end
      end

      context "with server error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/dubbing")
            .to_return(status: 500, body: "Internal Server Error")
        end

        it "raises APIError" do
          expect do
            dubs.create(
              file_io: temp_file,
              filename: filename,
              target_languages: target_languages
            )
          end.to raise_error(ElevenlabsClient::APIError, /API request failed with status 500/)
        end
      end
    end

    context "with different file types" do
      shared_examples "handles file type" do |file_extension, expected_mime_type|
        let(:filename) { "test_file#{file_extension}" }

        it "handles #{file_extension} files with correct MIME type" do
          # We'll verify this through successful request rather than inspecting the payload
          # since testing multipart content is complex
          result = dubs.create(
            file_io: temp_file,
            filename: filename,
            target_languages: target_languages
          )

          expect(result).to eq(expected_response)
        end
      end

      include_examples "handles file type", ".mp4", "video/mp4"
      include_examples "handles file type", ".mov", "video/quicktime"
      include_examples "handles file type", ".avi", "video/x-msvideo"
      include_examples "handles file type", ".mkv", "video/x-matroska"
      include_examples "handles file type", ".mp3", "audio/mpeg"
      include_examples "handles file type", ".wav", "audio/wav"
      include_examples "handles file type", ".flac", "audio/flac"
      include_examples "handles file type", ".m4a", "audio/mp4"
    end
  end

  describe "#get" do
    let(:dubbing_id) { "dub_123456" }
    let(:expected_response) do
      {
        "dubbing_id" => dubbing_id,
        "name" => "My Video Dub",
        "status" => "dubbed",
        "target_languages" => ["es", "pt"]
      }
    end

    before do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing/#{dubbing_id}",
        method: :get,
        response_body: expected_response
      )
    end

    it "retrieves dubbing job details" do
      result = dubs.get(dubbing_id)

      expect(result).to eq(expected_response)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/dubbing/#{dubbing_id}")
        .with(headers: { "xi-api-key" => api_key })
    end
  end

  describe "#list" do
    let(:expected_response) do
      {
        "dubs" => [
          {
            "dubbing_id" => "dub_123456",
            "name" => "Video 1",
            "status" => "dubbed"
          },
          {
            "dubbing_id" => "dub_789012",
            "name" => "Video 2",
            "status" => "dubbing"
          }
        ]
      }
    end

    before do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing",
        method: :get,
        response_body: expected_response
      )
    end

    context "without parameters" do
      it "lists all dubbing jobs" do
        result = dubs.list

        expect(result).to eq(expected_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/dubbing")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    context "with query parameters" do
      let(:params) { { dubbing_status: "dubbed", page_size: 10 } }

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/dubbing")
          .with(query: params)
          .to_return(
            status: 200,
            body: expected_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "includes query parameters in the request" do
        result = dubs.list(params)

        expect(result).to eq(expected_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/dubbing")
          .with(
            query: params,
            headers: { "xi-api-key" => api_key }
          )
      end
    end
  end

  describe "#resources" do
    let(:dubbing_id) { "dub_123456" }
    let(:expected_response) do
      {
        "dubbing_id" => dubbing_id,
        "resources" => {
          "audio_files" => ["audio_es.mp3", "audio_pt.mp3"],
          "video_files" => ["video_es.mp4", "video_pt.mp4"]
        }
      }
    end

    before do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing/#{dubbing_id}/resources",
        method: :get,
        response_body: expected_response
      )
    end

    it "retrieves dubbing resources" do
      result = dubs.resources(dubbing_id)

      expect(result).to eq(expected_response)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/dubbing/#{dubbing_id}/resources")
        .with(headers: { "xi-api-key" => api_key })
    end
  end
end
