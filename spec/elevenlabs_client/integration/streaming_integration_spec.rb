# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Streaming Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:voice_id) { "21m00Tcm4TlvDq8ikWAM" }
  let(:text) { "Hello, this is a streaming test." }

  describe "client.text_to_speech_stream accessor" do
    it "provides access to text_to_speech_stream endpoint" do
      expect(client.text_to_speech_stream).to be_an_instance_of(ElevenlabsClient::TextToSpeechStream)
    end
  end

  describe "streaming functionality via client" do
    let(:mock_response) { double("Faraday::Response", status: 200) }
    let(:audio_chunks) { ["audio_chunk_1", "audio_chunk_2", "audio_chunk_3"] }

    it "streams text-to-speech through client interface" do
      # Mock the post_streaming method to verify correct parameters
      expect(client).to receive(:post_streaming) do |endpoint, body, &block|
        expect(endpoint).to eq("/v1/text-to-speech/#{voice_id}/stream?output_format=mp3_44100_128")
        expect(body[:text]).to eq(text)
        expect(body[:model_id]).to eq("eleven_multilingual_v2")
        mock_response
      end

      result = client.text_to_speech_stream.stream(voice_id, text) { |chunk| }

      expect(result).to eq(mock_response)
    end

    it "supports the text_to_speech_stream alias method" do
      expect(client).to receive(:post_streaming).and_return(mock_response)

      result = client.text_to_speech_stream.text_to_speech_stream(voice_id, text) { |chunk| }

      expect(result).to eq(mock_response)
    end
  end

  describe "post_streaming method" do
    it "has the post_streaming method available" do
      expect(client).to respond_to(:post_streaming)
    end
  end

  describe "error handling integration" do
    context "with authentication error" do
      before do
        allow(client).to receive(:post_streaming).and_raise(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end

      it "raises AuthenticationError through client" do
        expect {
          client.text_to_speech_stream.stream(voice_id, text) { |chunk| }
        }.to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end
    end

    context "with rate limit error" do
      before do
        allow(client).to receive(:post_streaming).and_raise(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end

      it "raises RateLimitError through client" do
        expect {
          client.text_to_speech_stream.stream(voice_id, text) { |chunk| }
        }.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
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
      end

      it "uses configured settings for streaming requests" do
        client = ElevenlabsClient.new
        
        expect(client.api_key).to eq("configured_api_key")
        expect(client.base_url).to eq("https://configured.elevenlabs.io")
        expect(client.text_to_speech_stream).to be_an_instance_of(ElevenlabsClient::TextToSpeechStream)
      end
    end
  end

  describe "Rails usage example" do
    it "provides the necessary interface for Rails streaming" do
      # Verify the client has the streaming interface
      expect(client.text_to_speech_stream).to respond_to(:stream)
      expect(client.text_to_speech_stream).to respond_to(:text_to_speech_stream)
      
      # Verify it accepts the expected parameters
      expect { 
        client.text_to_speech_stream.stream(
          voice_id,
          "Welcome to our streaming service!",
          model_id: "eleven_multilingual_v2",
          voice_settings: {
            stability: 0.6,
            similarity_boost: 0.7
          }
        ) { |chunk| }
      }.not_to raise_error(ArgumentError)
    end
  end
end
