# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Speech-to-Text Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:model_id) { "scribe_v1" }
  let(:audio_file) { StringIO.new("fake_audio_data") }
  let(:filename) { "audio.mp3" }
  let(:transcription_id) { "transcription_123" }

  describe "client.speech_to_text accessor" do
    it "provides access to speech_to_text endpoint" do
      expect(client.speech_to_text).to be_an_instance_of(ElevenlabsClient::SpeechToText)
    end
  end

  describe "speech-to-text functionality via client" do
    let(:transcription_response) do
      {
        "language_code" => "en",
        "language_probability" => 0.98,
        "text" => "Hello world! This is a test transcription.",
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

    it "creates transcription through client interface" do
      result = client.speech_to_text.create(model_id, file: audio_file, filename: filename)

      expect(result).to eq(transcription_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end

    it "supports the transcribe alias method" do
      result = client.speech_to_text.transcribe(model_id, file: audio_file, filename: filename)

      expect(result).to eq(transcription_response)
    end

    it "supports cloud storage URL" do
      cloud_url = "https://example.com/audio.mp3"
      
      result = client.speech_to_text.create(model_id, cloud_storage_url: cloud_url)

      expect(result).to eq(transcription_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end

    it "supports query parameters" do
      stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-text?enable_logging=false")
        .to_return(
          status: 200,
          body: transcription_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.speech_to_text.create(
        model_id,
        file: audio_file,
        filename: filename,
        enable_logging: false
      )

      expect(result).to eq(transcription_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text?enable_logging=false")
    end

    it "supports optional form parameters" do
      result = client.speech_to_text.create(
        model_id,
        file: audio_file,
        filename: filename,
        language_code: "en",
        tag_audio_events: true,
        num_speakers: 2,
        timestamps_granularity: "character",
        diarize: true,
        file_format: "pcm_s16le_16"
      )

      expect(result).to eq(transcription_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end
  end

  describe "transcript retrieval functionality" do
    let(:transcript_response) do
      {
        "language_code" => "en",
        "language_probability" => 0.98,
        "text" => "Hello world! This is a complete transcript.",
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

    it "retrieves transcript through client interface" do
      result = client.speech_to_text.get_transcript(transcription_id)

      expect(result).to eq(transcript_response)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/speech-to-text/transcripts/#{transcription_id}")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end

    it "supports the get_transcription alias method" do
      result = client.speech_to_text.get_transcription(transcription_id)

      expect(result).to eq(transcript_response)
    end

    it "supports the retrieve_transcript alias method" do
      result = client.speech_to_text.retrieve_transcript(transcription_id)

      expect(result).to eq(transcript_response)
    end
  end

  describe "webhook functionality" do
    let(:webhook_response) do
      {
        "transcription_id" => transcription_id,
        "webhook_id" => "webhook_123",
        "status" => "processing"
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-text")
        .to_return(
          status: 200,
          body: webhook_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "supports webhook processing" do
      result = client.speech_to_text.create(
        model_id,
        file: audio_file,
        filename: filename,
        webhook: true,
        webhook_id: "webhook_123"
      )

      expect(result).to eq(webhook_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end

    it "supports webhook metadata as hash" do
      metadata = { "job_id" => "123", "user_id" => "456" }
      
      result = client.speech_to_text.create(
        model_id,
        file: audio_file,
        filename: filename,
        webhook: true,
        webhook_metadata: metadata
      )

      expect(result).to eq(webhook_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end

    it "supports webhook metadata as string" do
      metadata_string = '{"job_id": "123", "user_id": "456"}'
      
      result = client.speech_to_text.create(
        model_id,
        file: audio_file,
        filename: filename,
        webhook: true,
        webhook_metadata: metadata_string
      )

      expect(result).to eq(webhook_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end
  end

  describe "multi-channel processing" do
    let(:multichannel_response) do
      {
        "transcripts" => [
          {
            "language_code" => "en",
            "text" => "Speaker 1 content",
            "channel_index" => 0
          },
          {
            "language_code" => "en", 
            "text" => "Speaker 2 content",
            "channel_index" => 1
          }
        ]
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-text")
        .to_return(
          status: 200,
          body: multichannel_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "supports multi-channel processing" do
      result = client.speech_to_text.create(
        model_id,
        file: audio_file,
        filename: filename,
        use_multi_channel: true
      )

      expect(result).to eq(multichannel_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end
  end

  describe "diarization functionality" do
    let(:diarized_response) do
      {
        "language_code" => "en",
        "text" => "Hello world! How are you?",
        "words" => [
          {
            "text" => "Hello",
            "start" => 0.0,
            "end" => 0.5,
            "speaker_id" => "speaker_1"
          },
          {
            "text" => "world!",
            "start" => 0.6,
            "end" => 1.2,
            "speaker_id" => "speaker_1"
          },
          {
            "text" => "How",
            "start" => 2.0,
            "end" => 2.3,
            "speaker_id" => "speaker_2"
          },
          {
            "text" => "are",
            "start" => 2.4,
            "end" => 2.6,
            "speaker_id" => "speaker_2"
          },
          {
            "text" => "you?",
            "start" => 2.7,
            "end" => 3.0,
            "speaker_id" => "speaker_2"
          }
        ]
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-text")
        .to_return(
          status: 200,
          body: diarized_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "supports speaker diarization" do
      result = client.speech_to_text.create(
        model_id,
        file: audio_file,
        filename: filename,
        diarize: true,
        num_speakers: 2,
        diarization_threshold: 0.25
      )

      expect(result).to eq(diarized_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end
  end

  describe "additional formats functionality" do
    let(:formats_response) do
      {
        "language_code" => "en",
        "text" => "Hello world!",
        "additional_formats" => [
          {
            "requested_format" => "srt",
            "file_extension" => "srt",
            "content_type" => "text/plain",
            "is_base64_encoded" => false,
            "content" => "1\n00:00:00,000 --> 00:00:01,200\nHello world!"
          },
          {
            "requested_format" => "vtt",
            "file_extension" => "vtt",
            "content_type" => "text/vtt",
            "is_base64_encoded" => false,
            "content" => "WEBVTT\n\n00:00.000 --> 00:01.200\nHello world!"
          }
        ]
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-text")
        .to_return(
          status: 200,
          body: formats_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "supports additional export formats" do
      additional_formats = [
        {
          "requested_format" => "srt",
          "file_extension" => "srt",
          "content_type" => "text/plain"
        },
        {
          "requested_format" => "vtt",
          "file_extension" => "vtt",
          "content_type" => "text/vtt"
        }
      ]

      result = client.speech_to_text.create(
        model_id,
        file: audio_file,
        filename: filename,
        additional_formats: additional_formats
      )

      expect(result).to eq(formats_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end
  end

  describe "error handling integration" do
    context "with authentication error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-text")
          .to_return(status: 401, body: "Unauthorized")
      end

      it "raises AuthenticationError through client" do
        expect {
          client.speech_to_text.create(model_id, file: audio_file, filename: filename)
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

      it "raises UnprocessableEntityError through client" do
        expect {
          client.speech_to_text.create(model_id, file: audio_file, filename: filename)
        }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end

    context "with not found error for transcript" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/speech-to-text/transcripts/#{transcription_id}")
          .to_return(status: 404, body: "Transcript not found")
      end

      it "raises NotFoundError through client" do
        expect {
          client.speech_to_text.get_transcript(transcription_id)
        }.to raise_error(ElevenlabsClient::NotFoundError)
      end
    end
  end

  describe "Settings integration" do
    after do
      ElevenlabsClient::Settings.reset!
    end

    context "when Settings are configured" do
      let(:transcription_response) do
        {
          "language_code" => "en",
          "text" => "Hello world!"
        }
      end

      before do
        ElevenlabsClient.configure do |config|
          config.properties = {
            elevenlabs_base_uri: "https://configured.elevenlabs.io",
            elevenlabs_api_key: "configured_api_key"
          }
        end

        stub_request(:post, "https://configured.elevenlabs.io/v1/speech-to-text")
          .to_return(
            status: 200,
            body: transcription_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "uses configured settings for speech-to-text requests" do
        client = ElevenlabsClient.new
        result = client.speech_to_text.create(model_id, file: audio_file, filename: filename)

        expect(result).to eq(transcription_response)
        expect(WebMock).to have_requested(:post, "https://configured.elevenlabs.io/v1/speech-to-text")
          .with(headers: { "xi-api-key" => "configured_api_key" })
      end
    end
  end

  describe "Rails usage example" do
    let(:transcription_response) do
      {
        "language_code" => "en",
        "language_probability" => 0.98,
        "text" => "Welcome to our application! How can we help you today?",
        "words" => [
          {
            "text" => "Welcome",
            "start" => 0.0,
            "end" => 0.8,
            "type" => "word",
            "speaker_id" => "speaker_1"
          }
        ]
      }
    end

    let(:transcript_response) do
      {
        "transcription_id" => transcription_id,
        "text" => "Welcome to our application! How can we help you today?",
        "language_code" => "en"
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-text?enable_logging=true")
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
    end

    it "works as expected in a Rails-like environment" do
      # This simulates typical Rails usage
      client = ElevenlabsClient.new(api_key: api_key)
      
      # Transcribe audio with full options
      transcription = client.speech_to_text.create(
        "scribe_v1",
        file: audio_file,
        filename: "user_message.wav",
        language_code: "en",
        tag_audio_events: true,
        timestamps_granularity: "word",
        diarize: false,
        enable_logging: true,
        temperature: 0.0,
        seed: 12345
      )

      expect(transcription["text"]).to include("Welcome to our application")
      expect(transcription["language_code"]).to eq("en")

      # Retrieve the transcript later
      transcript = client.speech_to_text.get_transcript(transcription_id)
      expect(transcript["text"]).to include("Welcome to our application")

      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text?enable_logging=true")
        .with(
          headers: { "xi-api-key" => api_key }
        )
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/speech-to-text/transcripts/#{transcription_id}")
    end
  end

  describe "multipart file handling" do
    let(:file_content) { "binary_audio_content_here" }
    let(:test_file) { StringIO.new(file_content) }
    let(:transcription_response) do
      {
        "language_code" => "en",
        "text" => "Test transcription"
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

    it "properly handles file uploads in multipart requests" do
      result = client.speech_to_text.create(model_id, file: test_file, filename: "test.mp3")

      expect(result).to eq(transcription_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
    end

    it "handles different audio file extensions" do
      %w[mp3 wav flac m4a mp4 mov].each do |ext|
        client.speech_to_text.create(model_id, file: test_file, filename: "test.#{ext}")
      end
      
      # Expect 6 requests total (one for each file extension)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text").times(6)
    end
  end

  describe "deterministic transcription" do
    let(:transcription_response) do
      {
        "language_code" => "en",
        "text" => "Deterministic transcription result"
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

    it "supports seed for deterministic results" do
      seed = 54321
      
      result = client.speech_to_text.create(
        model_id,
        file: audio_file,
        filename: filename,
        seed: seed,
        temperature: 0.0
      )

      expect(result).to eq(transcription_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-text")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end
  end
end