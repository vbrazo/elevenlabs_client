# frozen_string_literal: true

require 'base64'

RSpec.describe "ElevenlabsClient Text-to-Speech Stream with Timestamps Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:voice_id) { "21m00Tcm4TlvDq8ikWAM" }
  let(:text) { "Hello, this is a streaming test with timestamps." }

  describe "client.text_to_speech_stream_with_timestamps accessor" do
    it "provides access to text_to_speech_stream_with_timestamps endpoint" do
      expect(client.text_to_speech_stream_with_timestamps).to be_an_instance_of(ElevenlabsClient::TextToSpeechStreamWithTimestamps)
    end
  end

  describe "streaming text-to-speech with timestamps functionality via client" do
    let(:streaming_chunks) do
      [
        {
          "audio_base64" => "chunk1_base64_data",
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
        },
        {
          "audio_base64" => "chunk2_base64_data",
          "alignment" => {
            "characters" => [",", " ", "t", "h", "i", "s"],
            "character_start_times_seconds" => [0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
            "character_end_times_seconds" => [0.6, 0.7, 0.8, 0.9, 1.0, 1.1]
          },
          "normalized_alignment" => {
            "characters" => [",", " ", "t", "h", "i", "s"],
            "character_start_times_seconds" => [0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
            "character_end_times_seconds" => [0.6, 0.7, 0.8, 0.9, 1.0, 1.1]
          }
        }
      ]
    end

    before do
      # Mock the post_streaming_with_timestamps method
      allow(client).to receive(:post_streaming_with_timestamps) do |endpoint, body, &block|
        if block
          streaming_chunks.each { |chunk| block.call(chunk) }
        end
        double("response", status: 200, body: "streaming_complete")
      end
    end

    it "streams speech with timestamps through client interface" do
      received_chunks = []
      
      result = client.text_to_speech_stream_with_timestamps.stream(voice_id, text) do |chunk|
        received_chunks << chunk
      end

      expect(received_chunks.length).to eq(2)
      
      # Validate first chunk
      expect(received_chunks[0]["audio_base64"]).to eq("chunk1_base64_data")
      expect(received_chunks[0]["alignment"]["characters"]).to eq(["H", "e", "l", "l", "o"])
      expect(received_chunks[0]["alignment"]["character_start_times_seconds"]).to eq([0.0, 0.1, 0.2, 0.3, 0.4])
      
      # Validate second chunk
      expect(received_chunks[1]["audio_base64"]).to eq("chunk2_base64_data")
      expect(received_chunks[1]["alignment"]["characters"]).to eq([",", " ", "t", "h", "i", "s"])
      expect(received_chunks[1]["alignment"]["character_start_times_seconds"]).to eq([0.5, 0.6, 0.7, 0.8, 0.9, 1.0])

      expect(result.status).to eq(200)
      expect(client).to have_received(:post_streaming_with_timestamps)
        .with("/v1/text-to-speech/#{voice_id}/stream/with-timestamps", { text: text })
    end

    it "supports the text_to_speech_stream_with_timestamps alias method" do
      received_chunks = []
      
      client.text_to_speech_stream_with_timestamps.text_to_speech_stream_with_timestamps(voice_id, text) do |chunk|
        received_chunks << chunk
      end

      expect(received_chunks.length).to eq(2)
    end
  end

  describe "real-time processing simulation" do
    let(:realistic_chunks) do
      [
        {
          "audio_base64" => "UklGRkQAAABXQVZFZm10IBAAAAABAAEA...", # Simulated realistic base64
          "alignment" => {
            "characters" => ["H", "e", "l"],
            "character_start_times_seconds" => [0.0, 0.05, 0.1],
            "character_end_times_seconds" => [0.05, 0.1, 0.15]
          }
        },
        {
          "audio_base64" => "VGhpcyBpcyBhIGZha2UgYXVkaW8gY2h1bms=", # Another simulated chunk
          "alignment" => {
            "characters" => ["l", "o", " "],
            "character_start_times_seconds" => [0.15, 0.2, 0.25],
            "character_end_times_seconds" => [0.2, 0.25, 0.3]
          }
        }
      ]
    end

    before do
      allow(client).to receive(:post_streaming_with_timestamps) do |endpoint, body, &block|
        # Simulate realistic streaming with small delays
        realistic_chunks.each_with_index do |chunk, index|
          sleep(0.01) # Simulate network latency
          block.call(chunk) if block
        end
        double("response", status: 200)
      end
    end

    it "handles realistic streaming scenarios with timing continuity" do
      total_audio_data = ""
      all_characters = []
      all_start_times = []
      
      client.text_to_speech_stream_with_timestamps.stream(voice_id, "Hello ") do |chunk|
        # Accumulate audio data
        if chunk["audio_base64"]
          audio_data = Base64.decode64(chunk["audio_base64"])
          total_audio_data += audio_data
        end
        
        # Accumulate timing data
        if chunk["alignment"]
          all_characters.concat(chunk["alignment"]["characters"])
          all_start_times.concat(chunk["alignment"]["character_start_times_seconds"])
        end
      end

      expect(total_audio_data.length).to be > 0
      expect(all_characters.join).to eq("Hello ")
      expect(all_start_times).to eq(all_start_times.sort) # Should be in ascending order
      expect(all_start_times.last).to eq(0.25)
    end
  end

  describe "advanced parameter integration" do
    let(:voice_settings) do
      {
        stability: 0.6,
        similarity_boost: 0.9,
        style: 0.4,
        use_speaker_boost: false
      }
    end

    before do
      allow(client).to receive(:post_streaming_with_timestamps) do |endpoint, body, &block|
        chunk = {
          "audio_base64" => "test_chunk_data",
          "alignment" => { "characters" => ["T"], "character_start_times_seconds" => [0.0] }
        }
        block.call(chunk) if block
        double("response", status: 200)
      end
    end

    it "handles complex parameter combinations for streaming" do
      received_chunks = []
      
      client.text_to_speech_stream_with_timestamps.stream(
        voice_id,
        text,
        model_id: "eleven_multilingual_v2",
        language_code: "en",
        voice_settings: voice_settings,
        output_format: "mp3_44100_128",
        enable_logging: false,
        seed: 67890,
        apply_text_normalization: "auto"
      ) do |chunk|
        received_chunks << chunk
      end

      expect(received_chunks.length).to eq(1)
      expect(client).to have_received(:post_streaming_with_timestamps)
        .with(
          "/v1/text-to-speech/#{voice_id}/stream/with-timestamps?enable_logging=false&output_format=mp3_44100_128",
          {
            text: text,
            model_id: "eleven_multilingual_v2",
            language_code: "en",
            voice_settings: voice_settings,
            seed: 67890,
            apply_text_normalization: "auto"
          }
        )
    end
  end

  describe "error handling during streaming" do
    context "when streaming encounters an error" do
      before do
        allow(client).to receive(:post_streaming_with_timestamps)
          .and_raise(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end

      it "propagates errors from the streaming client" do
        expect {
          client.text_to_speech_stream_with_timestamps.stream(voice_id, text) do |chunk|
            # This block should not be called
          end
        }.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end
    end

    context "when streaming is interrupted" do
      before do
        allow(client).to receive(:post_streaming_with_timestamps) do |endpoint, body, &block|
          # Simulate partial streaming that gets interrupted
          chunk = {
            "audio_base64" => "partial_chunk_data",
            "alignment" => { "characters" => ["T"], "character_start_times_seconds" => [0.0] }
          }
          block.call(chunk) if block
          raise ElevenlabsClient::APIError, "Connection interrupted"
        end
      end

      it "handles partial streaming gracefully" do
        received_chunks = []
        
        expect {
          client.text_to_speech_stream_with_timestamps.stream(voice_id, text) do |chunk|
            received_chunks << chunk
          end
        }.to raise_error(ElevenlabsClient::APIError, "Connection interrupted")

        # Should have received the partial chunk before the error
        expect(received_chunks.length).to eq(1)
        expect(received_chunks[0]["audio_base64"]).to eq("partial_chunk_data")
      end
    end
  end

  describe "Settings integration for streaming" do
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

        # Mock the configured client
        configured_client = ElevenlabsClient.new
        allow(configured_client).to receive(:post_streaming_with_timestamps) do |endpoint, body, &block|
          chunk = {
            "audio_base64" => "configured_chunk_data",
            "alignment" => { "characters" => ["C"], "character_start_times_seconds" => [0.0] }
          }
          block.call(chunk) if block
          double("response", status: 200)
        end
        
        # Replace the client with configured one
        allow(ElevenlabsClient).to receive(:new).and_return(configured_client)
      end

      it "uses configured settings for streaming timestamp TTS requests" do
        client = ElevenlabsClient.new
        received_chunks = []
        
        client.text_to_speech_stream_with_timestamps.stream(voice_id, text) do |chunk|
          received_chunks << chunk
        end

        expect(received_chunks.length).to eq(1)
        expect(received_chunks[0]["audio_base64"]).to eq("configured_chunk_data")
      end
    end
  end

  describe "performance and timing validation" do
    let(:performance_chunks) do
      (0..4).map do |i|
        {
          "audio_base64" => "chunk_#{i}_data",
          "alignment" => {
            "characters" => ["#{i}"],
            "character_start_times_seconds" => [i * 0.1],
            "character_end_times_seconds" => [(i * 0.1) + 0.1]
          }
        }
      end
    end

    before do
      allow(client).to receive(:post_streaming_with_timestamps) do |endpoint, body, &block|
        performance_chunks.each { |chunk| block.call(chunk) } if block
        double("response", status: 200)
      end
    end

    it "maintains timing accuracy across multiple chunks" do
      received_chunks = []
      timing_sequence = []
      
      start_time = Time.now
      
      client.text_to_speech_stream_with_timestamps.stream(voice_id, "01234") do |chunk|
        received_chunks << chunk
        timing_sequence << Time.now - start_time
        
        # Validate chunk timing data
        if chunk["alignment"]
          start_times = chunk["alignment"]["character_start_times_seconds"]
          end_times = chunk["alignment"]["character_end_times_seconds"]
          
          expect(start_times.length).to eq(end_times.length)
          start_times.each_with_index do |start_time, index|
            expect(start_time).to be < end_times[index]
          end
        end
      end

      expect(received_chunks.length).to eq(5)
      expect(timing_sequence.length).to eq(5)
      
      # All chunks should be processed quickly (simulated streaming)
      expect(timing_sequence.max).to be < 1.0 # Should complete within 1 second
    end
  end

  describe "Rails usage example for streaming" do
    before do
      # Stub for any client instance to cover newly instantiated clients
      allow_any_instance_of(ElevenlabsClient::Client).to receive(:post_streaming_with_timestamps) do |_, endpoint, body, &block|
        chunks = [
          {
            "audio_base64" => "welcome_chunk_1",
            "alignment" => {
              "characters" => ["W", "e", "l", "c", "o", "m", "e"],
              "character_start_times_seconds" => [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6],
              "character_end_times_seconds" => [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]
            }
          },
          {
            "audio_base64" => "welcome_chunk_2",
            "alignment" => {
              "characters" => [" ", "t", "o", " ", "o", "u", "r", " ", "a", "p", "p"],
              "character_start_times_seconds" => [0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7],
              "character_end_times_seconds" => [0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8]
            }
          }
        ]
        chunks.each { |chunk| block.call(chunk) if block }
        double("response", status: 200)
      end
    end

    it "works as expected in a Rails-like streaming environment" do
      # This simulates typical Rails streaming usage with timestamps
      client = ElevenlabsClient.new(api_key: api_key)
      
      audio_chunks = []
      character_timings = []
      
      # Stream speech with timestamps and collect data
      client.text_to_speech_stream_with_timestamps.stream(
        voice_id,
        "Welcome to our app",
        model_id: "eleven_multilingual_v2",
        voice_settings: {
          stability: 0.5,
          similarity_boost: 0.8
        },
        output_format: "mp3_44100_128"
      ) do |chunk|
        # Collect audio data for playback
        if chunk["audio_base64"]
          audio_data = Base64.decode64(chunk["audio_base64"])
          audio_chunks << audio_data
        end
        
        # Collect timing data for UI synchronization
        if chunk["alignment"]
          chunk["alignment"]["characters"].each_with_index do |char, index|
            character_timings << {
              character: char,
              start_time: chunk["alignment"]["character_start_times_seconds"][index],
              end_time: chunk["alignment"]["character_end_times_seconds"][index]
            }
          end
        end
      end

      # Validate collected data
      expect(audio_chunks.length).to eq(2)
      expect(character_timings.length).to eq(18) # "Welcome to our app" = 18 characters
      expect(character_timings.map { |ct| ct[:character] }.join).to eq("Welcome to our app")
      
      # Validate timing sequence
      start_times = character_timings.map { |ct| ct[:start_time] }
      expect(start_times).to eq(start_times.sort)
      expect(start_times.first).to eq(0.0)
      expect(start_times.last).to eq(1.7)

      expect(client).to have_received(:post_streaming_with_timestamps)
        .with(
          "/v1/text-to-speech/#{voice_id}/stream/with-timestamps?output_format=mp3_44100_128",
          {
            text: "Welcome to our app",
            model_id: "eleven_multilingual_v2",
            voice_settings: {
              stability: 0.5,
              similarity_boost: 0.8
            }
          }
        )
    end
  end
end
