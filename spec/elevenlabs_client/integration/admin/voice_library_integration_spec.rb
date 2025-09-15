# frozen_string_literal: true

RSpec.describe "ElevenlabsClient VoiceLibrary Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }

  describe "client.voice_library accessor" do
    it "provides access to voice_library endpoint" do
      expect(client.voice_library).to be_an_instance_of(ElevenlabsClient::Admin::VoiceLibrary)
    end
  end

  describe "shared voices functionality via client" do
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

    context "basic shared voices retrieval" do
      it "successfully retrieves shared voices" do
        stub_request(:get, "https://api.elevenlabs.io/v1/shared-voices")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: shared_voices_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = client.voice_library.get_shared_voices

        expect(result).to eq(shared_voices_response)
        expect(result["voices"]).to be_an(Array)
        expect(result["has_more"]).to be false
        expect(result["voices"].first["voice_id"]).to eq("sB1b5zUrxQVAFl2PhZFp")
        expect(result["voices"].first["name"]).to eq("Alita")
      end
    end

    context "filtered shared voices retrieval" do
      it "successfully retrieves filtered shared voices" do
        stub_request(:get, "https://api.elevenlabs.io/v1/shared-voices")
          .with(
            query: {
              category: "professional",
              gender: "Female",
              language: "en",
              featured: true,
              page_size: 10
            },
            headers: { "xi-api-key" => api_key }
          )
          .to_return(
            status: 200,
            body: shared_voices_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = client.voice_library.get_shared_voices(
          category: "professional",
          gender: "Female",
          language: "en",
          featured: true,
          page_size: 10
        )

        expect(result).to eq(shared_voices_response)
        expect(result["voices"].first["category"]).to eq("professional")
        expect(result["voices"].first["gender"]).to eq("Female")
        expect(result["voices"].first["language"]).to eq("en")
      end
    end

    context "shared voices with search and use cases" do
      it "successfully retrieves shared voices with search and use case filters" do
        stub_request(:get, "https://api.elevenlabs.io/v1/shared-voices")
          .with(
            query: {
              search: "calm voice",
              use_cases: ["characters_animation", "narration"],
              descriptives: ["calm", "strong"]
            },
            headers: { "xi-api-key" => api_key }
          )
          .to_return(
            status: 200,
            body: shared_voices_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = client.voice_library.get_shared_voices(
          search: "calm voice",
          use_cases: ["characters_animation", "narration"],
          descriptives: ["calm", "strong"]
        )

        expect(result).to eq(shared_voices_response)
        expect(result["voices"].first["use_case"]).to eq("characters_animation")
        expect(result["voices"].first["descriptive"]).to eq("calm")
      end
    end

    context "shared voices with pagination" do
      it "successfully retrieves paginated shared voices" do
        stub_request(:get, "https://api.elevenlabs.io/v1/shared-voices")
          .with(
            query: {
              page: 1,
              page_size: 5,
              sort: "created_date_desc"
            },
            headers: { "xi-api-key" => api_key }
          )
          .to_return(
            status: 200,
            body: shared_voices_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = client.voice_library.get_shared_voices(
          page: 1,
          page_size: 5,
          sort: "created_date_desc"
        )

        expect(result).to eq(shared_voices_response)
      end
    end

    context "voice details validation" do
      it "returns complete voice information" do
        stub_request(:get, "https://api.elevenlabs.io/v1/shared-voices")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: shared_voices_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = client.voice_library.get_shared_voices

        voice = result["voices"].first
        expect(voice).to include(
          "public_owner_id" => "63e84100a6bf7874ba37a1bab9a31828a379ec94b891b401653b655c5110880f",
          "voice_id" => "sB1b5zUrxQVAFl2PhZFp",
          "name" => "Alita",
          "accent" => "american",
          "gender" => "Female",
          "age" => "young",
          "descriptive" => "calm",
          "use_case" => "characters_animation",
          "category" => "professional",
          "language" => "en"
        )

        expect(voice["usage_character_count_1y"]).to eq(12852)
        expect(voice["cloned_by_count"]).to eq(11)
        expect(voice["free_users_allowed"]).to be true
        expect(voice["live_moderation_enabled"]).to be false
        expect(voice["featured"]).to be false
        expect(voice["rate"]).to eq(1)
        expect(voice["verified_languages"]).to be_an(Array)
      end
    end
  end

  describe "add shared voice functionality via client" do
    let(:public_user_id) { "63e84100a6bf7874ba37a1bab9a31828a379ec94b891b401653b655c5110880f" }
    let(:voice_id) { "sB1b5zUrxQVAFl2PhZFp" }
    let(:new_name) { "John Smith" }
    let(:add_voice_response) do
      {
        "voice_id" => "b38kUX8pkfYO2kHyqfFy"
      }
    end

    context "basic voice addition" do
      it "successfully adds a shared voice to collection" do
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

        result = client.voice_library.add_shared_voice(
          public_user_id: public_user_id,
          voice_id: voice_id,
          new_name: new_name
        )

        expect(result).to eq(add_voice_response)
        expect(result["voice_id"]).to eq("b38kUX8pkfYO2kHyqfFy")
      end
    end

    context "voice addition with different names" do
      ["Custom Voice Name", "My Favorite Voice", "Production Voice"].each do |voice_name|
        it "successfully adds voice with name '#{voice_name}'" do
          stub_request(:post, "https://api.elevenlabs.io/v1/voices/add/#{public_user_id}/#{voice_id}")
            .with(
              body: { new_name: voice_name }.to_json,
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

          result = client.voice_library.add_shared_voice(
            public_user_id: public_user_id,
            voice_id: voice_id,
            new_name: voice_name
          )

          expect(result).to eq(add_voice_response)
        end
      end
    end
  end

  describe "error handling" do
    context "shared voices errors" do
      it "handles authentication errors gracefully" do
        stub_request(:get, "https://api.elevenlabs.io/v1/shared-voices")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 401,
            body: { "detail" => "Invalid API key" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect do
          client.voice_library.get_shared_voices
        end.to raise_error(ElevenlabsClient::AuthenticationError)
      end

      it "handles validation errors gracefully" do
        stub_request(:get, "https://api.elevenlabs.io/v1/shared-voices")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 422,
            body: { "detail" => "Invalid parameters" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect do
          client.voice_library.get_shared_voices
        end.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end

    context "add voice errors" do
      let(:public_user_id) { "invalid_user_id" }
      let(:voice_id) { "invalid_voice_id" }
      let(:new_name) { "Test Voice" }

      it "handles not found errors gracefully" do
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
          client.voice_library.add_shared_voice(
            public_user_id: public_user_id,
            voice_id: voice_id,
            new_name: new_name
          )
        end.to raise_error(ElevenlabsClient::NotFoundError)
      end

      it "handles duplicate voice errors gracefully" do
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
            body: { "detail" => "Voice already exists in your collection" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect do
          client.voice_library.add_shared_voice(
            public_user_id: public_user_id,
            voice_id: voice_id,
            new_name: new_name
          )
        end.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end
  end

  describe "voice_library method aliases" do
    it "provides shared_voices alias" do
      expect(client.voice_library.method(:shared_voices)).to eq(client.voice_library.method(:get_shared_voices))
    end

    it "provides list_shared_voices alias" do
      expect(client.voice_library.method(:list_shared_voices)).to eq(client.voice_library.method(:get_shared_voices))
    end

    it "provides add_voice alias" do
      expect(client.voice_library.method(:add_voice)).to eq(client.voice_library.method(:add_shared_voice))
    end
  end
end
