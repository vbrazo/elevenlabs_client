# frozen_string_literal: true

RSpec.describe "Dubbing Resource Workflow Integration", type: :integration do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:dubbing_id) { "dub_integration_test_123" }
  let(:speaker_id) { "speaker_test_456" }
  let(:segment_id) { "segment_test_789" }
  let(:language) { "es" }

  describe "complete dubbing resource management workflow" do
    context "successful workflow" do
      before do
        # Stub all the API endpoints we'll be using
        stub_get_resource
        stub_create_segment
        stub_update_segment
        stub_transcribe_segment
        stub_translate_segment
        stub_dub_segment
        stub_render_project
        stub_update_speaker
        stub_get_similar_voices
        stub_delete_segment
        stub_delete_dubbing
      end

      it "completes a full dubbing resource workflow" do
        # Step 1: Get initial dubbing resource
        resource = client.dubs.get_resource(dubbing_id)
        expect(resource["id"]).to eq(dubbing_id)
        expect(resource["version"]).to eq(1)

        # Step 2: Create a new segment
        segment_result = client.dubs.create_segment(
          dubbing_id: dubbing_id,
          speaker_id: speaker_id,
          start_time: 10.5,
          end_time: 15.2,
          text: "Hello world",
          translations: { "es" => "Hola mundo" }
        )
        expect(segment_result["version"]).to eq(2)
        expect(segment_result["new_segment"]).to eq(segment_id)

        # Step 3: Update the segment
        update_result = client.dubs.update_segment(
          dubbing_id: dubbing_id,
          segment_id: segment_id,
          language: language,
          text: "Updated hello world"
        )
        expect(update_result["version"]).to eq(3)

        # Step 4: Transcribe segments
        transcribe_result = client.dubs.transcribe_segment(dubbing_id, [segment_id])
        expect(transcribe_result["version"]).to eq(4)

        # Step 5: Translate segments
        translate_result = client.dubs.translate_segment(dubbing_id, [segment_id], [language])
        expect(translate_result["version"]).to eq(5)

        # Step 6: Dub segments
        dub_result = client.dubs.dub_segment(dubbing_id, [segment_id], [language])
        expect(dub_result["version"]).to eq(6)

        # Step 7: Update speaker voice
        speaker_result = client.dubs.update_speaker(
          dubbing_id: dubbing_id,
          speaker_id: speaker_id,
          voice_id: "voice_123",
          languages: [language]
        )
        expect(speaker_result["version"]).to eq(7)

        # Step 8: Get similar voices for speaker
        voices_result = client.dubs.get_similar_voices(dubbing_id, speaker_id)
        expect(voices_result["voices"]).to be_an(Array)
        expect(voices_result["voices"].length).to eq(3)

        # Step 9: Render the project
        render_result = client.dubs.render_project(
          dubbing_id: dubbing_id,
          language: language,
          render_type: "mp4",
          normalize_volume: true
        )
        expect(render_result["version"]).to eq(8)
        expect(render_result["render_id"]).to eq("render_abc123")

        # Step 10: Clean up - delete segment
        delete_segment_result = client.dubs.delete_segment(dubbing_id, segment_id)
        expect(delete_segment_result["version"]).to eq(9)

        # Step 11: Clean up - delete dubbing project
        delete_result = client.dubs.delete(dubbing_id)
        expect(delete_result["status"]).to eq("ok")
      end
    end

    context "error handling in workflow" do
      it "handles resource not found errors gracefully" do
        stub_request(:get, "https://api.elevenlabs.io/v1/dubbing/resource/nonexistent")
          .to_return(status: 404, body: "Not Found")

        expect {
          client.dubs.get_resource("nonexistent")
        }.to raise_error(ElevenlabsClient::NotFoundError)
      end

      it "handles validation errors when creating segments" do
        stub_request(:post, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/speaker/#{speaker_id}/segment")
          .to_return(
            status: 422,
            body: { "detail" => "Invalid time range" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect {
          client.dubs.create_segment(
            dubbing_id: dubbing_id,
            speaker_id: speaker_id,
            start_time: 20.0,
            end_time: 10.0  # Invalid: end before start
          )
        }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end

      it "handles authentication errors" do
        stub_request(:patch, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/speaker/#{speaker_id}")
          .to_return(status: 401, body: "Unauthorized")

        expect {
          client.dubs.update_speaker(
            dubbing_id: dubbing_id,
            speaker_id: speaker_id,
            voice_id: "voice_123"
          )
        }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    context "render type validation" do
      before do
        stub_render_project_with_type
      end

      %w[mp4 aac mp3 wav aaf tracks_zip clips_zip].each do |render_type|
        it "successfully renders #{render_type} format" do
          result = client.dubs.render_project(
            dubbing_id: dubbing_id,
            language: language,
            render_type: render_type
          )
          expect(result["render_id"]).not_to be_nil
          expect(result["render_id"]).not_to be_empty
        end
      end
    end

    context "voice cloning workflow" do
      before do
        stub_update_speaker_with_cloning
        stub_get_similar_voices
      end

      it "supports track-clone voice assignment" do
        result = client.dubs.update_speaker(
          dubbing_id: dubbing_id,
          speaker_id: speaker_id,
          voice_id: "track-clone"
        )
        expect(result["version"]).to be > 0
      end

      it "supports clip-clone voice assignment" do
        result = client.dubs.update_speaker(
          dubbing_id: dubbing_id,
          speaker_id: speaker_id,
          voice_id: "clip-clone"
        )
        expect(result["version"]).to be > 0
      end

      it "provides similar voice recommendations" do
        result = client.dubs.get_similar_voices(dubbing_id, speaker_id)
        
        expect(result["voices"]).to be_an(Array)
        result["voices"].each do |voice|
          expect(voice).to have_key("voice_id")
          expect(voice).to have_key("name")
          expect(voice).to have_key("category")
          expect(voice).to have_key("description")
          expect(voice).to have_key("preview_url")
        end
      end
    end
  end

  private

  def stub_get_resource
    stub_request(:get, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}")
      .to_return(
        status: 200,
        body: {
          "id" => dubbing_id,
          "version" => 1,
          "source_language" => "en",
          "target_languages" => ["es", "pt"],
          "input" => {
            "src" => "input.mp4",
            "content_type" => "video/mp4",
            "duration_secs" => 120.5,
            "is_audio" => false,
            "url" => "https://example.com/input.mp4"
          },
          "speaker_tracks" => {},
          "speaker_segments" => {},
          "renders" => {}
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_create_segment
    stub_request(:post, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/speaker/#{speaker_id}/segment")
      .to_return(
        status: 201,
        body: { "version" => 2, "new_segment" => segment_id }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_update_segment
    stub_request(:patch, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/segment/#{segment_id}/#{language}")
      .to_return(
        status: 200,
        body: { "version" => 3 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_transcribe_segment
    stub_request(:post, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/transcribe")
      .to_return(
        status: 200,
        body: { "version" => 4 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_translate_segment
    stub_request(:post, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/translate")
      .to_return(
        status: 200,
        body: { "version" => 5 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_dub_segment
    stub_request(:post, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/dub")
      .to_return(
        status: 200,
        body: { "version" => 6 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_update_speaker
    stub_request(:patch, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/speaker/#{speaker_id}")
      .to_return(
        status: 200,
        body: { "version" => 7 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_get_similar_voices
    stub_request(:get, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/speaker/#{speaker_id}/similar-voices")
      .to_return(
        status: 200,
        body: {
          "voices" => [
            {
              "voice_id" => "voice_001",
              "name" => "Sarah",
              "category" => "premade",
              "description" => "Young adult female voice",
              "preview_url" => "https://example.com/preview1.mp3"
            },
            {
              "voice_id" => "voice_002",
              "name" => "Emma",
              "category" => "premade",
              "description" => "Professional female voice",
              "preview_url" => "https://example.com/preview2.mp3"
            },
            {
              "voice_id" => "voice_003",
              "name" => "Lisa",
              "category" => "cloned",
              "description" => "Custom cloned voice",
              "preview_url" => "https://example.com/preview3.mp3"
            }
          ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_render_project
    stub_request(:post, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/render/#{language}")
      .to_return(
        status: 200,
        body: { "version" => 8, "render_id" => "render_abc123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_delete_segment
    stub_request(:delete, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/segment/#{segment_id}")
      .to_return(
        status: 200,
        body: { "version" => 9 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_delete_dubbing
    stub_request(:delete, "https://api.elevenlabs.io/v1/dubbing/#{dubbing_id}")
      .to_return(
        status: 200,
        body: { "status" => "ok" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_render_project_with_type
    stub_request(:post, %r{https://api\.elevenlabs\.io/v1/dubbing/resource/#{dubbing_id}/render/#{language}})
      .to_return(
        status: 200,
        body: { "version" => 8, "render_id" => "render_abc123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_update_speaker_with_cloning
    stub_request(:patch, "https://api.elevenlabs.io/v1/dubbing/resource/#{dubbing_id}/speaker/#{speaker_id}")
      .to_return(
        status: 200,
        body: { "version" => 7 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
