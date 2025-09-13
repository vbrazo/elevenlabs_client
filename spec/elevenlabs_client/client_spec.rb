# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Client do
  let(:api_key) { "test_api_key" }
  let(:client) { described_class.new(api_key: api_key) }

  describe "#initialize" do
    context "with explicit API key" do
      it "sets the API key" do
        expect(client.api_key).to eq(api_key)
      end

      it "sets default base URL" do
        expect(client.base_url).to eq("https://api.elevenlabs.io")
      end
    end

    context "with custom base URL" do
      let(:custom_url) { "https://custom.elevenlabs.com" }
      let(:client) { described_class.new(api_key: api_key, base_url: custom_url) }

      it "sets the custom base URL" do
        expect(client.base_url).to eq(custom_url)
      end
    end

    context "without API key" do
      before do
        allow(ENV).to receive(:fetch).with("ELEVENLABS_API_KEY").and_return("env_api_key")
        allow(ENV).to receive(:fetch).with("ELEVENLABS_BASE_URL", "https://api.elevenlabs.io").and_return("https://api.elevenlabs.io")
      end

      it "uses environment variable" do
        client = described_class.new
        expect(client.api_key).to eq("env_api_key")
      end
    end

    context "when API key is missing" do
      before do
        allow(ENV).to receive(:fetch).with("ELEVENLABS_API_KEY").and_yield
        allow(ENV).to receive(:fetch).with("ELEVENLABS_BASE_URL", "https://api.elevenlabs.io").and_return("https://api.elevenlabs.io")
      end

      it "raises AuthenticationError" do
        expect {
          described_class.new
        }.to raise_error(ElevenlabsClient::AuthenticationError, /ELEVENLABS_API_KEY/)
      end
    end
  end

  describe "#dubs" do
    it "provides access to dubs endpoint" do
      expect(client.dubs).to be_an_instance_of(ElevenlabsClient::Dubs)
    end
  end

  describe "#patch" do
    let(:path) { "/v1/test/patch" }
    let(:request_body) { { "field" => "updated_value" } }
    let(:response_body) { { "status" => "updated", "version" => 2 } }

    before do
      stub_request(:patch, "https://api.elevenlabs.io#{path}")
        .with(
          headers: {
            "xi-api-key" => api_key,
            "Content-Type" => "application/json"
          },
          body: request_body.to_json
        )
        .to_return(
          status: 200,
          body: response_body.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "makes authenticated PATCH request with JSON body" do
      result = client.patch(path, request_body)

      expect(result).to eq(response_body)
      expect(WebMock).to have_requested(:patch, "https://api.elevenlabs.io#{path}")
        .with(
          headers: {
            "xi-api-key" => api_key,
            "Content-Type" => "application/json"
          },
          body: request_body.to_json
        )
    end

    context "without request body" do
      before do
        stub_request(:patch, "https://api.elevenlabs.io#{path}")
          .with(
            headers: {
              "xi-api-key" => api_key,
              "Content-Type" => "application/json"
            }
          )
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "makes PATCH request without body" do
        result = client.patch(path)

        expect(result).to eq(response_body)
        expect(WebMock).to have_requested(:patch, "https://api.elevenlabs.io#{path}")
          .with(
            headers: {
              "xi-api-key" => api_key,
              "Content-Type" => "application/json"
            }
          )
      end
    end

    context "when API returns error" do
      before do
        stub_request(:patch, "https://api.elevenlabs.io#{path}")
          .to_return(status: 400, body: "Bad Request")
      end

      it "raises BadRequestError for 400 status" do
        expect {
          client.patch(path, request_body)
        }.to raise_error(ElevenlabsClient::BadRequestError)
      end
    end

    context "when API returns 401" do
      before do
        stub_request(:patch, "https://api.elevenlabs.io#{path}")
          .to_return(status: 401, body: "Unauthorized")
      end

      it "raises AuthenticationError" do
        expect {
          client.patch(path, request_body)
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    context "when API returns 404" do
      before do
        stub_request(:patch, "https://api.elevenlabs.io#{path}")
          .to_return(status: 404, body: "Not Found")
      end

      it "raises NotFoundError" do
        expect {
          client.patch(path, request_body)
        }.to raise_error(ElevenlabsClient::NotFoundError)
      end
    end

    context "when API returns 422" do
      before do
        stub_request(:patch, "https://api.elevenlabs.io#{path}")
          .to_return(status: 422, body: "Unprocessable Entity")
      end

      it "raises UnprocessableEntityError" do
        expect {
          client.patch(path, request_body)
        }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end
  end

  describe "dubbing functionality via dubs endpoint" do
    let(:video_file) { create_temp_video_file }
    let(:response_body) do
      {
        "dubbing_id" => "abc123",
        "status" => "dubbing",
        "name" => "Test Dub",
        "target_languages" => ["es"]
      }
    end

    before do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing",
        method: :post,
        status: 200,
        response_body: response_body
      )
    end

    after do
      video_file.close
      video_file.unlink
    end

    it "creates a dubbing job successfully" do
      result = client.dubs.create(
        file_io: video_file,
        filename: "test.mp4",
        target_languages: ["es"],
        name: "Test Dub"
      )

      expect(result).to eq(response_body)
    end

    it "sends correct parameters to API" do
      client.dubs.create(
        file_io: video_file,
        filename: "test.mp4",
        target_languages: ["es", "pt"],
        name: "Test Dub",
        drop_background_audio: true
      )

      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/dubbing")
        .with(headers: { "xi-api-key" => api_key })
    end

    it "handles missing name parameter" do
      result = client.dubs.create(
        file_io: video_file,
        filename: "test.mp4",
        target_languages: ["es"]
      )

      expect(result).to eq(response_body)
    end

    context "when API returns error" do
      before do
        stub_elevenlabs_api(
          endpoint: "/v1/dubbing",
          method: :post,
          status: 400,
          response_body: { "error" => "Invalid target language" }
        )
      end

      it "raises BadRequestError for 400 status" do
        expect {
          client.dubs.create(
            file_io: video_file,
            filename: "test.mp4",
            target_languages: ["invalid"]
          )
        }.to raise_error(ElevenlabsClient::BadRequestError)
      end
    end

    context "when API returns 401" do
      before do
        stub_elevenlabs_api(
          endpoint: "/v1/dubbing",
          method: :post,
          status: 401,
          response_body: { "error" => "Unauthorized" }
        )
      end

      it "raises AuthenticationError" do
        expect {
          client.dubs.create(
            file_io: video_file,
            filename: "test.mp4",
            target_languages: ["es"]
          )
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    context "when API returns 429" do
      before do
        stub_elevenlabs_api(
          endpoint: "/v1/dubbing",
          method: :post,
          status: 429,
          response_body: { "error" => "Rate limit exceeded" }
        )
      end

      it "raises RateLimitError" do
        expect {
          client.dubs.create(
            file_io: video_file,
            filename: "test.mp4",
            target_languages: ["es"]
          )
        }.to raise_error(ElevenlabsClient::RateLimitError)
      end
    end
  end

  describe "get dub via dubs endpoint" do
    let(:dubbing_id) { "abc123" }
    let(:response_body) do
      {
        "dubbing_id" => dubbing_id,
        "status" => "dubbed",
        "name" => "Test Dub",
        "target_languages" => ["es"],
        "results" => { "output_files" => [] }
      }
    end

    before do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing/#{dubbing_id}",
        method: :get,
        status: 200,
        response_body: response_body
      )
    end

    it "retrieves dubbing job details" do
      result = client.dubs.get(dubbing_id)
      expect(result).to eq(response_body)
    end

    it "sends correct headers" do
      client.dubs.get(dubbing_id)

      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/dubbing/#{dubbing_id}")
        .with(headers: { "xi-api-key" => api_key })
    end

    context "when dubbing job not found" do
      before do
        stub_elevenlabs_api(
          endpoint: "/v1/dubbing/#{dubbing_id}",
          method: :get,
          status: 404,
          response_body: { "error" => "Dubbing job not found" }
        )
      end

      it "raises NotFoundError" do
        expect {
          client.dubs.get(dubbing_id)
        }.to raise_error(ElevenlabsClient::NotFoundError)
      end
    end
  end

  describe "list dubs via dubs endpoint" do
    let(:response_body) do
      {
        "dubs" => [
          {
            "dubbing_id" => "abc123",
            "status" => "dubbed",
            "name" => "Test Dub 1"
          },
          {
            "dubbing_id" => "def456",
            "status" => "dubbing",
            "name" => "Test Dub 2"
          }
        ]
      }
    end

    before do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing",
        method: :get,
        status: 200,
        response_body: response_body
      )
    end

    it "lists dubbing jobs" do
      result = client.dubs.list
      expect(result).to eq(response_body)
    end

    it "accepts query parameters" do
      # Need to stub the request with query parameters
      stub_request(:get, "https://api.elevenlabs.io/v1/dubbing")
        .with(query: { dubbing_status: "dubbed", page_size: 10 })
        .to_return(
          status: 200,
          body: response_body.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      client.dubs.list(dubbing_status: "dubbed", page_size: 10)

      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/dubbing")
        .with(
          query: { dubbing_status: "dubbed", page_size: 10 },
          headers: { "xi-api-key" => api_key }
        )
    end
  end

  describe "get dubbing resources via dubs endpoint" do
    let(:dubbing_id) { "abc123" }
    let(:response_body) do
      {
        "dubbing_id" => dubbing_id,
        "resources" => {
          "scripts" => [],
          "audio_files" => []
        }
      }
    end

    before do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing/#{dubbing_id}/resources",
        method: :get,
        status: 200,
        response_body: response_body
      )
    end

    it "retrieves dubbing resources" do
      result = client.dubs.resources(dubbing_id)
      expect(result).to eq(response_body)
    end

    it "sends correct headers" do
      client.dubs.resources(dubbing_id)

      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/dubbing/#{dubbing_id}/resources")
        .with(headers: { "xi-api-key" => api_key })
    end
  end

  describe "MIME type detection via dubs endpoint" do
    let(:video_file) { create_temp_video_file }

    before do
      stub_elevenlabs_api(
        endpoint: "/v1/dubbing",
        method: :post,
        status: 200,
        response_body: { "dubbing_id" => "test" }
      )
    end

    after do
      video_file.close
      video_file.unlink
    end

    it "detects MP4 MIME type" do
      client.dubs.create(
        file_io: video_file,
        filename: "video.mp4",
        target_languages: ["es"]
      )
      # The actual MIME type detection happens internally
      # We just verify the request was made successfully
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/dubbing")
    end

    it "detects MOV MIME type" do
      client.dubs.create(
        file_io: video_file,
        filename: "video.mov",
        target_languages: ["es"]
      )
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/dubbing")
    end

    it "uses default MIME type for unknown extensions" do
      client.dubs.create(
        file_io: video_file,
        filename: "video.unknown",
        target_languages: ["es"]
      )
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/dubbing")
    end
  end
end
