# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Forced Alignment Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:audio_file) { StringIO.new("fake_audio_data") }
  let(:filename) { "test_audio.mp3" }
  let(:text) { "Hello, this is a test transcript for forced alignment." }

  describe "client.forced_alignment accessor" do
    it "provides access to forced_alignment endpoint" do
      expect(client.forced_alignment).to be_an_instance_of(ElevenlabsClient::ForcedAlignment)
    end
  end

  describe "forced alignment functionality via client" do
    let(:alignment_response) do
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
          body: alignment_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates forced alignment through client interface" do
      result = client.forced_alignment.create(audio_file, filename, text)

      expect(result).to eq(alignment_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/forced-alignment")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end

    it "supports the align alias method" do
      result = client.forced_alignment.align(audio_file, filename, text)

      expect(result).to eq(alignment_response)
    end

    it "supports the force_align alias method" do
      result = client.forced_alignment.force_align(audio_file, filename, text)

      expect(result).to eq(alignment_response)
    end

    it "supports enabled_spooled_file option" do
      result = client.forced_alignment.create(audio_file, filename, text, enabled_spooled_file: true)

      expect(result).to eq(alignment_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/forced-alignment")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end
  end

  describe "response structure handling" do
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
      result = client.forced_alignment.create(audio_file, filename, text)

      expect(result["characters"]).to be_an(Array)
      expect(result["characters"].length).to eq(5)
      
      first_char = result["characters"].first
      expect(first_char).to include("text", "start", "end")
      expect(first_char["text"]).to eq("H")
      expect(first_char["start"]).to eq(0.0)
      expect(first_char["end"]).to eq(0.05)
    end

    it "returns detailed word timing information" do
      result = client.forced_alignment.create(audio_file, filename, text)

      expect(result["words"]).to be_an(Array)
      expect(result["words"].length).to eq(3)
      
      first_word = result["words"].first
      expect(first_word).to include("text", "start", "end", "loss")
      expect(first_word["text"]).to eq("Hello")
      expect(first_word["start"]).to eq(0.0)
      expect(first_word["end"]).to eq(0.5)
      expect(first_word["loss"]).to eq(0.1)
    end

    it "returns overall alignment loss score" do
      result = client.forced_alignment.create(audio_file, filename, text)

      expect(result["loss"]).to eq(0.06)
    end
  end

  describe "multipart file handling" do
    let(:file_content) { "binary_audio_content_here" }
    let(:test_file) { StringIO.new(file_content) }
    let(:alignment_response) do
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
          body: alignment_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "properly handles file uploads in multipart requests" do
      result = client.forced_alignment.create(test_file, "test.mp3", text)

      expect(result).to eq(alignment_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/forced-alignment")
    end

    it "handles different audio file extensions" do
      %w[mp3 wav flac m4a].each do |ext|
        client.forced_alignment.create(test_file, "test.#{ext}", text)
      end
      
      # Expect 4 requests total (one for each file extension)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/forced-alignment").times(4)
    end
  end

  describe "error handling integration" do
    context "with authentication error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/forced-alignment")
          .to_return(status: 401, body: "Unauthorized")
      end

      it "raises AuthenticationError through client" do
        expect {
          client.forced_alignment.create(audio_file, filename, text)
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

      it "raises UnprocessableEntityError through client" do
        expect {
          client.forced_alignment.create(audio_file, filename, text)
        }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end

    context "with rate limit error" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/forced-alignment")
          .to_return(status: 429, body: "Rate limit exceeded")
      end

      it "raises RateLimitError through client" do
        expect {
          client.forced_alignment.create(audio_file, filename, text)
        }.to raise_error(ElevenlabsClient::RateLimitError)
      end
    end
  end

  describe "Settings integration" do
    after do
      ElevenlabsClient::Settings.reset!
    end

    context "when Settings are configured" do
      let(:alignment_response) do
        {
          "characters" => [],
          "words" => [],
          "loss" => 0.0
        }
      end

      before do
        ElevenlabsClient.configure do |config|
          config.properties = {
            elevenlabs_base_uri: "https://configured.elevenlabs.io",
            elevenlabs_api_key: "configured_api_key"
          }
        end

        stub_request(:post, "https://configured.elevenlabs.io/v1/forced-alignment")
          .to_return(
            status: 200,
            body: alignment_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "uses configured settings for forced alignment requests" do
        client = ElevenlabsClient.new
        result = client.forced_alignment.create(audio_file, filename, text)

        expect(result).to eq(alignment_response)
        expect(WebMock).to have_requested(:post, "https://configured.elevenlabs.io/v1/forced-alignment")
          .with(headers: { "xi-api-key" => "configured_api_key" })
      end
    end
  end

  describe "Rails usage example" do
    let(:alignment_response) do
      {
        "characters" => [
          {
            "text" => "W",
            "start" => 0.0,
            "end" => 0.1
          }
        ],
        "words" => [
          {
            "text" => "Welcome",
            "start" => 0.0,
            "end" => 0.8,
            "loss" => 0.05
          }
        ],
        "loss" => 0.05
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/forced-alignment")
        .to_return(
          status: 200,
          body: alignment_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "works as expected in a Rails-like environment" do
      # This simulates typical Rails usage
      client = ElevenlabsClient.new(api_key: api_key)
      
      # Force align audio with transcript
      alignment = client.forced_alignment.create(
        audio_file,
        "welcome_message.wav",
        "Welcome to our application!",
        enabled_spooled_file: false
      )

      expect(alignment["words"]).to be_an(Array)
      expect(alignment["characters"]).to be_an(Array)
      expect(alignment["loss"]).to be_a(Numeric)
      
      # Verify the alignment data structure
      expect(alignment["words"].first["text"]).to eq("Welcome")
      expect(alignment["words"].first["start"]).to be_a(Numeric)
      expect(alignment["words"].first["end"]).to be_a(Numeric)
      expect(alignment["words"].first["loss"]).to be_a(Numeric)

      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/forced-alignment")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end
  end

  describe "large file handling" do
    let(:large_audio_file) { StringIO.new("large_audio_content" * 1000) }
    let(:long_transcript) { "This is a very long transcript that would be used with a large audio file for forced alignment processing." * 10 }
    let(:alignment_response) do
      {
        "characters" => [],
        "words" => [],
        "loss" => 0.1
      }
    end

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/forced-alignment")
        .to_return(
          status: 200,
          body: alignment_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "handles large files with spooled file option" do
      result = client.forced_alignment.create(
        large_audio_file,
        "large_audio.wav",
        long_transcript,
        enabled_spooled_file: true
      )

      expect(result).to eq(alignment_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/forced-alignment")
        .with(
          headers: { "xi-api-key" => api_key }
        )
    end
  end

  describe "text format handling" do
    let(:alignment_response) do
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
          body: alignment_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "handles text with punctuation" do
      punctuated_text = "Hello! How are you? I'm fine, thanks. What's new?"
      
      result = client.forced_alignment.create(audio_file, filename, punctuated_text)

      expect(result).to eq(alignment_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/forced-alignment")
    end

    it "handles text with numbers and special characters" do
      special_text = "The price is $29.99, and the code is ABC-123!"
      
      result = client.forced_alignment.create(audio_file, filename, special_text)

      expect(result).to eq(alignment_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/forced-alignment")
    end

    it "handles multi-paragraph text" do
      multi_paragraph_text = "This is the first paragraph.\n\nThis is the second paragraph with more content."
      
      result = client.forced_alignment.create(audio_file, filename, multi_paragraph_text)

      expect(result).to eq(alignment_response)
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/forced-alignment")
    end
  end
end
