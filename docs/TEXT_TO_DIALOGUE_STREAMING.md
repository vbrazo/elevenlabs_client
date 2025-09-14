# Text-to-Dialogue Streaming

This document explains how to use the Text-to-Dialogue streaming endpoint with the `elevenlabs_client` gem.

## Overview

- Endpoint: `POST /v1/text-to-dialogue/stream`
- Streams audio for a sequence of dialogue inputs (text + voice_id pairs)
- Supports model selection, language enforcement, pronunciation dictionaries, settings, seeding, and text normalization

## Basic Usage

```ruby
require 'elevenlabs_client'

client = ElevenlabsClient::Client.new(api_key: ENV['ELEVENLABS_API_KEY'])

inputs = [
  { text: "Knock knock", voice_id: "JBFqnCBsd6RMkjVDRZzb" },
  { text: "Who is there?", voice_id: "Aw4FAjKCGjjNkVhN1Xmq" }
]

# Stream dialogue as audio (default mp3_44100_128)
streamed_chunks = []
client.text_to_dialogue_stream.stream(inputs) do |chunk|
  streamed_chunks << chunk
end

File.binwrite("dialogue_stream.mp3", streamed_chunks.join)
```

## Options

```ruby
client.text_to_dialogue_stream.stream(
  inputs,
  model_id: "eleven_v3",
  language_code: "en",
  settings: { style: 0.6 },
  pronunciation_dictionary_locators: [{ id: "dict_1", version_id: "v1" }],
  seed: 123,
  apply_text_normalization: "auto",
  output_format: "pcm_16000"
) { |chunk| handle_chunk(chunk) }
```

- **output_format**: e.g. `mp3_44100_128` (default), `pcm_16000`, etc.
- **model_id**: defaults to `eleven_v3`
- **language_code**: ISO 639-1, enforces language for normalization
- **settings**: Hash of dialogue generation settings
- **pronunciation_dictionary_locators**: up to 3 `{ id, version_id }`
- **seed**: 0..4294967295, best-effort determinism
- **apply_text_normalization**: `auto` (default), `on`, or `off`

## Error Handling

```ruby
begin
  client.text_to_dialogue_stream.stream(inputs) { |chunk| process(chunk) }
rescue ElevenlabsClient::AuthenticationError
  # invalid API key
rescue ElevenlabsClient::RateLimitError
  # backoff and retry
rescue ElevenlabsClient::UnprocessableEntityError => e
  # invalid inputs/settings
end
```

## Rails Controller Example

```ruby
class DialogueStreamsController < ApplicationController
  def create
    inputs = params.require(:inputs)

    response.headers['Content-Type'] = 'audio/mpeg'
    response.headers['Cache-Control'] = 'no-cache'

    client = ElevenlabsClient::Client.new
    client.text_to_dialogue_stream.stream(inputs, output_format: 'mp3_44100_128') do |chunk|
      response.stream.write(chunk)
    end
  ensure
    response.stream.close
  end
end
```

## Notes

- Streaming yields raw audio chunks; concatenate or stream to a client as needed.
- For non-streaming dialogue generation, use `TextToDialogue#convert`.
