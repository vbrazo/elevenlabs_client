# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Endpoints::Music do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:music) { described_class.new(client) }

  describe "#compose" do
    let(:prompt) { "Create an upbeat electronic dance track with synthesizers" }
    let(:binary_response) { "fake_mp3_binary_data" }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/music")
        .to_return(
          status: 200,
          body: binary_response,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    context "with minimal parameters" do
      it "composes music successfully" do
        result = music.compose(prompt: prompt)

        expect(result).to eq(binary_response)
      end

      it "sends the correct request" do
        music.compose(prompt: prompt)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/music")
          .with(
            headers: {
              "Xi-Api-Key" => api_key,
              "Content-Type" => "application/json"
            },
            body: {
              prompt: prompt,
              model_id: "music_v1"
            }.to_json
          )
      end
    end

    context "with all parameters" do
      let(:composition_plan) do
        {
          "sections" => [
            { "name" => "intro", "duration_ms" => 8000 },
            { "name" => "verse", "duration_ms" => 16000 },
            { "name" => "chorus", "duration_ms" => 12000 }
          ]
        }
      end
      let(:music_length_ms) { 36000 }
      let(:model_id) { "music_v2" }
      let(:output_format) { "mp3_44100_192" }

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/music?output_format=#{output_format}")
          .to_return(
            status: 200,
            body: binary_response,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "includes all parameters in the request" do
        music.compose(
          prompt: prompt,
          composition_plan: composition_plan,
          music_length_ms: music_length_ms,
          model_id: model_id,
          output_format: output_format
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/music?output_format=#{output_format}")
          .with(
            body: {
              prompt: prompt,
              composition_plan: composition_plan,
              music_length_ms: music_length_ms,
              model_id: model_id
            }.to_json
          )
      end
    end

    context "when API returns an error" do
      context "with bad request" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/music")
            .to_return(status: 400, body: "Invalid prompt")
        end

        it "raises BadRequestError" do
          expect {
            music.compose(prompt: prompt)
          }.to raise_error(ElevenlabsClient::BadRequestError)
        end
      end

      context "with authentication error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/music")
            .to_return(status: 401, body: "Unauthorized")
        end

        it "raises AuthenticationError" do
          expect {
            music.compose(prompt: prompt)
          }.to raise_error(ElevenlabsClient::AuthenticationError)
        end
      end
    end
  end

  describe "#compose_stream" do
    let(:prompt) { "Create a relaxing ambient soundscape" }
    let(:audio_chunks) { ["chunk1", "chunk2", "chunk3"] }
    let(:received_chunks) { [] }

    before do
      # Mock the streaming response
      allow(client).to receive(:post_streaming) do |endpoint, body, &block|
        audio_chunks.each { |chunk| block.call(chunk) }
      end
    end

    it "streams music successfully" do
      music.compose_stream(prompt: prompt) do |chunk|
        received_chunks << chunk
      end

      expect(received_chunks).to eq(audio_chunks)
    end

    it "calls post_streaming with correct parameters" do
      expect(client).to receive(:post_streaming).with(
        "/v1/music/stream",
        {
          prompt: prompt,
          model_id: "music_v1"
        }
      )

      music.compose_stream(prompt: prompt) { |chunk| }
    end

    context "with output format" do
      let(:output_format) { "mp3_22050_64" }

      it "includes output format in query parameters" do
        expect(client).to receive(:post_streaming).with(
          "/v1/music/stream?output_format=#{output_format}",
          {
            prompt: prompt,
            model_id: "music_v1"
          }
        )

        music.compose_stream(prompt: prompt, output_format: output_format) { |chunk| }
      end
    end
  end

  describe "#compose_detailed" do
    let(:prompt) { "Create a classical piano piece" }
    let(:multipart_response) do
      "--boundary123\r\n" \
      "Content-Type: application/json\r\n\r\n" \
      '{"composition_id": "comp_123", "duration_ms": 30000}\r\n' \
      "--boundary123\r\n" \
      "Content-Type: audio/mpeg\r\n\r\n" \
      "binary_audio_data\r\n" \
      "--boundary123--"
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/music/detailed")
        .to_return(
          status: 200,
          body: multipart_response,
          headers: { "Content-Type" => "multipart/mixed; boundary=boundary123" }
        )
    end

    it "composes detailed music successfully" do
      result = music.compose_detailed(prompt: prompt)

      expect(result).to eq(multipart_response)
    end

    it "sends the correct request" do
      music.compose_detailed(prompt: prompt)

      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/music/detailed")
        .with(
          headers: {
            "xi-api-key" => api_key,
            "Content-Type" => "application/json",
            "Accept" => "multipart/mixed"
          },
          body: {
            prompt: prompt,
            model_id: "music_v1"
          }.to_json
        )
    end

    context "with composition plan" do
      let(:composition_plan) do
        {
          "tempo" => 120,
          "key" => "C major",
          "instruments" => ["piano", "strings"]
        }
      end

      it "includes composition plan in the request" do
        music.compose_detailed(
          prompt: prompt,
          composition_plan: composition_plan
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/music/detailed")
          .with(
            body: {
              prompt: prompt,
              composition_plan: composition_plan,
              model_id: "music_v1"
            }.to_json
          )
      end
    end
  end

  describe "#create_plan" do
    let(:prompt) { "Create a plan for an epic orchestral soundtrack" }
    let(:plan_response) do
      {
        "composition_plan_id" => "plan_456",
        "sections" => [
          {
            "name" => "introduction",
            "duration_ms" => 10000,
            "tempo" => 80,
            "key" => "D minor",
            "instruments" => ["strings", "brass"]
          },
          {
            "name" => "main_theme",
            "duration_ms" => 20000,
            "tempo" => 120,
            "key" => "D minor",
            "instruments" => ["full_orchestra"]
          }
        ],
        "total_duration_ms" => 30000
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/music/plan")
        .to_return(
          status: 200,
          body: plan_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates a music plan successfully" do
      result = music.create_plan(prompt: prompt)

      expect(result).to eq(plan_response)
    end

    it "sends the correct request" do
      music.create_plan(prompt: prompt)

      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/music/plan")
        .with(
          headers: {
            "xi-api-key" => api_key,
            "Content-Type" => "application/json"
          },
          body: {
            prompt: prompt,
            model_id: "music_v1"
          }.to_json
        )
    end

    context "with all parameters" do
      let(:music_length_ms) { 45000 }
      let(:source_plan) do
        {
          "sections" => [
            { "name" => "intro", "duration_ms" => 5000 }
          ]
        }
      end
      let(:model_id) { "music_v2" }

      it "includes all parameters in the request" do
        music.create_plan(
          prompt: prompt,
          music_length_ms: music_length_ms,
          source_composition_plan: source_plan,
          model_id: model_id
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/music/plan")
          .with(
            body: {
              prompt: prompt,
              music_length_ms: music_length_ms,
              source_composition_plan: source_plan,
              model_id: model_id
            }.to_json
          )
      end
    end

    context "when API returns an error" do
      context "with validation error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/music/plan")
            .to_return(status: 422, body: '{"detail": "Invalid music length"}')
        end

        it "raises UnprocessableEntityError" do
          expect {
            music.create_plan(prompt: prompt)
          }.to raise_error(ElevenlabsClient::UnprocessableEntityError, "Invalid music length")
        end
      end
    end
  end

  describe "alias methods" do
    let(:prompt) { "Test music" }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/music")
        .to_return(status: 200, body: "audio_data")
      stub_request(:post, "https://api.elevenlabs.io/v1/music/detailed")
        .to_return(status: 200, body: "multipart_data")
      stub_request(:post, "https://api.elevenlabs.io/v1/music/plan")
        .to_return(status: 200, body: {}.to_json)
      
      allow(client).to receive(:post_streaming)
    end

    describe "#compose_music" do
      it "is an alias for compose method" do
        music.compose_music(prompt: prompt)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/music")
      end
    end

    describe "#compose_music_stream" do
      it "is an alias for compose_stream method" do
        music.compose_music_stream(prompt: prompt) { |chunk| }

        expect(client).to have_received(:post_streaming)
      end
    end

    describe "#compose_music_detailed" do
      it "is an alias for compose_detailed method" do
        music.compose_music_detailed(prompt: prompt)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/music/detailed")
      end
    end

    describe "#create_music_plan" do
      it "is an alias for create_plan method" do
        music.create_music_plan(prompt: prompt)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/music/plan")
      end
    end
  end

  describe "parameter validation" do
    context "with empty options" do
      it "uses default model_id" do
        stub_request(:post, "https://api.elevenlabs.io/v1/music")
          .to_return(status: 200, body: "audio")

        music.compose({})

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/music")
          .with(
            body: {
              model_id: "music_v1"
            }.to_json
          )
      end
    end

    context "with nil values" do
      it "excludes nil values from request body" do
        stub_request(:post, "https://api.elevenlabs.io/v1/music")
          .to_return(status: 200, body: "audio")

        music.compose(
          prompt: "test",
          composition_plan: nil,
          music_length_ms: nil
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/music")
          .with(
            body: {
              prompt: "test",
              model_id: "music_v1"
            }.to_json
          )
      end
    end
  end

  describe "error handling integration" do
    let(:prompt) { "Test prompt" }

    context "with different error types" do
      it "handles NotFoundError" do
        stub_request(:post, "https://api.elevenlabs.io/v1/music")
          .to_return(status: 404, body: '{"detail": "Endpoint not found"}')

        expect {
          music.compose(prompt: prompt)
        }.to raise_error(ElevenlabsClient::NotFoundError, "Endpoint not found")
      end

      it "handles UnprocessableEntityError" do
        stub_request(:post, "https://api.elevenlabs.io/v1/music")
          .to_return(status: 422, body: '{"detail": {"message": "Invalid composition plan"}}')

        expect {
          music.compose(prompt: prompt)
        }.to raise_error(ElevenlabsClient::UnprocessableEntityError, "Invalid composition plan")
      end

      it "handles RateLimitError" do
        stub_request(:post, "https://api.elevenlabs.io/v1/music")
          .to_return(status: 429, body: '{"detail": "Rate limit exceeded"}')

        expect {
          music.compose(prompt: prompt)
        }.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end
    end
  end
end
