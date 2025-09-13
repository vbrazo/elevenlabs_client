# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Text-to-Speech Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:voice_id) { "21m00Tcm4TlvDq8ikWAM" }
  let(:text) { "Hello, this is a test." }
  let(:binary_audio_data) { "fake_mp3_binary_data_here" }

  describe "client.text_to_speech accessor" do
    it "provides access to text_to_speech endpoint" do
      expect(client.text_to_speech).to be_an_instance_of(ElevenlabsClient::TextToSpeech)
    end
  end

  describe "text-to-speech functionality via client" do
    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
        .to_return(
          status: 200,
          body: binary_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "converts text to speech through client interface" do
      result = client.text_to_speech.convert(voice_id, text)

      expect(result).to eq(binary_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
        .with(
          headers: { "xi-api-key" => api_key },
          body: { text: text }.to_json
        )
    end

    it "supports the text_to_speech alias method" do
      result = client.text_to_speech.text_to_speech(voice_id, text)

      expect(result).to eq(binary_audio_data)
    end
  end

  describe "binary response handling" do
    context "when API returns binary audio data" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
          .to_return(
            status: 200,
            body: binary_audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "returns the raw binary data" do
        result = client.text_to_speech.convert(voice_id, text)

        expect(result).to eq(binary_audio_data)
        expect(result).to be_a(String)
      end
    end

    context "when using streaming optimization" do
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
            headers: { 
              "Content-Type" => "audio/mpeg",
              "Transfer-Encoding" => "chunked"
            }
          )
      end

      it "handles streaming responses correctly" do
        result = client.text_to_speech.convert(voice_id, text, optimize_streaming: true)

        expect(result).to eq(binary_audio_data)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
          .with(
            headers: {
              "xi-api-key" => api_key,
              "Accept" => "audio/mpeg",
              "Transfer-Encoding" => "chunked"
            }
          )
      end
    end
  end

  describe "error handling integration" do
    context "with authentication error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
          .to_return(status: 401, body: "Unauthorized")
      end

      it "raises AuthenticationError through client" do
        expect {
          client.text_to_speech.convert(voice_id, text)
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    context "with rate limit error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
          .to_return(status: 429, body: "Rate limit exceeded")
      end

      it "raises RateLimitError through client" do
        expect {
          client.text_to_speech.convert(voice_id, text)
        }.to raise_error(ElevenlabsClient::RateLimitError)
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

        stub_request(:post, "https://configured.elevenlabs.io/v1/text-to-speech/#{voice_id}")
          .to_return(
            status: 200,
            body: binary_audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "uses configured settings for TTS requests" do
        client = ElevenlabsClient.new
        result = client.text_to_speech.convert(voice_id, text)

        expect(result).to eq(binary_audio_data)
        expect(WebMock).to have_requested(:post, "https://configured.elevenlabs.io/v1/text-to-speech/#{voice_id}")
          .with(headers: { "xi-api-key" => "configured_api_key" })
      end
    end
  end

  describe "Rails usage example" do
    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
        .to_return(
          status: 200,
          body: binary_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "works as expected in a Rails-like environment" do
      # This simulates typical Rails usage
      client = ElevenlabsClient.new(api_key: api_key)
      
      # Convert text to speech with voice settings
      audio_data = client.text_to_speech.convert(
        voice_id,
        "Welcome to our application!",
        model_id: "eleven_monolingual_v1",
        voice_settings: {
          stability: 0.5,
          similarity_boost: 0.8
        }
      )

      expect(audio_data).to eq(binary_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
        .with(
          body: {
            text: "Welcome to our application!",
            model_id: "eleven_monolingual_v1",
            voice_settings: {
              stability: 0.5,
              similarity_boost: 0.8
            }
          }.to_json
        )
    end
  end
end
