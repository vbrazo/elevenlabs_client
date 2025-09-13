# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Models do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:models) { described_class.new(client) }

  describe "#list" do
    let(:models_response) do
      {
        "models" => [
          {
            "model_id" => "eleven_monolingual_v1",
            "name" => "Eleven Monolingual v1",
            "can_be_finetuned" => true,
            "can_do_text_to_speech" => true,
            "can_do_voice_conversion" => false,
            "can_use_style" => false,
            "can_use_speaker_boost" => true,
            "serves_pro_voices" => false,
            "token_cost_factor" => 1.0,
            "description" => "Use our standard English model to generate speech in a variety of voices, styles and moods.",
            "requires_alpha_access" => false,
            "max_characters_request_free_user" => 333,
            "max_characters_request_subscribed_user" => 5000,
            "maximum_text_length_per_request" => 5000,
            "languages" => [
              {
                "language_id" => "en",
                "name" => "English"
              }
            ]
          },
          {
            "model_id" => "eleven_multilingual_v1",
            "name" => "Eleven Multilingual v1",
            "can_be_finetuned" => true,
            "can_do_text_to_speech" => true,
            "can_do_voice_conversion" => false,
            "can_use_style" => false,
            "can_use_speaker_boost" => true,
            "serves_pro_voices" => false,
            "token_cost_factor" => 1.0,
            "description" => "Cutting-edge multilingual speech synthesis, supporting multiple languages.",
            "requires_alpha_access" => false,
            "max_characters_request_free_user" => 333,
            "max_characters_request_subscribed_user" => 5000,
            "maximum_text_length_per_request" => 5000,
            "languages" => [
              {
                "language_id" => "en",
                "name" => "English"
              },
              {
                "language_id" => "es",
                "name" => "Spanish"
              },
              {
                "language_id" => "fr",
                "name" => "French"
              }
            ]
          },
          {
            "model_id" => "eleven_multilingual_v2",
            "name" => "Eleven Multilingual v2",
            "can_be_finetuned" => false,
            "can_do_text_to_speech" => true,
            "can_do_voice_conversion" => false,
            "can_use_style" => true,
            "can_use_speaker_boost" => true,
            "serves_pro_voices" => false,
            "token_cost_factor" => 1.0,
            "description" => "Cutting-edge multilingual speech synthesis, supporting multiple languages. Newest model with improved quality.",
            "requires_alpha_access" => false,
            "max_characters_request_free_user" => 333,
            "max_characters_request_subscribed_user" => 5000,
            "maximum_text_length_per_request" => 5000,
            "languages" => [
              {
                "language_id" => "en",
                "name" => "English"
              },
              {
                "language_id" => "es",
                "name" => "Spanish"
              },
              {
                "language_id" => "fr",
                "name" => "French"
              },
              {
                "language_id" => "de",
                "name" => "German"
              },
              {
                "language_id" => "it",
                "name" => "Italian"
              }
            ]
          },
          {
            "model_id" => "eleven_turbo_v2",
            "name" => "Eleven Turbo v2",
            "can_be_finetuned" => false,
            "can_do_text_to_speech" => true,
            "can_do_voice_conversion" => false,
            "can_use_style" => false,
            "can_use_speaker_boost" => true,
            "serves_pro_voices" => false,
            "token_cost_factor" => 0.3,
            "description" => "Our fastest English model, optimized for real-time applications.",
            "requires_alpha_access" => false,
            "max_characters_request_free_user" => 333,
            "max_characters_request_subscribed_user" => 5000,
            "maximum_text_length_per_request" => 5000,
            "languages" => [
              {
                "language_id" => "en",
                "name" => "English"
              }
            ]
          }
        ]
      }
    end

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/models")
        .to_return(
          status: 200,
          body: models_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists models successfully" do
      result = models.list

      expect(result).to eq(models_response)
    end

    it "sends the correct request" do
      models.list

      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/models")
        .with(
          headers: {
            "xi-api-key" => api_key
          }
        )
    end

    it "returns models with expected structure" do
      result = models.list

      expect(result).to have_key("models")
      expect(result["models"]).to be_an(Array)
      expect(result["models"].length).to eq(4)

      # Check first model structure
      first_model = result["models"].first
      expect(first_model).to have_key("model_id")
      expect(first_model).to have_key("name")
      expect(first_model).to have_key("can_be_finetuned")
      expect(first_model).to have_key("can_do_text_to_speech")
      expect(first_model).to have_key("description")
      expect(first_model).to have_key("languages")
      expect(first_model["languages"]).to be_an(Array)
    end

    it "includes model capabilities information" do
      result = models.list

      # Check monolingual model
      monolingual = result["models"].find { |m| m["model_id"] == "eleven_monolingual_v1" }
      expect(monolingual["can_be_finetuned"]).to be true
      expect(monolingual["can_do_text_to_speech"]).to be true
      expect(monolingual["can_use_style"]).to be false
      expect(monolingual["languages"].length).to eq(1)
      expect(monolingual["languages"].first["language_id"]).to eq("en")

      # Check multilingual v2 model
      multilingual_v2 = result["models"].find { |m| m["model_id"] == "eleven_multilingual_v2" }
      expect(multilingual_v2["can_use_style"]).to be true
      expect(multilingual_v2["languages"].length).to eq(5)

      # Check turbo model
      turbo = result["models"].find { |m| m["model_id"] == "eleven_turbo_v2" }
      expect(turbo["token_cost_factor"]).to eq(0.3)
      expect(turbo["description"]).to include("fastest")
    end

    it "includes usage limits information" do
      result = models.list

      result["models"].each do |model|
        expect(model).to have_key("max_characters_request_free_user")
        expect(model).to have_key("max_characters_request_subscribed_user")
        expect(model).to have_key("maximum_text_length_per_request")
        expect(model["max_characters_request_free_user"]).to be_a(Integer)
        expect(model["max_characters_request_subscribed_user"]).to be_a(Integer)
        expect(model["maximum_text_length_per_request"]).to be_a(Integer)
      end
    end

    context "when API returns an error" do
      context "with authentication error" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/models")
            .to_return(status: 401, body: "Unauthorized")
        end

        it "raises AuthenticationError" do
          expect {
            models.list
          }.to raise_error(ElevenlabsClient::AuthenticationError)
        end
      end

      context "with rate limit error" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/models")
            .to_return(status: 429, body: "Rate limit exceeded")
        end

        it "raises RateLimitError" do
          expect {
            models.list
          }.to raise_error(ElevenlabsClient::RateLimitError)
        end
      end

      context "with server error" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/models")
            .to_return(status: 500, body: "Internal server error")
        end

        it "raises APIError" do
          expect {
            models.list
          }.to raise_error(ElevenlabsClient::APIError)
        end
      end
    end
  end

  describe "#list_models" do
    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/models")
        .to_return(
          status: 200,
          body: { "models" => [] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "is an alias for list method" do
      models.list_models

      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/models")
    end

    it "returns the same result as list method" do
      expect(models.list_models).to eq(models.list)
    end
  end

  describe "model filtering helpers" do
    let(:models_response) do
      {
        "models" => [
          {
            "model_id" => "eleven_monolingual_v1",
            "name" => "Eleven Monolingual v1",
            "can_be_finetuned" => true,
            "can_do_text_to_speech" => true,
            "can_use_style" => false,
            "languages" => [{ "language_id" => "en", "name" => "English" }]
          },
          {
            "model_id" => "eleven_multilingual_v2",
            "name" => "Eleven Multilingual v2",
            "can_be_finetuned" => false,
            "can_do_text_to_speech" => true,
            "can_use_style" => true,
            "languages" => [
              { "language_id" => "en", "name" => "English" },
              { "language_id" => "es", "name" => "Spanish" }
            ]
          }
        ]
      }
    end

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/models")
        .to_return(
          status: 200,
          body: models_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "can be used to filter models by capabilities" do
      result = models.list
      
      # Filter models that can be finetuned
      finetunable_models = result["models"].select { |m| m["can_be_finetuned"] }
      expect(finetunable_models.length).to eq(1)
      expect(finetunable_models.first["model_id"]).to eq("eleven_monolingual_v1")

      # Filter models that can use style
      style_models = result["models"].select { |m| m["can_use_style"] }
      expect(style_models.length).to eq(1)
      expect(style_models.first["model_id"]).to eq("eleven_multilingual_v2")
    end

    it "can be used to filter models by language support" do
      result = models.list

      # Filter models that support Spanish
      spanish_models = result["models"].select do |model|
        model["languages"].any? { |lang| lang["language_id"] == "es" }
      end
      expect(spanish_models.length).to eq(1)
      expect(spanish_models.first["model_id"]).to eq("eleven_multilingual_v2")

      # Filter models that support English
      english_models = result["models"].select do |model|
        model["languages"].any? { |lang| lang["language_id"] == "en" }
      end
      expect(english_models.length).to eq(2)
    end
  end

  describe "integration scenarios" do
    let(:models_response) do
      {
        "models" => [
          {
            "model_id" => "eleven_multilingual_v2",
            "name" => "Eleven Multilingual v2",
            "can_do_text_to_speech" => true,
            "can_use_style" => true,
            "token_cost_factor" => 1.0,
            "description" => "Best quality multilingual model",
            "languages" => [
              { "language_id" => "en", "name" => "English" },
              { "language_id" => "es", "name" => "Spanish" }
            ]
          },
          {
            "model_id" => "eleven_turbo_v2",
            "name" => "Eleven Turbo v2",
            "can_do_text_to_speech" => true,
            "can_use_style" => false,
            "token_cost_factor" => 0.3,
            "description" => "Fastest model for real-time applications",
            "languages" => [
              { "language_id" => "en", "name" => "English" }
            ]
          }
        ]
      }
    end

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/models")
        .to_return(
          status: 200,
          body: models_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "supports model selection for text-to-speech applications" do
      result = models.list

      # Find best quality model
      quality_model = result["models"].max_by { |m| m["token_cost_factor"] }
      expect(quality_model["model_id"]).to eq("eleven_multilingual_v2")

      # Find fastest model
      fastest_model = result["models"].min_by { |m| m["token_cost_factor"] }
      expect(fastest_model["model_id"]).to eq("eleven_turbo_v2")
    end

    it "supports model selection for multilingual applications" do
      result = models.list

      # Find models with multiple language support
      multilingual_models = result["models"].select do |model|
        model["languages"].length > 1
      end
      expect(multilingual_models.length).to eq(1)
      expect(multilingual_models.first["model_id"]).to eq("eleven_multilingual_v2")
    end

    it "supports model selection based on features" do
      result = models.list

      # Find models that support style
      style_capable_models = result["models"].select { |m| m["can_use_style"] }
      expect(style_capable_models.length).to eq(1)
      expect(style_capable_models.first["model_id"]).to eq("eleven_multilingual_v2")
    end
  end
end
