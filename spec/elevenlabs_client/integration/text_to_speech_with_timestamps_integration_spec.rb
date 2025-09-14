# frozen_string_literal: true

require 'base64'
require 'json'

RSpec.describe "ElevenlabsClient Text-to-Speech with Timestamps Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:voice_id) { "21m00Tcm4TlvDq8ikWAM" }
  let(:text) { "Hello, this is a test with timestamps." }
  let(:response_body) do
    {
      "audio_base64" => "base64_encoded_audio_string",
      "alignment" => {
        "characters" => ["H", "e", "l", "l", "o", ",", " ", "t", "h", "i", "s"],
        "character_start_times_seconds" => [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
        "character_end_times_seconds" => [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1]
      },
      "normalized_alignment" => {
        "characters" => ["H", "e", "l", "l", "o", ",", " ", "t", "h", "i", "s"],
        "character_start_times_seconds" => [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
        "character_end_times_seconds" => [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1]
      }
    }
  end

  describe "client.text_to_speech_with_timestamps accessor" do
    it "provides access to text_to_speech_with_timestamps endpoint" do
      expect(client.text_to_speech_with_timestamps).to be_an_instance_of(ElevenlabsClient::TextToSpeechWithTimestamps)
    end
  end

  describe "text-to-speech with timestamps functionality via client" do
    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
        .to_return(
          status: 200,
          body: response_body.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "generates speech with timestamps through client interface" do
      result = client.text_to_speech_with_timestamps.generate(voice_id, text)

      expect(result).to eq(response_body)
      expect(result["audio_base64"]).to eq("base64_encoded_audio_string")
      expect(result["alignment"]["characters"].length).to eq(11)
      expect(result["normalized_alignment"]["character_start_times_seconds"].first).to eq(0.0)
      expect(result["normalized_alignment"]["character_end_times_seconds"].last).to eq(1.1)

      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
        .with(
          headers: { "xi-api-key" => api_key },
          body: { text: text }.to_json
        )
    end

    it "supports the text_to_speech_with_timestamps alias method" do
      result = client.text_to_speech_with_timestamps.text_to_speech_with_timestamps(voice_id, text)

      expect(result).to eq(response_body)
    end
  end

  describe "response parsing" do
    context "when API returns timestamp data" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "correctly parses alignment data" do
        result = client.text_to_speech_with_timestamps.generate(voice_id, text)

        expect(result["alignment"]).to be_a(Hash)
        expect(result["alignment"]["characters"]).to be_an(Array)
        expect(result["alignment"]["character_start_times_seconds"]).to be_an(Array)
        expect(result["alignment"]["character_end_times_seconds"]).to be_an(Array)

        # Check timing sequence
        start_times = result["alignment"]["character_start_times_seconds"]
        end_times = result["alignment"]["character_end_times_seconds"]
        
        expect(start_times).to all(be_a(Numeric))
        expect(end_times).to all(be_a(Numeric))
        expect(start_times).to eq(start_times.sort) # Should be in ascending order
      end

      it "correctly parses normalized alignment data" do
        result = client.text_to_speech_with_timestamps.generate(voice_id, text)

        expect(result["normalized_alignment"]).to be_a(Hash)
        expect(result["normalized_alignment"]["characters"]).to be_an(Array)
        expect(result["normalized_alignment"]["character_start_times_seconds"]).to be_an(Array)
        expect(result["normalized_alignment"]["character_end_times_seconds"]).to be_an(Array)
      end

      it "handles base64 audio data" do
        result = client.text_to_speech_with_timestamps.generate(voice_id, text)

        expect(result["audio_base64"]).to be_a(String)
        expect(result["audio_base64"]).not_to be_empty
        
        # Should be valid base64 (this is just a basic check)
        expect { Base64.decode64(result["audio_base64"]) }.not_to raise_error
      end
    end
  end

  describe "advanced parameter handling" do
    context "with comprehensive options" do
      let(:voice_settings) do
        {
          stability: 0.5,
          similarity_boost: 0.8,
          style: 0.3,
          use_speaker_boost: true
        }
      end

      let(:pronunciation_dictionary_locators) do
        [
          { id: "dict_1", version_id: "v1" },
          { id: "dict_2", version_id: "v2" }
        ]
      end

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps?output_format=mp3_44100_128&enable_logging=false")
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "handles complex parameter combinations correctly" do
        result = client.text_to_speech_with_timestamps.generate(
          voice_id,
          text,
          model_id: "eleven_multilingual_v2",
          language_code: "en",
          voice_settings: voice_settings,
          pronunciation_dictionary_locators: pronunciation_dictionary_locators,
          seed: 12345,
          previous_text: "Previous sentence.",
          next_text: "Next sentence.",
          apply_text_normalization: "auto",
          apply_language_text_normalization: true,
          output_format: "mp3_44100_128",
          enable_logging: false
        )

        expect(result).to eq(response_body)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps?output_format=mp3_44100_128&enable_logging=false")
          .with(
            body: {
              text: text,
              model_id: "eleven_multilingual_v2",
              language_code: "en",
              voice_settings: voice_settings,
              pronunciation_dictionary_locators: pronunciation_dictionary_locators,
              seed: 12345,
              previous_text: "Previous sentence.",
              next_text: "Next sentence.",
              apply_text_normalization: "auto",
              apply_language_text_normalization: true
            }.to_json
          )
      end
    end
  end

  describe "error handling integration" do
    context "with authentication error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
          .to_return(status: 401, body: "Unauthorized")
      end

      it "raises AuthenticationError through client" do
        expect {
          client.text_to_speech_with_timestamps.generate(voice_id, text)
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    context "with rate limit error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
          .to_return(status: 429, body: "Rate limit exceeded")
      end

      it "raises RateLimitError through client" do
        expect {
          client.text_to_speech_with_timestamps.generate(voice_id, text)
        }.to raise_error(ElevenlabsClient::RateLimitError)
      end
    end

    context "with validation error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
          .to_return(status: 422, body: '{"detail": "Invalid voice settings"}')
      end

      it "raises UnprocessableEntityError with detail message" do
        expect {
          client.text_to_speech_with_timestamps.generate(voice_id, text)
        }.to raise_error(ElevenlabsClient::UnprocessableEntityError, "Invalid voice settings")
      end
    end
  end

  describe "Settings integration" do
    after do
      ElevenlabsClient::Settings.reset!
    end

    context "when Settings are configured" do
      before do
        ElevenlabsClient.configure do |config|
          config.properties = {
            elevenlabs_base_uri: "https://configured.elevenlabs.io",
            elevenlabs_api_key: "configured_api_key"
          }
        end

        stub_request(:post, "https://configured.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "uses configured settings for timestamp TTS requests" do
        client = ElevenlabsClient.new
        result = client.text_to_speech_with_timestamps.generate(voice_id, text)

        expect(result).to eq(response_body)
        expect(WebMock).to have_requested(:post, "https://configured.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
          .with(headers: { "xi-api-key" => "configured_api_key" })
      end
    end
  end

  describe "Rails usage example" do
    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
        .to_return(
          status: 200,
          body: response_body.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "works as expected in a Rails-like environment with timestamps" do
      # This simulates typical Rails usage with timestamps
      client = ElevenlabsClient.new(api_key: api_key)
      
      # Generate speech with timestamps and voice settings
      result = client.text_to_speech_with_timestamps.generate(
        voice_id,
        "Welcome to our application!",
        model_id: "eleven_multilingual_v2",
        voice_settings: {
          stability: 0.5,
          similarity_boost: 0.8
        },
        language_code: "en",
        apply_text_normalization: "auto"
      )

      expect(result).to eq(response_body)
      expect(result["alignment"]).not_to be_nil
      expect(result["normalized_alignment"]).not_to be_nil
      expect(result["audio_base64"]).not_to be_nil

      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
        .with { |req|
          body = JSON.parse(req.body)
          body["text"] == "Welcome to our application!" &&
          body["model_id"] == "eleven_multilingual_v2" &&
          body["language_code"] == "en" &&
          body["apply_text_normalization"] == "auto" &&
          body["voice_settings"]["stability"] == 0.5 &&
          body["voice_settings"]["similarity_boost"] == 0.8
        }
    end
  end

  describe "timestamp data analysis" do
    let(:detailed_response) do
      {
        "audio_base64" => "base64_encoded_audio_string",
        "alignment" => {
          "characters" => ["T", "e", "s", "t", " ", "w", "o", "r", "d"],
          "character_start_times_seconds" => [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8],
          "character_end_times_seconds" => [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
        },
        "normalized_alignment" => {
          "characters" => ["T", "e", "s", "t", " ", "w", "o", "r", "d"],
          "character_start_times_seconds" => [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8],
          "character_end_times_seconds" => [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
        }
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
        .to_return(
          status: 200,
          body: detailed_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "provides usable timing data for audio-text synchronization" do
      result = client.text_to_speech_with_timestamps.generate(voice_id, "Test word")

      alignment = result["alignment"]
      characters = alignment["characters"]
      start_times = alignment["character_start_times_seconds"]
      end_times = alignment["character_end_times_seconds"]

      # Basic validation
      expect(characters.length).to eq(start_times.length)
      expect(characters.length).to eq(end_times.length)

      # Timing validation
      characters.each_with_index do |char, index|
        expect(start_times[index]).to be < end_times[index]
        if index > 0
          expect(start_times[index]).to be >= start_times[index - 1]
        end
      end

      # Character validation
      expect(characters.join).to eq("Test word")
    end
  end
end
