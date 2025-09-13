# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Speech-to-Speech Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:voice_id) { "21m00Tcm4TlvDq8ikWAM" }
  let(:audio_file) { StringIO.new("fake_audio_data") }
  let(:filename) { "input_audio.mp3" }
  let(:converted_audio_data) { "converted_audio_binary_data" }

  describe "client.speech_to_speech accessor" do
    it "provides access to speech_to_speech endpoint" do
      expect(client.speech_to_speech).to be_an_instance_of(ElevenlabsClient::SpeechToSpeech)
    end
  end

  describe "speech-to-speech functionality via client" do
    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
        .to_return(
          status: 200,
          body: converted_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "converts speech to speech through client interface" do
      result = client.speech_to_speech.convert(voice_id, audio_file, filename)

      expect(result).to eq(converted_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end

    it "supports the voice_changer alias method" do
      result = client.speech_to_speech.voice_changer(voice_id, audio_file, filename)

      expect(result).to eq(converted_audio_data)
    end

    it "supports query parameters" do
      stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}?output_format=mp3_22050_32&enable_logging=false")
        .to_return(
          status: 200,
          body: converted_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )

      result = client.speech_to_speech.convert(
        voice_id, 
        audio_file, 
        filename,
        output_format: "mp3_22050_32",
        enable_logging: false
      )

      expect(result).to eq(converted_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}?output_format=mp3_22050_32&enable_logging=false")
    end

    it "supports form parameters" do
      result = client.speech_to_speech.convert(
        voice_id, 
        audio_file, 
        filename,
        model_id: "eleven_multilingual_sts_v2",
        remove_background_noise: true,
        file_format: "pcm_s16le_16"
      )

      expect(result).to eq(converted_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end
  end

  describe "streaming speech-to-speech functionality" do
    let(:streaming_chunks) { ["chunk1", "chunk2", "chunk3"] }

    before do
      # Mock the connection and response for streaming
      request_mock = double("request")
      allow(request_mock).to receive(:headers).and_return({})
      allow(request_mock).to receive(:body=)
      allow(request_mock).to receive(:options).and_return(double("options", on_data: nil))
      
      allow(client.instance_variable_get(:@conn)).to receive(:post).and_yield(request_mock).and_return(
        double("response", status: 200, body: converted_audio_data)
      )
      allow(client).to receive(:send).with(:handle_response, anything).and_return(converted_audio_data)
    end

    it "converts speech to speech with streaming through client interface" do
      result = client.speech_to_speech.convert_stream(voice_id, audio_file, filename)

      expect(result).to eq(converted_audio_data)
      expect(client.instance_variable_get(:@conn)).to have_received(:post)
        .with("/v1/speech-to-speech/#{voice_id}/stream")
    end

    it "supports the voice_changer_stream alias method" do
      result = client.speech_to_speech.voice_changer_stream(voice_id, audio_file, filename)

      expect(result).to eq(converted_audio_data)
    end

    it "handles streaming chunks with block" do
      received_chunks = []
      
      # Mock the streaming behavior with proper request mock
      request_mock = double("request")
      allow(request_mock).to receive(:headers).and_return({})
      allow(request_mock).to receive(:body=)
      options_mock = double("options")
      allow(request_mock).to receive(:options).and_return(options_mock)
      
      allow(options_mock).to receive(:on_data=) do |proc|
        streaming_chunks.each { |chunk| proc.call(chunk, nil) }
      end
      
      allow(client.instance_variable_get(:@conn)).to receive(:post).and_yield(request_mock).and_return(
        double("response", status: 200, body: converted_audio_data)
      )
      allow(client).to receive(:send).with(:handle_response, anything).and_return(converted_audio_data)

      client.speech_to_speech.convert_stream(voice_id, audio_file, filename) do |chunk|
        received_chunks << chunk
      end

      expect(received_chunks).to eq(streaming_chunks)
    end

    it "supports query parameters in streaming" do
      client.speech_to_speech.convert_stream(
        voice_id, 
        audio_file, 
        filename,
        output_format: "mp3_44100_192",
        optimize_streaming_latency: 2
      )

      # Check that the endpoint was called with query parameters (order may vary)
      expect(client.instance_variable_get(:@conn)).to have_received(:post) do |endpoint|
        expect(endpoint).to include("/v1/speech-to-speech/#{voice_id}/stream")
        expect(endpoint).to include("output_format=mp3_44100_192")
        expect(endpoint).to include("optimize_streaming_latency=2")
      end
    end
  end

  describe "binary response handling" do
    context "when API returns binary audio data" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
          .to_return(
            status: 200,
            body: converted_audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "returns the raw binary data" do
        result = client.speech_to_speech.convert(voice_id, audio_file, filename)

        expect(result).to eq(converted_audio_data)
        expect(result).to be_a(String)
      end
    end
  end

  describe "error handling integration" do
    context "with authentication error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
          .to_return(status: 401, body: "Unauthorized")
      end

      it "raises AuthenticationError through client" do
        expect {
          client.speech_to_speech.convert(voice_id, audio_file, filename)
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    context "with unprocessable entity error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
          .to_return(
            status: 422,
            body: {
              detail: [
                {
                  loc: ["audio"],
                  msg: "Invalid audio file format",
                  type: "value_error"
                }
              ]
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises UnprocessableEntityError through client" do
        expect {
          client.speech_to_speech.convert(voice_id, audio_file, filename)
        }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end

    context "with rate limit error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
          .to_return(status: 429, body: "Rate limit exceeded")
      end

      it "raises RateLimitError through client" do
        expect {
          client.speech_to_speech.convert(voice_id, audio_file, filename)
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

        stub_request(:post, "https://configured.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
          .to_return(
            status: 200,
            body: converted_audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "uses configured settings for speech-to-speech requests" do
        client = ElevenlabsClient.new
        result = client.speech_to_speech.convert(voice_id, audio_file, filename)

        expect(result).to eq(converted_audio_data)
        expect(WebMock).to have_requested(:post, "https://configured.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
          .with(headers: { "xi-api-key" => "configured_api_key" })
      end
    end
  end

  describe "Rails usage example" do
    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}?output_format=mp3_44100_128&enable_logging=true")
        .to_return(
          status: 200,
          body: converted_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "works as expected in a Rails-like environment" do
      # This simulates typical Rails usage
      client = ElevenlabsClient.new(api_key: api_key)
      
      # Convert speech with voice changer
      converted_audio = client.speech_to_speech.convert(
        voice_id,
        audio_file,
        "user_recording.wav",
        model_id: "eleven_multilingual_sts_v2",
        output_format: "mp3_44100_128",
        enable_logging: true,
        remove_background_noise: true,
        voice_settings: '{"stability": 0.5, "similarity_boost": 0.8}'
      )

      expect(converted_audio).to eq(converted_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}?output_format=mp3_44100_128&enable_logging=true")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end
  end

  describe "multipart file handling" do
    let(:file_content) { "binary_audio_content_here" }
    let(:test_file) { StringIO.new(file_content) }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
        .to_return(
          status: 200,
          body: converted_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "properly handles file uploads in multipart requests" do
      result = client.speech_to_speech.convert(voice_id, test_file, "test.mp3")

      expect(result).to eq(converted_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
    end

    it "handles different audio file extensions" do
      %w[mp3 wav flac m4a].each do |ext|
        client.speech_to_speech.convert(voice_id, test_file, "test.#{ext}")
      end
      
      # Expect 4 requests total (one for each file extension)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}").times(4)
    end
  end

  describe "voice settings handling" do
    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
        .to_return(
          status: 200,
          body: converted_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "handles JSON voice settings" do
      voice_settings = '{"stability": 0.7, "similarity_boost": 0.9, "style": 0.2, "use_speaker_boost": true}'
      
      result = client.speech_to_speech.convert(
        voice_id, 
        audio_file, 
        filename,
        voice_settings: voice_settings
      )

      expect(result).to eq(converted_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end
  end

  describe "deterministic generation" do
    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
        .to_return(
          status: 200,
          body: converted_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "supports seed for deterministic results" do
      seed = 12345
      
      result = client.speech_to_speech.convert(
        voice_id, 
        audio_file, 
        filename,
        seed: seed
      )

      expect(result).to eq(converted_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end
  end

  describe "background noise removal" do
    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
        .to_return(
          status: 200,
          body: converted_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "supports background noise removal" do
      result = client.speech_to_speech.convert(
        voice_id, 
        audio_file, 
        filename,
        remove_background_noise: true
      )

      expect(result).to eq(converted_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end
  end

  describe "file format optimization" do
    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
        .to_return(
          status: 200,
          body: converted_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "supports PCM format for lower latency" do
      result = client.speech_to_speech.convert(
        voice_id, 
        audio_file, 
        filename,
        file_format: "pcm_s16le_16"
      )

      expect(result).to eq(converted_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end

    it "supports other format as default" do
      result = client.speech_to_speech.convert(
        voice_id, 
        audio_file, 
        filename,
        file_format: "other"
      )

      expect(result).to eq(converted_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end
  end
end