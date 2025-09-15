# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Admin::History do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:history) { described_class.new(client) }
  let(:history_item_id) { "ja9xsmfGhxYcymxGcOGB" }

  describe "#list" do
    let(:history_response) do
      {
        "history" => [
          {
            "history_item_id" => history_item_id,
            "date_unix" => 1714650306,
            "character_count_change_from" => 17189,
            "character_count_change_to" => 17231,
            "content_type" => "audio/mpeg",
            "state" => nil,
            "request_id" => "BF0BZg4IwLGBlaVjv9Im",
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

    context "with no parameters" do
      it "lists history items successfully" do
        result = history.list

        expect(result).to eq(history_response)
      end

      it "sends the correct request" do
        history.list

        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with page_size parameter" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/history?page_size=50")
          .to_return(
            status: 200,
            body: history_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "includes page_size in query parameters" do
        history.list(page_size: 50)

        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history?page_size=50")
      end
    end

    context "with start_after_history_item_id parameter" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/history?start_after_history_item_id=abc123")
          .to_return(
            status: 200,
            body: history_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "includes start_after_history_item_id in query parameters" do
        history.list(start_after_history_item_id: "abc123")

        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history?start_after_history_item_id=abc123")
      end
    end

    context "with voice_id parameter" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/history?voice_id=21m00Tcm4TlvDq8ikWAM")
          .to_return(
            status: 200,
            body: history_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "includes voice_id in query parameters" do
        history.list(voice_id: "21m00Tcm4TlvDq8ikWAM")

        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history?voice_id=21m00Tcm4TlvDq8ikWAM")
      end
    end

    context "with search and source parameters" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/history?search=hello&source=TTS")
          .to_return(
            status: 200,
            body: history_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "includes search and source in query parameters" do
        history.list(search: "hello", source: "TTS")

        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history?search=hello&source=TTS")
      end
    end

    context "with all parameters" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/history?page_size=25&start_after_history_item_id=xyz789&voice_id=voice123&search=test&source=STS")
          .to_return(
            status: 200,
            body: history_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "includes all parameters in query string" do
        history.list(
          page_size: 25,
          start_after_history_item_id: "xyz789",
          voice_id: "voice123",
          search: "test",
          source: "STS"
        )

        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history?page_size=25&start_after_history_item_id=xyz789&voice_id=voice123&search=test&source=STS")
      end
    end

    context "when API returns an error" do
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

        it "raises UnprocessableEntityError" do
          expect {
            history.list
          }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
        end
      end

      context "with authentication error" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/history")
            .to_return(status: 401, body: "Unauthorized")
        end

        it "raises AuthenticationError" do
          expect {
            history.list
          }.to raise_error(ElevenlabsClient::AuthenticationError)
        end
      end
    end
  end

  describe "#get" do
    let(:history_item_response) do
      {
        "history_item_id" => history_item_id,
        "date_unix" => 1714650306,
        "character_count_change_from" => 17189,
        "character_count_change_to" => 17231,
        "content_type" => "audio/mpeg",
        "state" => nil,
        "request_id" => "BF0BZg4IwLGBlaVjv9Im",
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

    it "gets history item successfully" do
      result = history.get(history_item_id)

      expect(result).to eq(history_item_response)
    end

    it "sends the correct request" do
      history.get(history_item_id)

      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
        .with(
          headers: {
            "xi-api-key" => api_key
          }
        )
    end

    context "when API returns an error" do
      context "with not found error" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
            .to_return(status: 404, body: "History item not found")
        end

        it "raises NotFoundError" do
          expect {
            history.get(history_item_id)
          }.to raise_error(ElevenlabsClient::NotFoundError)
        end
      end

      context "with unprocessable entity error" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
            .to_return(
              status: 422,
              body: {
                detail: [
                  {
                    loc: ["history_item_id"],
                    msg: "Invalid history item ID format",
                    type: "value_error"
                  }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "raises UnprocessableEntityError" do
          expect {
            history.get(history_item_id)
          }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
        end
      end
    end
  end

  describe "#delete" do
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

    it "deletes history item successfully" do
      result = history.delete(history_item_id)

      expect(result).to eq(delete_response)
    end

    it "sends the correct request" do
      history.delete(history_item_id)

      expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
        .with(
          headers: {
            "xi-api-key" => api_key
          }
        )
    end

    context "when API returns an error" do
      context "with not found error" do
        before do
          stub_request(:delete, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
            .to_return(status: 404, body: "History item not found")
        end

        it "raises NotFoundError" do
          expect {
            history.delete(history_item_id)
          }.to raise_error(ElevenlabsClient::NotFoundError)
        end
      end

      context "with unprocessable entity error" do
        before do
          stub_request(:delete, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
            .to_return(
              status: 422,
              body: {
                detail: [
                  {
                    loc: ["history_item_id"],
                    msg: "Cannot delete this history item",
                    type: "value_error"
                  }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "raises UnprocessableEntityError" do
          expect {
            history.delete(history_item_id)
          }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
        end
      end
    end
  end

  describe "#get_audio" do
    let(:audio_data) { "fake_binary_audio_data" }

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}/audio")
        .to_return(
          status: 200,
          body: audio_data,
          headers: { "Content-Type" => "audio/mpeg" }
        )
    end

    it "gets audio data successfully" do
      result = history.get_audio(history_item_id)

      expect(result).to eq(audio_data)
    end

    it "sends the correct request" do
      history.get_audio(history_item_id)

      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}/audio")
        .with(
          headers: {
            "xi-api-key" => api_key
          }
        )
    end

    context "when API returns an error" do
      context "with not found error" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}/audio")
            .to_return(status: 404, body: "History item not found")
        end

        it "raises NotFoundError" do
          expect {
            history.get_audio(history_item_id)
          }.to raise_error(ElevenlabsClient::NotFoundError)
        end
      end

      context "with unprocessable entity error" do
        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}/audio")
            .to_return(
              status: 422,
              body: {
                detail: [
                  {
                    loc: ["history_item_id"],
                    msg: "Audio not available for this history item",
                    type: "value_error"
                  }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "raises UnprocessableEntityError" do
          expect {
            history.get_audio(history_item_id)
          }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
        end
      end
    end
  end

  describe "#download" do
    let(:history_item_ids) { [history_item_id, "another_id_456"] }
    let(:zip_data) { "fake_zip_file_data" }

    context "with multiple history items" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/history/download")
          .to_return(
            status: 200,
            body: zip_data,
            headers: { "Content-Type" => "application/zip" }
          )
      end

      it "downloads multiple history items as zip successfully" do
        result = history.download(history_item_ids)

        expect(result).to eq(zip_data)
      end

      it "sends the correct request" do
        history.download(history_item_ids)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/history/download")
          .with(
            headers: {
              "xi-api-key" => api_key,
              "Content-Type" => "application/json"
            },
            body: {
              history_item_ids: history_item_ids
            }.to_json
          )
      end
    end

    context "with single history item" do
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

      it "downloads single history item as audio file successfully" do
        result = history.download(single_item_ids)

        expect(result).to eq(audio_data)
      end

      it "sends the correct request" do
        history.download(single_item_ids)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/history/download")
          .with(
            body: {
              history_item_ids: single_item_ids
            }.to_json
          )
      end
    end

    context "with output_format parameter" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/history/download")
          .to_return(
            status: 200,
            body: zip_data,
            headers: { "Content-Type" => "application/zip" }
          )
      end

      it "includes output_format in request body" do
        history.download(history_item_ids, output_format: "wav")

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/history/download")
          .with(
            body: {
              history_item_ids: history_item_ids,
              output_format: "wav"
            }.to_json
          )
      end
    end

    context "when API returns an error" do
      context "with bad request error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/history/download")
            .to_return(
              status: 400,
              body: {
                detail: "Invalid history item IDs provided"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "raises BadRequestError" do
          expect {
            history.download(history_item_ids)
          }.to raise_error(ElevenlabsClient::BadRequestError)
        end
      end

      context "with unprocessable entity error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/history/download")
            .to_return(
              status: 422,
              body: {
                detail: [
                  {
                    loc: ["history_item_ids"],
                    msg: "Some history items not found",
                    type: "value_error"
                  }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "raises UnprocessableEntityError" do
          expect {
            history.download(history_item_ids)
          }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
        end
      end
    end
  end

  describe "alias methods" do
    let(:history_response) { { "history" => [] } }
    let(:history_item_response) { { "history_item_id" => history_item_id } }
    let(:delete_response) { { "status" => "ok" } }
    let(:audio_data) { "audio_data" }
    let(:zip_data) { "zip_data" }

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/history")
        .to_return(
          status: 200, 
          body: history_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      stub_request(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
        .to_return(
          status: 200, 
          body: history_item_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      stub_request(:delete, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
        .to_return(
          status: 200, 
          body: delete_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      stub_request(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}/audio")
        .to_return(status: 200, body: audio_data)
      stub_request(:post, "https://api.elevenlabs.io/v1/history/download")
        .to_return(status: 200, body: zip_data)
    end

    describe "#get_generated_items" do
      it "is an alias for list method" do
        result = history.get_generated_items

        expect(result).to eq(history_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history")
      end
    end

    describe "#get_history_item" do
      it "is an alias for get method" do
        result = history.get_history_item(history_item_id)

        expect(result).to eq(history_item_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
      end
    end

    describe "#delete_history_item" do
      it "is an alias for delete method" do
        result = history.delete_history_item(history_item_id)

        expect(result).to eq(delete_response)
        expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/history/#{history_item_id}")
      end
    end

    describe "#get_audio_from_history_item" do
      it "is an alias for get_audio method" do
        result = history.get_audio_from_history_item(history_item_id)

        expect(result).to eq(audio_data)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/history/#{history_item_id}/audio")
      end
    end

    describe "#download_history_items" do
      it "is an alias for download method" do
        result = history.download_history_items([history_item_id])

        expect(result).to eq(zip_data)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/history/download")
      end
    end
  end
end
