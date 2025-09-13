# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Voices Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }

  describe "client.voices accessor" do
    it "provides access to voices endpoint" do
      expect(client.voices).to be_an_instance_of(ElevenlabsClient::Voices)
    end
  end

  describe "voice management functionality via client" do
    let(:voice_id) { "21m00Tcm4TlvDq8ikWAM" }
    let(:voice_response) do
      {
        "voice_id" => voice_id,
        "name" => "Rachel",
        "category" => "premade",
        "labels" => {
          "accent" => "american",
          "description" => "calm",
          "age" => "young",
          "gender" => "female"
        },
        "description" => "A calm, young American female voice perfect for narration.",
        "settings" => {
          "stability" => 0.75,
          "similarity_boost" => 0.75,
          "style" => 0.0,
          "use_speaker_boost" => true
        },
        "safety_control" => "ALLOW"
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

    it "gets voice details through client interface" do
      result = client.voices.get(voice_id)

      expect(result).to eq(voice_response)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
        .with(headers: { "xi-api-key" => api_key })
    end

    it "supports the get_voice alias method" do
      result = client.voices.get_voice(voice_id)

      expect(result).to eq(voice_response)
    end
  end

  describe "voice listing functionality via client" do
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

    it "lists voices through client interface" do
      result = client.voices.list

      expect(result).to eq(voices_response)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/voices")
        .with(headers: { "xi-api-key" => api_key })
    end

    it "supports the list_voices alias method" do
      result = client.voices.list_voices

      expect(result).to eq(voices_response)
    end
  end

  describe "voice creation functionality via client" do
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

    it "creates voices through client interface" do
      result = client.voices.create(voice_name, [sample_file])

      expect(result).to eq(create_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/voices/add")
        .with(headers: { "xi-api-key" => api_key })
    end

    it "supports the create_voice alias method" do
      result = client.voices.create_voice(voice_name, [sample_file])

      expect(result).to eq(create_response)
    end
  end

  describe "voice editing functionality via client" do
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

    it "edits voices through client interface" do
      result = client.voices.edit(voice_id, [sample_file], name: "Updated Voice Name")

      expect(result).to eq(edit_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/voices/#{voice_id}/edit")
        .with(headers: { "xi-api-key" => api_key })
    end

    it "supports the edit_voice alias method" do
      result = client.voices.edit_voice(voice_id, [sample_file], name: "Updated Voice Name")

      expect(result).to eq(edit_response)
    end
  end

  describe "voice deletion functionality via client" do
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

    it "deletes voices through client interface" do
      result = client.voices.delete(voice_id)

      expect(result).to eq(delete_response)
      expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
        .with(headers: { "xi-api-key" => api_key })
    end

    it "supports the delete_voice alias method" do
      result = client.voices.delete_voice(voice_id)

      expect(result).to eq(delete_response)
    end
  end

  describe "voice status checking via client" do
    let(:voice_id) { "voice_123" }

    describe "#banned?" do
      context "when voice is banned" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
            .to_return(
              status: 200,
              body: { "safety_control" => "BAN" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "returns true through client interface" do
          expect(client.voices.banned?(voice_id)).to be true
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

        it "returns false through client interface" do
          expect(client.voices.banned?(voice_id)).to be false
        end
      end
    end

    describe "#active?" do
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

      it "checks if voice is active through client interface" do
        expect(client.voices.active?(voice_id)).to be true
        expect(client.voices.active?("nonexistent_voice")).to be false
      end
    end
  end

  describe "error handling integration" do
    let(:voice_id) { "voice_123" }

    context "with authentication error" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
          .to_return(status: 401, body: "Unauthorized")
      end

      it "raises AuthenticationError through client" do
        expect {
          client.voices.get(voice_id)
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    context "with rate limit error" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
          .to_return(status: 429, body: "Rate limit exceeded")
      end

      it "raises RateLimitError through client" do
        expect {
          client.voices.get(voice_id)
        }.to raise_error(ElevenlabsClient::RateLimitError)
      end
    end

    context "with validation error" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
          .to_return(status: 404, body: "Voice not found")
      end

      it "raises ValidationError through client" do
        expect {
          client.voices.get(voice_id)
        }.to raise_error(ElevenlabsClient::ValidationError)
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

        stub_request(:get, "https://configured.elevenlabs.io/v1/voices")
          .to_return(
            status: 200,
            body: { "voices" => [] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "uses configured settings for voices requests" do
        client = ElevenlabsClient.new
        
        result = client.voices.list

        expect(WebMock).to have_requested(:get, "https://configured.elevenlabs.io/v1/voices")
          .with(headers: { "xi-api-key" => "configured_api_key" })
      end
    end
  end

  describe "Rails usage example" do
    let(:voice_id) { "rachel_voice" }
    let(:voice_response) do
      {
        "voice_id" => voice_id,
        "name" => "Rachel",
        "category" => "premade",
        "labels" => {
          "accent" => "american",
          "gender" => "female",
          "use_case" => "narration"
        },
        "settings" => {
          "stability" => 0.75,
          "similarity_boost" => 0.75
        }
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

    it "works as expected in a Rails-like environment" do
      # This simulates typical Rails usage
      client = ElevenlabsClient.new(api_key: api_key)
      
      # Get voice details
      result = client.voices.get(voice_id)

      expect(result).to eq(voice_response)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
    end
  end

  describe "voice management workflow" do
    let(:voice_name) { "Custom Narrator Voice" }
    let(:sample_file) { create_temp_audio_file }
    let(:create_response) do
      {
        "voice_id" => "custom_voice_789",
        "name" => voice_name,
        "category" => "cloned"
      }
    end
    let(:edit_response) do
      {
        "voice_id" => "custom_voice_789",
        "name" => "Updated Narrator Voice",
        "category" => "cloned"
      }
    end
    let(:delete_response) do
      {
        "message" => "Voice successfully deleted"
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/voices/add")
        .to_return(
          status: 200,
          body: create_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:post, "https://api.elevenlabs.io/v1/voices/custom_voice_789/edit")
        .to_return(
          status: 200,
          body: edit_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:delete, "https://api.elevenlabs.io/v1/voices/custom_voice_789")
        .to_return(
          status: 200,
          body: delete_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    after do
      sample_file.close
      sample_file.unlink
    end

    it "supports complete voice management workflow" do
      # Step 1: Create the voice
      create_result = client.voices.create(
        voice_name,
        [sample_file],
        description: "A custom narrator voice for audiobooks",
        labels: { "use_case" => "narration", "tone" => "professional" }
      )

      expect(create_result).to eq(create_response)
      
      # Step 2: Edit the voice
      voice_id = create_result["voice_id"]
      
      edit_result = client.voices.edit(
        voice_id,
        [],
        name: "Updated Narrator Voice",
        description: "An updated custom narrator voice"
      )

      expect(edit_result).to eq(edit_response)
      
      # Step 3: Delete the voice
      delete_result = client.voices.delete(voice_id)

      expect(delete_result).to eq(delete_response)
      
      # Verify all requests were made correctly
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/voices/add")
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/voices/custom_voice_789/edit")
      expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/voices/custom_voice_789")
    end
  end

  describe "voice filtering and management scenarios" do
    let(:voices_response) do
      {
        "voices" => [
          {
            "voice_id" => "v1",
            "name" => "Alice",
            "category" => "premade",
            "labels" => { "accent" => "british", "gender" => "female" }
          },
          {
            "voice_id" => "v2",
            "name" => "Bob",
            "category" => "cloned",
            "labels" => { "accent" => "american", "gender" => "male" }
          },
          {
            "voice_id" => "v3",
            "name" => "Carol",
            "category" => "generated",
            "labels" => { "accent" => "australian", "gender" => "female" }
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

    it "supports voice filtering by category" do
      voices = client.voices.list

      # Filter by category
      premade_voices = voices["voices"].select { |v| v["category"] == "premade" }
      cloned_voices = voices["voices"].select { |v| v["category"] == "cloned" }
      generated_voices = voices["voices"].select { |v| v["category"] == "generated" }

      expect(premade_voices.length).to eq(1)
      expect(cloned_voices.length).to eq(1)
      expect(generated_voices.length).to eq(1)
    end

    it "supports voice filtering by labels" do
      voices = client.voices.list

      # Filter by gender
      female_voices = voices["voices"].select do |voice|
        voice["labels"]["gender"] == "female"
      end
      expect(female_voices.length).to eq(2)

      # Filter by accent
      american_voices = voices["voices"].select do |voice|
        voice["labels"]["accent"] == "american"
      end
      expect(american_voices.length).to eq(1)
    end
  end

  describe "multipart file handling" do
    let(:voice_name) { "Multi-sample Voice" }
    let(:sample_file1) { create_temp_audio_file }
    let(:sample_file2) { create_temp_audio_file }
    let(:create_response) do
      {
        "voice_id" => "multi_sample_voice",
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
      sample_file1.close
      sample_file1.unlink
      sample_file2.close
      sample_file2.unlink
    end

    it "handles multiple sample files correctly" do
      result = client.voices.create(
        voice_name,
        [sample_file1, sample_file2],
        description: "Voice created from multiple samples"
      )

      expect(result).to eq(create_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/voices/add")
    end
  end

  private

  def create_temp_audio_file
    file = Tempfile.new(['sample', '.mp3'])
    file.write("fake audio content for testing")
    file.rewind
    file
  end
end
