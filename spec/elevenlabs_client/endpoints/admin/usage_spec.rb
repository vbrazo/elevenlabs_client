# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Admin::Usage do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:usage) { described_class.new(client) }

  describe "#get_character_stats" do
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

    context "with minimal parameters" do
      it "makes a GET request to /v1/usage/character-stats with required parameters" do
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

        result = usage.get_character_stats(start_unix: start_unix, end_unix: end_unix)

        expect(result).to eq(usage_response)
      end
    end

    context "with all parameters" do
      let(:params) do
        {
          start_unix: start_unix,
          end_unix: end_unix,
          include_workspace_metrics: true,
          breakdown_type: "voice",
          aggregation_interval: "day",
          aggregation_bucket_size: 3600,
          metric: "character_count"
        }
      end

      it "makes a GET request with all parameters" do
        stub_request(:get, "https://api.elevenlabs.io/v1/usage/character-stats")
          .with(
            query: params,
            headers: { "xi-api-key" => api_key }
          )
          .to_return(
            status: 200,
            body: usage_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = usage.get_character_stats(**params)

        expect(result).to eq(usage_response)
      end
    end

    context "with boolean false parameters" do
      it "includes false boolean parameters in the request" do
        stub_request(:get, "https://api.elevenlabs.io/v1/usage/character-stats")
          .with(
            query: {
              start_unix: start_unix,
              end_unix: end_unix,
              include_workspace_metrics: false
            },
            headers: { "xi-api-key" => api_key }
          )
          .to_return(
            status: 200,
            body: usage_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = usage.get_character_stats(
          start_unix: start_unix,
          end_unix: end_unix,
          include_workspace_metrics: false
        )

        expect(result).to eq(usage_response)
      end
    end

    context "when API returns an error" do
      it "raises UnprocessableEntityError for 422 status" do
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
          usage.get_character_stats(start_unix: start_unix, end_unix: end_unix)
        end.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end

      it "raises AuthenticationError for 401 status" do
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
          usage.get_character_stats(start_unix: start_unix, end_unix: end_unix)
        end.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    context "with breakdown types" do
      %w[voice model user].each do |breakdown_type|
        it "accepts #{breakdown_type} as breakdown_type" do
          stub_request(:get, "https://api.elevenlabs.io/v1/usage/character-stats")
            .with(
              query: {
                start_unix: start_unix,
                end_unix: end_unix,
                breakdown_type: breakdown_type
              },
              headers: { "xi-api-key" => api_key }
            )
            .to_return(
              status: 200,
              body: usage_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          result = usage.get_character_stats(
            start_unix: start_unix,
            end_unix: end_unix,
            breakdown_type: breakdown_type
          )

          expect(result).to eq(usage_response)
        end
      end
    end

    context "with aggregation intervals" do
      %w[hour day week month cumulative].each do |interval|
        it "accepts #{interval} as aggregation_interval" do
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

          result = usage.get_character_stats(
            start_unix: start_unix,
            end_unix: end_unix,
            aggregation_interval: interval
          )

          expect(result).to eq(usage_response)
        end
      end
    end
  end

  describe "aliases" do
    it "has character_stats alias for get_character_stats" do
      expect(usage.method(:character_stats)).to eq(usage.method(:get_character_stats))
    end
  end

  describe "private methods" do
    it "has client as a private attr_reader" do
      expect(usage.send(:client)).to eq(client)
    end
  end
end
