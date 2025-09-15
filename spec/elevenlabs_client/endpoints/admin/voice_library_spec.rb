# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Admin::VoiceLibrary do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:voice_library) { described_class.new(client) }

  describe "#get_shared_voices" do
    let(:shared_voices_response) do
      {
        "voices" => [
          {
            "public_owner_id" => "63e84100a6bf7874ba37a1bab9a31828a379ec94b891b401653b655c5110880f",
            "voice_id" => "sB1b5zUrxQVAFl2PhZFp",
            "date_unix" => 1714423232,
            "name" => "Alita",
            "accent" => "american",
            "gender" => "Female",
            "age" => "young",
            "descriptive" => "calm",
            "use_case" => "characters_animation",
            "category" => "professional",
            "usage_character_count_1y" => 12852,
            "usage_character_count_7d" => 12852,
            "play_api_usage_character_count_1y" => 12852,
            "cloned_by_count" => 11,
            "free_users_allowed" => true,
            "live_moderation_enabled" => false,
            "featured" => false,
            "language" => "en",
            "description" => "Perfectly calm, neutral and strong voice. Great for a young female protagonist.",
            "preview_url" => "https://storage.googleapis.com/eleven-public-prod/wqkMCd9huxXHX1dy5mLJn4QEQHj1/voices/sB1b5zUrxQVAFl2PhZFp/55e71aac-5cb7-4b3d-8241-429388160509.mp3",
            "rate" => 1,
            "verified_languages" => [
              {
                "language" => "en",
                "model_id" => "eleven_multilingual_v2",
                "accent" => "american",
                "locale" => "en-US",
                "preview_url" => "https://storage.googleapis.com/eleven-public-prod/wqkMCd9huxXHX1dy5mLJn4QEQHj1/voices/sB1b5zUrxQVAFl2PhZFp/55e71aac-5cb7-4b3d-8241-429388160509.mp3"
              }
            ]
          }
        ],
        "has_more" => false
      }
    end

    context "with no parameters" do
      it "makes a GET request to /v1/shared-voices" do
        stub_request(:get, "https://api.elevenlabs.io/v1/shared-voices")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: shared_voices_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = voice_library.get_shared_voices

        expect(result).to eq(shared_voices_response)
      end
    end

    context "with filtering parameters" do
      let(:params) do
        {
          page_size: 10,
          category: "professional",
          gender: "Female",
          age: "young",
          accent: "american",
          language: "en",
          locale: "en-US",
          search: "calm voice",
          featured: true,
          page: 1
        }
      end

      it "makes a GET request with query parameters" do
        stub_request(:get, "https://api.elevenlabs.io/v1/shared-voices")
          .with(
            query: params,
            headers: { "xi-api-key" => api_key }
          )
          .to_return(
            status: 200,
            body: shared_voices_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = voice_library.get_shared_voices(**params)

        expect(result).to eq(shared_voices_response)
      end
    end

    context "with array parameters" do
      let(:params) do
        {
          use_cases: ["characters_animation", "narration"],
          descriptives: ["calm", "strong"]
        }
      end

      it "makes a GET request with array parameters" do
        stub_request(:get, "https://api.elevenlabs.io/v1/shared-voices")
          .with(
            query: params,
            headers: { "xi-api-key" => api_key }
          )
          .to_return(
            status: 200,
            body: shared_voices_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = voice_library.get_shared_voices(**params)

        expect(result).to eq(shared_voices_response)
      end
    end

    context "with boolean parameters" do
      it "includes false boolean parameters" do
        stub_request(:get, "https://api.elevenlabs.io/v1/shared-voices")
          .with(
            query: {
              featured: false,
              include_custom_rates: false,
              include_live_moderated: false,
              reader_app_enabled: false
            },
            headers: { "xi-api-key" => api_key }
          )
          .to_return(
            status: 200,
            body: shared_voices_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = voice_library.get_shared_voices(
          featured: false,
          include_custom_rates: false,
          include_live_moderated: false,
          reader_app_enabled: false
        )

        expect(result).to eq(shared_voices_response)
      end
    end

    context "with category filtering" do
      %w[professional famous high_quality].each do |category|
        it "accepts #{category} as category" do
          stub_request(:get, "https://api.elevenlabs.io/v1/shared-voices")
            .with(
              query: { category: category },
              headers: { "xi-api-key" => api_key }
            )
            .to_return(
              status: 200,
              body: shared_voices_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          result = voice_library.get_shared_voices(category: category)

          expect(result).to eq(shared_voices_response)
        end
      end
    end

    context "when API returns an error" do
      it "raises UnprocessableEntityError for 422 status" do
        stub_request(:get, "https://api.elevenlabs.io/v1/shared-voices")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 422,
            body: { "detail" => "Invalid parameters" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect do
          voice_library.get_shared_voices
        end.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end

      it "raises AuthenticationError for 401 status" do
        stub_request(:get, "https://api.elevenlabs.io/v1/shared-voices")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 401,
            body: { "detail" => "Invalid API key" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect do
          voice_library.get_shared_voices
        end.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end
  end

  describe "#add_shared_voice" do
    let(:public_user_id) { "63e84100a6bf7874ba37a1bab9a31828a379ec94b891b401653b655c5110880f" }
    let(:voice_id) { "sB1b5zUrxQVAFl2PhZFp" }
    let(:new_name) { "John Smith" }
    let(:add_voice_response) do
      {
        "voice_id" => "b38kUX8pkfYO2kHyqfFy"
      }
    end

    it "makes a POST request to /v1/voices/add/:public_user_id/:voice_id" do
      stub_request(:post, "https://api.elevenlabs.io/v1/voices/add/#{public_user_id}/#{voice_id}")
        .with(
          body: { new_name: new_name }.to_json,
          headers: {
            "xi-api-key" => api_key,
            "Content-Type" => "application/json"
          }
        )
        .to_return(
          status: 200,
          body: add_voice_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = voice_library.add_shared_voice(
        public_user_id: public_user_id,
        voice_id: voice_id,
        new_name: new_name
      )

      expect(result).to eq(add_voice_response)
    end

    context "when API returns an error" do
      it "raises UnprocessableEntityError for 422 status" do
        stub_request(:post, "https://api.elevenlabs.io/v1/voices/add/#{public_user_id}/#{voice_id}")
          .with(
            body: { new_name: new_name }.to_json,
            headers: {
              "xi-api-key" => api_key,
              "Content-Type" => "application/json"
            }
          )
          .to_return(
            status: 422,
            body: { "detail" => "Voice already exists" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect do
          voice_library.add_shared_voice(
            public_user_id: public_user_id,
            voice_id: voice_id,
            new_name: new_name
          )
        end.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end

      it "raises AuthenticationError for 401 status" do
        stub_request(:post, "https://api.elevenlabs.io/v1/voices/add/#{public_user_id}/#{voice_id}")
          .with(
            body: { new_name: new_name }.to_json,
            headers: {
              "xi-api-key" => api_key,
              "Content-Type" => "application/json"
            }
          )
          .to_return(
            status: 401,
            body: { "detail" => "Invalid API key" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect do
          voice_library.add_shared_voice(
            public_user_id: public_user_id,
            voice_id: voice_id,
            new_name: new_name
          )
        end.to raise_error(ElevenlabsClient::AuthenticationError)
      end

      it "raises NotFoundError for 404 status" do
        stub_request(:post, "https://api.elevenlabs.io/v1/voices/add/#{public_user_id}/#{voice_id}")
          .with(
            body: { new_name: new_name }.to_json,
            headers: {
              "xi-api-key" => api_key,
              "Content-Type" => "application/json"
            }
          )
          .to_return(
            status: 404,
            body: { "detail" => "Voice not found" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect do
          voice_library.add_shared_voice(
            public_user_id: public_user_id,
            voice_id: voice_id,
            new_name: new_name
          )
        end.to raise_error(ElevenlabsClient::NotFoundError)
      end
    end
  end

  describe "aliases" do
    it "has shared_voices alias for get_shared_voices" do
      expect(voice_library.method(:shared_voices)).to eq(voice_library.method(:get_shared_voices))
    end

    it "has list_shared_voices alias for get_shared_voices" do
      expect(voice_library.method(:list_shared_voices)).to eq(voice_library.method(:get_shared_voices))
    end

    it "has add_voice alias for add_shared_voice" do
      expect(voice_library.method(:add_voice)).to eq(voice_library.method(:add_shared_voice))
    end
  end

  describe "private methods" do
    it "has client as a private attr_reader" do
      expect(voice_library.send(:client)).to eq(client)
    end
  end
end
