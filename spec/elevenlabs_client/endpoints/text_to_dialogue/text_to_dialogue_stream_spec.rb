# frozen_string_literal: true

RSpec.describe "TextToDialogue#stream" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:dialogue_stream) { ElevenlabsClient::TextToDialogue.new(client) }
  let(:inputs) do
    [
      { text: "Knock knock", voice_id: "JBFqnCBsd6RMkjVDRZzb" },
      { text: "Who is there?", voice_id: "Aw4FAjKCGjjNkVhN1Xmq" }
    ]
  end

  describe "#stream" do
    before do
      allow(client).to receive(:post_streaming).and_yield("chunk1").and_yield("chunk2")
    end

    it "streams audio chunks successfully" do
      chunks = []
      dialogue_stream.stream(inputs) { |chunk| chunks << chunk }
      expect(chunks).to eq(["chunk1", "chunk2"])
    end

    it "sends the correct request with default parameters" do
      expect(client).to receive(:post_streaming).with(
        "/v1/text-to-dialogue/stream?output_format=mp3_44100_128",
        { inputs: inputs }
      )

      dialogue_stream.stream(inputs) { |_| }
    end

    it "includes output_format in the URL when provided" do
      expect(client).to receive(:post_streaming).with(
        "/v1/text-to-dialogue/stream?output_format=pcm_16000",
        { inputs: inputs }
      )

      dialogue_stream.stream(inputs, output_format: "pcm_16000") { |_| }
    end

    it "includes model_id and language_code in the request body" do
      expect(client).to receive(:post_streaming).with(
        "/v1/text-to-dialogue/stream?output_format=mp3_44100_128",
        { inputs: inputs, model_id: "eleven_v3", language_code: "en" }
      )

      dialogue_stream.stream(inputs, model_id: "eleven_v3", language_code: "en") { |_| }
    end

    it "includes settings and seed in the request body" do
      settings = { style: 0.5 }
      expect(client).to receive(:post_streaming).with(
        "/v1/text-to-dialogue/stream?output_format=mp3_44100_128",
        { inputs: inputs, settings: settings, seed: 42 }
      )

      dialogue_stream.stream(inputs, settings: settings, seed: 42) { |_| }
    end

    it "includes pronunciation_dictionary_locators and apply_text_normalization" do
      locators = [{ id: "dict_1", version_id: "v1" }]
      expect(client).to receive(:post_streaming).with(
        "/v1/text-to-dialogue/stream?output_format=mp3_44100_128",
        { inputs: inputs, pronunciation_dictionary_locators: locators, apply_text_normalization: "auto" }
      )

      dialogue_stream.stream(inputs, pronunciation_dictionary_locators: locators, apply_text_normalization: "auto") { |_| }
    end

    it "works without a block" do
      allow(client).to receive(:post_streaming).and_return(double("Response", status: 200))

      expect {
        dialogue_stream.stream(inputs)
      }.not_to raise_error
    end
  end
end
