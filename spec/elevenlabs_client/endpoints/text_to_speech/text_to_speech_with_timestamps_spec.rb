# frozen_string_literal: true

RSpec.describe "TextToSpeech#convert_with_timestamps" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:text_to_speech_with_timestamps) { ElevenlabsClient::TextToSpeech.new(client) }
  let(:voice_id) { "21m00Tcm4TlvDq8ikWAM" }
  let(:text) { "Hello, this is a test for timestamps." }

  describe "#convert_with_timestamps" do
    let(:response_body) do
      {
        "audio_base64" => "base64_encoded_audio_string",
        "alignment" => {
          "characters" => ["H", "e", "l", "l", "o"],
          "character_start_times_seconds" => [0.0, 0.1, 0.2, 0.3, 0.4],
          "character_end_times_seconds" => [0.1, 0.2, 0.3, 0.4, 0.5]
        },
        "normalized_alignment" => {
          "characters" => ["H", "e", "l", "l", "o"],
          "character_start_times_seconds" => [0.0, 0.1, 0.2, 0.3, 0.4],
          "character_end_times_seconds" => [0.1, 0.2, 0.3, 0.4, 0.5]
        }
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
        .to_return(
          status: 200,
          body: response_body.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    context "with required parameters only" do
      it "generates speech with timestamps successfully" do
        result = text_to_speech_with_timestamps.convert_with_timestamps(voice_id, text)

        expect(result).to eq(response_body)
        expect(result["audio_base64"]).to eq("base64_encoded_audio_string")
        expect(result["alignment"]["characters"]).to eq(["H", "e", "l", "l", "o"])
        expect(result["normalized_alignment"]["character_start_times_seconds"]).to eq([0.0, 0.1, 0.2, 0.3, 0.4])
      end

      it "sends the correct request" do
        text_to_speech_with_timestamps.convert_with_timestamps(voice_id, text)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
          .with(
            headers: {
              "xi-api-key" => api_key,
              "Content-Type" => "application/json"
            },
            body: { text: text }.to_json
          )
      end
    end

    context "with model_id option" do
      let(:model_id) { "eleven_multilingual_v2" }

      it "includes model_id in the request" do
        text_to_speech_with_timestamps.convert_with_timestamps(voice_id, text, model_id: model_id)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
          .with(
            body: {
              text: text,
              model_id: model_id
            }.to_json
          )
      end
    end

    context "with voice_settings option" do
      let(:voice_settings) do
        {
          stability: 0.5,
          similarity_boost: 0.8,
          style: 0.2,
          use_speaker_boost: true
        }
      end

      it "includes voice_settings in the request" do
        text_to_speech_with_timestamps.convert_with_timestamps(voice_id, text, voice_settings: voice_settings)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
          .with(
            body: {
              text: text,
              voice_settings: voice_settings
            }.to_json
          )
      end
    end

    context "with query parameters" do
      let(:output_format) { "mp3_44100_128" }
      let(:enable_logging) { false }

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps?enable_logging=false&output_format=mp3_44100_128")
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "includes query parameters in the URL" do
        text_to_speech_with_timestamps.convert_with_timestamps(
          voice_id, 
          text, 
          output_format: output_format,
          enable_logging: enable_logging
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps?enable_logging=false&output_format=mp3_44100_128")
      end
    end

    context "with advanced options" do
      let(:model_id) { "eleven_multilingual_v2" }
      let(:language_code) { "en" }
      let(:voice_settings) do
        {
          stability: 0.7,
          similarity_boost: 0.9,
          style: 0.1,
          use_speaker_boost: false
        }
      end
      let(:seed) { 12345 }
      let(:previous_text) { "This is previous text." }
      let(:apply_text_normalization) { "on" }

      it "includes all options in the request" do
        text_to_speech_with_timestamps.convert_with_timestamps(
          voice_id, 
          text, 
          model_id: model_id,
          language_code: language_code,
          voice_settings: voice_settings,
          seed: seed,
          previous_text: previous_text,
          apply_text_normalization: apply_text_normalization
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
          .with(
            body: {
              text: text,
              model_id: model_id,
              language_code: language_code,
              voice_settings: voice_settings,
              seed: seed,
              previous_text: previous_text,
              apply_text_normalization: apply_text_normalization
            }.to_json
          )
      end
    end

    context "with pronunciation dictionary locators" do
      let(:pronunciation_dictionary_locators) do
        [
          { id: "dict_1", version_id: "v1" },
          { id: "dict_2", version_id: "v2" }
        ]
      end

      it "includes pronunciation_dictionary_locators in the request" do
        text_to_speech_with_timestamps.convert_with_timestamps(
          voice_id, 
          text, 
          pronunciation_dictionary_locators: pronunciation_dictionary_locators
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
          .with(
            body: {
              text: text,
              pronunciation_dictionary_locators: pronunciation_dictionary_locators
            }.to_json
          )
      end
    end

    context "with request IDs" do
      let(:previous_request_ids) { ["req_1", "req_2"] }
      let(:next_request_ids) { ["req_3", "req_4"] }

      it "includes request IDs in the request" do
        text_to_speech_with_timestamps.convert_with_timestamps(
          voice_id, 
          text, 
          previous_request_ids: previous_request_ids,
          next_request_ids: next_request_ids
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
          .with(
            body: {
              text: text,
              previous_request_ids: previous_request_ids,
              next_request_ids: next_request_ids
            }.to_json
          )
      end
    end

    context "with boolean options" do
      let(:apply_language_text_normalization) { true }
      let(:use_pvc_as_ivc) { false }

      it "includes boolean options correctly" do
        text_to_speech_with_timestamps.convert_with_timestamps(
          voice_id, 
          text, 
          apply_language_text_normalization: apply_language_text_normalization,
          use_pvc_as_ivc: use_pvc_as_ivc
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
          .with(
            body: {
              text: text,
              apply_language_text_normalization: apply_language_text_normalization,
              use_pvc_as_ivc: use_pvc_as_ivc
            }.to_json
          )
      end
    end

    context "when API returns an error" do
      context "with authentication error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
            .to_return(status: 401, body: "Unauthorized")
        end

        it "raises AuthenticationError" do
          expect {
            text_to_speech_with_timestamps.convert_with_timestamps(voice_id, text)
          }.to raise_error(ElevenlabsClient::AuthenticationError)
        end
      end

      context "with rate limit error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
            .to_return(status: 429, body: "Rate limit exceeded")
        end

        it "raises RateLimitError" do
          expect {
            text_to_speech_with_timestamps.convert_with_timestamps(voice_id, text)
          }.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
        end
      end

      context "with validation error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
            .to_return(status: 422, body: "Invalid parameters")
        end

        it "raises UnprocessableEntityError" do
          expect {
            text_to_speech_with_timestamps.convert_with_timestamps(voice_id, text)
          }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
        end
      end

      context "with server error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
            .to_return(status: 500, body: "Internal Server Error")
        end

        it "raises APIError" do
          expect {
            text_to_speech_with_timestamps.convert_with_timestamps(voice_id, text)
          }.to raise_error(ElevenlabsClient::APIError)
        end
      end
    end

    context "with different voice IDs" do
      let(:different_voice_id) { "pNInz6obpgDQGcFmaJgB" }

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{different_voice_id}/with-timestamps")
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "uses the correct voice ID in the endpoint" do
        text_to_speech_with_timestamps.convert_with_timestamps(different_voice_id, text)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{different_voice_id}/with-timestamps")
      end
    end

    context "with different text content" do
      let(:long_text) { "This is a much longer text that should be converted to speech with character-level timing information. It contains multiple sentences and should test the API's ability to handle longer content with precise timestamps." }

      it "handles longer text content" do
        text_to_speech_with_timestamps.convert_with_timestamps(voice_id, long_text)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/with-timestamps")
          .with(
            body: { text: long_text }.to_json
          )
      end
    end
  end
end
