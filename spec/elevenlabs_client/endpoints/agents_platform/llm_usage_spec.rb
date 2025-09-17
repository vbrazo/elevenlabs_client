# frozen_string_literal: true

require "spec_helper"

RSpec.describe ElevenlabsClient::Endpoints::AgentsPlatform::LlmUsage do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test-api-key") }
  let(:llm_usage) { described_class.new(client) }

  describe "#calculate" do
    let(:endpoint) { "/v1/convai/llm-usage/calculate" }
    let(:prompt_length) { 800 }
    let(:number_of_pages) { 25 }
    let(:rag_enabled) { true }
    let(:response) do
      {
        "llm_prices" => [
          {
            "llm" => "gpt-4o-mini",
            "price_per_minute" => 0.0045
          },
          {
            "llm" => "gpt-4o",
            "price_per_minute" => 0.0180
          },
          {
            "llm" => "claude-3-haiku",
            "price_per_minute" => 0.0037
          }
        ]
      }
    end

    before do
      allow(client).to receive(:post).with(endpoint, any_args).and_return(response)
    end

    it "calculates LLM usage successfully" do
      result = llm_usage.calculate(
        prompt_length: prompt_length,
        number_of_pages: number_of_pages,
        rag_enabled: rag_enabled
      )

      expect(result).to eq(response)
      expect(result["llm_prices"].size).to eq(3)
      expect(result["llm_prices"].first["llm"]).to eq("gpt-4o-mini")
      expect(result["llm_prices"].first["price_per_minute"]).to eq(0.0045)
    end

    it "calls the correct endpoint with correct payload" do
      llm_usage.calculate(
        prompt_length: prompt_length,
        number_of_pages: number_of_pages,
        rag_enabled: rag_enabled
      )

      expected_body = {
        prompt_length: prompt_length,
        number_of_pages: number_of_pages,
        rag_enabled: rag_enabled
      }

      expect(client).to have_received(:post).with(endpoint, expected_body)
    end

    it "handles different parameter combinations" do
      # Test with RAG disabled
      llm_usage.calculate(
        prompt_length: 500,
        number_of_pages: 0,
        rag_enabled: false
      )

      expected_body = {
        prompt_length: 500,
        number_of_pages: 0,
        rag_enabled: false
      }

      expect(client).to have_received(:post).with(endpoint, expected_body)
    end

    it "requires prompt_length parameter" do
      expect {
        llm_usage.calculate(
          prompt_length: nil,
          number_of_pages: number_of_pages,
          rag_enabled: rag_enabled
        )
      }.to raise_error(ArgumentError, "prompt_length is required")
    end

    it "requires number_of_pages parameter" do
      expect {
        llm_usage.calculate(
          prompt_length: prompt_length,
          number_of_pages: nil,
          rag_enabled: rag_enabled
        )
      }.to raise_error(ArgumentError, "number_of_pages is required")
    end

    it "requires rag_enabled parameter" do
      expect {
        llm_usage.calculate(
          prompt_length: prompt_length,
          number_of_pages: number_of_pages,
          rag_enabled: nil
        )
      }.to raise_error(ArgumentError, "rag_enabled is required")
    end

    context "with zero values" do
      it "accepts zero prompt_length" do
        expect {
          llm_usage.calculate(
            prompt_length: 0,
            number_of_pages: number_of_pages,
            rag_enabled: rag_enabled
          )
        }.not_to raise_error
      end

      it "accepts zero number_of_pages" do
        expect {
          llm_usage.calculate(
            prompt_length: prompt_length,
            number_of_pages: 0,
            rag_enabled: rag_enabled
          )
        }.not_to raise_error
      end

      it "accepts false rag_enabled" do
        expect {
          llm_usage.calculate(
            prompt_length: prompt_length,
            number_of_pages: number_of_pages,
            rag_enabled: false
          )
        }.not_to raise_error
      end
    end

    context "with large values" do
      it "handles large prompt_length" do
        large_prompt = 50000

        llm_usage.calculate(
          prompt_length: large_prompt,
          number_of_pages: number_of_pages,
          rag_enabled: rag_enabled
        )

        expected_body = {
          prompt_length: large_prompt,
          number_of_pages: number_of_pages,
          rag_enabled: rag_enabled
        }

        expect(client).to have_received(:post).with(endpoint, expected_body)
      end

      it "handles large number_of_pages" do
        large_pages = 1000

        llm_usage.calculate(
          prompt_length: prompt_length,
          number_of_pages: large_pages,
          rag_enabled: rag_enabled
        )

        expected_body = {
          prompt_length: prompt_length,
          number_of_pages: large_pages,
          rag_enabled: rag_enabled
        }

        expect(client).to have_received(:post).with(endpoint, expected_body)
      end
    end
  end

  describe "#calculate_usage" do
    it "is an alias for calculate" do
      expect(llm_usage.method(:calculate_usage)).to eq(llm_usage.method(:calculate))
    end
  end

  describe "error scenarios" do
    let(:endpoint) { "/v1/convai/llm-usage/calculate" }

    context "when client raises an error" do
      before do
        allow(client).to receive(:post).and_raise(ElevenlabsClient::APIError, "API Error")
      end

      it "propagates the error" do
        expect {
          llm_usage.calculate(
            prompt_length: 800,
            number_of_pages: 25,
            rag_enabled: true
          )
        }.to raise_error(ElevenlabsClient::APIError, "API Error")
      end
    end

    context "when authentication fails" do
      before do
        allow(client).to receive(:post).and_raise(ElevenlabsClient::AuthenticationError, "Unauthorized")
      end

      it "raises AuthenticationError" do
        expect {
          llm_usage.calculate(
            prompt_length: 800,
            number_of_pages: 25,
            rag_enabled: true
          )
        }.to raise_error(ElevenlabsClient::AuthenticationError, "Unauthorized")
      end
    end

    context "when validation fails" do
      before do
        allow(client).to receive(:post).and_raise(ElevenlabsClient::UnprocessableEntityError, "Invalid parameters")
      end

      it "raises UnprocessableEntityError" do
        expect {
          llm_usage.calculate(
            prompt_length: -100,  # Invalid negative value
            number_of_pages: 25,
            rag_enabled: true
          )
        }.to raise_error(ElevenlabsClient::UnprocessableEntityError, "Invalid parameters")
      end
    end

    context "when rate limited" do
      before do
        allow(client).to receive(:post).and_raise(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end

      it "raises RateLimitError" do
        expect {
          llm_usage.calculate(
            prompt_length: 800,
            number_of_pages: 25,
            rag_enabled: true
          )
        }.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
      end
    end
  end

  describe "response parsing" do
    let(:endpoint) { "/v1/convai/llm-usage/calculate" }

    context "with single model response" do
      let(:single_model_response) do
        {
          "llm_prices" => [
            {
              "llm" => "gpt-4o-mini",
              "price_per_minute" => 0.0045
            }
          ]
        }
      end

      before do
        allow(client).to receive(:post).with(endpoint, any_args).and_return(single_model_response)
      end

      it "handles single model response correctly" do
        result = llm_usage.calculate(
          prompt_length: 300,
          number_of_pages: 0,
          rag_enabled: false
        )

        expect(result["llm_prices"].size).to eq(1)
        expect(result["llm_prices"].first["llm"]).to eq("gpt-4o-mini")
        expect(result["llm_prices"].first["price_per_minute"]).to eq(0.0045)
      end
    end

    context "with multiple models response" do
      let(:multiple_models_response) do
        {
          "llm_prices" => [
            { "llm" => "gpt-4o-mini", "price_per_minute" => 0.0045 },
            { "llm" => "gpt-4o", "price_per_minute" => 0.0180 },
            { "llm" => "claude-3-haiku", "price_per_minute" => 0.0037 },
            { "llm" => "claude-3-sonnet", "price_per_minute" => 0.0150 },
            { "llm" => "claude-3-opus", "price_per_minute" => 0.0750 }
          ]
        }
      end

      before do
        allow(client).to receive(:post).with(endpoint, any_args).and_return(multiple_models_response)
      end

      it "handles multiple models response correctly" do
        result = llm_usage.calculate(
          prompt_length: 1500,
          number_of_pages: 100,
          rag_enabled: true
        )

        expect(result["llm_prices"].size).to eq(5)
        
        # Check for expected models
        model_names = result["llm_prices"].map { |model| model["llm"] }
        expect(model_names).to include("gpt-4o-mini", "gpt-4o", "claude-3-haiku", "claude-3-sonnet", "claude-3-opus")
        
        # Check that all prices are positive numbers
        result["llm_prices"].each do |model|
          expect(model["price_per_minute"]).to be > 0
          expect(model["price_per_minute"]).to be_a(Numeric)
        end
      end

      it "allows cost analysis of the response" do
        result = llm_usage.calculate(
          prompt_length: 1000,
          number_of_pages: 50,
          rag_enabled: true
        )

        prices = result["llm_prices"].map { |model| model["price_per_minute"] }
        cheapest_price = prices.min
        most_expensive_price = prices.max
        
        expect(cheapest_price).to eq(0.0037)  # claude-3-haiku
        expect(most_expensive_price).to eq(0.0750)  # claude-3-opus
        expect(most_expensive_price).to be > cheapest_price
      end
    end

    context "with empty response" do
      let(:empty_response) do
        {
          "llm_prices" => []
        }
      end

      before do
        allow(client).to receive(:post).with(endpoint, any_args).and_return(empty_response)
      end

      it "handles empty response gracefully" do
        result = llm_usage.calculate(
          prompt_length: 100,
          number_of_pages: 1,
          rag_enabled: false
        )

        expect(result["llm_prices"]).to eq([])
        expect(result["llm_prices"].size).to eq(0)
      end
    end
  end

  describe "parameter validation edge cases" do
    let(:endpoint) { "/v1/convai/llm-usage/calculate" }

    before do
      allow(client).to receive(:post).with(endpoint, any_args).and_return({ "llm_prices" => [] })
    end

    it "accepts string numbers for prompt_length" do
      expect {
        llm_usage.calculate(
          prompt_length: "800",
          number_of_pages: 25,
          rag_enabled: true
        )
      }.not_to raise_error
    end

    it "accepts string numbers for number_of_pages" do
      expect {
        llm_usage.calculate(
          prompt_length: 800,
          number_of_pages: "25",
          rag_enabled: true
        )
      }.not_to raise_error
    end

    it "accepts string boolean for rag_enabled" do
      expect {
        llm_usage.calculate(
          prompt_length: 800,
          number_of_pages: 25,
          rag_enabled: "true"
        )
      }.not_to raise_error
    end

    it "rejects empty string for prompt_length" do
      # Note: This would be caught by the API, not our validation
      # Our validation only checks for nil
      expect {
        llm_usage.calculate(
          prompt_length: "",
          number_of_pages: 25,
          rag_enabled: true
        )
      }.not_to raise_error  # Local validation doesn't check empty strings
    end
  end
end
