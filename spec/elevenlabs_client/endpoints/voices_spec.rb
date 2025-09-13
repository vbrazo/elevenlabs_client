# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Voices do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:voices) { described_class.new(client) }

  describe "#get" do
    let(:voice_id) { "21m00Tcm4TlvDq8ikWAM" }
    let(:voice_response) do
      {
        "voice_id" => voice_id,
        "name" => "Rachel",
        "samples" => [
          {
            "sample_id" => "sample_1",
            "file_name" => "sample1.mp3",
            "mime_type" => "audio/mpeg",
            "size_bytes" => 123456,
            "hash" => "abc123"
          }
        ],
        "category" => "premade",
        "fine_tuning" => {
          "is_allowed_to_fine_tune" => true,
          "state" => {},
          "verification" => {
            "requires_verification" => false,
            "is_verified" => true,
            "verification_failures" => [],
            "verification_attempts_count" => 0
          },
          "manual_verification" => {
            "extra_text" => "",
            "request_time_unix" => 0,
            "files" => []
          },
          "manual_verification_requested" => false
        },
        "labels" => {
          "accent" => "american",
          "description" => "calm",
          "age" => "young",
          "gender" => "female",
          "use case" => "narration"
        },
        "description" => "A calm, young American female voice perfect for narration.",
        "preview_url" => "https://storage.googleapis.com/eleven-public-prod/premade/voices/21m00Tcm4TlvDq8ikWAM/df6788f9-5c96-470d-8312-aab3b3d8f50a.mp3",
        "available_for_tiers" => ["free", "starter", "creator", "pro", "scale", "business"],
        "settings" => {
          "stability" => 0.75,
          "similarity_boost" => 0.75,
          "style" => 0.0,
          "use_speaker_boost" => true
        },
        "sharing" => {
          "status" => "enabled",
          "history_item_sample_id" => "sample_123",
          "original_voice_id" => "original_voice_456",
          "public_owner_id" => "public_owner_789",
          "liked_by_count" => 42,
          "cloned_by_count" => 15,
          "name" => "Rachel Clone",
          "description" => "A cloned version of Rachel",
          "labels" => {
            "accent" => "american",
            "gender" => "female"
          },
          "review_status" => "approved",
          "review_message" => "",
          "enabled_in_library" => true,
          "instagram_username" => "",
          "twitter_username" => "",
          "youtube_username" => "",
          "tiktok_username" => ""
        },
        "high_quality_base_model_ids" => ["model_1", "model_2"],
        "safety_control" => "ALLOW",
        "voice_verification" => {
          "requires_verification" => false,
          "is_verified" => true,
          "verification_failures" => [],
          "verification_attempts_count" => 0
        },
        "permission_on_resource" => "owner"
      }
    end

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
        .to_return(
          status: 200,
          body: voice_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "gets voice details successfully" do
      result = voices.get(voice_id)

      expect(result).to eq(voice_response)
    end

    it "sends the correct request" do
      voices.get(voice_id)

      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
        .with(
          headers: {
            "xi-api-key" => api_key
          }
        )
    end

    it "returns voice with expected structure" do
      result = voices.get(voice_id)

      expect(result).to have_key("voice_id")
      expect(result).to have_key("name")
      expect(result).to have_key("samples")
      expect(result).to have_key("category")
      expect(result).to have_key("labels")
      expect(result).to have_key("settings")
      expect(result["samples"]).to be_an(Array)
    end

    context "when API returns an error" do
      context "with voice not found" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
            .to_return(status: 404, body: "Voice not found")
        end

        it "raises ValidationError" do
          expect {
            voices.get(voice_id)
          }.to raise_error(ElevenlabsClient::ValidationError)
        end
      end

      context "with authentication error" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
            .to_return(status: 401, body: "Unauthorized")
        end

        it "raises AuthenticationError" do
          expect {
            voices.get(voice_id)
          }.to raise_error(ElevenlabsClient::AuthenticationError)
        end
      end
    end
  end

  describe "#list" do
    let(:voices_response) do
      {
        "voices" => [
          {
            "voice_id" => "voice_1",
            "name" => "Alice",
            "category" => "premade",
            "labels" => { "accent" => "british", "gender" => "female" }
          },
          {
            "voice_id" => "voice_2",
            "name" => "Bob",
            "category" => "cloned",
            "labels" => { "accent" => "american", "gender" => "male" }
          }
        ]
      }
    end

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/voices")
        .to_return(
          status: 200,
          body: voices_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists voices successfully" do
      result = voices.list

      expect(result).to eq(voices_response)
    end

    it "sends the correct request" do
      voices.list

      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/voices")
        .with(
          headers: {
            "xi-api-key" => api_key
          }
        )
    end
  end

  describe "#create" do
    let(:voice_name) { "My Custom Voice" }
    let(:sample_file) { create_temp_audio_file }
    let(:create_response) do
      {
        "voice_id" => "new_voice_123",
        "name" => voice_name,
        "category" => "cloned"
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/voices/add")
        .to_return(
          status: 200,
          body: create_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    after do
      sample_file.close
      sample_file.unlink
    end

    context "with required parameters only" do
      it "creates a voice successfully" do
        result = voices.create(voice_name, [sample_file])

        expect(result).to eq(create_response)
      end

      it "sends the correct multipart request" do
        voices.create(voice_name, [sample_file])

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/voices/add")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with description option" do
      let(:description) { "A warm, friendly voice for customer service" }

      it "includes description in the request" do
        voices.create(voice_name, [sample_file], description: description)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/voices/add")
      end
    end

    context "with labels option" do
      let(:labels) { { "accent" => "american", "gender" => "female", "age" => "adult" } }

      it "includes labels in the request" do
        voices.create(voice_name, [sample_file], labels: labels)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/voices/add")
      end
    end

    context "with multiple sample files" do
      let(:sample_file2) { create_temp_audio_file }

      after do
        sample_file2.close
        sample_file2.unlink
      end

      it "handles multiple files" do
        voices.create(voice_name, [sample_file, sample_file2])

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/voices/add")
      end
    end

    context "when API returns an error" do
      context "with validation error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/voices/add")
            .to_return(status: 400, body: "Invalid voice name")
        end

        it "raises ValidationError" do
          expect {
            voices.create(voice_name, [sample_file])
          }.to raise_error(ElevenlabsClient::ValidationError)
        end
      end
    end
  end

  describe "#edit" do
    let(:voice_id) { "voice_123" }
    let(:sample_file) { create_temp_audio_file }
    let(:edit_response) do
      {
        "voice_id" => voice_id,
        "name" => "Updated Voice Name",
        "category" => "cloned"
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/voices/#{voice_id}/edit")
        .to_return(
          status: 200,
          body: edit_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    after do
      sample_file.close
      sample_file.unlink
    end

    context "with name update only" do
      it "updates voice name successfully" do
        result = voices.edit(voice_id, [], name: "Updated Voice Name")

        expect(result).to eq(edit_response)
      end

      it "sends the correct request" do
        voices.edit(voice_id, [], name: "Updated Voice Name")

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/voices/#{voice_id}/edit")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with description update" do
      it "updates voice description" do
        voices.edit(voice_id, [], description: "New description")

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/voices/#{voice_id}/edit")
      end
    end

    context "with labels update" do
      let(:labels) { { "accent" => "british", "tone" => "professional" } }

      it "updates voice labels" do
        voices.edit(voice_id, [], labels: labels)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/voices/#{voice_id}/edit")
      end
    end

    context "with new sample files" do
      it "updates voice with new samples" do
        voices.edit(voice_id, [sample_file], name: "Updated Name")

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/voices/#{voice_id}/edit")
      end
    end

    context "with all options" do
      let(:labels) { { "accent" => "american", "gender" => "female" } }

      it "updates all voice properties" do
        voices.edit(
          voice_id,
          [sample_file],
          name: "Complete Update",
          description: "Completely updated voice",
          labels: labels
        )

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/voices/#{voice_id}/edit")
      end
    end
  end

  describe "#delete" do
    let(:voice_id) { "voice_to_delete" }
    let(:delete_response) do
      {
        "message" => "Voice successfully deleted"
      }
    end

    before do
      stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
        .to_return(
          status: 200,
          body: delete_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "deletes voice successfully" do
      result = voices.delete(voice_id)

      expect(result).to eq(delete_response)
    end

    it "sends the correct request" do
      voices.delete(voice_id)

      expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
        .with(
          headers: {
            "xi-api-key" => api_key
          }
        )
    end

    context "when voice doesn't exist" do
      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
          .to_return(status: 404, body: "Voice not found")
      end

      it "raises ValidationError" do
        expect {
          voices.delete(voice_id)
        }.to raise_error(ElevenlabsClient::ValidationError)
      end
    end
  end

  describe "#banned?" do
    let(:voice_id) { "voice_123" }

    context "when voice is banned" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
          .to_return(
            status: 200,
            body: { "safety_control" => "BAN" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns true" do
        expect(voices.banned?(voice_id)).to be true
      end
    end

    context "when voice is not banned" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
          .to_return(
            status: 200,
            body: { "safety_control" => "ALLOW" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns false" do
        expect(voices.banned?(voice_id)).to be false
      end
    end

    context "when voice doesn't exist" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
          .to_return(status: 404, body: "Voice not found")
      end

      it "returns false" do
        expect(voices.banned?(voice_id)).to be false
      end
    end
  end

  describe "#active?" do
    let(:voice_id) { "voice_123" }
    let(:voices_response) do
      {
        "voices" => [
          { "voice_id" => "voice_123", "name" => "Active Voice" },
          { "voice_id" => "voice_456", "name" => "Another Voice" }
        ]
      }
    end

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/voices")
        .to_return(
          status: 200,
          body: voices_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    context "when voice is in the list" do
      it "returns true" do
        expect(voices.active?(voice_id)).to be true
      end
    end

    context "when voice is not in the list" do
      it "returns false" do
        expect(voices.active?("nonexistent_voice")).to be false
      end
    end

    context "when API call fails" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/voices")
          .to_return(status: 500, body: "Internal server error")
      end

      it "returns false" do
        expect(voices.active?(voice_id)).to be false
      end
    end
  end

  describe "alias methods" do
    let(:voice_id) { "voice_123" }
    let(:voice_name) { "Test Voice" }
    let(:sample_file) { create_temp_audio_file }

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
        .to_return(status: 200, body: {}.to_json)
      stub_request(:get, "https://api.elevenlabs.io/v1/voices")
        .to_return(status: 200, body: { "voices" => [] }.to_json)
      stub_request(:post, "https://api.elevenlabs.io/v1/voices/add")
        .to_return(status: 200, body: {}.to_json)
      stub_request(:post, "https://api.elevenlabs.io/v1/voices/#{voice_id}/edit")
        .to_return(status: 200, body: {}.to_json)
      stub_request(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
        .to_return(status: 200, body: {}.to_json)
    end

    after do
      sample_file.close
      sample_file.unlink
    end

    describe "#get_voice" do
      it "is an alias for get method" do
        voices.get_voice(voice_id)

        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
      end
    end

    describe "#list_voices" do
      it "is an alias for list method" do
        voices.list_voices

        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/voices")
      end
    end

    describe "#create_voice" do
      it "is an alias for create method" do
        voices.create_voice(voice_name, [sample_file])

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/voices/add")
      end
    end

    describe "#edit_voice" do
      it "is an alias for edit method" do
        voices.edit_voice(voice_id, [sample_file])

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/voices/#{voice_id}/edit")
      end
    end

    describe "#delete_voice" do
      it "is an alias for delete method" do
        voices.delete_voice(voice_id)

        expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
      end
    end
  end

  private

  def create_temp_audio_file
    file = Tempfile.new(['sample', '.mp3'])
    file.write("fake audio content")
    file.rewind
    file
  end
end
