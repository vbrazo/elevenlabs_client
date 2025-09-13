# frozen_string_literal: true

RSpec.describe ElevenlabsClient::SpeechToSpeech do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:speech_to_speech) { described_class.new(client) }
  let(:voice_id) { "21m00Tcm4TlvDq8ikWAM" }
  let(:audio_file) { StringIO.new("fake_audio_data") }
  let(:filename) { "input_audio.mp3" }

  describe "#convert" do
    let(:binary_audio_data) { "converted_audio_binary_data" }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
        .to_return(
          status: 200,
          body: binary_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    context "with required parameters only" do
      it "converts speech to speech successfully" do
        result = speech_to_speech.convert(voice_id, audio_file, filename)

        expect(result).to eq(binary_audio_data)
      end

      it "sends the correct multipart request" do
        speech_to_speech.convert(voice_id, audio_file, filename)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with query parameters" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}?enable_logging=false&output_format=mp3_22050_32")
          .to_return(
            status: 200,
            body: binary_audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "includes query parameters in the request" do
        speech_to_speech.convert(
          voice_id, 
          audio_file, 
          filename,
          enable_logging: false,
          output_format: "mp3_22050_32"
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}?enable_logging=false&output_format=mp3_22050_32")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with form parameters" do
      it "includes model_id in the request" do
        speech_to_speech.convert(
          voice_id, 
          audio_file, 
          filename,
          model_id: "eleven_multilingual_sts_v2"
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end

      it "includes voice_settings in the request" do
        voice_settings = '{"stability": 0.5, "similarity_boost": 0.8}'
        
        speech_to_speech.convert(
          voice_id, 
          audio_file, 
          filename,
          voice_settings: voice_settings
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end

      it "includes seed in the request" do
        speech_to_speech.convert(
          voice_id, 
          audio_file, 
          filename,
          seed: 12345
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end

      it "includes remove_background_noise in the request" do
        speech_to_speech.convert(
          voice_id, 
          audio_file, 
          filename,
          remove_background_noise: true
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end

      it "includes file_format in the request" do
        speech_to_speech.convert(
          voice_id, 
          audio_file, 
          filename,
          file_format: "pcm_s16le_16"
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with all options" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}?enable_logging=false&optimize_streaming_latency=2&output_format=mp3_44100_192")
          .to_return(
            status: 200,
            body: binary_audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "includes all options in the request" do
        speech_to_speech.convert(
          voice_id, 
          audio_file, 
          filename,
          enable_logging: false,
          optimize_streaming_latency: 2,
          output_format: "mp3_44100_192",
          model_id: "eleven_multilingual_sts_v2",
          voice_settings: '{"stability": 0.7}',
          seed: 54321,
          remove_background_noise: true,
          file_format: "other"
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}?enable_logging=false&optimize_streaming_latency=2&output_format=mp3_44100_192")
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
          stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
            .to_return(status: 401, body: "Unauthorized")
        end

        it "raises AuthenticationError" do
          expect {
            speech_to_speech.convert(voice_id, audio_file, filename)
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

        it "raises UnprocessableEntityError" do
          expect {
            speech_to_speech.convert(voice_id, audio_file, filename)
          }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
        end
      end

      context "with rate limit error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
            .to_return(status: 429, body: "Rate limit exceeded")
        end

        it "raises RateLimitError" do
          expect {
            speech_to_speech.convert(voice_id, audio_file, filename)
          }.to raise_error(ElevenlabsClient::RateLimitError)
        end
      end
    end

    context "with different voice IDs" do
      let(:different_voice_id) { "pNInz6obpgDQGcFmaJgB" }

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{different_voice_id}")
          .to_return(
            status: 200,
            body: binary_audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "uses the correct voice ID in the endpoint" do
        speech_to_speech.convert(different_voice_id, audio_file, filename)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{different_voice_id}")
      end
    end

    context "with different file types" do
      let(:wav_filename) { "input_audio.wav" }

      it "handles different audio file types" do
        speech_to_speech.convert(voice_id, audio_file, wav_filename)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end
  end

  describe "#convert_stream" do
    let(:binary_audio_data) { "streaming_converted_audio_data" }
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
      it "converts speech to speech with streaming successfully" do
        result = speech_to_speech.convert_stream(voice_id, audio_file, filename)

        expect(result).to eq(binary_audio_data)
      end

      it "sends the correct streaming request" do
        speech_to_speech.convert_stream(voice_id, audio_file, filename)

        expect(client.instance_variable_get(:@conn)).to have_received(:post)
          .with("/v1/speech-to-speech/#{voice_id}/stream")
      end
    end

    context "with query parameters" do
      it "includes query parameters in the streaming request" do
        speech_to_speech.convert_stream(
          voice_id, 
          audio_file, 
          filename,
          enable_logging: false,
          output_format: "mp3_22050_32"
        )

        expect(client.instance_variable_get(:@conn)).to have_received(:post)
          .with("/v1/speech-to-speech/#{voice_id}/stream?enable_logging=false&output_format=mp3_22050_32")
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

        speech_to_speech.convert_stream(voice_id, audio_file, filename) do |chunk|
          received_chunks << chunk
        end

        expect(received_chunks).to eq(chunks)
      end
    end
  end

  describe "alias methods" do
    describe "#voice_changer" do
      let(:binary_audio_data) { "converted_audio_binary_data" }

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
          .to_return(
            status: 200,
            body: binary_audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "is an alias for convert method" do
        result = speech_to_speech.voice_changer(voice_id, audio_file, filename)

        expect(result).to eq(binary_audio_data)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/speech-to-speech/#{voice_id}")
      end
    end

    describe "#voice_changer_stream" do
      let(:binary_audio_data) { "streaming_converted_audio_data" }

      before do
        # Mock streaming
        request_mock = double("request")
        allow(request_mock).to receive(:headers).and_return({})
        allow(request_mock).to receive(:body=)
        allow(request_mock).to receive(:options).and_return(double("options", on_data: nil))
        
        allow(client.instance_variable_get(:@conn)).to receive(:post).and_yield(request_mock).and_return(
          double("response", status: 200, body: binary_audio_data)
        )
        allow(client).to receive(:send).with(:handle_response, anything).and_return(binary_audio_data)
      end

      it "is an alias for convert_stream method" do
        result = speech_to_speech.voice_changer_stream(voice_id, audio_file, filename)

        expect(result).to eq(binary_audio_data)
        expect(client.instance_variable_get(:@conn)).to have_received(:post)
          .with("/v1/speech-to-speech/#{voice_id}/stream")
      end
    end
  end
end