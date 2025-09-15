# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Usage Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }

  describe "client.usage accessor" do
    it "provides access to usage endpoint" do
      expect(client.usage).to be_an_instance_of(ElevenlabsClient::Admin::Usage)
    end
  end

  describe "usage character stats functionality via client" do
    let(:start_unix) { 1685574000 }
    let(:end_unix) { 1688165999 }
    let(:usage_response) do
      {
        "time" => [
          1738252091000,
          1739404800000
        ],
        "usage" => {
          "All" => [
            49,
            1053
          ]
        }
      }
    end

    context "basic character stats retrieval" do
      it "successfully retrieves character usage stats" do
        stub_request(:get, "https://api.elevenlabs.io/v1/usage/character-stats")
          .with(
            query: {
              start_unix: start_unix,
              end_unix: end_unix
            },
            headers: { "xi-api-key" => api_key }
          )
          .to_return(
            status: 200,
            body: usage_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = client.usage.get_character_stats(start_unix: start_unix, end_unix: end_unix)

        expect(result).to eq(usage_response)
        expect(result["time"]).to be_an(Array)
        expect(result["usage"]).to be_a(Hash)
        expect(result["usage"]["All"]).to be_an(Array)
      end
    end

    context "character stats with workspace metrics" do
      it "successfully retrieves workspace character usage stats" do
        extended_response = usage_response.merge(
          "usage" => {
            "All" => [49, 1053],
            "Workspace" => [25, 500]
          }
        )

        stub_request(:get, "https://api.elevenlabs.io/v1/usage/character-stats")
          .with(
            query: {
              start_unix: start_unix,
              end_unix: end_unix,
              include_workspace_metrics: true
            },
            headers: { "xi-api-key" => api_key }
          )
          .to_return(
            status: 200,
            body: extended_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = client.usage.get_character_stats(
          start_unix: start_unix,
          end_unix: end_unix,
          include_workspace_metrics: true
        )

        expect(result).to eq(extended_response)
        expect(result["usage"]).to have_key("All")
        expect(result["usage"]).to have_key("Workspace")
      end
    end

    context "character stats with breakdown by voice" do
      it "successfully retrieves character usage stats broken down by voice" do
        voice_breakdown_response = {
          "time" => [1738252091000, 1739404800000],
          "usage" => {
            "Voice1" => [20, 400],
            "Voice2" => [29, 653]
          }
        }

        stub_request(:get, "https://api.elevenlabs.io/v1/usage/character-stats")
          .with(
            query: {
              start_unix: start_unix,
              end_unix: end_unix,
              breakdown_type: "voice"
            },
            headers: { "xi-api-key" => api_key }
          )
          .to_return(
            status: 200,
            body: voice_breakdown_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = client.usage.get_character_stats(
          start_unix: start_unix,
          end_unix: end_unix,
          breakdown_type: "voice"
        )

        expect(result).to eq(voice_breakdown_response)
        expect(result["usage"]).to have_key("Voice1")
        expect(result["usage"]).to have_key("Voice2")
      end
    end

    context "character stats with different aggregation intervals" do
      %w[hour day week month cumulative].each do |interval|
        it "successfully retrieves character usage stats with #{interval} aggregation" do
          stub_request(:get, "https://api.elevenlabs.io/v1/usage/character-stats")
            .with(
              query: {
                start_unix: start_unix,
                end_unix: end_unix,
                aggregation_interval: interval
              },
              headers: { "xi-api-key" => api_key }
            )
            .to_return(
              status: 200,
              body: usage_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          result = client.usage.get_character_stats(
            start_unix: start_unix,
            end_unix: end_unix,
            aggregation_interval: interval
          )

          expect(result).to eq(usage_response)
        end
      end
    end

    context "error handling" do
      it "handles authentication errors gracefully" do
        stub_request(:get, "https://api.elevenlabs.io/v1/usage/character-stats")
          .with(
            query: {
              start_unix: start_unix,
              end_unix: end_unix
            },
            headers: { "xi-api-key" => api_key }
          )
          .to_return(
            status: 401,
            body: { "detail" => "Invalid API key" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect do
          client.usage.get_character_stats(start_unix: start_unix, end_unix: end_unix)
        end.to raise_error(ElevenlabsClient::AuthenticationError)
      end

      it "handles validation errors gracefully" do
        stub_request(:get, "https://api.elevenlabs.io/v1/usage/character-stats")
          .with(
            query: {
              start_unix: start_unix,
              end_unix: end_unix
            },
            headers: { "xi-api-key" => api_key }
          )
          .to_return(
            status: 422,
            body: { "detail" => "Invalid date range" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect do
          client.usage.get_character_stats(start_unix: start_unix, end_unix: end_unix)
        end.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end
  end

  describe "usage method aliases" do
    it "provides character_stats alias" do
      expect(client.usage.method(:character_stats)).to eq(client.usage.method(:get_character_stats))
    end
  end
end
