# frozen_string_literal: true

RSpec.describe "Admin::Samples Integration", :integration do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:samples) { client.samples }

  describe "#delete_sample" do
    context "when deleting a voice sample" do
      let(:voice_id) { "test_voice_id" }
      let(:sample_id) { "test_sample_id" }

      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}/samples/#{sample_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: { status: "ok" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "successfully deletes a voice sample" do
        result = samples.delete_sample(voice_id: voice_id, sample_id: sample_id)
        
        expect(result).to be_a(Hash)
        expect(result["status"]).to eq("ok")
      end
    end

    context "when voice_id is invalid" do
      let(:invalid_voice_id) { "invalid_voice_id" }
      let(:sample_id) { "test_sample_id" }

      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{invalid_voice_id}/samples/#{sample_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 404,
            body: { detail: "Voice not found" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises a NotFoundError" do
        expect {
          samples.delete_sample(voice_id: invalid_voice_id, sample_id: sample_id)
        }.to raise_error(ElevenlabsClient::NotFoundError)
      end
    end

    context "when sample_id is invalid" do
      let(:voice_id) { "test_voice_id" }
      let(:invalid_sample_id) { "invalid_sample_id" }

      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}/samples/#{invalid_sample_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 404,
            body: { detail: "Sample not found" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises a NotFoundError" do
        expect {
          samples.delete_sample(voice_id: voice_id, sample_id: invalid_sample_id)
        }.to raise_error(ElevenlabsClient::NotFoundError)
      end
    end

    context "when both voice_id and sample_id are invalid" do
      let(:invalid_voice_id) { "invalid_voice_id" }
      let(:invalid_sample_id) { "invalid_sample_id" }

      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{invalid_voice_id}/samples/#{invalid_sample_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 404,
            body: { detail: "Voice not found" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises a NotFoundError" do
        expect {
          samples.delete_sample(voice_id: invalid_voice_id, sample_id: invalid_sample_id)
        }.to raise_error(ElevenlabsClient::NotFoundError)
      end
    end
  end

  describe "aliases" do
    context "when using delete_voice_sample alias" do
      let(:voice_id) { "test_voice_id" }
      let(:sample_id) { "test_sample_id" }

      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}/samples/#{sample_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: { status: "ok" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "successfully deletes a voice sample" do
        result = samples.delete_voice_sample(voice_id: voice_id, sample_id: sample_id)
        
        expect(result).to be_a(Hash)
        expect(result["status"]).to eq("ok")
      end
    end

    context "when using remove_sample alias" do
      let(:voice_id) { "test_voice_id" }
      let(:sample_id) { "test_sample_id" }

      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}/samples/#{sample_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: { status: "ok" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "successfully deletes a voice sample" do
        result = samples.remove_sample(voice_id: voice_id, sample_id: sample_id)
        
        expect(result).to be_a(Hash)
        expect(result["status"]).to eq("ok")
      end
    end
  end

  describe "error handling" do
    context "when authentication fails" do
      let(:client_with_invalid_key) { ElevenlabsClient::Client.new(api_key: "invalid_key") }
      let(:samples_with_invalid_key) { client_with_invalid_key.samples }
      let(:voice_id) { "test_voice_id" }
      let(:sample_id) { "test_sample_id" }

      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}/samples/#{sample_id}")
          .with(headers: { "xi-api-key" => "invalid_key" })
          .to_return(
            status: 401,
            body: { detail: "Unauthorized" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises an AuthenticationError" do
        expect {
          samples_with_invalid_key.delete_sample(voice_id: voice_id, sample_id: sample_id)
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    context "when parameters are malformed" do
      let(:malformed_voice_id) { "" }
      let(:malformed_sample_id) { "" }

      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{malformed_voice_id}/samples/#{malformed_sample_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 422,
            body: { detail: "Invalid parameters" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises an UnprocessableEntityError or NotFoundError" do
        expect {
          samples.delete_sample(voice_id: malformed_voice_id, sample_id: malformed_sample_id)
        }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end
  end

  describe "response structure" do
    context "when deletion is successful" do
      let(:voice_id) { "test_voice_id" }
      let(:sample_id) { "test_sample_id" }

      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}/samples/#{sample_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: { status: "ok" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns the expected response structure" do
        result = samples.delete_sample(voice_id: voice_id, sample_id: sample_id)
        
        expect(result).to be_a(Hash)
        expect(result).to have_key("status")
        expect(result["status"]).to be_a(String)
        expect(result["status"]).to eq("ok")
      end
    end
  end
end
