# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Text-to-Dialogue Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:binary_audio_data) { "fake_dialogue_mp3_binary_data_here" }

  describe "client.text_to_dialogue accessor" do
    it "provides access to text_to_dialogue endpoint" do
      expect(client.text_to_dialogue).to be_an_instance_of(ElevenlabsClient::TextToDialogue)
    end
  end

  describe "text-to-dialogue functionality via client" do
    let(:dialogue_inputs) do
      [
        { text: "Hello, how are you?", voice_id: "21m00Tcm4TlvDq8ikWAM" },
        { text: "I'm doing well, thanks!", voice_id: "pNInz6obpgDQGcFmaJgB" }
      ]
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
        .to_return(
          status: 200,
          body: binary_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "converts dialogue to speech through client interface" do
      result = client.text_to_dialogue.convert(dialogue_inputs)

      expect(result).to eq(binary_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
        .with(
          headers: { "xi-api-key" => api_key },
          body: { inputs: dialogue_inputs }.to_json
        )
    end

    it "supports the text_to_dialogue alias method" do
      result = client.text_to_dialogue.text_to_dialogue(dialogue_inputs)

      expect(result).to eq(binary_audio_data)
    end
  end

  describe "binary response handling" do
    let(:dialogue_inputs) do
      [{ text: "Test dialogue", voice_id: "test_voice" }]
    end

    context "when API returns binary audio data" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
          .to_return(
            status: 200,
            body: binary_audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "returns the raw binary data" do
        result = client.text_to_dialogue.convert(dialogue_inputs)

        expect(result).to eq(binary_audio_data)
        expect(result).to be_a(String)
      end
    end
  end

  describe "error handling integration" do
    let(:dialogue_inputs) do
      [{ text: "Test", voice_id: "test_voice" }]
    end

    context "with authentication error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
          .to_return(status: 401, body: "Unauthorized")
      end

      it "raises AuthenticationError through client" do
        expect {
          client.text_to_dialogue.convert(dialogue_inputs)
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    context "with rate limit error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
          .to_return(status: 429, body: "Rate limit exceeded")
      end

      it "raises RateLimitError through client" do
        expect {
          client.text_to_dialogue.convert(dialogue_inputs)
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

        stub_request(:post, "https://configured.elevenlabs.io/v1/text-to-dialogue")
          .to_return(
            status: 200,
            body: binary_audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "uses configured settings for dialogue requests" do
        client = ElevenlabsClient.new
        dialogue_inputs = [{ text: "Test", voice_id: "test_voice" }]
        
        result = client.text_to_dialogue.convert(dialogue_inputs)

        expect(result).to eq(binary_audio_data)
        expect(WebMock).to have_requested(:post, "https://configured.elevenlabs.io/v1/text-to-dialogue")
          .with(headers: { "xi-api-key" => "configured_api_key" })
      end
    end
  end

  describe "Rails usage example" do
    let(:dialogue_inputs) do
      [
        { text: "Welcome to our service!", voice_id: "narrator_voice" },
        { text: "Thank you for choosing us.", voice_id: "customer_service_voice" }
      ]
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
        .to_return(
          status: 200,
          body: binary_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "works as expected in a Rails-like environment" do
      # This simulates typical Rails usage
      client = ElevenlabsClient.new(api_key: api_key)
      
      # Convert dialogue to speech with settings
      audio_data = client.text_to_dialogue.convert(
        dialogue_inputs,
        model_id: "eleven_multilingual_v1",
        settings: {
          stability: 0.6,
          use_speaker_boost: true
        },
        seed: 12345
      )

      expect(audio_data).to eq(binary_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
        .with(
          body: {
            inputs: dialogue_inputs,
            model_id: "eleven_multilingual_v1",
            settings: {
              stability: 0.6,
              use_speaker_boost: true
            },
            seed: 12345
          }.to_json
        )
    end
  end

  describe "conversation scenarios" do
    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
        .to_return(
          status: 200,
          body: binary_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "handles customer service conversation" do
      conversation = [
        { text: "Hello, how can I help you today?", voice_id: "agent_voice" },
        { text: "I have a question about my order.", voice_id: "customer_voice" },
        { text: "I'd be happy to help with that. What's your order number?", voice_id: "agent_voice" },
        { text: "It's order number 12345.", voice_id: "customer_voice" }
      ]

      result = client.text_to_dialogue.convert(conversation)

      expect(result).to eq(binary_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
        .with(body: { inputs: conversation }.to_json)
    end

    it "handles educational content dialogue" do
      lesson = [
        { text: "Today we'll learn about photosynthesis.", voice_id: "teacher_voice" },
        { text: "What is photosynthesis?", voice_id: "student_voice" },
        { text: "Great question! Photosynthesis is the process plants use to make food from sunlight.", voice_id: "teacher_voice" }
      ]

      result = client.text_to_dialogue.convert(
        lesson,
        model_id: "eleven_multilingual_v1",
        settings: { stability: 0.8, use_speaker_boost: false }
      )

      expect(result).to eq(binary_audio_data)
    end

    it "handles storytelling with multiple characters" do
      story = [
        { text: "Once upon a time, in a faraway kingdom...", voice_id: "narrator_voice" },
        { text: "I must find the magical crystal!", voice_id: "hero_voice" },
        { text: "You'll never succeed!", voice_id: "villain_voice" },
        { text: "And so the adventure began...", voice_id: "narrator_voice" }
      ]

      result = client.text_to_dialogue.convert(story, seed: 98765)

      expect(result).to eq(binary_audio_data)
    end
  end
end
