# frozen_string_literal: true

RSpec.describe ElevenlabsClient::TextToDialogue do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:text_to_dialogue) { described_class.new(client) }
  let(:binary_audio_data) { "fake_dialogue_mp3_binary_data_here" }

  describe "#convert" do
    let(:dialogue_inputs) do
      [
        { text: "Hello, how are you today?", voice_id: "21m00Tcm4TlvDq8ikWAM" },
        { text: "I'm doing great, thank you for asking!", voice_id: "pNInz6obpgDQGcFmaJgB" },
        { text: "That's wonderful to hear.", voice_id: "21m00Tcm4TlvDq8ikWAM" }
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

    context "with required parameters only" do
      it "converts dialogue to speech successfully" do
        result = text_to_dialogue.convert(dialogue_inputs)

        expect(result).to eq(binary_audio_data)
      end

      it "sends the correct request" do
        text_to_dialogue.convert(dialogue_inputs)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
          .with(
            headers: {
              "xi-api-key" => api_key,
              "Content-Type" => "application/json"
            },
            body: { inputs: dialogue_inputs }.to_json
          )
      end
    end

    context "with model_id option" do
      let(:model_id) { "eleven_multilingual_v1" }

      it "includes model_id in the request" do
        text_to_dialogue.convert(dialogue_inputs, model_id: model_id)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
          .with(
            body: {
              inputs: dialogue_inputs,
              model_id: model_id
            }.to_json
          )
      end
    end

    context "with settings option" do
      let(:settings) do
        {
          stability: 0.5,
          use_speaker_boost: true
        }
      end

      it "includes settings in the request" do
        text_to_dialogue.convert(dialogue_inputs, settings: settings)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
          .with(
            body: {
              inputs: dialogue_inputs,
              settings: settings
            }.to_json
          )
      end
    end

    context "with seed option" do
      let(:seed) { 12345 }

      it "includes seed in the request" do
        text_to_dialogue.convert(dialogue_inputs, seed: seed)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
          .with(
            body: {
              inputs: dialogue_inputs,
              seed: seed
            }.to_json
          )
      end
    end

    context "with all options" do
      let(:model_id) { "eleven_multilingual_v1" }
      let(:settings) do
        {
          stability: 0.7,
          use_speaker_boost: false
        }
      end
      let(:seed) { 54321 }

      it "includes all options in the request" do
        text_to_dialogue.convert(
          dialogue_inputs,
          model_id: model_id,
          settings: settings,
          seed: seed
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
          .with(
            body: {
              inputs: dialogue_inputs,
              model_id: model_id,
              settings: settings,
              seed: seed
            }.to_json
          )
      end
    end

    context "with empty settings" do
      it "does not include empty settings in the request" do
        text_to_dialogue.convert(dialogue_inputs, settings: {})

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
          .with(
            body: { inputs: dialogue_inputs }.to_json
          )
      end
    end

    context "when API returns an error" do
      context "with authentication error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
            .to_return(status: 401, body: "Unauthorized")
        end

        it "raises AuthenticationError" do
          expect {
            text_to_dialogue.convert(dialogue_inputs)
          }.to raise_error(ElevenlabsClient::AuthenticationError)
        end
      end

      context "with rate limit error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
            .to_return(status: 429, body: "Rate limit exceeded")
        end

        it "raises RateLimitError" do
          expect {
            text_to_dialogue.convert(dialogue_inputs)
          }.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
        end
      end

      context "with validation error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
            .to_return(status: 400, body: "Invalid dialogue inputs")
        end

        it "raises BadRequestError" do
          expect {
            text_to_dialogue.convert(dialogue_inputs)
          }.to raise_error(ElevenlabsClient::BadRequestError)
        end
      end

      context "with server error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
            .to_return(status: 500, body: "Internal Server Error")
        end

        it "raises APIError" do
          expect {
            text_to_dialogue.convert(dialogue_inputs)
          }.to raise_error(ElevenlabsClient::APIError)
        end
      end
    end

    context "with different dialogue scenarios" do
      context "single speaker dialogue" do
        let(:single_speaker_inputs) do
          [
            { text: "First sentence.", voice_id: "21m00Tcm4TlvDq8ikWAM" },
            { text: "Second sentence.", voice_id: "21m00Tcm4TlvDq8ikWAM" },
            { text: "Third sentence.", voice_id: "21m00Tcm4TlvDq8ikWAM" }
          ]
        end

        it "handles single speaker dialogue" do
          result = text_to_dialogue.convert(single_speaker_inputs)

          expect(result).to eq(binary_audio_data)
          expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
            .with(body: { inputs: single_speaker_inputs }.to_json)
        end
      end

      context "multi-speaker dialogue" do
        let(:multi_speaker_inputs) do
          [
            { text: "Speaker A: Hello there!", voice_id: "voice_a_id" },
            { text: "Speaker B: Hi! How are you?", voice_id: "voice_b_id" },
            { text: "Speaker C: Great to see you both!", voice_id: "voice_c_id" },
            { text: "Speaker A: Likewise!", voice_id: "voice_a_id" }
          ]
        end

        it "handles multi-speaker dialogue" do
          result = text_to_dialogue.convert(multi_speaker_inputs)

          expect(result).to eq(binary_audio_data)
          expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
            .with(body: { inputs: multi_speaker_inputs }.to_json)
        end
      end

      context "long dialogue" do
        let(:long_dialogue_inputs) do
          (1..10).map do |i|
            {
              text: "This is sentence number #{i} in a long dialogue that tests the API's ability to handle extended conversations.",
              voice_id: i.even? ? "voice_1" : "voice_2"
            }
          end
        end

        it "handles long dialogue" do
          result = text_to_dialogue.convert(long_dialogue_inputs)

          expect(result).to eq(binary_audio_data)
          expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
            .with(body: { inputs: long_dialogue_inputs }.to_json)
        end
      end
    end

    context "with different voice combinations" do
      let(:mixed_voice_inputs) do
        [
          { text: "English text", voice_id: "english_voice_id" },
          { text: "Texto en español", voice_id: "spanish_voice_id" },
          { text: "Texte français", voice_id: "french_voice_id" }
        ]
      end

      it "handles different voice combinations" do
        result = text_to_dialogue.convert(mixed_voice_inputs)

        expect(result).to eq(binary_audio_data)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-dialogue")
          .with(body: { inputs: mixed_voice_inputs }.to_json)
      end
    end
  end
end
