# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Admin::Samples do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test_api_key") }
  let(:samples) { client.samples }

  describe "#delete_sample" do
    let(:voice_id) { "test_voice_id" }
    let(:sample_id) { "test_sample_id" }

    context "when deletion is successful" do
      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}/samples/#{sample_id}")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(
            status: 200,
            body: { status: "ok" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "deletes the voice sample successfully" do
        result = samples.delete_sample(voice_id: voice_id, sample_id: sample_id)
        expect(result).to eq({ "status" => "ok" })
      end

      it "makes a DELETE request to the correct endpoint" do
        samples.delete_sample(voice_id: voice_id, sample_id: sample_id)
        
        expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}/samples/#{sample_id}")
          .with(headers: { "xi-api-key" => "test_api_key" })
      end
    end

    context "when voice_id is missing" do
      it "raises an ArgumentError" do
        expect {
          samples.delete_sample(sample_id: sample_id)
        }.to raise_error(ArgumentError)
      end
    end

    context "when sample_id is missing" do
      it "raises an ArgumentError" do
        expect {
          samples.delete_sample(voice_id: voice_id)
        }.to raise_error(ArgumentError)
      end
    end

    context "when the voice is not found" do
      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}/samples/#{sample_id}")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(
            status: 404,
            body: { detail: "Voice not found" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises a NotFoundError" do
        expect {
          samples.delete_sample(voice_id: voice_id, sample_id: sample_id)
        }.to raise_error(ElevenlabsClient::NotFoundError)
      end
    end

    context "when the sample is not found" do
      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}/samples/#{sample_id}")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(
            status: 404,
            body: { detail: "Sample not found" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises a NotFoundError" do
        expect {
          samples.delete_sample(voice_id: voice_id, sample_id: sample_id)
        }.to raise_error(ElevenlabsClient::NotFoundError)
      end
    end

    context "when there's a validation error" do
      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}/samples/#{sample_id}")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(
            status: 422,
            body: { detail: "Invalid voice or sample ID" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises an UnprocessableEntityError" do
        expect {
          samples.delete_sample(voice_id: voice_id, sample_id: sample_id)
        }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end

    context "when authentication fails" do
      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}/samples/#{sample_id}")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(
            status: 401,
            body: { detail: "Unauthorized" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises an AuthenticationError" do
        expect {
          samples.delete_sample(voice_id: voice_id, sample_id: sample_id)
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    context "when rate limit is exceeded" do
      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}/samples/#{sample_id}")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(
            status: 429,
            body: { detail: "Rate limit exceeded" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises a RateLimitError" do
        expect {
          samples.delete_sample(voice_id: voice_id, sample_id: sample_id)
        }.to raise_error(ElevenlabsClient::RateLimitError)
      end
    end

    context "when there's a server error" do
      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}/samples/#{sample_id}")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(
            status: 500,
            body: { detail: "Internal server error" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises an APIError" do
        expect {
          samples.delete_sample(voice_id: voice_id, sample_id: sample_id)
        }.to raise_error(ElevenlabsClient::APIError)
      end
    end
  end

  describe "aliases" do
    let(:voice_id) { "test_voice_id" }
    let(:sample_id) { "test_sample_id" }

    before do
      stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}/samples/#{sample_id}")
        .with(headers: { "xi-api-key" => "test_api_key" })
        .to_return(
          status: 200,
          body: { status: "ok" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    describe "#delete_voice_sample" do
      it "works as an alias for delete_sample" do
        result = samples.delete_voice_sample(voice_id: voice_id, sample_id: sample_id)
        expect(result).to eq({ "status" => "ok" })
      end
    end

    describe "#remove_sample" do
      it "works as an alias for delete_sample" do
        result = samples.remove_sample(voice_id: voice_id, sample_id: sample_id)
        expect(result).to eq({ "status" => "ok" })
      end
    end
  end
end
