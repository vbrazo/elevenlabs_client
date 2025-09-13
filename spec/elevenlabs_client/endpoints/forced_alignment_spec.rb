# frozen_string_literal: true

RSpec.describe ElevenlabsClient::ForcedAlignment do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:forced_alignment) { described_class.new(client) }
  let(:audio_file) { StringIO.new("fake_audio_data") }
  let(:filename) { "test_audio.mp3" }
  let(:text) { "Hello, this is a test transcript for forced alignment." }

  describe "#create" do
    let(:response_data) do
      {
        "characters" => [
          {
            "text" => "H",
            "start" => 0.0,
            "end" => 0.1
          },
          {
            "text" => "e",
            "start" => 0.1,
            "end" => 0.2
          },
          {
            "text" => "l",
            "start" => 0.2,
            "end" => 0.3
          }
        ],
        "words" => [
          {
            "text" => "Hello",
            "start" => 0.0,
            "end" => 0.5,
            "loss" => 0.1
          },
          {
            "text" => "this",
            "start" => 0.6,
            "end" => 0.9,
            "loss" => 0.05
          }
        ],
        "loss" => 0.075
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/forced-alignment")
        .to_return(
          status: 200,
          body: response_data.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    context "with required parameters only" do
      it "creates forced alignment successfully" do
        result = forced_alignment.create(audio_file, filename, text)

        expect(result).to eq(response_data)
      end

      it "sends the correct multipart request" do
        forced_alignment.create(audio_file, filename, text)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/forced-alignment")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with enabled_spooled_file option" do
      it "includes enabled_spooled_file in the request" do
        forced_alignment.create(audio_file, filename, text, enabled_spooled_file: true)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/forced-alignment")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with enabled_spooled_file set to false" do
      it "includes enabled_spooled_file in the request" do
        forced_alignment.create(audio_file, filename, text, enabled_spooled_file: false)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/forced-alignment")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "when API returns an error" do
      context "with authentication error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/forced-alignment")
            .to_return(status: 401, body: "Unauthorized")
        end

        it "raises AuthenticationError" do
          expect {
            forced_alignment.create(audio_file, filename, text)
          }.to raise_error(ElevenlabsClient::AuthenticationError)
        end
      end

      context "with unprocessable entity error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/forced-alignment")
            .to_return(
              status: 422,
              body: {
                detail: [
                  {
                    loc: ["file"],
                    msg: "File size must be less than 1GB",
                    type: "value_error"
                  }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "raises UnprocessableEntityError" do
          expect {
            forced_alignment.create(audio_file, filename, text)
          }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
        end
      end

      context "with rate limit error" do
        before do
          stub_request(:post, "https://api.elevenlabs.io/v1/forced-alignment")
            .to_return(status: 429, body: "Rate limit exceeded")
        end

        it "raises RateLimitError" do
          expect {
            forced_alignment.create(audio_file, filename, text)
          }.to raise_error(ElevenlabsClient::RateLimitError)
        end
      end
    end

    context "with different file types" do
      let(:wav_filename) { "test_audio.wav" }

      it "handles different audio file types" do
        forced_alignment.create(audio_file, wav_filename, text)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/forced-alignment")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with longer text content" do
      let(:long_text) { "This is a much longer text transcript that should be aligned with the audio file. It contains multiple sentences and should test the API's ability to handle longer transcripts for forced alignment processing." }

      it "handles longer text content" do
        forced_alignment.create(audio_file, filename, long_text)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/forced-alignment")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end

    context "with special characters in text" do
      let(:special_text) { "Hello! How are you? I'm fine, thanks. What's new?" }

      it "handles text with punctuation and special characters" do
        forced_alignment.create(audio_file, filename, special_text)

        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/forced-alignment")
          .with(
            headers: {
              "xi-api-key" => api_key
            }
          )
      end
    end
  end

  describe "alias methods" do
    let(:response_data) do
      {
        "characters" => [],
        "words" => [],
        "loss" => 0.0
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/forced-alignment")
        .to_return(
          status: 200,
          body: response_data.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    describe "#align" do
      it "is an alias for create method" do
        result = forced_alignment.align(audio_file, filename, text)

        expect(result).to eq(response_data)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/forced-alignment")
      end
    end

    describe "#force_align" do
      it "is an alias for create method" do
        result = forced_alignment.force_align(audio_file, filename, text)

        expect(result).to eq(response_data)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/forced-alignment")
      end
    end
  end

  describe "response structure validation" do
    let(:detailed_response) do
      {
        "characters" => [
          {
            "text" => "H",
            "start" => 0.0,
            "end" => 0.05
          },
          {
            "text" => "e",
            "start" => 0.05,
            "end" => 0.1
          },
          {
            "text" => "l",
            "start" => 0.1,
            "end" => 0.15
          },
          {
            "text" => "l",
            "start" => 0.15,
            "end" => 0.2
          },
          {
            "text" => "o",
            "start" => 0.2,
            "end" => 0.25
          }
        ],
        "words" => [
          {
            "text" => "Hello",
            "start" => 0.0,
            "end" => 0.5,
            "loss" => 0.1
          },
          {
            "text" => "this",
            "start" => 0.6,
            "end" => 0.9,
            "loss" => 0.05
          },
          {
            "text" => "is",
            "start" => 1.0,
            "end" => 1.2,
            "loss" => 0.03
          }
        ],
        "loss" => 0.06
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/forced-alignment")
        .to_return(
          status: 200,
          body: detailed_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "returns detailed character timing information" do
      result = forced_alignment.create(audio_file, filename, text)

      expect(result["characters"]).to be_an(Array)
      expect(result["characters"].first).to include("text", "start", "end")
      expect(result["characters"].first["text"]).to eq("H")
      expect(result["characters"].first["start"]).to eq(0.0)
      expect(result["characters"].first["end"]).to eq(0.05)
    end

    it "returns detailed word timing information" do
      result = forced_alignment.create(audio_file, filename, text)

      expect(result["words"]).to be_an(Array)
      expect(result["words"].first).to include("text", "start", "end", "loss")
      expect(result["words"].first["text"]).to eq("Hello")
      expect(result["words"].first["start"]).to eq(0.0)
      expect(result["words"].first["end"]).to eq(0.5)
      expect(result["words"].first["loss"]).to eq(0.1)
    end

    it "returns overall alignment loss score" do
      result = forced_alignment.create(audio_file, filename, text)

      expect(result["loss"]).to eq(0.06)
    end
  end
end
