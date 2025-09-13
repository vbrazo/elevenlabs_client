# frozen_string_literal: true

RSpec.describe "Dubbing workflow integration" do
  let(:client) { ElevenlabsClient.new(api_key: "test_api_key") }
  let(:video_file) { create_temp_video_file }
  let(:dubbing_id) { "test_dubbing_123" }

  after do
    video_file.close
    video_file.unlink
  end

  describe "complete dubbing workflow" do
    it "creates, monitors, and retrieves a dubbing job" do
      # Step 1: Create dubbing job
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing",
        method: :post,
        status: 200,
        response_body: {
          "dubbing_id" => dubbing_id,
          "status" => "dubbing",
          "name" => "Integration Test",
          "target_languages" => ["es"]
        }
      )

      create_result = client.dubs.create(
        file_io: video_file,
        filename: "test_video.mp4",
        target_languages: ["es"],
        name: "Integration Test"
      )

      expect(create_result["dubbing_id"]).to eq(dubbing_id)
      expect(create_result["status"]).to eq("dubbing")

      # Step 2: Check status (still dubbing)
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing/#{dubbing_id}",
        method: :get,
        status: 200,
        response_body: {
          "dubbing_id" => dubbing_id,
          "status" => "dubbing",
          "name" => "Integration Test",
          "target_languages" => ["es"],
          "progress" => 45
        }
      )

      status_result = client.dubs.get(dubbing_id)
      expect(status_result["status"]).to eq("dubbing")
      expect(status_result["progress"]).to eq(45)

      # Step 3: Check status (completed)
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing/#{dubbing_id}",
        method: :get,
        status: 200,
        response_body: {
          "dubbing_id" => dubbing_id,
          "status" => "dubbed",
          "name" => "Integration Test",
          "target_languages" => ["es"],
          "results" => {
            "output_files" => [
              {
                "language_code" => "es",
                "url" => "https://api.elevenlabs.io/download/dubbed_video_es.mp4"
              }
            ]
          }
        }
      )

      final_result = client.dubs.get(dubbing_id)
      expect(final_result["status"]).to eq("dubbed")
      expect(final_result["results"]["output_files"]).to be_an(Array)
      expect(final_result["results"]["output_files"].first["language_code"]).to eq("es")

      # Verify all API calls were made correctly
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/dubbing")
        .with(headers: { "xi-api-key" => "test_api_key" })

      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/dubbing/#{dubbing_id}")
        .with(headers: { "xi-api-key" => "test_api_key" })
        .twice
    end
  end

  describe "error handling in workflow" do
    it "handles authentication errors during creation" do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing",
        method: :post,
        status: 401,
        response_body: { "error" => "Invalid API key" }
      )

      expect {
        client.dubs.create(
          file_io: video_file,
          filename: "test_video.mp4",
          target_languages: ["es"]
        )
      }.to raise_error(ElevenlabsClient::AuthenticationError)
    end

    it "handles validation errors for invalid language codes" do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing",
        method: :post,
        status: 400,
        response_body: {
          "error" => "Invalid target language code: 'invalid_lang'"
        }
      )

      expect {
        client.dubs.create(
          file_io: video_file,
          filename: "test_video.mp4",
          target_languages: ["invalid_lang"]
        )
      }.to raise_error(ElevenlabsClient::BadRequestError)
    end

    it "handles rate limiting during high usage" do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing",
        method: :post,
        status: 429,
        response_body: { "error" => "Rate limit exceeded" }
      )

      expect {
        client.dubs.create(
          file_io: video_file,
          filename: "test_video.mp4",
          target_languages: ["es"]
        )
      }.to raise_error(ElevenlabsClient::RateLimitError)
    end

    it "handles server errors" do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing",
        method: :post,
        status: 500,
        response_body: { "error" => "Internal server error" }
      )

      expect {
        client.dubs.create(
          file_io: video_file,
          filename: "test_video.mp4",
          target_languages: ["es"]
        )
      }.to raise_error(ElevenlabsClient::APIError)
    end
  end

  describe "multiple language dubbing" do
    it "creates dub with multiple target languages" do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing",
        method: :post,
        status: 200,
        response_body: {
          "dubbing_id" => dubbing_id,
          "status" => "dubbing",
          "name" => "Multi-language Test",
          "target_languages" => ["es", "pt", "fr"]
        }
      )

      result = client.dubs.create(
        file_io: video_file,
        filename: "test_video.mp4",
        target_languages: ["es", "pt", "fr"],
        name: "Multi-language Test"
      )

      expect(result["target_languages"]).to eq(["es", "pt", "fr"])
    end
  end

  describe "dubbing with options" do
    it "creates dub with custom options" do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing",
        method: :post,
        status: 200,
        response_body: {
          "dubbing_id" => dubbing_id,
          "status" => "dubbing",
          "name" => "Options Test",
          "target_languages" => ["es"]
        }
      )

      result = client.dubs.create(
        file_io: video_file,
        filename: "test_video.mp4",
        target_languages: ["es"],
        name: "Options Test",
        drop_background_audio: true,
        use_profanity_filter: false,
        dubbing_studio: true
      )

      expect(result["status"]).to eq("dubbing")
    end
  end
end
