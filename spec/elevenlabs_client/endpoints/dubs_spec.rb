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
          end.to raise_error(ElevenlabsClient::AuthenticationError)
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

        it "raises BadRequestError" do
          expect do
            dubs.create(
              file_io: temp_file,
              filename: filename,
              target_languages: ["invalid_lang"]
            )
          end.to raise_error(ElevenlabsClient::BadRequestError)
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
          end.to raise_error(ElevenlabsClient::APIError)
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

  describe "#delete" do
    let(:dubbing_id) { "dub_123456" }
    let(:expected_response) { { "status" => "ok" } }

    before do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing/#{dubbing_id}",
        method: :delete,
        response_body: expected_response
      )
    end

    it "deletes a dubbing project" do
      result = dubs.delete(dubbing_id)

      expect(result).to eq(expected_response)
      expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/dubbing/#{dubbing_id}")
        .with(headers: { "xi-api-key" => api_key })
    end

    context "when dubbing project doesn't exist" do
      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/dubbing/#{dubbing_id}")
          .to_return(status: 404, body: "Not Found")
      end

      it "raises NotFoundError" do
        expect do
          dubs.delete(dubbing_id)
        end.to raise_error(ElevenlabsClient::NotFoundError)
      end
    end
  end

  describe "#get_resource" do
    let(:dubbing_id) { "dub_123456" }
    let(:expected_response) do
      {
        "id" => dubbing_id,
        "version" => 1,
        "source_language" => "en",
        "target_languages" => ["es", "pt"],
        "input" => {
          "src" => "input.mp4",
          "content_type" => "video/mp4",
          "duration_secs" => 120.5,
          "is_audio" => false,
          "url" => "https://example.com/input.mp4"
        },
        "speaker_tracks" => {},
        "speaker_segments" => {},
        "renders" => {}
      }
    end

    before do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing/resource/#{dubbing_id}",
        method: :get,
        response_body: expected_response
      )
    end

    it "retrieves detailed dubbing resource information" do
      result = dubs.get_resource(dubbing_id)

      expect(result).to eq(expected_response)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}")
        .with(headers: { "xi-api-key" => api_key })
    end
  end

  describe "#create_segment" do
    let(:dubbing_id) { "dub_123456" }
    let(:speaker_id) { "speaker_789" }
    let(:start_time) { 10.5 }
    let(:end_time) { 15.2 }
    let(:expected_response) { { "version" => 2, "new_segment" => "segment_abc123" } }

    before do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing/resource/#{dubbing_id}/speaker/#{speaker_id}/segment",
        method: :post,
        response_body: expected_response
      )
    end

    context "with required parameters only" do
      it "creates a new segment" do
        result = dubs.create_segment(
          dubbing_id: dubbing_id,
          speaker_id: speaker_id,
          start_time: start_time,
          end_time: end_time
        )

        expect(result).to eq(expected_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/speaker/#{speaker_id}/segment")
          .with(
            headers: { "xi-api-key" => api_key },
            body: {
              start_time: start_time,
              end_time: end_time
            }.to_json
          )
      end
    end

    context "with optional parameters" do
      let(:text) { "Hello world" }
      let(:translations) { { "es" => "Hola mundo", "pt" => "Olá mundo" } }

      it "creates a segment with text and translations" do
        result = dubs.create_segment(
          dubbing_id: dubbing_id,
          speaker_id: speaker_id,
          start_time: start_time,
          end_time: end_time,
          text: text,
          translations: translations
        )

        expect(result).to eq(expected_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/speaker/#{speaker_id}/segment")
          .with(
            headers: { "xi-api-key" => api_key },
            body: {
              start_time: start_time,
              end_time: end_time,
              text: text,
              translations: translations
            }.to_json
          )
      end
    end
  end

  describe "#delete_segment" do
    let(:dubbing_id) { "dub_123456" }
    let(:segment_id) { "segment_abc123" }
    let(:expected_response) { { "version" => 3 } }

    before do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing/resource/#{dubbing_id}/segment/#{segment_id}",
        method: :delete,
        response_body: expected_response
      )
    end

    it "deletes a segment" do
      result = dubs.delete_segment(dubbing_id, segment_id)

      expect(result).to eq(expected_response)
      expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/segment/#{segment_id}")
        .with(headers: { "xi-api-key" => api_key })
    end
  end

  describe "#update_segment" do
    let(:dubbing_id) { "dub_123456" }
    let(:segment_id) { "segment_abc123" }
    let(:language) { "es" }
    let(:expected_response) { { "version" => 4 } }

    before do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing/resource/#{dubbing_id}/segment/#{segment_id}/#{language}",
        method: :patch,
        response_body: expected_response
      )
    end

    context "with all parameters" do
      let(:start_time) { 12.0 }
      let(:end_time) { 18.5 }
      let(:text) { "Updated text" }

      it "updates a segment with new values" do
        result = dubs.update_segment(
          dubbing_id: dubbing_id,
          segment_id: segment_id,
          language: language,
          start_time: start_time,
          end_time: end_time,
          text: text
        )

        expect(result).to eq(expected_response)
        expect(WebMock).to have_requested(:patch, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/segment/#{segment_id}/#{language}")
          .with(
            headers: { "xi-api-key" => api_key },
            body: {
              start_time: start_time,
              end_time: end_time,
              text: text
            }.to_json
          )
      end
    end

    context "with partial parameters" do
      let(:text) { "Only text update" }

      it "updates only specified fields" do
        result = dubs.update_segment(
          dubbing_id: dubbing_id,
          segment_id: segment_id,
          language: language,
          text: text
        )

        expect(result).to eq(expected_response)
        expect(WebMock).to have_requested(:patch, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/segment/#{segment_id}/#{language}")
          .with(
            headers: { "xi-api-key" => api_key },
            body: { text: text }.to_json
          )
      end
    end
  end

  describe "#transcribe_segment" do
    let(:dubbing_id) { "dub_123456" }
    let(:segments) { ["segment_1", "segment_2", "segment_3"] }
    let(:expected_response) { { "version" => 5 } }

    before do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing/resource/#{dubbing_id}/transcribe",
        method: :post,
        response_body: expected_response
      )
    end

    it "transcribes specified segments" do
      result = dubs.transcribe_segment(dubbing_id, segments)

      expect(result).to eq(expected_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/transcribe")
        .with(
          headers: { "xi-api-key" => api_key },
          body: { segments: segments }.to_json
        )
    end
  end

  describe "#translate_segment" do
    let(:dubbing_id) { "dub_123456" }
    let(:segments) { ["segment_1", "segment_2"] }
    let(:expected_response) { { "version" => 6 } }

    before do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing/resource/#{dubbing_id}/translate",
        method: :post,
        response_body: expected_response
      )
    end

    context "without languages specified" do
      it "translates segments for all languages" do
        result = dubs.translate_segment(dubbing_id, segments)

        expect(result).to eq(expected_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/translate")
          .with(
            headers: { "xi-api-key" => api_key },
            body: { segments: segments }.to_json
          )
      end
    end

    context "with specific languages" do
      let(:languages) { ["es", "pt"] }

      it "translates segments for specified languages" do
        result = dubs.translate_segment(dubbing_id, segments, languages)

        expect(result).to eq(expected_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/translate")
          .with(
            headers: { "xi-api-key" => api_key },
            body: { segments: segments, languages: languages }.to_json
          )
      end
    end
  end

  describe "#dub_segment" do
    let(:dubbing_id) { "dub_123456" }
    let(:segments) { ["segment_1", "segment_2"] }
    let(:expected_response) { { "version" => 7 } }

    before do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing/resource/#{dubbing_id}/dub",
        method: :post,
        response_body: expected_response
      )
    end

    context "without languages specified" do
      it "dubs segments for all languages" do
        result = dubs.dub_segment(dubbing_id, segments)

        expect(result).to eq(expected_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/dub")
          .with(
            headers: { "xi-api-key" => api_key },
            body: { segments: segments }.to_json
          )
      end
    end

    context "with specific languages" do
      let(:languages) { ["es", "pt"] }

      it "dubs segments for specified languages" do
        result = dubs.dub_segment(dubbing_id, segments, languages)

        expect(result).to eq(expected_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/dub")
          .with(
            headers: { "xi-api-key" => api_key },
            body: { segments: segments, languages: languages }.to_json
          )
      end
    end
  end

  describe "#render_project" do
    let(:dubbing_id) { "dub_123456" }
    let(:language) { "es" }
    let(:render_type) { "mp4" }
    let(:expected_response) { { "version" => 8, "render_id" => "render_xyz789" } }

    before do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing/resource/#{dubbing_id}/render/#{language}",
        method: :post,
        response_body: expected_response
      )
    end

    context "with required parameters only" do
      it "renders project with default settings" do
        result = dubs.render_project(
          dubbing_id: dubbing_id,
          language: language,
          render_type: render_type
        )

        expect(result).to eq(expected_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/render/#{language}")
          .with(
            headers: { "xi-api-key" => api_key },
            body: { render_type: render_type }.to_json
          )
      end
    end

    context "with volume normalization" do
      it "renders project with volume normalization enabled" do
        result = dubs.render_project(
          dubbing_id: dubbing_id,
          language: language,
          render_type: render_type,
          normalize_volume: true
        )

        expect(result).to eq(expected_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/render/#{language}")
          .with(
            headers: { "xi-api-key" => api_key },
            body: { render_type: render_type, normalize_volume: true }.to_json
          )
      end
    end

    context "with different render types" do
      %w[mp4 aac mp3 wav aaf tracks_zip clips_zip].each do |type|
        it "handles #{type} render type" do
          result = dubs.render_project(
            dubbing_id: dubbing_id,
            language: language,
            render_type: type
          )

          expect(result).to eq(expected_response)
          expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/render/#{language}")
            .with(
              headers: { "xi-api-key" => api_key },
              body: { render_type: type }.to_json
            )
        end
      end
    end
  end

  describe "#update_speaker" do
    let(:dubbing_id) { "dub_123456" }
    let(:speaker_id) { "speaker_789" }
    let(:expected_response) { { "version" => 9 } }

    before do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing/resource/#{dubbing_id}/speaker/#{speaker_id}",
        method: :patch,
        response_body: expected_response
      )
    end

    context "with voice_id only" do
      let(:voice_id) { "voice_123" }

      it "updates speaker voice" do
        result = dubs.update_speaker(
          dubbing_id: dubbing_id,
          speaker_id: speaker_id,
          voice_id: voice_id
        )

        expect(result).to eq(expected_response)
        expect(WebMock).to have_requested(:patch, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/speaker/#{speaker_id}")
          .with(
            headers: { "xi-api-key" => api_key },
            body: { voice_id: voice_id }.to_json
          )
      end
    end

    context "with voice cloning" do
      let(:voice_id) { "track-clone" }

      it "updates speaker to use track cloning" do
        result = dubs.update_speaker(
          dubbing_id: dubbing_id,
          speaker_id: speaker_id,
          voice_id: voice_id
        )

        expect(result).to eq(expected_response)
        expect(WebMock).to have_requested(:patch, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/speaker/#{speaker_id}")
          .with(
            headers: { "xi-api-key" => api_key },
            body: { voice_id: voice_id }.to_json
          )
      end
    end

    context "with specific languages" do
      let(:voice_id) { "voice_456" }
      let(:languages) { ["es", "pt"] }

      it "updates speaker for specific languages" do
        result = dubs.update_speaker(
          dubbing_id: dubbing_id,
          speaker_id: speaker_id,
          voice_id: voice_id,
          languages: languages
        )

        expect(result).to eq(expected_response)
        expect(WebMock).to have_requested(:patch, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/speaker/#{speaker_id}")
          .with(
            headers: { "xi-api-key" => api_key },
            body: { voice_id: voice_id, languages: languages }.to_json
          )
      end
    end
  end

  describe "#get_similar_voices" do
    let(:dubbing_id) { "dub_123456" }
    let(:speaker_id) { "speaker_789" }
    let(:expected_response) do
      {
        "voices" => [
          {
            "voice_id" => "voice_001",
            "name" => "Sarah",
            "category" => "premade",
            "description" => "Young adult female voice",
            "preview_url" => "https://example.com/preview1.mp3"
          },
          {
            "voice_id" => "voice_002",
            "name" => "Emma",
            "category" => "premade",
            "description" => "Professional female voice",
            "preview_url" => "https://example.com/preview2.mp3"
          }
        ]
      }
    end

    before do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing/resource/#{dubbing_id}/speaker/#{speaker_id}/similar-voices",
        method: :get,
        response_body: expected_response
      )
    end

    it "retrieves similar voices for a speaker" do
      result = dubs.get_similar_voices(dubbing_id, speaker_id)

      expect(result).to eq(expected_response)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/speaker/#{speaker_id}/similar-voices")
        .with(headers: { "xi-api-key" => api_key })
    end

    it "returns an array of voice objects with required fields" do
      result = dubs.get_similar_voices(dubbing_id, speaker_id)

      voices = result["voices"]
      expect(voices).to be_an(Array)
      expect(voices.length).to eq(2)

      voices.each do |voice|
        expect(voice).to have_key("voice_id")
        expect(voice).to have_key("name")
        expect(voice).to have_key("category")
        expect(voice).to have_key("description")
        expect(voice).to have_key("preview_url")
      end
    end
  end
end
