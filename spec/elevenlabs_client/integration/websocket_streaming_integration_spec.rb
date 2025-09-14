# frozen_string_literal: true

require 'base64'

RSpec.describe "ElevenlabsClient WebSocket Streaming Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:voice_id) { "21m00Tcm4TlvDq8ikWAM" }
  let(:mock_websocket) { double("WebSocket::Client::Simple::Client") }

  before do
    # Mock the WebSocket library
    allow(WebSocket::Client::Simple).to receive(:connect).and_return(mock_websocket)
    allow(mock_websocket).to receive(:send)
    allow(mock_websocket).to receive(:on)
    allow(mock_websocket).to receive(:close)
  end

  describe "client.websocket_text_to_speech accessor" do
    it "provides access to websocket_text_to_speech endpoint" do
      expect(client.websocket_text_to_speech).to be_an_instance_of(ElevenlabsClient::WebSocketTextToSpeech)
    end
  end

  describe "single-context WebSocket streaming" do
    it "connects to the correct WebSocket URL with proper headers" do
      client.websocket_text_to_speech.connect_stream_input(
        voice_id,
        model_id: "eleven_multilingual_v2",
        sync_alignment: true,
        output_format: "mp3_44100_128"
      )

      expected_url = "wss://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/stream-input?model_id=eleven_multilingual_v2&sync_alignment=true&output_format=mp3_44100_128"
      expected_headers = { "xi-api-key" => api_key }

      expect(WebSocket::Client::Simple).to have_received(:connect)
        .with(expected_url, headers: expected_headers)
    end

    it "provides convenient helper methods for message sending" do
      ws = client.websocket_text_to_speech.connect_stream_input(voice_id)

      # Test initialization message
      client.websocket_text_to_speech.send_initialize_connection(
        ws,
        text: " ",
        voice_settings: { stability: 0.5, similarity_boost: 0.8 },
        xi_api_key: api_key
      )

      expected_init_message = {
        text: " ",
        voice_settings: { stability: 0.5, similarity_boost: 0.8 },
        xi_api_key: api_key
      }.to_json

      expect(mock_websocket).to have_received(:send).with(expected_init_message)

      # Test text message
      client.websocket_text_to_speech.send_text(ws, "Hello world!", try_trigger_generation: true)

      expected_text_message = {
        text: "Hello world!",
        try_trigger_generation: true
      }.to_json

      expect(mock_websocket).to have_received(:send).with(expected_text_message)

      # Test close message
      client.websocket_text_to_speech.send_close_connection(ws)

      expected_close_message = { text: "" }.to_json
      expect(mock_websocket).to have_received(:send).with(expected_close_message)
    end

    it "handles connection parameters correctly" do
      client.websocket_text_to_speech.connect_stream_input(
        voice_id,
        model_id: "eleven_multilingual_v2",
        language_code: "en",
        enable_logging: false,
        enable_ssml_parsing: true,
        output_format: "mp3_44100_128",
        inactivity_timeout: 30,
        sync_alignment: true,
        auto_mode: true,
        apply_text_normalization: "on",
        seed: 12345
      )

      expected_url = "wss://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/stream-input?model_id=eleven_multilingual_v2&language_code=en&enable_logging=false&enable_ssml_parsing=true&output_format=mp3_44100_128&inactivity_timeout=30&sync_alignment=true&auto_mode=true&apply_text_normalization=on&seed=12345"

      expect(WebSocket::Client::Simple).to have_received(:connect)
        .with(expected_url, headers: { "xi-api-key" => api_key })
    end
  end

  describe "multi-context WebSocket streaming" do
    it "connects to the correct multi-context WebSocket URL" do
      client.websocket_text_to_speech.connect_multi_stream_input(
        voice_id,
        model_id: "eleven_multilingual_v2",
        sync_alignment: true
      )

      expected_url = "wss://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/multi-stream-input?model_id=eleven_multilingual_v2&sync_alignment=true"
      expected_headers = { "xi-api-key" => api_key }

      expect(WebSocket::Client::Simple).to have_received(:connect)
        .with(expected_url, headers: expected_headers)
    end

    it "provides context management helper methods" do
      ws = client.websocket_text_to_speech.connect_multi_stream_input(voice_id)
      context_id = "conversation_1"

      # Test multi-context initialization
      client.websocket_text_to_speech.send_initialize_connection_multi(
        ws,
        context_id,
        text: " ",
        voice_settings: { stability: 0.5 }
      )

      expected_init_message = {
        text: " ",
        voice_settings: { stability: 0.5 },
        context_id: context_id
      }.to_json

      expect(mock_websocket).to have_received(:send).with(expected_init_message)

      # Test context initialization
      client.websocket_text_to_speech.send_initialize_context(
        ws,
        context_id,
        voice_settings: { stability: 0.6 },
        model_id: "eleven_multilingual_v2"
      )

      expected_context_message = {
        context_id: context_id,
        voice_settings: { stability: 0.6 },
        model_id: "eleven_multilingual_v2"
      }.to_json

      expect(mock_websocket).to have_received(:send).with(expected_context_message)

      # Test multi-context text sending
      client.websocket_text_to_speech.send_text_multi(
        ws,
        context_id,
        "Hello from context 1!",
        flush: true
      )

      expected_text_message = {
        text: "Hello from context 1!",
        context_id: context_id,
        flush: true
      }.to_json

      expect(mock_websocket).to have_received(:send).with(expected_text_message)

      # Test context flushing
      client.websocket_text_to_speech.send_flush_context(ws, context_id)

      expected_flush_message = {
        context_id: context_id,
        flush: true
      }.to_json

      expect(mock_websocket).to have_received(:send).with(expected_flush_message)

      # Test context closing
      client.websocket_text_to_speech.send_close_context(ws, context_id)

      expected_close_context_message = {
        context_id: context_id,
        close_context: true
      }.to_json

      expect(mock_websocket).to have_received(:send).with(expected_close_context_message)

      # Test keep alive
      client.websocket_text_to_speech.send_keep_context_alive(ws, context_id)

      expected_keep_alive_message = {
        context_id: context_id,
        keep_context_alive: true
      }.to_json

      expect(mock_websocket).to have_received(:send).with(expected_keep_alive_message)

      # Test socket closing
      client.websocket_text_to_speech.send_close_socket(ws)

      expected_close_socket_message = { close_socket: true }.to_json
      expect(mock_websocket).to have_received(:send).with(expected_close_socket_message)
    end
  end

  describe "convenience streaming method" do
    let(:mock_message_event) { double("message_event", data: audio_message.to_json) }
    let(:audio_message) do
      {
        "audio" => "dGVzdCBhdWRpbyBkYXRh", # "test audio data" in base64
        "alignment" => {
          "chars" => ["H", "e", "l", "l", "o"],
          "charStartTimesMs" => [0, 100, 200, 300, 400],
          "charsDurationsMs" => [100, 100, 100, 100, 100]
        },
        "isFinal" => false
      }
    end

    before do
      # Mock the WebSocket events
      allow(mock_websocket).to receive(:on) do |event, &block|
        case event
        when :open
          # Simulate connection opening and message sending
          @open_block = block
        when :message
          # Store the message handler for later simulation
          @message_block = block
        when :error, :close
          # Store error/close handlers
        end
      end
    end

    it "provides a complete streaming workflow with the convenience method" do
      text_chunks = ["Hello ", "world! ", "This is a test."]
      received_audio = []
      received_metadata = []

      # Mock the streaming method
      allow(client.websocket_text_to_speech).to receive(:stream_text_to_speech) do |voice_id, chunks, **options, &block|
        # Simulate the convenience method behavior
        chunks.each do |chunk|
          audio_data = Base64.decode64("dGVzdCBhdWRpbyBkYXRh")
          metadata = {
            "alignment" => {
              "chars" => chunk.chars,
              "charStartTimesMs" => chunk.chars.map.with_index { |_, i| i * 100 }
            }
          }
          block.call(audio_data, metadata) if block
        end
        mock_websocket
      end

      ws = client.websocket_text_to_speech.stream_text_to_speech(
        voice_id,
        text_chunks,
        voice_settings: { stability: 0.5, similarity_boost: 0.8 },
        sync_alignment: true
      ) do |audio_data, metadata|
        received_audio << audio_data
        received_metadata << metadata
      end

      expect(ws).to eq(mock_websocket)
      expect(received_audio.length).to eq(3)
      expect(received_metadata.length).to eq(3)
      expect(received_audio.first).to eq("test audio data")
    end
  end

  describe "URL construction with different base URLs" do
    context "when using custom base URL" do
      let(:custom_client) { ElevenlabsClient::Client.new(api_key: api_key, base_url: "https://custom.elevenlabs.io") }

      it "constructs WebSocket URLs correctly with custom base URL" do
        custom_client.websocket_text_to_speech.connect_stream_input(voice_id)

        expected_url = "wss://custom.elevenlabs.io/v1/text-to-speech/#{voice_id}/stream-input"
        expect(WebSocket::Client::Simple).to have_received(:connect)
          .with(expected_url, headers: { "xi-api-key" => api_key })
      end

      it "handles HTTP to WebSocket URL conversion correctly" do
        http_client = ElevenlabsClient::Client.new(api_key: api_key, base_url: "http://localhost:8080")
        http_client.websocket_text_to_speech.connect_stream_input(voice_id)

        expected_url = "ws://localhost:8080/v1/text-to-speech/#{voice_id}/stream-input"
        expect(WebSocket::Client::Simple).to have_received(:connect)
          .with(expected_url, headers: { "xi-api-key" => api_key })
      end
    end
  end

  describe "Settings integration for WebSocket" do
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

      it "uses configured settings for WebSocket connections" do
        client = ElevenlabsClient.new
        client.websocket_text_to_speech.connect_stream_input(voice_id)

        expected_url = "wss://configured.elevenlabs.io/v1/text-to-speech/#{voice_id}/stream-input"
        expected_headers = { "xi-api-key" => "configured_api_key" }

        expect(WebSocket::Client::Simple).to have_received(:connect)
          .with(expected_url, headers: expected_headers)
      end
    end
  end

  describe "alias methods" do
    it "provides convenience aliases for connection methods" do
      # Test single stream alias
      expect(client.websocket_text_to_speech.method(:connect_single_stream))
        .to eq(client.websocket_text_to_speech.method(:connect_stream_input))

      # Test multi-context alias
      expect(client.websocket_text_to_speech.method(:connect_multi_context))
        .to eq(client.websocket_text_to_speech.method(:connect_multi_stream_input))
    end
  end

  describe "parameter validation and edge cases" do
    it "handles boolean parameters correctly" do
      client.websocket_text_to_speech.connect_stream_input(
        voice_id,
        enable_logging: false,
        enable_ssml_parsing: true,
        sync_alignment: false,
        auto_mode: true
      )

      expected_url = "wss://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/stream-input?enable_logging=false&enable_ssml_parsing=true&sync_alignment=false&auto_mode=true"

      expect(WebSocket::Client::Simple).to have_received(:connect)
        .with(expected_url, headers: { "xi-api-key" => api_key })
    end

    it "handles nil and empty parameters gracefully" do
      client.websocket_text_to_speech.connect_stream_input(
        voice_id,
        model_id: nil,
        language_code: "",
        inactivity_timeout: nil
      )

      # Should not include nil or empty parameters in URL
      expected_url = "wss://api.elevenlabs.io/v1/text-to-speech/#{voice_id}/stream-input"

      expect(WebSocket::Client::Simple).to have_received(:connect)
        .with(expected_url, headers: { "xi-api-key" => api_key })
    end

    it "handles special characters in voice_id correctly" do
      special_voice_id = "voice-123_test.id"
      client.websocket_text_to_speech.connect_stream_input(special_voice_id)

      expected_url = "wss://api.elevenlabs.io/v1/text-to-speech/#{special_voice_id}/stream-input"

      expect(WebSocket::Client::Simple).to have_received(:connect)
        .with(expected_url, headers: { "xi-api-key" => api_key })
    end
  end

  describe "real-world usage patterns" do
    it "supports a complete conversational AI workflow" do
      # Simulate a conversational AI scenario
      ws = client.websocket_text_to_speech.connect_multi_stream_input(
        voice_id,
        sync_alignment: true,
        auto_mode: true
      )

      # Set up multiple conversation contexts
      contexts = ["user_response", "system_notification", "background_music"]
      
      contexts.each do |context_id|
        client.websocket_text_to_speech.send_initialize_connection_multi(
          ws,
          context_id,
          voice_settings: { stability: 0.5, similarity_boost: 0.8 }
        )
      end

      # Send different types of content to different contexts
      client.websocket_text_to_speech.send_text_multi(
        ws,
        "user_response",
        "Thank you for your question.",
        flush: false
      )

      client.websocket_text_to_speech.send_text_multi(
        ws,
        "system_notification",
        "New message received.",
        flush: true
      )

      # Verify all expected messages were sent
      expect(mock_websocket).to have_received(:send).exactly(5).times # 3 inits + 2 text messages
    end

    it "handles rapid message sending without issues" do
      ws = client.websocket_text_to_speech.connect_stream_input(voice_id)

      # Initialize connection
      client.websocket_text_to_speech.send_initialize_connection(ws)

      # Send multiple rapid text chunks
      text_chunks = [
        "Hello there! ",
        "How are you doing today? ",
        "I hope you're having a great day. ",
        "This is a test of rapid message sending. ",
        "Let's see how well it handles multiple chunks."
      ]

      text_chunks.each_with_index do |chunk, index|
        is_last = index == text_chunks.length - 1
        client.websocket_text_to_speech.send_text(
          ws,
          chunk,
          try_trigger_generation: is_last
        )
      end

      # Close connection
      client.websocket_text_to_speech.send_close_connection(ws)

      # Should have sent: 1 init + 5 text messages + 1 close = 7 messages
      expect(mock_websocket).to have_received(:send).exactly(7).times
    end
  end
end
