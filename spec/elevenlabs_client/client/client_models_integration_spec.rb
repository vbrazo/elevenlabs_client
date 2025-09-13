# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Models Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }

  describe "client.models accessor" do
    it "provides access to models endpoint" do
      expect(client.models).to be_an_instance_of(ElevenlabsClient::Models)
    end
  end

  describe "models listing functionality via client" do
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
            "model_id" => "eleven_multilingual_v2",
            "name" => "Eleven Multilingual v2",
            "can_be_finetuned" => false,
            "can_do_text_to_speech" => true,
            "can_do_voice_conversion" => false,
            "can_use_style" => true,
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

    it "lists models through client interface" do
      result = client.models.list

      expect(result).to eq(models_response)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/models")
        .with(headers: { "xi-api-key" => api_key })
    end

    it "supports the list_models alias method" do
      result = client.models.list_models

      expect(result).to eq(models_response)
    end

    it "returns models with complete information" do
      result = client.models.list

      expect(result["models"]).to be_an(Array)
      expect(result["models"].length).to eq(3)

      # Verify model structure
      result["models"].each do |model|
        expect(model).to have_key("model_id")
        expect(model).to have_key("name")
        expect(model).to have_key("description")
        expect(model).to have_key("can_do_text_to_speech")
        expect(model).to have_key("languages")
        expect(model["languages"]).to be_an(Array)
      end
    end
  end

  describe "error handling integration" do
    context "with authentication error" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/models")
          .to_return(status: 401, body: "Unauthorized")
      end

      it "raises AuthenticationError through client" do
        expect {
          client.models.list
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    context "with rate limit error" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/models")
          .to_return(status: 429, body: "Rate limit exceeded")
      end

      it "raises RateLimitError through client" do
        expect {
          client.models.list
        }.to raise_error(ElevenlabsClient::RateLimitError)
      end
    end

    context "with server error" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/models")
          .to_return(status: 500, body: "Internal server error")
      end

      it "raises APIError through client" do
        expect {
          client.models.list
        }.to raise_error(ElevenlabsClient::APIError)
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

        stub_request(:get, "https://configured.elevenlabs.io/v1/models")
          .to_return(
            status: 200,
            body: { "models" => [] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "uses configured settings for models requests" do
        client = ElevenlabsClient.new
        
        result = client.models.list

        expect(WebMock).to have_requested(:get, "https://configured.elevenlabs.io/v1/models")
          .with(headers: { "xi-api-key" => "configured_api_key" })
      end
    end
  end

  describe "Rails usage example" do
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
              { "language_id" => "es", "name" => "Spanish" },
              { "language_id" => "fr", "name" => "French" }
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

    it "works as expected in a Rails-like environment" do
      # This simulates typical Rails usage
      client = ElevenlabsClient.new(api_key: api_key)
      
      # Get available models
      result = client.models.list

      expect(result).to eq(models_response)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/models")
    end
  end

  describe "model selection scenarios" do
    let(:models_response) do
      {
        "models" => [
          {
            "model_id" => "eleven_monolingual_v1",
            "name" => "Eleven Monolingual v1",
            "can_be_finetuned" => true,
            "can_do_text_to_speech" => true,
            "can_use_style" => false,
            "can_use_speaker_boost" => true,
            "token_cost_factor" => 1.0,
            "languages" => [{ "language_id" => "en", "name" => "English" }]
          },
          {
            "model_id" => "eleven_multilingual_v2",
            "name" => "Eleven Multilingual v2",
            "can_be_finetuned" => false,
            "can_do_text_to_speech" => true,
            "can_use_style" => true,
            "can_use_speaker_boost" => true,
            "token_cost_factor" => 1.0,
            "languages" => [
              { "language_id" => "en", "name" => "English" },
              { "language_id" => "es", "name" => "Spanish" },
              { "language_id" => "fr", "name" => "French" }
            ]
          },
          {
            "model_id" => "eleven_turbo_v2",
            "name" => "Eleven Turbo v2",
            "can_be_finetuned" => false,
            "can_do_text_to_speech" => true,
            "can_use_style" => false,
            "can_use_speaker_boost" => true,
            "token_cost_factor" => 0.3,
            "languages" => [{ "language_id" => "en", "name" => "English" }]
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

    it "supports finding models by capabilities" do
      models = client.models.list

      # Find models that can be finetuned
      finetunable = models["models"].select { |m| m["can_be_finetuned"] }
      expect(finetunable.length).to eq(1)
      expect(finetunable.first["model_id"]).to eq("eleven_monolingual_v1")

      # Find models that support style
      style_capable = models["models"].select { |m| m["can_use_style"] }
      expect(style_capable.length).to eq(1)
      expect(style_capable.first["model_id"]).to eq("eleven_multilingual_v2")

      # Find fastest model (lowest token cost)
      fastest = models["models"].min_by { |m| m["token_cost_factor"] }
      expect(fastest["model_id"]).to eq("eleven_turbo_v2")
    end

    it "supports finding models by language support" do
      models = client.models.list

      # Find multilingual models
      multilingual = models["models"].select do |model|
        model["languages"].length > 1
      end
      expect(multilingual.length).to eq(1)
      expect(multilingual.first["model_id"]).to eq("eleven_multilingual_v2")

      # Find models that support Spanish
      spanish_support = models["models"].select do |model|
        model["languages"].any? { |lang| lang["language_id"] == "es" }
      end
      expect(spanish_support.length).to eq(1)
      expect(spanish_support.first["model_id"]).to eq("eleven_multilingual_v2")
    end
  end

  describe "model information for other endpoints" do
    let(:models_response) do
      {
        "models" => [
          {
            "model_id" => "eleven_multilingual_v2",
            "name" => "Eleven Multilingual v2",
            "can_do_text_to_speech" => true,
            "can_use_style" => true,
            "max_characters_request_subscribed_user" => 5000,
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

    it "provides information useful for text-to-speech endpoint" do
      models = client.models.list
      
      tts_models = models["models"].select { |m| m["can_do_text_to_speech"] }
      expect(tts_models.length).to eq(1)
      
      model = tts_models.first
      expect(model["model_id"]).to eq("eleven_multilingual_v2")
      expect(model["can_use_style"]).to be true
      expect(model["max_characters_request_subscribed_user"]).to eq(5000)
    end

    it "provides language information for multilingual applications" do
      models = client.models.list
      
      model = models["models"].first
      supported_languages = model["languages"].map { |lang| lang["language_id"] }
      expect(supported_languages).to include("en", "es")
    end
  end

  describe "caching and performance scenarios" do
    let(:models_response) { { "models" => [] } }

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/models")
        .to_return(
          status: 200,
          body: models_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "makes separate requests for each call (no built-in caching)" do
      client.models.list
      client.models.list

      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/models").twice
    end

    it "supports external caching patterns" do
      # Simulate external caching
      cached_models = nil
      
      # First call - cache miss
      cached_models ||= client.models.list
      
      # Second call - cache hit (no API call)
      result = cached_models
      
      expect(result).to eq(models_response)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/models").once
    end
  end
end
