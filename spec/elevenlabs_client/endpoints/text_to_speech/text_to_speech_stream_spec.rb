# frozen_string_literal: true

RSpec.describe "TextToSpeech#stream" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:text_to_speech_stream) { ElevenlabsClient::TextToSpeech.new(client) }
  let(:voice_id) { "21m00Tcm4TlvDq8ikWAM" }
  let(:text) { "Hello, this is a streaming test." }

  describe "#stream" do
    let(:audio_chunks) { ["chunk1", "chunk2", "chunk3"] }
    let(:received_chunks) { [] }

    before do
      # Mock the streaming response
      allow(client).to receive(:post_streaming).and_yield("chunk1").and_yield("chunk2").and_yield("chunk3")
    end

    context "with required parameters only" do
      it "streams audio chunks successfully" do
        text_to_speech_stream.stream(voice_id, text) do |chunk|
          received_chunks << chunk
        end

        expect(received_chunks).to eq(audio_chunks)
      end

      it "sends the correct request with default parameters" do
        expect(client).to receive(:post_streaming).with(
          "/v1/text-to-speech/#{voice_id}/stream?output_format=mp3_44100_128",
          {
            text: text,
            model_id: "eleven_multilingual_v2"
          }
        )

        text_to_speech_stream.stream(voice_id, text) { |chunk| }
      end
    end

    context "with custom model_id" do
      let(:model_id) { "eleven_monolingual_v1" }

      it "includes custom model_id in the request" do
        expect(client).to receive(:post_streaming).with(
          "/v1/text-to-speech/#{voice_id}/stream?output_format=mp3_44100_128",
          {
            text: text,
            model_id: model_id
          }
        )

        text_to_speech_stream.stream(voice_id, text, model_id: model_id) { |chunk| }
      end
    end

    context "with custom output_format" do
      let(:output_format) { "pcm_16000" }

      it "includes custom output_format in the URL" do
        expect(client).to receive(:post_streaming).with(
          "/v1/text-to-speech/#{voice_id}/stream?output_format=#{output_format}",
          {
            text: text,
            model_id: "eleven_multilingual_v2"
          }
        )

        text_to_speech_stream.stream(voice_id, text, output_format: output_format) { |chunk| }
      end
    end

    context "with voice_settings" do
      let(:voice_settings) do
        {
          stability: 0.5,
          similarity_boost: 0.8,
          style: 0.2,
          use_speaker_boost: true
        }
      end

      it "includes voice_settings in the request" do
        expect(client).to receive(:post_streaming).with(
          "/v1/text-to-speech/#{voice_id}/stream?output_format=mp3_44100_128",
          {
            text: text,
            model_id: "eleven_multilingual_v2",
            voice_settings: voice_settings
          }
        )

        text_to_speech_stream.stream(voice_id, text, voice_settings: voice_settings) { |chunk| }
      end
    end

    context "with all options" do
      let(:model_id) { "eleven_turbo_v2" }
      let(:output_format) { "mp3_22050_32" }
      let(:voice_settings) do
        {
          stability: 0.7,
          similarity_boost: 0.9
        }
      end

      it "includes all options in the request" do
        expect(client).to receive(:post_streaming).with(
          "/v1/text-to-speech/#{voice_id}/stream?output_format=#{output_format}",
          {
            text: text,
            model_id: model_id,
            voice_settings: voice_settings
          }
        )

        text_to_speech_stream.stream(
          voice_id, 
          text, 
          model_id: model_id,
          output_format: output_format,
          voice_settings: voice_settings
        ) { |chunk| }
      end
    end

    context "without block" do
      before do
        allow(client).to receive(:post_streaming).and_return(double("Response", status: 200))
      end

      it "still makes the request without error" do
        expect(client).to receive(:post_streaming).with(
          "/v1/text-to-speech/#{voice_id}/stream?output_format=mp3_44100_128",
          {
            text: text,
            model_id: "eleven_multilingual_v2"
          }
        )

        expect {
          text_to_speech_stream.stream(voice_id, text)
        }.not_to raise_error
      end
    end

    context "with different voice IDs" do
      let(:different_voice_id) { "pNInz6obpgDQGcFmaJgB" }

      it "uses the correct voice ID in the endpoint" do
        expect(client).to receive(:post_streaming).with(
          "/v1/text-to-speech/#{different_voice_id}/stream?output_format=mp3_44100_128",
          anything
        )

        text_to_speech_stream.stream(different_voice_id, text) { |chunk| }
      end
    end

    context "with longer text content" do
      let(:long_text) { "This is a much longer text that should be streamed as audio. It contains multiple sentences and should test the streaming API's ability to handle longer content in real-time." }

      it "handles longer text content" do
        expect(client).to receive(:post_streaming).with(
          anything,
          hash_including(text: long_text)
        )

        text_to_speech_stream.stream(voice_id, long_text) { |chunk| }
      end
    end

    context "when collecting all chunks" do
      it "allows collecting all streamed chunks" do
        all_chunks = []
        
        text_to_speech_stream.stream(voice_id, text) do |chunk|
          all_chunks << chunk
        end

        expect(all_chunks).to eq(audio_chunks)
        expect(all_chunks.join).to eq("chunk1chunk2chunk3")
      end
    end
  end

  describe "error handling" do
    context "when client raises AuthenticationError" do
      before do
        allow(client).to receive(:post_streaming).and_raise(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end

      it "propagates the AuthenticationError" do
        expect {
          text_to_speech_stream.stream(voice_id, text) { |chunk| }
        }.to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end
    end

    context "when client raises RateLimitError" do
      before do
        allow(client).to receive(:post_streaming).and_raise(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end

      it "propagates the RateLimitError" do
        expect {
          text_to_speech_stream.stream(voice_id, text) { |chunk| }
        }.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end
    end

    context "when client raises ValidationError" do
      before do
        allow(client).to receive(:post_streaming).and_raise(ElevenlabsClient::ValidationError, "Invalid voice ID")
      end

      it "propagates the ValidationError" do
        expect {
          text_to_speech_stream.stream(voice_id, text) { |chunk| }
        }.to raise_error(ElevenlabsClient::ValidationError, "Invalid voice ID")
      end
    end

    context "when client raises APIError" do
      before do
        allow(client).to receive(:post_streaming).and_raise(ElevenlabsClient::APIError, "Server error")
      end

      it "propagates the APIError" do
        expect {
          text_to_speech_stream.stream(voice_id, text) { |chunk| }
        }.to raise_error(ElevenlabsClient::APIError, "Server error")
      end
    end
  end
end
