# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Text-to-Dialogue Streaming Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:inputs) do
    [
      { text: "Knock knock", voice_id: "JBFqnCBsd6RMkjVDRZzb" },
      { text: "Who is there?", voice_id: "Aw4FAjKCGjjNkVhN1Xmq" }
    ]
  end

  describe "client.text_to_dialogue_stream accessor" do
    it "provides access to text_to_dialogue_stream endpoint" do
      expect(client.text_to_dialogue_stream).to be_an_instance_of(ElevenlabsClient::TextToDialogueStream)
    end
  end

  describe "streaming dialogue via client" do
    before do
      allow(client).to receive(:post_streaming) do |endpoint, body, &block|
        ["chunk1", "chunk2"].each { |ch| block.call(ch) } if block
        double("response", status: 200)
      end
    end

    it "streams audio and yields chunks" do
      chunks = []
      result = client.text_to_dialogue_stream.stream(inputs) { |c| chunks << c }
      expect(chunks).to eq(["chunk1", "chunk2"])
      expect(result.status).to eq(200)
      expect(client).to have_received(:post_streaming)
        .with("/v1/text-to-dialogue/stream?output_format=mp3_44100_128", { inputs: inputs })
    end

    it "supports options in body and query" do
      chunks = []
      client.text_to_dialogue_stream.stream(
        inputs,
        model_id: "eleven_v3",
        language_code: "en",
        settings: { style: 0.6 },
        pronunciation_dictionary_locators: [{ id: "dict_1", version_id: "v1" }],
        seed: 123,
        apply_text_normalization: "auto",
        output_format: "pcm_16000"
      ) { |c| chunks << c }

      expect(client).to have_received(:post_streaming)
        .with(
          "/v1/text-to-dialogue/stream?output_format=pcm_16000",
          {
            inputs: inputs,
            model_id: "eleven_v3",
            language_code: "en",
            settings: { style: 0.6 },
            pronunciation_dictionary_locators: [{ id: "dict_1", version_id: "v1" }],
            seed: 123,
            apply_text_normalization: "auto"
          }
        )
    end
  end

  describe "error handling integration" do
    it "propagates client errors" do
      allow(client).to receive(:post_streaming).and_raise(ElevenlabsClient::RateLimitError, "Rate limit exceeded")

      expect {
        client.text_to_dialogue_stream.stream(inputs) { |_| }
      }.to raise_error(ElevenlabsClient::RateLimitError, "Rate limit exceeded")
    end
  end
end


