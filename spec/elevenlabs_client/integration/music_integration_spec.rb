# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Music Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }

  describe "client.music accessor" do
    it "provides access to music endpoint" do
      expect(client.music).to be_an_instance_of(ElevenlabsClient::Endpoints::Music)
    end
  end

  describe "music composition functionality via client" do
    let(:prompt) { "Create an upbeat electronic dance track" }
    let(:binary_response) { "fake_mp3_binary_data" }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/music")
        .to_return(
          status: 200,
          body: binary_response,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "composes music through client interface" do
      result = client.music.compose(prompt: prompt)

      expect(result).to eq(binary_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/music")
        .with(headers: { "Xi-Api-Key" => api_key })
    end

    it "supports the compose_music alias method" do
      result = client.music.compose_music(prompt: prompt)

      expect(result).to eq(binary_response)
    end
  end

  describe "music streaming functionality via client" do
    let(:prompt) { "Create a relaxing ambient track" }
    let(:audio_chunks) { ["chunk1", "chunk2", "chunk3"] }
    let(:received_chunks) { [] }

    before do
      # Mock the streaming behavior
      allow(client).to receive(:post_streaming) do |endpoint, body, &block|
        audio_chunks.each { |chunk| block.call(chunk) }
      end
    end

    it "streams music through client interface" do
      client.music.compose_stream(prompt: prompt) do |chunk|
        received_chunks << chunk
      end

      expect(received_chunks).to eq(audio_chunks)
      expect(client).to have_received(:post_streaming).with(
        "/v1/music/stream",
        { prompt: prompt, model_id: "music_v1" }
      )
    end

    it "supports the compose_music_stream alias method" do
      client.music.compose_music_stream(prompt: prompt) do |chunk|
        received_chunks << chunk
      end

      expect(received_chunks).to eq(audio_chunks)
    end
  end

  describe "detailed music composition via client" do
    let(:prompt) { "Create a classical symphony" }
    let(:multipart_response) do
      "--boundary123\r\n" \
      "Content-Type: application/json\r\n\r\n" \
      '{"composition_id": "comp_456", "duration_ms": 180000}\r\n' \
      "--boundary123\r\n" \
      "Content-Type: audio/mpeg\r\n\r\n" \
      "symphony_audio_data\r\n" \
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

    it "composes detailed music through client interface" do
      result = client.music.compose_detailed(prompt: prompt)

      expect(result).to eq(multipart_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/music/detailed")
        .with(headers: { "Xi-Api-Key" => api_key, "Accept" => "multipart/mixed" })
    end

    it "supports the compose_music_detailed alias method" do
      result = client.music.compose_music_detailed(prompt: prompt)

      expect(result).to eq(multipart_response)
    end
  end

  describe "music plan creation via client" do
    let(:prompt) { "Create a plan for an epic orchestral piece" }
    let(:plan_response) do
      {
        "composition_plan_id" => "plan_789",
        "sections" => [
          {
            "name" => "overture",
            "duration_ms" => 15000,
            "tempo" => 90,
            "key" => "C major"
          }
        ],
        "total_duration_ms" => 15000
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

    it "creates music plans through client interface" do
      result = client.music.create_plan(prompt: prompt)

      expect(result).to eq(plan_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/music/plan")
        .with(headers: { "Xi-Api-Key" => api_key })
    end

    it "supports the create_music_plan alias method" do
      result = client.music.create_music_plan(prompt: prompt)

      expect(result).to eq(plan_response)
    end
  end

  describe "consolidated error handling integration" do
    let(:prompt) { "Test prompt" }

    context "with BadRequestError" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/music")
          .to_return(
            status: 400,
            body: '{"detail": "Invalid prompt format"}'
          )
      end

      it "raises BadRequestError through client" do
        expect {
          client.music.compose(prompt: prompt)
        }.to raise_error(ElevenlabsClient::BadRequestError, "Invalid prompt format")
      end
    end

    context "with AuthenticationError" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/music")
          .to_return(
            status: 401,
            body: '{"detail": "Invalid API key provided"}'
          )
      end

      it "raises AuthenticationError through client" do
        expect {
          client.music.compose(prompt: prompt)
        }.to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key provided")
      end
    end

    context "with NotFoundError" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/music")
          .to_return(
            status: 404,
            body: '{"detail": "Music endpoint not found"}'
          )
      end

      it "raises NotFoundError through client" do
        expect {
          client.music.compose(prompt: prompt)
        }.to raise_error(ElevenlabsClient::NotFoundError, "Music endpoint not found")
      end
    end

    context "with UnprocessableEntityError" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/music")
          .to_return(
            status: 422,
            body: '{"detail": {"message": "Invalid composition parameters"}}'
          )
      end

      it "raises UnprocessableEntityError through client" do
        expect {
          client.music.compose(prompt: prompt)
        }.to raise_error(ElevenlabsClient::UnprocessableEntityError, "Invalid composition parameters")
      end
    end

    context "with RateLimitError" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/music")
          .to_return(
            status: 429,
            body: '{"detail": "Rate limit exceeded for music generation"}'
          )
      end

      it "raises RateLimitError through client" do
        expect {
          client.music.compose(prompt: prompt)
        }.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded for music generation")
      end
    end

    context "with ValidationError for other 4xx errors" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/music")
          .to_return(
            status: 403,
            body: '{"detail": "Access forbidden"}'
          )
      end

      it "raises ForbiddenError for access forbidden" do
        expect {
          client.music.compose(prompt: prompt)
        }.to raise_error(ElevenlabsClient::ForbiddenError, "Access forbidden")
      end
    end

    context "with APIError for server errors" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/music")
          .to_return(
            status: 500,
            body: '{"detail": "Internal server error"}'
          )
      end

      it "raises APIError for server errors" do
        expect {
          client.music.compose(prompt: prompt)
        }.to raise_error(ElevenlabsClient::APIError, "Internal server error")
      end
    end

    context "with enhanced error message extraction" do
      context "with nested error details" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/music")
            .to_return(
              status: 400,
              body: '{"detail": {"message": "Nested error message"}}'
            )
        end

        it "extracts nested error messages" do
          expect {
            client.music.compose(prompt: prompt)
          }.to raise_error(ElevenlabsClient::BadRequestError, "Nested error message")
        end
      end

      context "with array error details" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/music")
            .to_return(
              status: 400,
              body: '{"detail": ["First error", "Second error"]}'
            )
        end

        it "extracts first error from array" do
          expect {
            client.music.compose(prompt: prompt)
          }.to raise_error(ElevenlabsClient::BadRequestError, "First error")
        end
      end

      context "with non-JSON error response" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/music")
            .to_return(
              status: 500,
              body: "Internal Server Error - Something went wrong"
            )
        end

        it "handles non-JSON error responses" do
          expect {
            client.music.compose(prompt: prompt)
          }.to raise_error(ElevenlabsClient::APIError, "Internal Server Error - Something went wrong")
        end
      end

      context "with very long error message" do
        let(:long_error) { "Error: " + "x" * 300 }

        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/music")
            .to_return(status: 500, body: long_error)
        end

        it "truncates very long error messages" do
          expect {
            client.music.compose(prompt: prompt)
          }.to raise_error(ElevenlabsClient::APIError) do |error|
            expect(error.message.length).to be <= 204 # 200 + "..." + potential rounding
            expect(error.message).to end_with("...")
          end
        end
      end

      context "with empty error response" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/music")
            .to_return(status: 400, body: "")
        end

        it "uses default error message for empty responses" do
          expect {
            client.music.compose(prompt: prompt)
          }.to raise_error(ElevenlabsClient::BadRequestError, "Bad request - invalid parameters")
        end
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

        stub_request(:post, "https://configured.elevenlabs.io/v1/music")
          .to_return(
            status: 200,
            body: "configured_audio",
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "uses configured settings for music requests" do
        client = ElevenlabsClient.new
        
        result = client.music.compose(prompt: "test")

        expect(WebMock).to have_requested(:post, "https://configured.elevenlabs.io/v1/music")
          .with(headers: { "Xi-Api-Key" => "configured_api_key" })
      end
    end
  end

  describe "Rails usage example" do
    let(:prompt) { "Create background music for a video game" }
    let(:composition_plan) do
      {
        "sections" => [
          { "name" => "intro", "duration_ms" => 5000, "tempo" => 100 },
          { "name" => "loop", "duration_ms" => 30000, "tempo" => 120 }
        ]
      }
    end
    let(:audio_response) { "game_music_binary_data" }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128")
        .to_return(
          status: 200,
          body: audio_response,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "works as expected in a Rails-like environment" do
      # This simulates typical Rails usage
      client = ElevenlabsClient.new(api_key: api_key)
      
      # Compose music with detailed parameters
      result = client.music.compose(
        prompt: prompt,
        composition_plan: composition_plan["sections"],
        music_length_ms: 35000,
        model_id: "music_v1",
        output_format: "mp3_44100_128"
      )

      expect(result).to eq(audio_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128")
    end
  end

  describe "music composition workflow" do
    let(:prompt) { "Create an epic fantasy soundtrack" }
    let(:plan_response) do
      {
        "composition_plan_id" => "plan_epic_123",
        "sections" => [
          { "name" => "intro", "duration_ms" => 8000, "tempo" => 80 },
          { "name" => "main_theme", "duration_ms" => 25000, "tempo" => 120 },
          { "name" => "finale", "duration_ms" => 12000, "tempo" => 140 }
        ],
        "total_duration_ms" => 45000
      }
    end
    let(:audio_response) { "epic_fantasy_music_data" }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/music/plan")
        .to_return(
          status: 200,
          body: plan_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:post, "https://api.elevenlabs.io/v1/music")
        .to_return(
          status: 200,
          body: audio_response,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "supports complete music creation workflow" do
      # Step 1: Create a composition plan
      plan = client.music.create_plan(
        prompt: prompt,
        music_length_ms: 45000
      )

      expect(plan).to eq(plan_response)
      
      # Step 2: Use the plan to compose music
      music_result = client.music.compose(
        prompt: prompt,
        composition_plan: plan["sections"],
        music_length_ms: plan["total_duration_ms"]
      )

      expect(music_result).to eq(audio_response)
      
      # Verify all requests were made correctly
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/music/plan")
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/music")
    end
  end

  describe "streaming music scenarios" do
    let(:prompt) { "Create a live performance ambient track" }
    let(:large_audio_chunks) do
      # Simulate larger audio chunks
      Array.new(10) { |i| "audio_chunk_#{i}_" + "x" * 1024 }
    end
    let(:received_chunks) { [] }

    before do
      allow(client).to receive(:post_streaming) do |endpoint, body, &block|
        large_audio_chunks.each { |chunk| block.call(chunk) }
      end
    end

    it "handles large streaming audio chunks efficiently" do
      client.music.compose_stream(
        prompt: prompt,
        music_length_ms: 60000,
        output_format: "mp3_44100_192"
      ) do |chunk|
        received_chunks << chunk
        # Simulate processing each chunk
        expect(chunk).to be_a(String)
        expect(chunk.length).to be > 1000
      end

      expect(received_chunks.length).to eq(10)
      expect(received_chunks).to eq(large_audio_chunks)
    end
  end

  describe "music parameter combinations" do
    let(:prompt) { "Create adaptive game music" }

    before do
      stub_request(:post, %r{https://api\.elevenlabs\.io/v1/music.*})
        .to_return(status: 200, body: "music_data")
    end

    it "handles various parameter combinations correctly" do
      # Test different combinations of parameters
      test_cases = [
        { prompt: prompt },
        { prompt: prompt, model_id: "music_v2" },
        { prompt: prompt, music_length_ms: 30000 },
        { prompt: prompt, output_format: "wav_44100" },
        {
          prompt: prompt,
          composition_plan: { "tempo" => 120 },
          music_length_ms: 45000,
          model_id: "music_v2",
          output_format: "mp3_22050_64"
        }
      ]

      test_cases.each do |params|
        expect { client.music.compose(params) }.not_to raise_error
      end
    end
  end

  describe "multipart response handling" do
    let(:prompt) { "Create detailed orchestral piece" }
    let(:complex_multipart_response) do
      "--complex_boundary\r\n" \
      "Content-Type: application/json\r\n" \
      "Content-Disposition: form-data; name=\"metadata\"\r\n\r\n" \
      '{"id": "comp_complex", "sections": 5, "instruments": ["violin", "piano"]}\r\n' \
      "--complex_boundary\r\n" \
      "Content-Type: audio/mpeg\r\n" \
      "Content-Disposition: form-data; name=\"audio\"; filename=\"composition.mp3\"\r\n\r\n" \
      "complex_binary_audio_data_here\r\n" \
      "--complex_boundary--"
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/music/detailed")
        .to_return(
          status: 200,
          body: complex_multipart_response,
          headers: { "Content-Type" => "multipart/mixed; boundary=complex_boundary" }
        )
    end

    it "handles complex multipart responses" do
      result = client.music.compose_detailed(prompt: prompt)

      expect(result).to eq(complex_multipart_response)
      expect(result).to include("comp_complex")
      expect(result).to include("complex_binary_audio_data_here")
    end
  end

  describe "consolidated error handling across all methods" do
    let(:prompt) { "Test error handling" }

    shared_examples "proper error handling" do |method_name, endpoint_path|
      context "for #{method_name}" do
        it "handles BadRequestError consistently" do
          stub_request(:post, "https://api.elevenlabs.io#{endpoint_path}")
            .to_return(status: 400, body: '{"detail": "Bad request"}')

          expect {
            case method_name
            when :compose
              client.music.compose(prompt: prompt)
            when :compose_stream
              client.music.compose_stream(prompt: prompt) { |chunk| }
            when :compose_detailed
              client.music.compose_detailed(prompt: prompt)
            when :create_plan
              client.music.create_plan(prompt: prompt)
            end
          }.to raise_error(ElevenlabsClient::BadRequestError, "Bad request")
        end

        it "handles AuthenticationError consistently" do
          stub_request(:post, "https://api.elevenlabs.io#{endpoint_path}")
            .to_return(status: 401, body: '{"detail": "Unauthorized"}')

          expect {
            case method_name
            when :compose
              client.music.compose(prompt: prompt)
            when :compose_stream
              client.music.compose_stream(prompt: prompt) { |chunk| }
            when :compose_detailed
              client.music.compose_detailed(prompt: prompt)
            when :create_plan
              client.music.create_plan(prompt: prompt)
            end
          }.to raise_error(ElevenlabsClient::AuthenticationError, "Unauthorized")
        end
      end
    end

    include_examples "proper error handling", :compose, "/v1/music"
    include_examples "proper error handling", :compose_detailed, "/v1/music/detailed"
    include_examples "proper error handling", :create_plan, "/v1/music/plan"
  end
end
