# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Admin History Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:history_item_id) { "ja9xsmfGhxYcymxGcOGB" }

  describe "client.history accessor" do
    it "provides access to history endpoint" do
      expect(client.history).to be_an_instance_of(ElevenlabsClient::Admin::History)
    end
  end

  describe "history listing functionality via client" do
    let(:history_response) do
      {
        "history" => [
          {
            "history_item_id" => history_item_id,
            "date_unix" => 1714650306,
            "character_count_change_from" => 17189,
            "character_count_change_to" => 17231,
            "content_type" => "audio/mpeg",
            "voice_id" => "21m00Tcm4TlvDq8ikWAM",
            "model_id" => "eleven_multilingual_v2",
            "voice_name" => "Rachel",
            "voice_category" => "premade",
            "text" => "Hello, world!",
            "source" => "TTS"
          }
        ],
        "has_more" => true,
        "last_history_item_id" => history_item_id,
        "scanned_until" => 1714650306
      }
    end

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/history")
        .to_return(
          status: 200,
          body: history_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "lists history items through client interface" do
      result = client.history.list

      expect(result).to eq(history_response)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end

    it "supports the get_generated_items alias method" do
      result = client.history.get_generated_items

      expect(result).to eq(history_response)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history")
    end

    context "with pagination parameters" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/history?page_size=50&start_after_history_item_id=abc123")
          .to_return(
            status: 200,
            body: history_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "handles pagination parameters correctly" do
        result = client.history.list(page_size: 50, start_after_history_item_id: "abc123")

        expect(result["history"]).to be_an(Array)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history?page_size=50&start_after_history_item_id=abc123")
      end
    end

    context "with filtering parameters" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/history?voice_id=21m00Tcm4TlvDq8ikWAM&search=hello&source=TTS")
          .to_return(
            status: 200,
            body: history_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "handles filtering parameters correctly" do
        result = client.history.list(
          voice_id: "21m00Tcm4TlvDq8ikWAM",
          search: "hello",
          source: "TTS"
        )

        expect(result["history"]).to be_an(Array)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history?voice_id=21m00Tcm4TlvDq8ikWAM&search=hello&source=TTS")
      end
    end
  end

  describe "history item retrieval functionality via client" do
    let(:history_item_response) do
      {
        "history_item_id" => history_item_id,
        "date_unix" => 1714650306,
        "character_count_change_from" => 17189,
        "character_count_change_to" => 17231,
        "content_type" => "audio/mpeg",
        "voice_id" => "21m00Tcm4TlvDq8ikWAM",
        "model_id" => "eleven_multilingual_v2",
        "voice_name" => "Rachel",
        "voice_category" => "premade",
        "text" => "Hello, world!",
        "settings" => {
          "similarity_boost" => 0.5,
          "stability" => 0.71,
          "style" => 0,
          "use_speaker_boost" => true
        },
        "source" => "TTS"
      }
    end

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
        .to_return(
          status: 200,
          body: history_item_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "retrieves history item through client interface" do
      result = client.history.get(history_item_id)

      expect(result).to eq(history_item_response)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end

    it "supports the get_history_item alias method" do
      result = client.history.get_history_item(history_item_id)

      expect(result).to eq(history_item_response)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
    end
  end

  describe "history item deletion functionality via client" do
    let(:delete_response) do
      {
        "status" => "ok"
      }
    end

    before do
      stub_request(:delete, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
        .to_return(
          status: 200,
          body: delete_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "deletes history item through client interface" do
      result = client.history.delete(history_item_id)

      expect(result).to eq(delete_response)
      expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end

    it "supports the delete_history_item alias method" do
      result = client.history.delete_history_item(history_item_id)

      expect(result).to eq(delete_response)
      expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
    end
  end

  describe "audio retrieval functionality via client" do
    let(:audio_data) { "fake_binary_audio_data" }

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}/audio")
        .to_return(
          status: 200,
          body: audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "retrieves audio data through client interface" do
      result = client.history.get_audio(history_item_id)

      expect(result).to eq(audio_data)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}/audio")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end

    it "supports the get_audio_from_history_item alias method" do
      result = client.history.get_audio_from_history_item(history_item_id)

      expect(result).to eq(audio_data)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}/audio")
    end
  end

  describe "download functionality via client" do
    let(:history_item_ids) { [history_item_id, "another_id_456"] }

    context "when downloading multiple items" do
      let(:zip_data) { "fake_zip_file_data" }

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/history/download")
          .to_return(
            status: 200,
            body: zip_data,
            headers: { "Content-Type" => "application/zip" }
          )
      end

      it "downloads multiple items as zip through client interface" do
        result = client.history.download(history_item_ids)

        expect(result).to eq(zip_data)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/history/download")
          .with(
            headers: { "xi-api-key" => api_key, "Content-Type" => "application/json" },
            body: { history_item_ids: history_item_ids }.to_json
          )
      end

      it "supports the download_history_items alias method" do
        result = client.history.download_history_items(history_item_ids)

        expect(result).to eq(zip_data)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/history/download")
      end
    end

    context "when downloading single item" do
      let(:single_item_ids) { [history_item_id] }
      let(:audio_data) { "fake_audio_file_data" }

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/history/download")
          .to_return(
            status: 200,
            body: audio_data,
            headers: { "Content-Type" => "audio/mpeg" }
          )
      end

      it "downloads single item as audio file through client interface" do
        result = client.history.download(single_item_ids)

        expect(result).to eq(audio_data)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/history/download")
          .with(
            body: { history_item_ids: single_item_ids }.to_json
          )
      end
    end

    context "with output format specification" do
      let(:wav_data) { "fake_wav_file_data" }

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/history/download")
          .to_return(
            status: 200,
            body: wav_data,
            headers: { "Content-Type" => "audio/wav" }
          )
      end

      it "handles output format parameter correctly" do
        result = client.history.download([history_item_id], output_format: "wav")

        expect(result).to eq(wav_data)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/history/download")
          .with(
            body: {
              history_item_ids: [history_item_id],
              output_format: "wav"
            }.to_json
          )
      end
    end
  end

  describe "error handling integration" do
    context "with authentication error" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/history")
          .to_return(status: 401, body: "Unauthorized")
      end

      it "raises AuthenticationError through client" do
        expect {
          client.history.list
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    context "with not found error for history item" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/history/nonexistent_id")
          .to_return(status: 404, body: "History item not found")
      end

      it "raises NotFoundError through client" do
        expect {
          client.history.get("nonexistent_id")
        }.to raise_error(ElevenlabsClient::NotFoundError)
      end
    end

    context "with unprocessable entity error" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/history")
          .to_return(
            status: 422,
            body: {
              detail: [
                {
                  loc: ["page_size"],
                  msg: "Page size must be between 1 and 1000",
                  type: "value_error"
                }
              ]
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises UnprocessableEntityError through client" do
        expect {
          client.history.list
        }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end

    context "with bad request error for download" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/history/download")
          .to_return(
            status: 400,
            body: { detail: "Invalid history item IDs provided" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises BadRequestError through client" do
        expect {
          client.history.download(["invalid_id"])
        }.to raise_error(ElevenlabsClient::BadRequestError)
      end
    end
  end

  describe "Settings integration" do
    context "when Settings are configured" do
      it "uses configured settings for history requests" do
        # Use a fresh settings configuration for this test only
        ElevenlabsClient::Settings.configure do |config|
          config.properties = {
            elevenlabs_api_key: "settings_api_key",
            elevenlabs_base_uri: "https://custom.api.url"
          }
        end

        stub_request(:get, "https://custom.api.url/v1/history")
          .to_return(
            status: 200,
            body: { history: [] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Create a new client that will use the configured settings
        settings_client = ElevenlabsClient.new
        settings_client.history.list

        expect(WebMock).to have_requested(:get, "https://custom.api.url/v1/history")
          .with(headers: { "xi-api-key" => "settings_api_key" })

        # Clean up settings after the test
        ElevenlabsClient::Settings.configure do |config|
          config.properties = {}
        end
      end
    end
  end

  describe "Rails usage example" do
    it "works as expected in a Rails-like environment" do
      stub_request(:get, "https://api.elevenlabs.io/v1/history")
        .to_return(
          status: 200,
          body: { history: [] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Simulate Rails controller usage with explicit API key
      rails_client = ElevenlabsClient::Client.new(api_key: "rails_api_key")
      result = rails_client.history.list

      expect(result["history"]).to be_an(Array)
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history")
        .with(headers: { "xi-api-key" => "rails_api_key" })
    end
  end

  describe "complete history workflow" do
    let(:history_list_response) do
      {
        "history" => [
          {
            "history_item_id" => history_item_id,
            "text" => "Hello, world!",
            "voice_name" => "Rachel",
            "date_unix" => 1714650306
          }
        ],
        "has_more" => false
      }
    end

    let(:history_item_response) do
      {
        "history_item_id" => history_item_id,
        "text" => "Hello, world!",
        "voice_name" => "Rachel",
        "settings" => { "stability" => 0.71 }
      }
    end

    let(:audio_data) { "binary_audio_data" }
    let(:delete_response) { { "status" => "ok" } }

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/history")
        .to_return(
          status: 200,
          body: history_list_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      
      stub_request(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
        .to_return(
          status: 200,
          body: history_item_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      
      stub_request(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}/audio")
        .to_return(
          status: 200,
          body: audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
      
      stub_request(:delete, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
        .to_return(
          status: 200,
          body: delete_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "supports complete history management workflow" do
      # Step 1: List history items
      history_list = client.history.list
      expect(history_list["history"]).to be_an(Array)
      expect(history_list["history"].first["history_item_id"]).to eq(history_item_id)

      # Step 2: Get specific history item details
      history_item = client.history.get(history_item_id)
      expect(history_item["history_item_id"]).to eq(history_item_id)
      expect(history_item["settings"]).to include("stability")

      # Step 3: Get audio data
      audio = client.history.get_audio(history_item_id)
      expect(audio).to eq(audio_data)

      # Step 4: Delete history item
      delete_result = client.history.delete(history_item_id)
      expect(delete_result["status"]).to eq("ok")

      # Verify all API calls were made
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history")
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}/audio")
      expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
    end
  end

  describe "bulk operations" do
    let(:history_item_ids) { ["item1", "item2", "item3"] }
    let(:zip_data) { "bulk_download_zip_data" }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/history/download")
        .to_return(
          status: 200,
          body: zip_data,
          headers: { "Content-Type" => "application/zip" }
        )
    end

    it "handles bulk download operations efficiently" do
      result = client.history.download(history_item_ids, output_format: "wav")

      expect(result).to eq(zip_data)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/history/download")
        .with(
          body: {
            history_item_ids: history_item_ids,
            output_format: "wav"
          }.to_json
        )
    end
  end
end
