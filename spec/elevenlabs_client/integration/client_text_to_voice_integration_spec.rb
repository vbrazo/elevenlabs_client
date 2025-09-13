# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Text-to-Voice Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }

  describe "client.text_to_voice accessor" do
    it "provides access to text_to_voice endpoint" do
      expect(client.text_to_voice).to be_an_instance_of(ElevenlabsClient::TextToVoice)
    end
  end

  describe "voice design functionality via client" do
    let(:voice_description) { "A warm, professional female voice with a slight American accent" }
    let(:design_response) do
      {
        "previews" => [
          {
            "generated_voice_id" => "gen_voice_123",
            "audio_base_64" => "base64_audio_data",
            "text" => "Sample preview text"
          }
        ],
        "text" => "Auto-generated text for voice preview"
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
        .to_return(
          status: 200,
          body: design_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "designs voices through client interface" do
      result = client.text_to_voice.design(voice_description)

      expect(result).to eq(design_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
        .with(
          headers: { "xi-api-key" => api_key },
          body: { voice_description: voice_description }.to_json
        )
    end

    it "supports the design_voice alias method" do
      result = client.text_to_voice.design_voice(voice_description)

      expect(result).to eq(design_response)
    end
  end

  describe "voice creation functionality via client" do
    let(:voice_name) { "Custom Business Voice" }
    let(:voice_description) { "Professional voice for business presentations" }
    let(:generated_voice_id) { "gen_voice_456" }
    let(:create_response) do
      {
        "voice_id" => "final_voice_789",
        "name" => voice_name,
        "description" => voice_description,
        "category" => "generated",
        "labels" => {}
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-voice")
        .to_return(
          status: 200,
          body: create_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates voices through client interface" do
      result = client.text_to_voice.create(voice_name, voice_description, generated_voice_id)

      expect(result).to eq(create_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice")
        .with(
          headers: { "xi-api-key" => api_key },
          body: {
            voice_name: voice_name,
            voice_description: voice_description,
            generated_voice_id: generated_voice_id
          }.to_json
        )
    end

    it "supports the create_from_generated_voice alias method" do
      result = client.text_to_voice.create_from_generated_voice(voice_name, voice_description, generated_voice_id)

      expect(result).to eq(create_response)
    end
  end

  describe "voice listing functionality via client" do
    let(:voices_response) do
      {
        "voices" => [
          {
            "voice_id" => "premade_1",
            "name" => "Rachel",
            "category" => "premade",
            "labels" => { "accent" => "american", "description" => "calm", "age" => "young" }
          },
          {
            "voice_id" => "generated_1",
            "name" => "My Custom Voice",
            "category" => "generated",
            "labels" => { "use_case" => "narration" }
          }
        ]
      }
    end

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/voices")
        .to_return(
          status: 200,
          body: voices_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists voices through client interface" do
      result = client.text_to_voice.list_voices

      expect(result).to eq(voices_response)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/voices")
        .with(headers: { "xi-api-key" => api_key })
    end
  end

  describe "error handling integration" do
    let(:voice_description) { "Test voice" }

    context "with authentication error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
          .to_return(status: 401, body: "Unauthorized")
      end

      it "raises AuthenticationError through client" do
        expect {
          client.text_to_voice.design(voice_description)
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    context "with rate limit error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
          .to_return(status: 429, body: "Rate limit exceeded")
      end

      it "raises RateLimitError through client" do
        expect {
          client.text_to_voice.design(voice_description)
        }.to raise_error(ElevenlabsClient::RateLimitError)
      end
    end

    context "with validation error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
          .to_return(status: 400, body: "Voice description too short")
      end

      it "raises ValidationError through client" do
        expect {
          client.text_to_voice.design(voice_description)
        }.to raise_error(ElevenlabsClient::ValidationError)
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

        stub_request(:post, "https://configured.elevenlabs.io/v1/text-to-voice/design")
          .to_return(
            status: 200,
            body: { "previews" => [] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "uses configured settings for text-to-voice requests" do
        client = ElevenlabsClient.new
        voice_description = "Test voice with configured settings"
        
        result = client.text_to_voice.design(voice_description)

        expect(WebMock).to have_requested(:post, "https://configured.elevenlabs.io/v1/text-to-voice/design")
          .with(headers: { "xi-api-key" => "configured_api_key" })
      end
    end
  end

  describe "Rails usage example" do
    let(:voice_description) { "Professional narrator voice for e-learning content" }
    let(:design_response) do
      {
        "previews" => [
          {
            "generated_voice_id" => "elearning_voice_123",
            "audio_base_64" => "base64_preview_audio",
            "text" => "Welcome to our e-learning platform"
          }
        ]
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
        .to_return(
          status: 200,
          body: design_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "works as expected in a Rails-like environment" do
      # This simulates typical Rails usage
      client = ElevenlabsClient.new(api_key: api_key)
      
      # Design a voice with specific options
      result = client.text_to_voice.design(
        voice_description,
        model_id: "eleven_multilingual_ttv_v2",
        text: "This is a custom text for the voice preview that meets the minimum character requirements for the API.",
        auto_generate_text: false,
        loudness: 0.6,
        guidance_scale: 7.0,
        seed: 12345
      )

      expect(result).to eq(design_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
        .with { |req| 
          body = JSON.parse(req.body)
          body["voice_description"] == voice_description &&
          body["model_id"] == "eleven_multilingual_ttv_v2" &&
          body["text"] == "This is a custom text for the voice preview that meets the minimum character requirements for the API." &&
          body["auto_generate_text"] == false &&
          body["loudness"] == 0.6 &&
          body["guidance_scale"] == 7.0 &&
          body["seed"] == 12345
        }
    end
  end

  describe "voice design workflow" do
    let(:voice_description) { "Energetic sports commentator voice" }
    let(:design_response) do
      {
        "previews" => [
          {
            "generated_voice_id" => "sports_voice_456",
            "audio_base_64" => "base64_sports_audio",
            "text" => "And here comes the final play!"
          }
        ]
      }
    end
    let(:create_response) do
      {
        "voice_id" => "final_sports_voice_789",
        "name" => "Sports Commentator",
        "category" => "generated"
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
        .to_return(
          status: 200,
          body: design_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-voice")
        .to_return(
          status: 200,
          body: create_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "supports complete voice design and creation workflow" do
      # Step 1: Design the voice
      design_result = client.text_to_voice.design(
        voice_description,
        model_id: "eleven_ttv_v3",
        auto_generate_text: true,
        loudness: 0.8,
        guidance_scale: 6.0
      )

      expect(design_result).to eq(design_response)
      
      # Step 2: Create the voice from the generated preview
      generated_voice_id = design_result["previews"].first["generated_voice_id"]
      
      create_result = client.text_to_voice.create(
        "Sports Commentator",
        voice_description,
        generated_voice_id,
        labels: { "use_case" => "sports", "energy" => "high" }
      )

      expect(create_result).to eq(create_response)
      
      # Verify both requests were made correctly
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice")
    end
  end

  describe "voice management scenarios" do
    let(:voices_response) do
      {
        "voices" => [
          { "voice_id" => "v1", "name" => "Alice", "category" => "premade" },
          { "voice_id" => "v2", "name" => "Bob", "category" => "generated" },
          { "voice_id" => "v3", "name" => "Carol", "category" => "cloned" }
        ]
      }
    end

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/voices")
        .to_return(
          status: 200,
          body: voices_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "handles voice listing for voice management" do
      voices = client.text_to_voice.list_voices

      expect(voices["voices"]).to be_an(Array)
      expect(voices["voices"].length).to eq(3)
      
      # Check voice categories
      categories = voices["voices"].map { |v| v["category"] }
      expect(categories).to include("premade", "generated", "cloned")
    end
  end

  describe "advanced voice design options" do
    let(:voice_description) { "Sophisticated AI assistant voice with neutral tone" }
    let(:reference_audio) { "base64_encoded_reference_audio_sample" }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
        .to_return(
          status: 200,
          body: { "previews" => [] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "handles advanced options including reference audio" do
      client.text_to_voice.design(
        voice_description,
        model_id: "eleven_ttv_v3",
        reference_audio_base64: reference_audio,
        prompt_strength: 0.8,
        quality: 0.9,
        stream_previews: true
      )

      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
        .with { |req| 
          body = JSON.parse(req.body)
          body["voice_description"] == voice_description &&
          body["model_id"] == "eleven_ttv_v3" &&
          body["reference_audio_base64"] == reference_audio &&
          body["prompt_strength"] == 0.8 &&
          body["quality"] == 0.9 &&
          body["stream_previews"] == true
        }
    end
  end
end
