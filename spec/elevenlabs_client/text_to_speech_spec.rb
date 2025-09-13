# frozen_string_literal: true

RSpec.describe ElevenlabsClient::TextToSpeech do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:text_to_speech) { described_class.new(client) }
  let(:voice_id) { "21m00Tcm4TlvDq8ikWAM" }
  let(:text) { "Hello, this is a test of the text-to-speech functionality." }

  describe "#convert" do
    let(:binary_audio_data) { "fake_mp3_binary_data_here" }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
        .to_return(
          status: 200,
          body: binary_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    context "with required parameters only" do
      it "converts text to speech successfully" do
        result = text_to_speech.convert(voice_id, text)

        expect(result).to eq(binary_audio_data)
      end

      it "sends the correct request" do
        text_to_speech.convert(voice_id, text)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
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
      let(:model_id) { "eleven_monolingual_v1" }

      it "includes model_id in the request" do
        text_to_speech.convert(voice_id, text, model_id: model_id)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
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
        text_to_speech.convert(voice_id, text, voice_settings: voice_settings)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
          .with(
            body: {
              text: text,
              voice_settings: voice_settings
            }.to_json
          )
      end
    end

    context "with all options" do
      let(:model_id) { "eleven_multilingual_v1" }
      let(:voice_settings) do
        {
          stability: 0.7,
          similarity_boost: 0.9,
          style: 0.1,
          use_speaker_boost: false
        }
      end

      it "includes all options in the request" do
        text_to_speech.convert(
          voice_id, 
          text, 
          model_id: model_id,
          voice_settings: voice_settings
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
          .with(
            body: {
              text: text,
              model_id: model_id,
              voice_settings: voice_settings
            }.to_json
          )
      end
    end

    context "with optimize_streaming option" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
          .with(
            headers: {
              "Accept" => "audio/mpeg",
              "Transfer-Encoding" => "chunked"
            }
          )
          .to_return(
            status: 200,
            body: binary_audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "includes streaming headers" do
        text_to_speech.convert(voice_id, text, optimize_streaming: true)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
          .with(
            headers: {
              "xi-api-key" => api_key,
              "Content-Type" => "application/json",
              "Accept" => "audio/mpeg",
              "Transfer-Encoding" => "chunked"
            }
          )
      end

      it "returns binary audio data" do
        result = text_to_speech.convert(voice_id, text, optimize_streaming: true)

        expect(result).to eq(binary_audio_data)
      end
    end

    context "when API returns an error" do
      context "with authentication error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
            .to_return(status: 401, body: "Unauthorized")
        end

        it "raises AuthenticationError" do
          expect {
            text_to_speech.convert(voice_id, text)
          }.to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key or authentication failed")
        end
      end

      context "with rate limit error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
            .to_return(status: 429, body: "Rate limit exceeded")
        end

        it "raises RateLimitError" do
          expect {
            text_to_speech.convert(voice_id, text)
          }.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
        end
      end

      context "with validation error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
            .to_return(status: 400, body: "Invalid voice ID")
        end

        it "raises ValidationError" do
          expect {
            text_to_speech.convert(voice_id, text)
          }.to raise_error(ElevenlabsClient::ValidationError)
        end
      end

      context "with server error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
            .to_return(status: 500, body: "Internal Server Error")
        end

        it "raises APIError" do
          expect {
            text_to_speech.convert(voice_id, text)
          }.to raise_error(ElevenlabsClient::APIError)
        end
      end
    end

    context "with different voice IDs" do
      let(:different_voice_id) { "pNInz6obpgDQGcFmaJgB" }

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{different_voice_id}")
          .to_return(
            status: 200,
            body: binary_audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "uses the correct voice ID in the endpoint" do
        text_to_speech.convert(different_voice_id, text)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{different_voice_id}")
      end
    end

    context "with different text content" do
      let(:long_text) { "This is a much longer text that should be converted to speech. It contains multiple sentences and should test the API's ability to handle longer content." }

      it "handles longer text content" do
        text_to_speech.convert(voice_id, long_text)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
          .with(
            body: { text: long_text }.to_json
          )
      end
    end
  end

  describe "#text_to_speech" do
    let(:binary_audio_data) { "fake_mp3_binary_data_here" }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
        .to_return(
          status: 200,
          body: binary_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "is an alias for convert method" do
      result = text_to_speech.text_to_speech(voice_id, text)

      expect(result).to eq(binary_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
    end
  end
end
