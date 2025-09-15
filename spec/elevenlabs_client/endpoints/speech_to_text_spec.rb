# frozen_string_literal: true

RSpec.describe ElevenlabsClient::SpeechToText do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:speech_to_text) { described_class.new(client) }
  let(:model_id) { "scribe_v1" }
  let(:audio_file) { StringIO.new("fake_audio_data") }
  let(:filename) { "audio.mp3" }
  let(:transcription_id) { "transcription_123" }

  describe "#create" do
    let(:transcription_response) do
      {
        "language_code" => "en",
        "language_probability" => 0.98,
        "text" => "Hello world!",
        "words" => [
          {
            "text" => "Hello",
            "start" => 0.0,
            "end" => 0.5,
            "type" => "word",
            "speaker_id" => "speaker_1",
            "logprob" => -0.124
          },
          {
            "text" => "world!",
            "start" => 0.6,
            "end" => 1.2,
            "type" => "word",
            "speaker_id" => "speaker_1",
            "logprob" => -0.089
          }
        ]
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-text")
        .to_return(
          status: 200,
          body: transcription_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    context "with required parameters only (file)" do
      it "creates transcription successfully" do
        result = speech_to_text.create(model_id, file: audio_file, filename: filename)

        expect(result).to eq(transcription_response)
      end

      it "sends the correct multipart request" do
        speech_to_text.create(model_id, file: audio_file, filename: filename)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with cloud storage URL" do
      let(:cloud_url) { "https://example.com/audio.mp3" }

      it "creates transcription with cloud storage URL" do
        result = speech_to_text.create(model_id, cloud_storage_url: cloud_url)

        expect(result).to eq(transcription_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with missing file and cloud_storage_url" do
      it "raises ArgumentError" do
        expect {
          speech_to_text.create(model_id)
        }.to raise_error(ArgumentError, "Either :file with :filename or :cloud_storage_url must be provided")
      end
    end

    context "with query parameters" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-text?enable_logging=false")
          .to_return(
            status: 200,
            body: transcription_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "includes query parameters in the request" do
        speech_to_text.create(
          model_id,
          file: audio_file,
          filename: filename,
          enable_logging: false
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text?enable_logging=false")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with optional form parameters" do
      it "includes language_code in the request" do
        speech_to_text.create(
          model_id,
          file: audio_file,
          filename: filename,
          language_code: "en"
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end

      it "includes tag_audio_events in the request" do
        speech_to_text.create(
          model_id,
          file: audio_file,
          filename: filename,
          tag_audio_events: false
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end

      it "includes num_speakers in the request" do
        speech_to_text.create(
          model_id,
          file: audio_file,
          filename: filename,
          num_speakers: 2
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end

      it "includes timestamps_granularity in the request" do
        speech_to_text.create(
          model_id,
          file: audio_file,
          filename: filename,
          timestamps_granularity: "character"
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end

      it "includes diarize in the request" do
        speech_to_text.create(
          model_id,
          file: audio_file,
          filename: filename,
          diarize: true
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end

      it "includes diarization_threshold in the request" do
        speech_to_text.create(
          model_id,
          file: audio_file,
          filename: filename,
          diarization_threshold: 0.3
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end

      it "includes file_format in the request" do
        speech_to_text.create(
          model_id,
          file: audio_file,
          filename: filename,
          file_format: "pcm_s16le_16"
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end

      it "includes webhook parameters in the request" do
        speech_to_text.create(
          model_id,
          file: audio_file,
          filename: filename,
          webhook: true,
          webhook_id: "webhook_123"
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end

      it "includes temperature and seed in the request" do
        speech_to_text.create(
          model_id,
          file: audio_file,
          filename: filename,
          temperature: 0.5,
          seed: 12345
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end

      it "includes use_multi_channel in the request" do
        speech_to_text.create(
          model_id,
          file: audio_file,
          filename: filename,
          use_multi_channel: true
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with webhook_metadata as hash" do
      let(:metadata_hash) { { "job_id" => "123", "user_id" => "456" } }

      it "converts hash to JSON string" do
        speech_to_text.create(
          model_id,
          file: audio_file,
          filename: filename,
          webhook_metadata: metadata_hash
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with webhook_metadata as string" do
      let(:metadata_string) { '{"job_id": "123", "user_id": "456"}' }

      it "uses string as-is" do
        speech_to_text.create(
          model_id,
          file: audio_file,
          filename: filename,
          webhook_metadata: metadata_string
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with additional_formats" do
      let(:additional_formats) do
        [
          {
            "requested_format" => "srt",
            "file_extension" => "srt",
            "content_type" => "text/plain"
          }
        ]
      end

      it "includes additional_formats in the request" do
        speech_to_text.create(
          model_id,
          file: audio_file,
          filename: filename,
          additional_formats: additional_formats
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
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
          stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-text")
            .to_return(status: 401, body: "Unauthorized")
        end

        it "raises AuthenticationError" do
          expect {
            speech_to_text.create(model_id, file: audio_file, filename: filename)
          }.to raise_error(ElevenlabsClient::AuthenticationError)
        end
      end

      context "with unprocessable entity error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-text")
            .to_return(
              status: 422,
              body: {
                detail: [
                  {
                    loc: ["file"],
                    msg: "File size must be less than 3GB",
                    type: "value_error"
                  }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "raises UnprocessableEntityError" do
          expect {
            speech_to_text.create(model_id, file: audio_file, filename: filename)
          }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
        end
      end

      context "with rate limit error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-text")
            .to_return(status: 429, body: "Rate limit exceeded")
        end

        it "raises RateLimitError" do
          expect {
            speech_to_text.create(model_id, file: audio_file, filename: filename)
          }.to raise_error(ElevenlabsClient::RateLimitError)
        end
      end
    end
  end

  describe "#get_transcript" do
    let(:transcript_response) do
      {
        "language_code" => "en",
        "language_probability" => 0.98,
        "text" => "Hello world! This is a test transcript.",
        "words" => [
          {
            "text" => "Hello",
            "start" => 0.0,
            "end" => 0.5,
            "type" => "word",
            "speaker_id" => "speaker_1",
            "logprob" => -0.124,
            "characters" => [
              {
                "text" => "H",
                "start" => 0.0,
                "end" => 0.1
              },
              {
                "text" => "e",
                "start" => 0.1,
                "end" => 0.2
              }
            ]
          }
        ],
        "channel_index" => 1,
        "additional_formats" => [
          {
            "requested_format" => "srt",
            "file_extension" => "srt",
            "content_type" => "text/plain",
            "is_base64_encoded" => false,
            "content" => "1\n00:00:00,000 --> 00:00:01,200\nHello world!"
          }
        ],
        "transcription_id" => transcription_id
      }
    end

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/speech-to-text/transcripts/#{transcription_id}")
        .to_return(
          status: 200,
          body: transcript_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    context "with valid transcription_id" do
      it "retrieves transcript successfully" do
        result = speech_to_text.get_transcript(transcription_id)

        expect(result).to eq(transcript_response)
      end

      it "sends the correct GET request" do
        speech_to_text.get_transcript(transcription_id)

        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/speech-to-text/transcripts/#{transcription_id}")
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
          stub_request(:get, "https://api.elevenlabs.io/v1/speech-to-text/transcripts/#{transcription_id}")
            .to_return(status: 404, body: "Transcript not found")
        end

        it "raises NotFoundError" do
          expect {
            speech_to_text.get_transcript(transcription_id)
          }.to raise_error(ElevenlabsClient::NotFoundError)
        end
      end

      context "with unprocessable entity error" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/speech-to-text/transcripts/#{transcription_id}")
            .to_return(
              status: 422,
              body: {
                detail: [
                  {
                    loc: ["transcription_id"],
                    msg: "Invalid transcription ID format",
                    type: "value_error"
                  }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "raises UnprocessableEntityError" do
          expect {
            speech_to_text.get_transcript(transcription_id)
          }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
        end
      end
    end
  end

  describe "#delete_transcript" do
    let(:delete_response) do
      {
        "message" => "Delete completed successfully."
      }
    end

    before do
      stub_request(:delete, "https://api.elevenlabs.io/v1/speech-to-text/transcripts/#{transcription_id}")
        .to_return(
          status: 200,
          body: delete_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    context "with valid transcription_id" do
      it "deletes transcript successfully" do
        result = speech_to_text.delete_transcript(transcription_id)

        expect(result).to eq(delete_response)
      end

      it "sends the correct DELETE request" do
        speech_to_text.delete_transcript(transcription_id)

        expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/speech-to-text/transcripts/#{transcription_id}")
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
          stub_request(:delete, "https://api.elevenlabs.io/v1/speech-to-text/transcripts/#{transcription_id}")
            .to_return(status: 404, body: "Transcript not found")
        end

        it "raises NotFoundError" do
          expect {
            speech_to_text.delete_transcript(transcription_id)
          }.to raise_error(ElevenlabsClient::NotFoundError)
        end
      end

      context "with unprocessable entity error" do
        before do
          stub_request(:delete, "https://api.elevenlabs.io/v1/speech-to-text/transcripts/#{transcription_id}")
            .to_return(
              status: 422,
              body: {
                detail: [
                  {
                    loc: ["transcription_id"],
                    msg: "Invalid transcription ID format",
                    type: "value_error"
                  }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "raises UnprocessableEntityError" do
          expect {
            speech_to_text.delete_transcript(transcription_id)
          }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
        end
      end

      context "with authentication error" do
        before do
          stub_request(:delete, "https://api.elevenlabs.io/v1/speech-to-text/transcripts/#{transcription_id}")
            .to_return(status: 401, body: "Unauthorized")
        end

        it "raises AuthenticationError" do
          expect {
            speech_to_text.delete_transcript(transcription_id)
          }.to raise_error(ElevenlabsClient::AuthenticationError)
        end
      end
    end
  end

  describe "alias methods" do
    let(:transcription_response) do
      {
        "language_code" => "en",
        "text" => "Hello world!"
      }
    end

    let(:transcript_response) do
      {
        "transcription_id" => transcription_id,
        "text" => "Hello world!"
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-text")
        .to_return(
          status: 200,
          body: transcription_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      stub_request(:get, "https://api.elevenlabs.io/v1/speech-to-text/transcripts/#{transcription_id}")
        .to_return(
          status: 200,
          body: transcript_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      stub_request(:delete, "https://api.elevenlabs.io/v1/speech-to-text/transcripts/#{transcription_id}")
        .to_return(
          status: 200,
          body: { message: "Delete completed successfully." }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    describe "#transcribe" do
      it "is an alias for create method" do
        result = speech_to_text.transcribe(model_id, file: audio_file, filename: filename)

        expect(result).to eq(transcription_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
      end
    end

    describe "#get_transcription" do
      it "is an alias for get_transcript method" do
        result = speech_to_text.get_transcription(transcription_id)

        expect(result).to eq(transcript_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/speech-to-text/transcripts/#{transcription_id}")
      end
    end

    describe "#retrieve_transcript" do
      it "is an alias for get_transcript method" do
        result = speech_to_text.retrieve_transcript(transcription_id)

        expect(result).to eq(transcript_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/speech-to-text/transcripts/#{transcription_id}")
      end
    end

    describe "#delete_transcription" do
      it "is an alias for delete_transcript method" do
        result = speech_to_text.delete_transcription(transcription_id)

        expect(result).to eq({ "message" => "Delete completed successfully." })
        expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/speech-to-text/transcripts/#{transcription_id}")
      end
    end

    describe "#remove_transcript" do
      it "is an alias for delete_transcript method" do
        result = speech_to_text.remove_transcript(transcription_id)

        expect(result).to eq({ "message" => "Delete completed successfully." })
        expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/speech-to-text/transcripts/#{transcription_id}")
      end
    end
  end
end