# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Sound Generation Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:binary_audio_data) { "fake_sound_effect_mp3_binary_data_here" }

  describe "client.sound_generation accessor" do
    it "provides access to sound_generation endpoint" do
      expect(client.sound_generation).to be_an_instance_of(ElevenlabsClient::SoundGeneration)
    end
  end

  describe "sound generation functionality via client" do
    let(:text) { "Ocean waves crashing on rocks" }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/sound-generation")
        .to_return(
          status: 200,
          body: binary_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "generates sound effects through client interface" do
      result = client.sound_generation.generate(text)

      expect(result).to eq(binary_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/sound-generation")
        .with(
          headers: { "xi-api-key" => api_key },
          body: { text: text }.to_json
        )
    end

    it "supports the sound_generation alias method" do
      result = client.sound_generation.sound_generation(text)

      expect(result).to eq(binary_audio_data)
    end
  end

  describe "binary response handling" do
    let(:text) { "Wind through trees" }

    context "when API returns binary audio data" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/sound-generation")
          .to_return(
            status: 200,
            body: binary_audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "returns the raw binary data" do
        result = client.sound_generation.generate(text)

        expect(result).to eq(binary_audio_data)
        expect(result).to be_a(String)
      end
    end
  end

  describe "error handling integration" do
    let(:text) { "Test sound" }

    context "with authentication error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/sound-generation")
          .to_return(status: 401, body: "Unauthorized")
      end

      it "raises AuthenticationError through client" do
        expect {
          client.sound_generation.generate(text)
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    context "with rate limit error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/sound-generation")
          .to_return(status: 429, body: "Rate limit exceeded")
      end

      it "raises RateLimitError through client" do
        expect {
          client.sound_generation.generate(text)
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

        stub_request(:post, "https://configured.elevenlabs.io/v1/sound-generation")
          .to_return(
            status: 200,
            body: binary_audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "uses configured settings for sound generation requests" do
        client = ElevenlabsClient.new
        text = "Configured sound effect"
        
        result = client.sound_generation.generate(text)

        expect(result).to eq(binary_audio_data)
        expect(WebMock).to have_requested(:post, "https://configured.elevenlabs.io/v1/sound-generation")
          .with(headers: { "xi-api-key" => "configured_api_key" })
      end
    end
  end

  describe "Rails usage example" do
    let(:text) { "Ambient cafe sounds with gentle chatter" }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/sound-generation")
        .to_return(
          status: 200,
          body: binary_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
      
      stub_request(:post, "https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_22050_32")
        .to_return(
          status: 200,
          body: binary_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "works as expected in a Rails-like environment" do
      # This simulates typical Rails usage
      client = ElevenlabsClient.new(api_key: api_key)
      
      # Generate sound effect with all options
      audio_data = client.sound_generation.generate(
        text,
        loop: true,
        duration_seconds: 15.0,
        prompt_influence: 0.6,
        output_format: "mp3_22050_32"
      )

      expect(audio_data).to eq(binary_audio_data)
    end
  end

  describe "sound effect scenarios" do
    before do
      stub_request(:post, /https:\/\/api\.elevenlabs\.io\/v1\/sound-generation/)
        .to_return(
          status: 200,
          body: binary_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "handles nature sound effects" do
      nature_sounds = [
        "Gentle rain on leaves",
        "Birds singing at dawn",
        "Ocean waves on beach",
        "Wind through forest"
      ]

      nature_sounds.each do |sound|
        result = client.sound_generation.generate(sound)
        expect(result).to eq(binary_audio_data)
      end
    end

    it "handles ambient sound effects" do
      ambient_sounds = [
        "Busy coffee shop atmosphere",
        "Library with quiet whispers",
        "City street with distant traffic",
        "Crackling fireplace"
      ]

      ambient_sounds.each do |sound|
        result = client.sound_generation.generate(
          sound,
          loop: true,
          duration_seconds: 30.0
        )
        expect(result).to eq(binary_audio_data)
      end
    end

    it "handles mechanical sound effects" do
      mechanical_sounds = [
        "Old clock ticking",
        "Typewriter keys clicking",
        "Steam engine chugging",
        "Fan blades spinning"
      ]

      mechanical_sounds.each do |sound|
        result = client.sound_generation.generate(
          sound,
          prompt_influence: 0.8
        )
        expect(result).to eq(binary_audio_data)
      end
    end

    it "handles short sound effects" do
      short_sounds = [
        "Door creaking open",
        "Glass breaking",
        "Footstep on wooden floor",
        "Paper rustling"
      ]

      short_sounds.each do |sound|
        result = client.sound_generation.generate(
          sound,
          duration_seconds: 2.0
        )
        expect(result).to eq(binary_audio_data)
      end
    end
  end

  describe "output format handling" do
    let(:text) { "Test sound for format" }

    it "handles different output formats correctly" do
      formats = ["mp3_44100_128", "mp3_22050_32", "pcm_16000"]
      
      formats.each do |format|
        stub_request(:post, "https://api.elevenlabs.io/v1/sound-generation?output_format=#{format}")
          .to_return(
            status: 200,
            body: binary_audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )

        result = client.sound_generation.generate(text, output_format: format)
        expect(result).to eq(binary_audio_data)
      end
    end
  end

  describe "parameter validation scenarios" do
    let(:text) { "Test sound" }

    before do
      stub_request(:post, /https:\/\/api\.elevenlabs\.io\/v1\/sound-generation/)
        .to_return(
          status: 200,
          body: binary_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "handles edge case duration values" do
      edge_durations = [0.5, 30.0]
      
      edge_durations.each do |duration|
        result = client.sound_generation.generate(text, duration_seconds: duration)
        expect(result).to eq(binary_audio_data)
      end
    end

    it "handles edge case prompt influence values" do
      edge_influences = [0.0, 1.0]
      
      edge_influences.each do |influence|
        result = client.sound_generation.generate(text, prompt_influence: influence)
        expect(result).to eq(binary_audio_data)
      end
    end

    it "handles boolean loop values" do
      [true, false].each do |loop_value|
        result = client.sound_generation.generate(text, loop: loop_value)
        expect(result).to eq(binary_audio_data)
      end
    end
  end
end
