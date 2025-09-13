# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Audio Isolation Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:audio_file) { StringIO.new("fake_audio_data") }
  let(:filename) { "test_audio.mp3" }
  let(:isolated_audio_data) { "isolated_audio_binary_data" }

  describe "client.audio_isolation accessor" do
    it "provides access to audio_isolation endpoint" do
      expect(client.audio_isolation).to be_an_instance_of(ElevenlabsClient::AudioIsolation)
    end
  end

  describe "audio isolation functionality via client" do
    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/audio-isolation")
        .to_return(
          status: 200,
          body: isolated_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "isolates audio through client interface" do
      result = client.audio_isolation.isolate(audio_file, filename)

      expect(result).to eq(isolated_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-isolation")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end

    it "supports file format options" do
      result = client.audio_isolation.isolate(audio_file, filename, file_format: "pcm_s16le_16")

      expect(result).to eq(isolated_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-isolation")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end
  end

  describe "streaming audio isolation functionality" do
    let(:streaming_chunks) { ["chunk1", "chunk2", "chunk3"] }

    before do
      # Mock the connection and response for streaming
      request_mock = double("request")
      allow(request_mock).to receive(:headers).and_return({})
      allow(request_mock).to receive(:body=)
      allow(request_mock).to receive(:options).and_return(double("options", on_data: nil))
      
      allow(client.instance_variable_get(:@conn)).to receive(:post).and_yield(request_mock).and_return(
        double("response", status: 200, body: isolated_audio_data)
      )
      allow(client).to receive(:send).with(:handle_response, anything).and_return(isolated_audio_data)
    end

    it "isolates audio with streaming through client interface" do
      result = client.audio_isolation.isolate_stream(audio_file, filename)

      expect(result).to eq(isolated_audio_data)
      expect(client.instance_variable_get(:@conn)).to have_received(:post)
        .with("/v1/audio-isolation/stream")
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
        double("response", status: 200, body: isolated_audio_data)
      )
      allow(client).to receive(:send).with(:handle_response, anything).and_return(isolated_audio_data)

      client.audio_isolation.isolate_stream(audio_file, filename) do |chunk|
        received_chunks << chunk
      end

      expect(received_chunks).to eq(streaming_chunks)
    end
  end

  describe "binary response handling" do
    context "when API returns binary audio data" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/audio-isolation")
          .to_return(
            status: 200,
            body: isolated_audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "returns the raw binary data" do
        result = client.audio_isolation.isolate(audio_file, filename)

        expect(result).to eq(isolated_audio_data)
        expect(result).to be_a(String)
      end
    end
  end

  describe "error handling integration" do
    context "with authentication error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/audio-isolation")
          .to_return(status: 401, body: "Unauthorized")
      end

      it "raises AuthenticationError through client" do
        expect {
          client.audio_isolation.isolate(audio_file, filename)
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    context "with unprocessable entity error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/audio-isolation")
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
          client.audio_isolation.isolate(audio_file, filename)
        }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end

    context "with rate limit error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/audio-isolation")
          .to_return(status: 429, body: "Rate limit exceeded")
      end

      it "raises RateLimitError through client" do
        expect {
          client.audio_isolation.isolate(audio_file, filename)
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

        stub_request(:post, "https://configured.elevenlabs.io/v1/audio-isolation")
          .to_return(
            status: 200,
            body: isolated_audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "uses configured settings for audio isolation requests" do
        client = ElevenlabsClient.new
        result = client.audio_isolation.isolate(audio_file, filename)

        expect(result).to eq(isolated_audio_data)
        expect(WebMock).to have_requested(:post, "https://configured.elevenlabs.io/v1/audio-isolation")
          .with(headers: { "xi-api-key" => "configured_api_key" })
      end
    end
  end

  describe "Rails usage example" do
    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/audio-isolation")
        .to_return(
          status: 200,
          body: isolated_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "works as expected in a Rails-like environment" do
      # This simulates typical Rails usage
      client = ElevenlabsClient.new(api_key: api_key)
      
      # Isolate audio with specific format
      isolated_audio = client.audio_isolation.isolate(
        audio_file,
        "noisy_recording.wav",
        file_format: "other"
      )

      expect(isolated_audio).to eq(isolated_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-isolation")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end
  end

  describe "multipart file handling" do
    let(:file_content) { "binary_audio_content_here" }
    let(:test_file) { StringIO.new(file_content) }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/audio-isolation")
        .to_return(
          status: 200,
          body: isolated_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "properly handles file uploads in multipart requests" do
      result = client.audio_isolation.isolate(test_file, "test.mp3")

      expect(result).to eq(isolated_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-isolation")
    end

    it "handles different audio file extensions" do
      %w[mp3 wav flac m4a].each do |ext|
        client.audio_isolation.isolate(test_file, "test.#{ext}")
      end
      
      # Expect 4 requests total (one for each file extension)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-isolation").times(4)
    end
  end
end
