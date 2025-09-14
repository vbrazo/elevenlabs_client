# frozen_string_literal: true

RSpec.describe ElevenlabsClient::TextToSpeechStreamWithTimestamps do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:text_to_speech_stream_with_timestamps) { described_class.new(client) }
  let(:voice_id) { "21m00Tcm4TlvDq8ikWAM" }
  let(:text) { "Hello, this is a streaming test with timestamps." }

  describe "#stream" do
    let(:streaming_response_chunks) do
      [
        {
          "audio_base64" => "chunk1_base64_data",
          "alignment" => {
            "characters" => ["H", "e", "l"],
            "character_start_times_seconds" => [0.0, 0.1, 0.2],
            "character_end_times_seconds" => [0.1, 0.2, 0.3]
          },
          "normalized_alignment" => {
            "characters" => ["H", "e", "l"],
            "character_start_times_seconds" => [0.0, 0.1, 0.2],
            "character_end_times_seconds" => [0.1, 0.2, 0.3]
          }
        },
        {
          "audio_base64" => "chunk2_base64_data",
          "alignment" => {
            "characters" => ["l", "o"],
            "character_start_times_seconds" => [0.3, 0.4],
            "character_end_times_seconds" => [0.4, 0.5]
          },
          "normalized_alignment" => {
            "characters" => ["l", "o"],
            "character_start_times_seconds" => [0.3, 0.4],
            "character_end_times_seconds" => [0.4, 0.5]
          }
        }
      ]
    end

    before do
      # Mock the post_streaming_with_timestamps method to simulate streaming chunks
      allow(client).to receive(:post_streaming_with_timestamps) do |endpoint, body, &block|
        if block
          streaming_response_chunks.each { |chunk| block.call(chunk) }
        end
        double("response", status: 200, body: "streaming_complete")
      end
    end

    context "with required parameters only" do
      it "streams speech with timestamps successfully" do
        received_chunks = []
        
        text_to_speech_stream_with_timestamps.stream(voice_id, text) do |chunk|
          received_chunks << chunk
        end

        expect(received_chunks.length).to eq(2)
        expect(received_chunks[0]["audio_base64"]).to eq("chunk1_base64_data")
        expect(received_chunks[0]["alignment"]["characters"]).to eq(["H", "e", "l"])
        expect(received_chunks[1]["audio_base64"]).to eq("chunk2_base64_data")
        expect(received_chunks[1]["alignment"]["characters"]).to eq(["l", "o"])
      end

      it "calls the correct endpoint" do
        text_to_speech_stream_with_timestamps.stream(voice_id, text) { |chunk| }

        expect(client).to have_received(:post_streaming_with_timestamps)
          .with("/v1/text-to-speech/#{voice_id}/stream/with-timestamps", { text: text })
      end
    end

    context "with model_id option" do
      let(:model_id) { "eleven_multilingual_v2" }

      it "includes model_id in the request body" do
        text_to_speech_stream_with_timestamps.stream(voice_id, text, model_id: model_id) { |chunk| }

        expect(client).to have_received(:post_streaming_with_timestamps)
          .with("/v1/text-to-speech/#{voice_id}/stream/with-timestamps", {
            text: text,
            model_id: model_id
          })
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

      it "includes voice_settings in the request body" do
        text_to_speech_stream_with_timestamps.stream(voice_id, text, voice_settings: voice_settings) { |chunk| }

        expect(client).to have_received(:post_streaming_with_timestamps)
          .with("/v1/text-to-speech/#{voice_id}/stream/with-timestamps", {
            text: text,
            voice_settings: voice_settings
          })
      end
    end

    context "with query parameters" do
      let(:output_format) { "mp3_44100_128" }
      let(:enable_logging) { false }
      let(:optimize_streaming_latency) { 1 }

      it "includes query parameters in the URL" do
        text_to_speech_stream_with_timestamps.stream(
          voice_id, 
          text, 
          output_format: output_format,
          enable_logging: enable_logging,
          optimize_streaming_latency: optimize_streaming_latency
        ) { |chunk| }

        expect(client).to have_received(:post_streaming_with_timestamps)
          .with("/v1/text-to-speech/#{voice_id}/stream/with-timestamps?enable_logging=false&optimize_streaming_latency=1&output_format=mp3_44100_128", {
            text: text
          })
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
      let(:next_text) { "This is next text." }
      let(:apply_text_normalization) { "on" }

      it "includes all options in the request body" do
        text_to_speech_stream_with_timestamps.stream(
          voice_id, 
          text, 
          model_id: model_id,
          language_code: language_code,
          voice_settings: voice_settings,
          seed: seed,
          previous_text: previous_text,
          next_text: next_text,
          apply_text_normalization: apply_text_normalization
        ) { |chunk| }

        expect(client).to have_received(:post_streaming_with_timestamps)
          .with("/v1/text-to-speech/#{voice_id}/stream/with-timestamps", {
            text: text,
            model_id: model_id,
            language_code: language_code,
            voice_settings: voice_settings,
            seed: seed,
            previous_text: previous_text,
            next_text: next_text,
            apply_text_normalization: apply_text_normalization
          })
      end
    end

    context "with pronunciation dictionary locators" do
      let(:pronunciation_dictionary_locators) do
        [
          { id: "dict_1", version_id: "v1" },
          { id: "dict_2", version_id: "v2" }
        ]
      end

      it "includes pronunciation_dictionary_locators in the request body" do
        text_to_speech_stream_with_timestamps.stream(
          voice_id, 
          text, 
          pronunciation_dictionary_locators: pronunciation_dictionary_locators
        ) { |chunk| }

        expect(client).to have_received(:post_streaming_with_timestamps)
          .with("/v1/text-to-speech/#{voice_id}/stream/with-timestamps", {
            text: text,
            pronunciation_dictionary_locators: pronunciation_dictionary_locators
          })
      end
    end

    context "with request IDs" do
      let(:previous_request_ids) { ["req_1", "req_2"] }
      let(:next_request_ids) { ["req_3", "req_4"] }

      it "includes request IDs in the request body" do
        text_to_speech_stream_with_timestamps.stream(
          voice_id, 
          text, 
          previous_request_ids: previous_request_ids,
          next_request_ids: next_request_ids
        ) { |chunk| }

        expect(client).to have_received(:post_streaming_with_timestamps)
          .with("/v1/text-to-speech/#{voice_id}/stream/with-timestamps", {
            text: text,
            previous_request_ids: previous_request_ids,
            next_request_ids: next_request_ids
          })
      end
    end

    context "with boolean options" do
      let(:apply_language_text_normalization) { true }
      let(:use_pvc_as_ivc) { false }

      it "includes boolean options correctly in the request body" do
        text_to_speech_stream_with_timestamps.stream(
          voice_id, 
          text, 
          apply_language_text_normalization: apply_language_text_normalization,
          use_pvc_as_ivc: use_pvc_as_ivc
        ) { |chunk| }

        expect(client).to have_received(:post_streaming_with_timestamps)
          .with("/v1/text-to-speech/#{voice_id}/stream/with-timestamps", {
            text: text,
            apply_language_text_normalization: apply_language_text_normalization,
            use_pvc_as_ivc: use_pvc_as_ivc
          })
      end
    end

    context "without block" do
      it "still makes the request but doesn't process chunks" do
        result = text_to_speech_stream_with_timestamps.stream(voice_id, text)

        expect(client).to have_received(:post_streaming_with_timestamps)
          .with("/v1/text-to-speech/#{voice_id}/stream/with-timestamps", { text: text })
        expect(result.status).to eq(200)
      end
    end

    context "with different voice IDs" do
      let(:different_voice_id) { "pNInz6obpgDQGcFmaJgB" }

      it "uses the correct voice ID in the endpoint" do
        text_to_speech_stream_with_timestamps.stream(different_voice_id, text) { |chunk| }

        expect(client).to have_received(:post_streaming_with_timestamps)
          .with("/v1/text-to-speech/#{different_voice_id}/stream/with-timestamps", { text: text })
      end
    end

    context "with different text content" do
      let(:long_text) { "This is a much longer text that should be converted to speech with character-level timing information in streaming mode. It contains multiple sentences and should test the API's ability to handle longer content with precise timestamps in real-time." }

      it "handles longer text content" do
        text_to_speech_stream_with_timestamps.stream(voice_id, long_text) { |chunk| }

        expect(client).to have_received(:post_streaming_with_timestamps)
          .with("/v1/text-to-speech/#{voice_id}/stream/with-timestamps", { text: long_text })
      end
    end

    context "error handling" do
      context "when client raises an error" do
        before do
          allow(client).to receive(:post_streaming_with_timestamps)
            .and_raise(ElevenlabsClient::AuthenticationError, "Invalid API key")
        end

        it "propagates the error" do
          expect {
            text_to_speech_stream_with_timestamps.stream(voice_id, text) { |chunk| }
          }.to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key")
        end
      end
    end
  end

  describe "#text_to_speech_stream_with_timestamps" do
    before do
      allow(client).to receive(:post_streaming_with_timestamps) do |endpoint, body, &block|
        if block
          block.call({ "audio_base64" => "test_data", "alignment" => {} })
        end
        double("response", status: 200)
      end
    end

    it "is an alias for stream method" do
      received_chunks = []
      
      text_to_speech_stream_with_timestamps.text_to_speech_stream_with_timestamps(voice_id, text) do |chunk|
        received_chunks << chunk
      end

      expect(received_chunks.length).to eq(1)
      expect(received_chunks[0]["audio_base64"]).to eq("test_data")
      expect(client).to have_received(:post_streaming_with_timestamps)
        .with("/v1/text-to-speech/#{voice_id}/stream/with-timestamps", { text: text })
    end
  end
end
