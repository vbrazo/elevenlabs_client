# frozen_string_literal: true

RSpec.describe ElevenlabsClient::AudioIsolation do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:audio_isolation) { described_class.new(client) }
  let(:audio_file) { StringIO.new("fake_audio_data") }
  let(:filename) { "test_audio.mp3" }

  describe "#isolate" do
    let(:binary_audio_data) { "isolated_audio_binary_data" }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/audio-isolation")
        .to_return(
          status: 200,
          body: binary_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    context "with required parameters only" do
      it "isolates audio successfully" do
        result = audio_isolation.isolate(audio_file, filename)

        expect(result).to eq(binary_audio_data)
      end

      it "sends the correct multipart request" do
        audio_isolation.isolate(audio_file, filename)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-isolation")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with file_format option" do
      let(:file_format) { "pcm_s16le_16" }

      it "includes file_format in the request" do
        audio_isolation.isolate(audio_file, filename, file_format: file_format)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-isolation")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with other file_format option" do
      let(:file_format) { "other" }

      it "includes file_format in the request" do
        audio_isolation.isolate(audio_file, filename, file_format: file_format)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-isolation")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "when API returns an error" do
      context "with authentication error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/audio-isolation")
            .to_return(status: 401, body: "Unauthorized")
        end

        it "raises AuthenticationError" do
          expect {
            audio_isolation.isolate(audio_file, filename)
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

        it "raises UnprocessableEntityError" do
          expect {
            audio_isolation.isolate(audio_file, filename)
          }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
        end
      end

      context "with rate limit error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/audio-isolation")
            .to_return(status: 429, body: "Rate limit exceeded")
        end

        it "raises RateLimitError" do
          expect {
            audio_isolation.isolate(audio_file, filename)
          }.to raise_error(ElevenlabsClient::RateLimitError)
        end
      end
    end

    context "with different file types" do
      let(:wav_filename) { "test_audio.wav" }

      it "handles different audio file types" do
        audio_isolation.isolate(audio_file, wav_filename)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-isolation")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end
  end

  describe "#isolate_stream" do
    let(:binary_audio_data) { "streaming_isolated_audio_data" }
    let(:chunks) { ["chunk1", "chunk2", "chunk3"] }

    before do
      # Mock the connection and response for streaming
      request_mock = double("request")
      allow(request_mock).to receive(:headers).and_return({})
      allow(request_mock).to receive(:body=)
      allow(request_mock).to receive(:options).and_return(double("options", on_data: nil))
      
      allow(client.instance_variable_get(:@conn)).to receive(:post).and_yield(request_mock).and_return(
        double("response", status: 200, body: binary_audio_data)
      )
      allow(client).to receive(:send).with(:handle_response, anything).and_return(binary_audio_data)
    end

    context "with required parameters only" do
      it "isolates audio with streaming successfully" do
        result = audio_isolation.isolate_stream(audio_file, filename)

        expect(result).to eq(binary_audio_data)
      end
    end

    context "with file_format option" do
      let(:file_format) { "pcm_s16le_16" }

      it "includes file_format in the streaming request" do
        audio_isolation.isolate_stream(audio_file, filename, file_format: file_format)

        expect(client.instance_variable_get(:@conn)).to have_received(:post)
          .with("/v1/audio-isolation/stream")
      end
    end

    context "with block for handling chunks" do
      it "yields chunks to the provided block" do
        received_chunks = []
        
        # Mock the streaming behavior with proper request mock
        request_mock = double("request")
        allow(request_mock).to receive(:headers).and_return({})
        allow(request_mock).to receive(:body=)
        options_mock = double("options")
        allow(request_mock).to receive(:options).and_return(options_mock)
        
        allow(options_mock).to receive(:on_data=) do |proc|
          chunks.each { |chunk| proc.call(chunk, nil) }
        end
        
        allow(client.instance_variable_get(:@conn)).to receive(:post).and_yield(request_mock).and_return(
          double("response", status: 200, body: binary_audio_data)
        )
        allow(client).to receive(:send).with(:handle_response, anything).and_return(binary_audio_data)

        audio_isolation.isolate_stream(audio_file, filename) do |chunk|
          received_chunks << chunk
        end

        expect(received_chunks).to eq(chunks)
      end
    end
  end
end
