# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Agents Platform LLM Usage Integration" do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test-api-key") }
  let(:base_url) { "https://api.elevenlabs.io" }

  describe "LLM Usage Calculation" do
    describe "POST /v1/convai/llm-usage/calculate" do
      context "successful calculation" do
        before do
          stub_request(:post, "#{base_url}/v1/convai/llm-usage/calculate")
            .with(
              body: {
                prompt_length: 800,
                number_of_pages: 25,
                rag_enabled: true
              }.to_json
            )
            .to_return(
              status: 200,
              body: {
                llm_prices: [
                  {
                    llm: "gpt-4o-mini",
                    price_per_minute: 0.0045
                  },
                  {
                    llm: "gpt-4o",
                    price_per_minute: 0.0180
                  },
                  {
                    llm: "claude-3-haiku",
                    price_per_minute: 0.0037
                  },
                  {
                    llm: "claude-3-sonnet",
                    price_per_minute: 0.0150
                  }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "calculates LLM usage for RAG-enabled agent" do
          result = client.llm_usage.calculate(
            prompt_length: 800,
            number_of_pages: 25,
            rag_enabled: true
          )

          expect(result["llm_prices"].size).to eq(4)
          
          # Verify model availability
          model_names = result["llm_prices"].map { |model| model["llm"] }
          expect(model_names).to include("gpt-4o-mini", "gpt-4o", "claude-3-haiku", "claude-3-sonnet")
          
          # Verify pricing structure
          result["llm_prices"].each do |model|
            expect(model).to have_key("llm")
            expect(model).to have_key("price_per_minute")
            expect(model["price_per_minute"]).to be > 0
          end
        end

        it "provides cost analysis capabilities" do
          result = client.llm_usage.calculate(
            prompt_length: 800,
            number_of_pages: 25,
            rag_enabled: true
          )

          prices = result["llm_prices"].map { |model| model["price_per_minute"] }
          cheapest_price = prices.min
          most_expensive_price = prices.max
          
          expect(cheapest_price).to eq(0.0037)  # claude-3-haiku
          expect(most_expensive_price).to eq(0.0180)  # gpt-4o
          expect(most_expensive_price).to be > cheapest_price

          # Calculate potential monthly costs
          daily_minutes = 60
          monthly_cost_cheapest = cheapest_price * daily_minutes * 30
          monthly_cost_expensive = most_expensive_price * daily_minutes * 30
          
          expect(monthly_cost_cheapest).to be < monthly_cost_expensive
          expect(monthly_cost_cheapest).to eq(6.66)  # $0.0037 * 60 * 30
          expect(monthly_cost_expensive).to eq(32.40)  # $0.0180 * 60 * 30
        end

        it "sends correct request format" do
          client.llm_usage.calculate(
            prompt_length: 800,
            number_of_pages: 25,
            rag_enabled: true
          )

          expect(WebMock).to have_requested(:post, "#{base_url}/v1/convai/llm-usage/calculate")
            .with(
              headers: { "xi-api-key" => "test-api-key" },
              body: {
                prompt_length: 800,
                number_of_pages: 25,
                rag_enabled: true
              }.to_json
            )
        end
      end

      context "simple agent without RAG" do
        before do
          stub_request(:post, "#{base_url}/v1/convai/llm-usage/calculate")
            .with(
              body: {
                prompt_length: 300,
                number_of_pages: 0,
                rag_enabled: false
              }.to_json
            )
            .to_return(
              status: 200,
              body: {
                llm_prices: [
                  {
                    llm: "gpt-4o-mini",
                    price_per_minute: 0.0025
                  },
                  {
                    llm: "gpt-4o",
                    price_per_minute: 0.0120
                  }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "calculates usage for simple agent without knowledge base" do
          result = client.llm_usage.calculate(
            prompt_length: 300,
            number_of_pages: 0,
            rag_enabled: false
          )

          expect(result["llm_prices"].size).to eq(2)
          
          # Verify that costs are generally lower without RAG
          prices = result["llm_prices"].map { |model| model["price_per_minute"] }
          expect(prices.max).to eq(0.0120)  # Lower than RAG-enabled version
          expect(prices.min).to eq(0.0025)  # Lower than RAG-enabled version
        end
      end

      context "large knowledge base scenario" do
        before do
          stub_request(:post, "#{base_url}/v1/convai/llm-usage/calculate")
            .with(
              body: {
                prompt_length: 1500,
                number_of_pages: 100,
                rag_enabled: true
              }.to_json
            )
            .to_return(
              status: 200,
              body: {
                llm_prices: [
                  {
                    llm: "gpt-4o-mini",
                    price_per_minute: 0.0085
                  },
                  {
                    llm: "gpt-4o",
                    price_per_minute: 0.0320
                  },
                  {
                    llm: "claude-3-haiku",
                    price_per_minute: 0.0070
                  }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "calculates higher costs for large knowledge base" do
          result = client.llm_usage.calculate(
            prompt_length: 1500,
            number_of_pages: 100,
            rag_enabled: true
          )

          # Verify that costs are higher for larger configurations
          prices = result["llm_prices"].map { |model| model["price_per_minute"] }
          expect(prices.max).to eq(0.0320)  # Higher than smaller configurations
          expect(prices.min).to eq(0.0070)  # Higher than smaller configurations
        end
      end

      context "cost comparison workflow" do
        let(:configurations) do
          [
            { prompt_length: 300, pages: 0, rag: false, name: "Simple" },
            { prompt_length: 800, pages: 25, rag: true, name: "Standard" },
            { prompt_length: 1500, pages: 100, rag: true, name: "Enterprise" }
          ]
        end

        before do
          # Stub simple configuration
          stub_request(:post, "#{base_url}/v1/convai/llm-usage/calculate")
            .with(body: { prompt_length: 300, number_of_pages: 0, rag_enabled: false }.to_json)
            .to_return(
              status: 200,
              body: { llm_prices: [{ llm: "gpt-4o-mini", price_per_minute: 0.0025 }] }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          # Stub standard configuration
          stub_request(:post, "#{base_url}/v1/convai/llm-usage/calculate")
            .with(body: { prompt_length: 800, number_of_pages: 25, rag_enabled: true }.to_json)
            .to_return(
              status: 200,
              body: { llm_prices: [{ llm: "gpt-4o-mini", price_per_minute: 0.0045 }] }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          # Stub enterprise configuration
          stub_request(:post, "#{base_url}/v1/convai/llm-usage/calculate")
            .with(body: { prompt_length: 1500, number_of_pages: 100, rag_enabled: true }.to_json)
            .to_return(
              status: 200,
              body: { llm_prices: [{ llm: "gpt-4o-mini", price_per_minute: 0.0085 }] }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "enables cost comparison across configurations" do
          comparison_results = []

          configurations.each do |config|
            result = client.llm_usage.calculate(
              prompt_length: config[:prompt_length],
              number_of_pages: config[:pages],
              rag_enabled: config[:rag]
            )

            cheapest = result["llm_prices"].min_by { |model| model["price_per_minute"] }
            comparison_results << {
              name: config[:name],
              configuration: config,
              cheapest_cost: cheapest["price_per_minute"]
            }
          end

          # Verify cost progression
          expect(comparison_results[0][:cheapest_cost]).to eq(0.0025)  # Simple
          expect(comparison_results[1][:cheapest_cost]).to eq(0.0045)  # Standard
          expect(comparison_results[2][:cheapest_cost]).to eq(0.0085)  # Enterprise

          # Verify that costs increase with complexity
          expect(comparison_results[1][:cheapest_cost]).to be > comparison_results[0][:cheapest_cost]
          expect(comparison_results[2][:cheapest_cost]).to be > comparison_results[1][:cheapest_cost]
        end
      end

      context "error scenarios" do
        context "when validation fails" do
          before do
            stub_request(:post, "#{base_url}/v1/convai/llm-usage/calculate")
              .to_return(status: 422, body: { detail: "Invalid parameters" }.to_json)
          end

          it "raises UnprocessableEntityError" do
            expect {
              client.llm_usage.calculate(
                prompt_length: -100,  # Invalid negative value
                number_of_pages: 25,
                rag_enabled: true
              )
            }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
          end
        end

        context "when authentication fails" do
          before do
            stub_request(:post, "#{base_url}/v1/convai/llm-usage/calculate")
              .to_return(status: 401, body: { detail: "Authentication failed" }.to_json)
          end

          it "raises AuthenticationError" do
            expect {
              client.llm_usage.calculate(
                prompt_length: 800,
                number_of_pages: 25,
                rag_enabled: true
              )
            }.to raise_error(ElevenlabsClient::AuthenticationError)
          end
        end

        context "when rate limited" do
          before do
            stub_request(:post, "#{base_url}/v1/convai/llm-usage/calculate")
              .to_return(status: 429, body: { detail: "Rate limit exceeded" }.to_json)
          end

          it "raises RateLimitError" do
            expect {
              client.llm_usage.calculate(
                prompt_length: 800,
                number_of_pages: 25,
                rag_enabled: true
              )
            }.to raise_error(ElevenlabsClient::RateLimitError)
          end
        end
      end

      context "edge case scenarios" do
        context "with zero values" do
          before do
            stub_request(:post, "#{base_url}/v1/convai/llm-usage/calculate")
              .with(
                body: {
                  prompt_length: 0,
                  number_of_pages: 0,
                  rag_enabled: false
                }.to_json
              )
              .to_return(
                status: 200,
                body: {
                  llm_prices: [
                    { llm: "gpt-4o-mini", price_per_minute: 0.001 }
                  ]
                }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "handles minimal configuration" do
            result = client.llm_usage.calculate(
              prompt_length: 0,
              number_of_pages: 0,
              rag_enabled: false
            )

            expect(result["llm_prices"]).not_to be_empty
            expect(result["llm_prices"].first["price_per_minute"]).to be > 0
          end
        end

        context "with very large values" do
          before do
            stub_request(:post, "#{base_url}/v1/convai/llm-usage/calculate")
              .with(
                body: {
                  prompt_length: 50000,
                  number_of_pages: 1000,
                  rag_enabled: true
                }.to_json
              )
              .to_return(
                status: 200,
                body: {
                  llm_prices: [
                    { llm: "gpt-4o", price_per_minute: 0.150 }
                  ]
                }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "handles very large configurations" do
            result = client.llm_usage.calculate(
              prompt_length: 50000,
              number_of_pages: 1000,
              rag_enabled: true
            )

            expect(result["llm_prices"]).not_to be_empty
            expect(result["llm_prices"].first["price_per_minute"]).to eq(0.150)
          end
        end
      end

      context "real-world usage scenarios" do
        context "customer service agent" do
          before do
            stub_request(:post, "#{base_url}/v1/convai/llm-usage/calculate")
              .with(
                body: {
                  prompt_length: 1200,
                  number_of_pages: 30,
                  rag_enabled: true
                }.to_json
              )
              .to_return(
                status: 200,
                body: {
                  llm_prices: [
                    { llm: "gpt-4o-mini", price_per_minute: 0.0055 },
                    { llm: "gpt-4o", price_per_minute: 0.0220 }
                  ]
                }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "provides realistic cost estimates for customer service" do
            # Customer service agent with comprehensive knowledge base
            result = client.llm_usage.calculate(
              prompt_length: 1200,  # Detailed customer service instructions
              number_of_pages: 30,  # FAQ and policy documents
              rag_enabled: true     # Knowledge retrieval enabled
            )

            cheapest = result["llm_prices"].min_by { |model| model["price_per_minute"] }
            
            # Calculate monthly costs for different usage levels
            low_usage = cheapest["price_per_minute"] * 30 * 30      # 30 min/day
            medium_usage = cheapest["price_per_minute"] * 120 * 30  # 2 hours/day
            high_usage = cheapest["price_per_minute"] * 480 * 30    # 8 hours/day

            expect(low_usage.round(2)).to eq(4.95)    # $4.95/month for light usage
            expect(medium_usage.round(2)).to eq(19.80) # $19.80/month for medium usage
            expect(high_usage.round(2)).to eq(79.20)   # $79.20/month for heavy usage
          end
        end

        context "sales assistant" do
          before do
            stub_request(:post, "#{base_url}/v1/convai/llm-usage/calculate")
              .with(
                body: {
                  prompt_length: 800,
                  number_of_pages: 15,
                  rag_enabled: true
                }.to_json
              )
              .to_return(
                status: 200,
                body: {
                  llm_prices: [
                    { llm: "gpt-4o-mini", price_per_minute: 0.0040 }
                  ]
                }.to_json,
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "calculates costs for sales assistant with product catalog" do
            result = client.llm_usage.calculate(
              prompt_length: 800,   # Sales training and guidelines
              number_of_pages: 15,  # Product catalog
              rag_enabled: true     # Product information retrieval
            )

            cost_per_minute = result["llm_prices"].first["price_per_minute"]
            
            # Calculate ROI scenarios
            cost_per_call = cost_per_minute * 5    # 5-minute average call
            cost_per_lead = cost_per_call * 10     # 10% conversion rate
            
            expect(cost_per_call).to eq(0.02)   # $0.02 per call
            expect(cost_per_lead).to eq(0.20)   # $0.20 per lead
          end
        end
      end

      context "network and parsing errors" do
        context "when network timeout occurs" do
          before do
            stub_request(:post, "#{base_url}/v1/convai/llm-usage/calculate")
              .to_timeout
          end

          it "handles network timeouts appropriately" do
            expect {
              client.llm_usage.calculate(
                prompt_length: 800,
                number_of_pages: 25,
                rag_enabled: true
              )
            }.to raise_error(Faraday::ConnectionFailed)
          end
        end

        context "when response is malformed" do
          before do
            stub_request(:post, "#{base_url}/v1/convai/llm-usage/calculate")
              .to_return(
                status: 200,
                body: "Invalid JSON response",
                headers: { "Content-Type" => "application/json" }
              )
          end

          it "handles malformed JSON responses" do
            expect {
              client.llm_usage.calculate(
                prompt_length: 800,
                number_of_pages: 25,
                rag_enabled: true
              )
            }.to raise_error(Faraday::ParsingError)
          end
        end
      end
    end

    describe "convenience alias methods" do
      before do
        stub_request(:post, "#{base_url}/v1/convai/llm-usage/calculate")
          .to_return(
            status: 200,
            body: { llm_prices: [] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "supports calculate_usage alias" do
        client.llm_usage.calculate_usage(
          prompt_length: 500,
          number_of_pages: 10,
          rag_enabled: false
        )

        expect(WebMock).to have_requested(:post, "#{base_url}/v1/convai/llm-usage/calculate")
      end
    end
  end
end
