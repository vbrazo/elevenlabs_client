# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Audio Native Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:project_name) { "Test Project" }
  let(:project_id) { "JBFqnCBsd6RMkjVDRZzb" }

  describe "client.audio_native accessor" do
    it "provides access to audio_native endpoint" do
      expect(client.audio_native).to be_an_instance_of(ElevenlabsClient::AudioNative)
    end
  end

  describe "audio native project creation functionality via client" do
    let(:create_response) do
      {
        "project_id" => project_id,
        "converting" => false,
        "html_snippet" => "<div id='audio-native-player'></div>"
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/audio-native")
        .to_return(
          status: 200,
          body: create_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates audio native project through client interface" do
      result = client.audio_native.create(project_name)

      expect(result).to eq(create_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-native")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end

    it "supports the create_project alias method" do
      result = client.audio_native.create_project(project_name)

      expect(result).to eq(create_response)
    end

    it "supports optional parameters" do
      result = client.audio_native.create(
        project_name,
        author: "John Doe",
        title: "My Article",
        voice_id: "21m00Tcm4TlvDq8ikWAM",
        auto_convert: true
      )

      expect(result).to eq(create_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-native")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end
  end

  describe "audio native project content update functionality" do
    let(:update_response) do
      {
        "project_id" => project_id,
        "converting" => true,
        "publishing" => false,
        "html_snippet" => "<div id='audio-native-player'></div>"
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/content")
        .to_return(
          status: 200,
          body: update_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "updates project content through client interface" do
      result = client.audio_native.update_content(project_id)

      expect(result).to eq(update_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/content")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end

    it "supports the update_project_content alias method" do
      result = client.audio_native.update_project_content(project_id)

      expect(result).to eq(update_response)
    end

    it "supports optional parameters" do
      result = client.audio_native.update_content(
        project_id,
        auto_convert: true,
        auto_publish: false
      )

      expect(result).to eq(update_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/content")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end
  end

  describe "audio native project settings retrieval functionality" do
    let(:settings_response) do
      {
        "enabled" => true,
        "snapshot_id" => "JBFqnCBsd6RMkjVDRZzb",
        "settings" => {
          "title" => "My Project",
          "author" => "John Doe",
          "status" => "ready"
        }
      }
    end

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/settings")
        .to_return(
          status: 200,
          body: settings_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves project settings through client interface" do
      result = client.audio_native.get_settings(project_id)

      expect(result).to eq(settings_response)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/settings")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end

    it "supports the project_settings alias method" do
      result = client.audio_native.project_settings(project_id)

      expect(result).to eq(settings_response)
    end
  end

  describe "file upload handling" do
    let(:file_content) { StringIO.new("<html><body><p>Test article content</p></body></html>") }
    let(:filename) { "article.html" }
    let(:create_response) do
      {
        "project_id" => project_id,
        "converting" => false,
        "html_snippet" => "<div id='audio-native-player'></div>"
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/audio-native")
        .to_return(
          status: 200,
          body: create_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "handles file uploads in project creation" do
      result = client.audio_native.create(
        project_name,
        file: file_content,
        filename: filename
      )

      expect(result).to eq(create_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-native")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end

    it "handles different file types" do
      %w[html txt].each do |ext|
        client.audio_native.create(
          project_name,
          file: file_content,
          filename: "test.#{ext}"
        )
      end
      
      # Expect 2 requests total (one for each file type)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/audio-native").times(2)
    end
  end

  describe "error handling integration" do
    context "with authentication error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/audio-native")
          .to_return(status: 401, body: "Unauthorized")
      end

      it "raises AuthenticationError through client" do
        expect {
          client.audio_native.create(project_name)
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    context "with unprocessable entity error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/audio-native")
          .to_return(
            status: 422,
            body: {
              detail: [
                {
                  loc: ["name"],
                  msg: "Project name is required",
                  type: "value_error"
                }
              ]
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises UnprocessableEntityError through client" do
        expect {
          client.audio_native.create(project_name)
        }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end

    context "with not found error for settings" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/settings")
          .to_return(status: 404, body: "Project not found")
      end

      it "raises NotFoundError through client" do
        expect {
          client.audio_native.get_settings(project_id)
        }.to raise_error(ElevenlabsClient::NotFoundError)
      end
    end
  end

  describe "Settings integration" do
    after do
      ElevenlabsClient::Settings.reset!
    end

    context "when Settings are configured" do
      let(:create_response) do
        {
          "project_id" => project_id,
          "converting" => false,
          "html_snippet" => "<div id='audio-native-player'></div>"
        }
      end

      before do
        ElevenlabsClient.configure do |config|
          config.properties = {
            elevenlabs_base_uri: "https://configured.elevenlabs.io",
            elevenlabs_api_key: "configured_api_key"
          }
        end

        stub_request(:post, "https://configured.elevenlabs.io/v1/audio-native")
          .to_return(
            status: 200,
            body: create_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "uses configured settings for audio native requests" do
        client = ElevenlabsClient.new
        result = client.audio_native.create(project_name)

        expect(result).to eq(create_response)
        expect(WebMock).to have_requested(:post, "https://configured.elevenlabs.io/v1/audio-native")
          .with(headers: { "xi-api-key" => "configured_api_key" })
      end
    end
  end

  describe "Rails usage example" do
    let(:create_response) do
      {
        "project_id" => project_id,
        "converting" => false,
        "html_snippet" => "<div id='audio-native-player'></div>"
      }
    end

    let(:update_response) do
      {
        "project_id" => project_id,
        "converting" => true,
        "publishing" => false,
        "html_snippet" => "<div id='audio-native-player'></div>"
      }
    end

    let(:settings_response) do
      {
        "enabled" => true,
        "settings" => {
          "status" => "ready"
        }
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/audio-native")
        .to_return(
          status: 200,
          body: create_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      stub_request(:post, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/content")
        .to_return(
          status: 200,
          body: update_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      stub_request(:get, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/settings")
        .to_return(
          status: 200,
          body: settings_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "works as expected in a Rails-like environment" do
      # This simulates typical Rails usage
      client = ElevenlabsClient.new(api_key: api_key)
      
      # Create a new audio native project
      project = client.audio_native.create(
        "My Blog Post",
        author: "Jane Doe",
        title: "How to Use Audio Native",
        voice_id: "21m00Tcm4TlvDq8ikWAM",
        auto_convert: true,
        apply_text_normalization: "auto"
      )

      expect(project["project_id"]).to eq(project_id)

      # Update the project content
      updated_project = client.audio_native.update_content(
        project_id,
        auto_convert: true,
        auto_publish: false
      )

      expect(updated_project["converting"]).to be true

      # Get project settings
      settings = client.audio_native.get_settings(project_id)

      expect(settings["enabled"]).to be true
      expect(settings["settings"]["status"]).to eq("ready")
    end
  end

  describe "complete workflow integration" do
    let(:html_content) { StringIO.new("<html><body><h1>My Article</h1><p>This is the content.</p></body></html>") }
    let(:create_response) do
      {
        "project_id" => project_id,
        "converting" => false,
        "html_snippet" => "<div id='audio-native-player'></div>"
      }
    end

    let(:update_response) do
      {
        "project_id" => project_id,
        "converting" => true,
        "publishing" => false,
        "html_snippet" => "<div id='audio-native-player'></div>"
      }
    end

    let(:settings_response) do
      {
        "enabled" => true,
        "snapshot_id" => "snapshot123",
        "settings" => {
          "title" => "My Article",
          "author" => "John Doe",
          "status" => "converting"
        }
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/audio-native")
        .to_return(
          status: 200,
          body: create_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      stub_request(:post, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/content")
        .to_return(
          status: 200,
          body: update_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      stub_request(:get, "https://api.elevenlabs.io/v1/audio-native/#{project_id}/settings")
        .to_return(
          status: 200,
          body: settings_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "supports a complete audio native workflow" do
      # Step 1: Create project with file
      project = client.audio_native.create(
        "My Article Project",
        file: html_content,
        filename: "article.html",
        author: "John Doe",
        title: "My Article",
        voice_id: "21m00Tcm4TlvDq8ikWAM",
        auto_convert: false
      )

      expect(project["project_id"]).to eq(project_id)
      expect(project["converting"]).to be false

      # Step 2: Update content and trigger conversion
      updated_project = client.audio_native.update_content(
        project_id,
        file: StringIO.new("Updated content"),
        filename: "updated.txt",
        auto_convert: true,
        auto_publish: false
      )

      expect(updated_project["converting"]).to be true

      # Step 3: Check project settings
      settings = client.audio_native.get_settings(project_id)

      expect(settings["enabled"]).to be true
      expect(settings["settings"]["status"]).to eq("converting")
    end
  end
end
