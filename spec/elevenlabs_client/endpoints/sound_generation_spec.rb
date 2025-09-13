# frozen_string_literal: true

RSpec.describe ElevenlabsClient::SoundGeneration do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:sound_generation) { described_class.new(client) }
  let(:binary_audio_data) { "fake_sound_effect_mp3_binary_data_here" }

  describe "#generate" do
    let(:text) { "A gentle rain falling on leaves" }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/sound-generation")
        .to_return(
          status: 200,
          body: binary_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    context "with required parameters only" do
      it "generates sound effects successfully" do
        result = sound_generation.generate(text)

        expect(result).to eq(binary_audio_data)
      end

      it "sends the correct request" do
        sound_generation.generate(text)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/sound-generation")
          .with(
            headers: {
              "xi-api-key" => api_key,
              "Content-Type" => "application/json"
            },
            body: { text: text }.to_json
          )
      end
    end

    context "with loop option" do
      it "includes loop parameter when true" do
        sound_generation.generate(text, loop: true)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/sound-generation")
          .with(
            body: {
              text: text,
              loop: true
            }.to_json
          )
      end

      it "includes loop parameter when false" do
        sound_generation.generate(text, loop: false)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/sound-generation")
          .with(
            body: {
              text: text,
              loop: false
            }.to_json
          )
      end

      it "does not include loop parameter when nil" do
        sound_generation.generate(text, loop: nil)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/sound-generation")
          .with(
            body: { text: text }.to_json
          )
      end
    end

    context "with duration_seconds option" do
      let(:duration) { 5.5 }

      it "includes duration_seconds in the request" do
        sound_generation.generate(text, duration_seconds: duration)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/sound-generation")
          .with(
            body: {
              text: text,
              duration_seconds: duration
            }.to_json
          )
      end
    end

    context "with prompt_influence option" do
      let(:prompt_influence) { 0.7 }

      it "includes prompt_influence in the request" do
        sound_generation.generate(text, prompt_influence: prompt_influence)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/sound-generation")
          .with(
            body: {
              text: text,
              prompt_influence: prompt_influence
            }.to_json
          )
      end
    end

    context "with output_format option" do
      let(:output_format) { "mp3_22050_32" }

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_22050_32")
          .to_return(
            status: 200,
            body: binary_audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "includes output_format as query parameter" do
        sound_generation.generate(text, output_format: output_format)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_22050_32")
          .with(
            body: { text: text }.to_json
          )
      end
    end

    context "with all options" do
      let(:options) do
        {
          loop: true,
          duration_seconds: 10.0,
          prompt_influence: 0.8,
          output_format: "mp3_22050_32"
        }
      end

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_22050_32")
          .to_return(
            status: 200,
            body: binary_audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "includes all options in the request" do
        sound_generation.generate(text, **options)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_22050_32")
          .with(
            body: {
              text: text,
              loop: true,
              duration_seconds: 10.0,
              prompt_influence: 0.8
            }.to_json
          )
      end
    end

    context "when API returns an error" do
      context "with authentication error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/sound-generation")
            .to_return(status: 401, body: "Unauthorized")
        end

        it "raises AuthenticationError" do
          expect {
            sound_generation.generate(text)
          }.to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key or authentication failed")
        end
      end

      context "with rate limit error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/sound-generation")
            .to_return(status: 429, body: "Rate limit exceeded")
        end

        it "raises RateLimitError" do
          expect {
            sound_generation.generate(text)
          }.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
        end
      end

      context "with validation error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/sound-generation")
            .to_return(status: 400, body: "Invalid sound generation parameters")
        end

        it "raises ValidationError" do
          expect {
            sound_generation.generate(text)
          }.to raise_error(ElevenlabsClient::ValidationError)
        end
      end

      context "with server error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/sound-generation")
            .to_return(status: 500, body: "Internal Server Error")
        end

        it "raises APIError" do
          expect {
            sound_generation.generate(text)
          }.to raise_error(ElevenlabsClient::APIError)
        end
      end
    end

    context "with different sound effect prompts" do
      let(:sound_prompts) do
        [
          "Ocean waves crashing on the shore",
          "Birds chirping in a forest at dawn",
          "Heavy rain with thunder",
          "Crackling fireplace",
          "City traffic during rush hour",
          "Wind blowing through trees",
          "Footsteps on gravel",
          "Clock ticking in a quiet room"
        ]
      end

      it "handles various sound effect prompts" do
        sound_prompts.each do |prompt|
          result = sound_generation.generate(prompt)
          expect(result).to eq(binary_audio_data)
        end

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/sound-generation")
          .times(sound_prompts.length)
      end
    end

    context "with different duration ranges" do
      let(:durations) { [0.5, 1.0, 5.0, 10.0, 15.0, 30.0] }

      it "handles different duration values" do
        durations.each do |duration|
          sound_generation.generate(text, duration_seconds: duration)

          expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/sound-generation")
            .with(
              body: hash_including(duration_seconds: duration)
            )
        end
      end
    end

    context "with different prompt influence values" do
      let(:influences) { [0.0, 0.1, 0.3, 0.5, 0.7, 1.0] }

      it "handles different prompt influence values" do
        influences.each do |influence|
          sound_generation.generate(text, prompt_influence: influence)

          expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/sound-generation")
            .with(
              body: hash_including(prompt_influence: influence)
            )
        end
      end
    end

    context "with different output formats" do
      let(:formats) do
        [
          "mp3_44100_128",
          "mp3_22050_32",
          "pcm_16000",
          "pcm_24000"
        ]
      end

      it "handles different output formats" do
        formats.each do |format|
          stub_request(:post, "https://api.elevenlabs.io/v1/sound-generation?output_format=#{format}")
            .to_return(
              status: 200,
              body: binary_audio_data,
              headers: { "Content-Type" => "audio/mpeg" }
            )

          result = sound_generation.generate(text, output_format: format)
          expect(result).to eq(binary_audio_data)

          expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/sound-generation?output_format=#{format}")
        end
      end
    end

    context "with looping sound effects" do
      it "generates looping sound effects" do
        result = sound_generation.generate(
          "Ambient forest sounds",
          loop: true,
          duration_seconds: 30.0
        )

        expect(result).to eq(binary_audio_data)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/sound-generation")
          .with(
            body: {
              text: "Ambient forest sounds",
              loop: true,
              duration_seconds: 30.0
            }.to_json
          )
      end
    end
  end

  describe "#sound_generation" do
    let(:text) { "Thunder and lightning" }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/sound-generation")
        .to_return(
          status: 200,
          body: binary_audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "is an alias for generate method" do
      result = sound_generation.sound_generation(text)

      expect(result).to eq(binary_audio_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/sound-generation")
    end
  end
end
