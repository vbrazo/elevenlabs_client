# frozen_string_literal: true

RSpec.describe ElevenlabsClient::TextToVoice do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:text_to_voice) { described_class.new(client) }

  describe "#design" do
    let(:voice_description) { "A warm, friendly female voice with a slight British accent" }
    let(:design_response) do
      {
        "previews" => [
          {
            "generated_voice_id" => "voice_123",
            "audio_base_64" => "base64_audio_data_here",
            "text" => "Sample text for preview"
          }
        ],
        "text" => "Generated sample text"
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

    context "with required parameters only" do
      it "designs a voice successfully" do
        result = text_to_voice.design(voice_description)

        expect(result).to eq(design_response)
      end

      it "sends the correct request" do
        text_to_voice.design(voice_description)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
          .with(
            headers: {
              "xi-api-key" => api_key,
              "Content-Type" => "application/json"
            },
            body: { voice_description: voice_description }.to_json
          )
      end
    end

    context "with output_format option" do
      let(:output_format) { "mp3_22050_32" }

      it "includes output_format in the request" do
        text_to_voice.design(voice_description, output_format: output_format)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
          .with(
            body: {
              voice_description: voice_description,
              output_format: output_format
            }.to_json
          )
      end
    end

    context "with model_id option" do
      let(:model_id) { "eleven_multilingual_ttv_v2" }

      it "includes model_id in the request" do
        text_to_voice.design(voice_description, model_id: model_id)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
          .with(
            body: {
              voice_description: voice_description,
              model_id: model_id
            }.to_json
          )
      end
    end

    context "with text option" do
      let(:text) { "This is a custom text for voice generation that should be at least 100 characters long to meet the API requirements." }

      it "includes text in the request" do
        text_to_voice.design(voice_description, text: text)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
          .with(
            body: {
              voice_description: voice_description,
              text: text
            }.to_json
          )
      end
    end

    context "with boolean options" do
      it "includes auto_generate_text when true" do
        text_to_voice.design(voice_description, auto_generate_text: true)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
          .with(
            body: {
              voice_description: voice_description,
              auto_generate_text: true
            }.to_json
          )
      end

      it "includes auto_generate_text when false" do
        text_to_voice.design(voice_description, auto_generate_text: false)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
          .with(
            body: {
              voice_description: voice_description,
              auto_generate_text: false
            }.to_json
          )
      end

      it "includes stream_previews when true" do
        text_to_voice.design(voice_description, stream_previews: true)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
          .with(
            body: {
              voice_description: voice_description,
              stream_previews: true
            }.to_json
          )
      end
    end

    context "with numeric options" do
      it "includes loudness" do
        text_to_voice.design(voice_description, loudness: 0.7)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
          .with(
            body: {
              voice_description: voice_description,
              loudness: 0.7
            }.to_json
          )
      end

      it "includes seed" do
        text_to_voice.design(voice_description, seed: 12345)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
          .with(
            body: {
              voice_description: voice_description,
              seed: 12345
            }.to_json
          )
      end

      it "includes guidance_scale" do
        text_to_voice.design(voice_description, guidance_scale: 7.5)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
          .with(
            body: {
              voice_description: voice_description,
              guidance_scale: 7.5
            }.to_json
          )
      end

      it "includes quality" do
        text_to_voice.design(voice_description, quality: 0.8)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
          .with(
            body: {
              voice_description: voice_description,
              quality: 0.8
            }.to_json
          )
      end

      it "includes prompt_strength" do
        text_to_voice.design(voice_description, prompt_strength: 0.6)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
          .with(
            body: {
              voice_description: voice_description,
              prompt_strength: 0.6
            }.to_json
          )
      end
    end

    context "with remixing options" do
      it "includes remixing_session_id" do
        session_id = "session_123"
        text_to_voice.design(voice_description, remixing_session_id: session_id)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
          .with(
            body: {
              voice_description: voice_description,
              remixing_session_id: session_id
            }.to_json
          )
      end

      it "includes remixing_session_iteration_id" do
        iteration_id = "iteration_456"
        text_to_voice.design(voice_description, remixing_session_iteration_id: iteration_id)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
          .with(
            body: {
              voice_description: voice_description,
              remixing_session_iteration_id: iteration_id
            }.to_json
          )
      end
    end

    context "with reference audio" do
      let(:reference_audio) { "base64_encoded_audio_data_here" }

      it "includes reference_audio_base64" do
        text_to_voice.design(voice_description, reference_audio_base64: reference_audio)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
          .with(
            body: {
              voice_description: voice_description,
              reference_audio_base64: reference_audio
            }.to_json
          )
      end
    end

    context "with all options" do
      let(:all_options) do
        {
          output_format: "mp3_44100_192",
          model_id: "eleven_ttv_v3",
          text: "Custom text for voice generation that meets the minimum character requirements for the API endpoint.",
          auto_generate_text: false,
          loudness: 0.6,
          seed: 98765,
          guidance_scale: 8.0,
          stream_previews: true,
          remixing_session_id: "session_789",
          remixing_session_iteration_id: "iteration_101",
          quality: 0.9,
          reference_audio_base64: "base64_reference_audio",
          prompt_strength: 0.7
        }
      end

      it "includes all options in the request" do
        text_to_voice.design(voice_description, **all_options)

        expected_body = { voice_description: voice_description }.merge(all_options)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
          .with(body: expected_body.to_json)
      end
    end

    context "when API returns an error" do
      context "with authentication error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
            .to_return(status: 401, body: "Unauthorized")
        end

        it "raises AuthenticationError" do
          expect {
            text_to_voice.design(voice_description)
          }.to raise_error(ElevenlabsClient::AuthenticationError)
        end
      end

      context "with validation error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
            .to_return(status: 400, body: "Invalid voice description")
        end

        it "raises BadRequestError" do
          expect {
            text_to_voice.design(voice_description)
          }.to raise_error(ElevenlabsClient::BadRequestError)
        end
      end
    end
  end

  describe "#create" do
    let(:voice_name) { "My Custom Voice" }
    let(:voice_description) { "A warm, friendly female voice" }
    let(:generated_voice_id) { "generated_voice_123" }
    let(:create_response) do
      {
        "voice_id" => "voice_456",
        "name" => voice_name,
        "description" => voice_description,
        "category" => "generated"
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

    context "with required parameters only" do
      it "creates a voice successfully" do
        result = text_to_voice.create(voice_name, voice_description, generated_voice_id)

        expect(result).to eq(create_response)
      end

      it "sends the correct request" do
        text_to_voice.create(voice_name, voice_description, generated_voice_id)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice")
          .with(
            headers: {
              "xi-api-key" => api_key,
              "Content-Type" => "application/json"
            },
            body: {
              voice_name: voice_name,
              voice_description: voice_description,
              generated_voice_id: generated_voice_id
            }.to_json
          )
      end
    end

    context "with labels option" do
      let(:labels) { { "accent" => "british", "gender" => "female" } }

      it "includes labels in the request" do
        text_to_voice.create(voice_name, voice_description, generated_voice_id, labels: labels)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice")
          .with(
            body: {
              voice_name: voice_name,
              voice_description: voice_description,
              generated_voice_id: generated_voice_id,
              labels: labels
            }.to_json
          )
      end
    end

    context "with played_not_selected_voice_ids option" do
      let(:played_voice_ids) { ["voice_1", "voice_2", "voice_3"] }

      it "includes played_not_selected_voice_ids in the request" do
        text_to_voice.create(
          voice_name, 
          voice_description, 
          generated_voice_id, 
          played_not_selected_voice_ids: played_voice_ids
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice")
          .with(
            body: {
              voice_name: voice_name,
              voice_description: voice_description,
              generated_voice_id: generated_voice_id,
              played_not_selected_voice_ids: played_voice_ids
            }.to_json
          )
      end
    end

    context "with all options" do
      let(:labels) { { "accent" => "american", "age" => "young_adult" } }
      let(:played_voice_ids) { ["voice_a", "voice_b"] }

      it "includes all options in the request" do
        text_to_voice.create(
          voice_name,
          voice_description,
          generated_voice_id,
          labels: labels,
          played_not_selected_voice_ids: played_voice_ids
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice")
          .with(
            body: {
              voice_name: voice_name,
              voice_description: voice_description,
              generated_voice_id: generated_voice_id,
              labels: labels,
              played_not_selected_voice_ids: played_voice_ids
            }.to_json
          )
      end
    end
  end

  describe "#list_voices" do
    let(:voices_response) do
      {
        "voices" => [
          {
            "voice_id" => "voice_1",
            "name" => "Alice",
            "category" => "premade"
          },
          {
            "voice_id" => "voice_2",
            "name" => "Bob",
            "category" => "generated"
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

    it "lists voices successfully" do
      result = text_to_voice.list_voices

      expect(result).to eq(voices_response)
    end

    it "sends the correct request" do
      text_to_voice.list_voices

      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/voices")
        .with(
          headers: {
            "xi-api-key" => api_key
          }
        )
    end
  end

  describe "#stream_preview" do
    let(:generated_voice_id) { "generated_voice_123" }
    let(:audio_chunks) { ["chunk1", "chunk2", "chunk3"] }

    before do
      # Mock the streaming response
      stub_request(:get, "https://api.elevenlabs.io/v1/text-to-voice/#{generated_voice_id}/stream")
        .to_return(status: 200, body: audio_chunks.join)
    end

    context "with valid generated_voice_id" do
      it "streams voice preview successfully" do
        collected_chunks = []
        
        text_to_voice.stream_preview(generated_voice_id) do |chunk|
          collected_chunks << chunk
        end

        expect(collected_chunks).not_to be_empty
      end

      it "sends the correct GET request" do
        text_to_voice.stream_preview(generated_voice_id) { |chunk| }

        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/text-to-voice/#{generated_voice_id}/stream")
          .with(
            headers: {
              "xi-api-key" => api_key,
              "Accept" => "audio/mpeg"
            }
          )
      end

      it "works without a block" do
        expect {
          text_to_voice.stream_preview(generated_voice_id)
        }.not_to raise_error
      end
    end

    context "when API returns an error" do
      context "with unprocessable entity error" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/text-to-voice/#{generated_voice_id}/stream")
            .to_return(
              status: 422,
              body: {
                detail: [
                  {
                    loc: ["generated_voice_id"],
                    msg: "Invalid generated voice ID",
                    type: "value_error"
                  }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "raises UnprocessableEntityError" do
          expect {
            text_to_voice.stream_preview(generated_voice_id) { |chunk| }
          }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
        end
      end

      context "with authentication error" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/text-to-voice/#{generated_voice_id}/stream")
            .to_return(status: 401, body: "Unauthorized")
        end

        it "raises AuthenticationError" do
          expect {
            text_to_voice.stream_preview(generated_voice_id) { |chunk| }
          }.to raise_error(ElevenlabsClient::AuthenticationError)
        end
      end

      context "with not found error" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/text-to-voice/#{generated_voice_id}/stream")
            .to_return(status: 404, body: "Generated voice not found")
        end

        it "raises NotFoundError" do
          expect {
            text_to_voice.stream_preview(generated_voice_id) { |chunk| }
          }.to raise_error(ElevenlabsClient::NotFoundError)
        end
      end
    end

    context "with different generated voice IDs" do
      it "uses the correct generated voice ID in the endpoint" do
        different_voice_id = "different_voice_456"
        
        stub_request(:get, "https://api.elevenlabs.io/v1/text-to-voice/#{different_voice_id}/stream")
          .to_return(status: 200, body: "audio_data")

        text_to_voice.stream_preview(different_voice_id) { |chunk| }

        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/text-to-voice/#{different_voice_id}/stream")
      end
    end

    context "when collecting all chunks" do
      it "allows collecting all streamed chunks" do
        all_chunks = []
        
        text_to_voice.stream_preview(generated_voice_id) do |chunk|
          all_chunks << chunk
        end

        expect(all_chunks.join).to eq(audio_chunks.join)
      end
    end
  end

  describe "alias methods" do
    let(:voice_description) { "Test voice description" }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
        .to_return(status: 200, body: {}.to_json)
      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-voice")
        .to_return(status: 200, body: {}.to_json)
      stub_request(:get, "https://api.elevenlabs.io/v1/text-to-voice/generated_voice_123/stream")
        .to_return(status: 200, body: "audio_data")
    end

    describe "#design_voice" do
      it "is an alias for design method" do
        text_to_voice.design_voice(voice_description)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice/design")
      end
    end

    describe "#create_from_generated_voice" do
      it "is an alias for create method" do
        text_to_voice.create_from_generated_voice("Name", "Description", "generated_id")

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/text-to-voice")
      end
    end

    describe "#stream_voice_preview" do
      it "is an alias for stream_preview method" do
        text_to_voice.stream_voice_preview("generated_voice_123") { |chunk| }

        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/text-to-voice/generated_voice_123/stream")
      end
    end
  end
end
