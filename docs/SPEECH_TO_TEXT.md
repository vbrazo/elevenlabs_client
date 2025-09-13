# Speech-to-Text

The Speech-to-Text endpoint allows you to transcribe audio and video files into text with advanced features like speaker diarization, timestamp granularity, multi-channel processing, and webhook support.

## Usage

### Basic Transcription

```ruby
require 'elevenlabs_client'

# Initialize the client
client = ElevenlabsClient.new(api_key: "your_api_key")

# Open an audio file
audio_file = File.open("path/to/audio.mp3", "rb")

# Transcribe the audio
transcription = client.speech_to_text.create("scribe_v1", file: audio_file, filename: "audio.mp3")

puts "Transcribed text: #{transcription['text']}"
puts "Language: #{transcription['language_code']}"
puts "Confidence: #{transcription['language_probability']}"

audio_file.close
```

### Transcription with Cloud Storage URL

```ruby
# Transcribe from cloud storage
transcription = client.speech_to_text.create(
  "scribe_v1",
  cloud_storage_url: "https://example.com/audio.mp3"
)
```

### Advanced Transcription with All Options

```ruby
audio_file = File.open("meeting_recording.wav", "rb")

transcription = client.speech_to_text.create(
  "scribe_v1",
  file: audio_file,
  filename: "meeting_recording.wav",
  language_code: "en",
  tag_audio_events: true,
  num_speakers: 3,
  timestamps_granularity: "character",
  diarize: true,
  diarization_threshold: 0.25,
  temperature: 0.0,
  seed: 12345,
  use_multi_channel: false,
  enable_logging: true
)

audio_file.close
```

### Retrieving Transcripts

```ruby
# Get a previously created transcript
transcript = client.speech_to_text.get_transcript("transcription_id_123")

puts "Full transcript: #{transcript['text']}"
puts "Word-level timing:"
transcript['words'].each do |word|
  puts "#{word['text']}: #{word['start']}s - #{word['end']}s (Speaker: #{word['speaker_id']})"
end
```

## Methods

### `create(model_id, **options)`

Creates a new transcription from an audio or video file.

**Parameters:**
- **model_id** (String, required): The transcription model to use

**File Input (choose one):**
- **file** (IO, File): The audio/video file to transcribe
- **filename** (String): Original filename (required if file provided)
- **cloud_storage_url** (String): HTTPS URL of file to transcribe

**Options:**
- **enable_logging** (Boolean): Enable logging (default: true)
- **language_code** (String): ISO-639-1 or ISO-639-3 language code
- **tag_audio_events** (Boolean): Tag audio events like (laughter) (default: true)
- **num_speakers** (Integer): Maximum number of speakers (1-32)
- **timestamps_granularity** (String): Timestamp level ("none", "word", "character")
- **diarize** (Boolean): Annotate which speaker is talking (default: false)
- **diarization_threshold** (Float): Diarization threshold (0.1-0.4)
- **additional_formats** (Array): Additional export formats
- **file_format** (String): Input file format ("pcm_s16le_16" or "other")
- **webhook** (Boolean): Send result to webhook (default: false)
- **webhook_id** (String): Specific webhook ID
- **temperature** (Float): Randomness control (0.0-2.0)
- **seed** (Integer): Deterministic sampling seed (0-2147483647)
- **use_multi_channel** (Boolean): Multi-channel processing (default: false)
- **webhook_metadata** (String, Hash): Metadata for webhook

**Returns:** Hash with transcription result or webhook response

### `get_transcript(transcription_id)`

Retrieves a previously generated transcript by its ID.

**Parameters:**
- **transcription_id** (String, required): The unique ID of the transcript

**Returns:** Hash with detailed transcript data

## Models

### Available Models
- `"scribe_v1"` - Standard transcription model
- `"scribe_v1_experimental"` - Experimental model with latest features

Check the Models endpoint for current model availability and capabilities.

## Language Support

### Automatic Language Detection
```ruby
# Let the system detect the language automatically
transcription = client.speech_to_text.create(
  "scribe_v1",
  file: audio_file,
  filename: "audio.mp3"
  # language_code not specified - will be auto-detected
)

puts "Detected language: #{transcription['language_code']}"
puts "Confidence: #{transcription['language_probability']}"
```

### Explicit Language Setting
```ruby
# Specify the language for better accuracy
transcription = client.speech_to_text.create(
  "scribe_v1",
  file: audio_file,
  filename: "audio.mp3",
  language_code: "es"  # Spanish
)
```

## Speaker Diarization

Speaker diarization identifies and separates different speakers in the audio:

```ruby
# Enable speaker diarization
transcription = client.speech_to_text.create(
  "scribe_v1",
  file: audio_file,
  filename: "meeting.wav",
  diarize: true,
  num_speakers: 3,  # Expected number of speakers
  diarization_threshold: 0.22  # Sensitivity threshold
)

# Process results by speaker
speakers = {}
transcription['words'].each do |word|
  speaker_id = word['speaker_id']
  speakers[speaker_id] ||= []
  speakers[speaker_id] << word['text']
end

speakers.each do |speaker_id, words|
  puts "#{speaker_id}: #{words.join(' ')}"
end
```

### Diarization Threshold

- **Lower values (0.1-0.2)**: More speakers detected, higher chance of splitting one speaker
- **Higher values (0.3-0.4)**: Fewer speakers detected, higher chance of merging different speakers
- **Default**: 0.22 (balanced)

## Timestamp Granularity

Control the level of timing information returned:

### Word-Level Timestamps (Default)
```ruby
transcription = client.speech_to_text.create(
  "scribe_v1",
  file: audio_file,
  filename: "audio.mp3",
  timestamps_granularity: "word"
)

transcription['words'].each do |word|
  puts "#{word['text']}: #{word['start']}s - #{word['end']}s"
end
```

### Character-Level Timestamps
```ruby
transcription = client.speech_to_text.create(
  "scribe_v1",
  file: audio_file,
  filename: "audio.mp3",
  timestamps_granularity: "character"
)

transcription['words'].each do |word|
  puts "Word: #{word['text']}"
  word['characters'].each do |char|
    puts "  #{char['text']}: #{char['start']}s - #{char['end']}s"
  end
end
```

### No Timestamps
```ruby
transcription = client.speech_to_text.create(
  "scribe_v1",
  file: audio_file,
  filename: "audio.mp3",
  timestamps_granularity: "none"
)

# Only text will be available, no timing information
puts transcription['text']
```

## Multi-Channel Processing

Process audio files with multiple channels (up to 5 channels):

```ruby
# Enable multi-channel processing
transcription = client.speech_to_text.create(
  "scribe_v1",
  file: stereo_audio_file,
  filename: "stereo_recording.wav",
  use_multi_channel: true
)

# Results will include channel information
transcription['transcripts'].each_with_index do |channel_transcript, index|
  puts "Channel #{index}: #{channel_transcript['text']}"
end

# Word-level channel information
transcription['words'].each do |word|
  puts "#{word['text']} (Channel #{word['channel_index']})"
end
```

## Audio Events Tagging

Tag non-speech audio events in the transcription:

```ruby
# Enable audio event tagging (default: true)
transcription = client.speech_to_text.create(
  "scribe_v1",
  file: audio_file,
  filename: "podcast.mp3",
  tag_audio_events: true
)

# Events like (laughter), (applause), (music) will be included in the text
puts transcription['text']
# Output: "Welcome to the show (music) today we're discussing (laughter) artificial intelligence"
```

## Additional Export Formats

Export transcriptions in multiple formats:

```ruby
additional_formats = [
  {
    "requested_format" => "srt",
    "file_extension" => "srt", 
    "content_type" => "text/plain"
  },
  {
    "requested_format" => "vtt",
    "file_extension" => "vtt",
    "content_type" => "text/vtt"
  },
  {
    "requested_format" => "txt",
    "file_extension" => "txt",
    "content_type" => "text/plain"
  }
]

transcription = client.speech_to_text.create(
  "scribe_v1",
  file: audio_file,
  filename: "video.mp4",
  additional_formats: additional_formats
)

# Access the additional formats
transcription['additional_formats'].each do |format|
  puts "Format: #{format['requested_format']}"
  puts "Content: #{format['content']}"
  
  # Save to file
  File.write("transcript.#{format['file_extension']}", format['content'])
end
```

## Webhook Processing

Process transcriptions asynchronously using webhooks:

```ruby
# Submit for webhook processing
webhook_response = client.speech_to_text.create(
  "scribe_v1",
  file: large_audio_file,
  filename: "long_recording.wav",
  webhook: true,
  webhook_id: "my_webhook_123",
  webhook_metadata: {
    job_id: "job_456",
    user_id: "user_789",
    priority: "high"
  }
)

puts "Transcription ID: #{webhook_response['transcription_id']}"
puts "Status: #{webhook_response['status']}"

# Later, retrieve the completed transcription
completed_transcript = client.speech_to_text.get_transcript(webhook_response['transcription_id'])
```

### Webhook Metadata

Webhook metadata can be provided as a Hash or JSON string:

```ruby
# As Hash (will be converted to JSON)
metadata_hash = {
  job_id: "123",
  user_id: "456",
  callback_url: "https://myapp.com/webhook"
}

# As JSON string
metadata_json = '{"job_id": "123", "user_id": "456"}'

transcription = client.speech_to_text.create(
  "scribe_v1",
  file: audio_file,
  filename: "audio.mp3",
  webhook: true,
  webhook_metadata: metadata_hash  # or metadata_json
)
```

## File Format Optimization

### PCM Format for Lower Latency
```ruby
# Use PCM format for faster processing
transcription = client.speech_to_text.create(
  "scribe_v1",
  file: pcm_audio_file,
  filename: "audio.wav",
  file_format: "pcm_s16le_16"  # 16-bit PCM, 16kHz, mono, little-endian
)
```

### Other Formats (Default)
```ruby
# Standard format for all other audio/video files
transcription = client.speech_to_text.create(
  "scribe_v1",
  file: audio_file,
  filename: "audio.mp3",
  file_format: "other"  # Default - supports MP3, WAV, MP4, MOV, etc.
)
```

## Deterministic Transcription

For reproducible results, use temperature and seed:

```ruby
# Deterministic transcription
transcription = client.speech_to_text.create(
  "scribe_v1",
  file: audio_file,
  filename: "audio.mp3",
  temperature: 0.0,  # No randomness
  seed: 12345        # Fixed seed
)

# Running this multiple times with the same parameters should yield identical results
```

## Error Handling

```ruby
begin
  transcription = client.speech_to_text.create("scribe_v1", file: audio_file, filename: "audio.mp3")
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Invalid file or parameters: #{e.message}"
rescue ElevenlabsClient::NotFoundError => e
  puts "Transcript not found: #{e.message}"
rescue ElevenlabsClient::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Practical Examples

### Meeting Transcription with Speaker Identification
```ruby
def transcribe_meeting(audio_file_path)
  audio_file = File.open(audio_file_path, "rb")
  
  transcription = client.speech_to_text.create(
    "scribe_v1",
    file: audio_file,
    filename: File.basename(audio_file_path),
    diarize: true,
    num_speakers: 5,
    timestamps_granularity: "word",
    tag_audio_events: true,
    language_code: "en"
  )
  
  # Group by speaker
  speakers = {}
  transcription['words'].each do |word|
    speaker = word['speaker_id']
    speakers[speaker] ||= { words: [], start_time: word['start'] }
    speakers[speaker][:words] << word['text']
  end
  
  # Generate speaker-separated transcript
  speakers.each do |speaker_id, data|
    puts "#{speaker_id} (#{format_time(data[:start_time])}): #{data[:words].join(' ')}"
  end
  
  audio_file.close
end

def format_time(seconds)
  Time.at(seconds).utc.strftime("%M:%S")
end
```

### Podcast Transcription with Subtitles
```ruby
def create_podcast_subtitles(audio_file_path)
  audio_file = File.open(audio_file_path, "rb")
  
  transcription = client.speech_to_text.create(
    "scribe_v1",
    file: audio_file,
    filename: File.basename(audio_file_path),
    timestamps_granularity: "word",
    tag_audio_events: true,
    additional_formats: [
      {
        "requested_format" => "srt",
        "file_extension" => "srt",
        "content_type" => "text/plain"
      },
      {
        "requested_format" => "vtt",
        "file_extension" => "vtt", 
        "content_type" => "text/vtt"
      }
    ]
  )
  
  # Save subtitle files
  transcription['additional_formats'].each do |format|
    filename = "podcast.#{format['file_extension']}"
    File.write(filename, format['content'])
    puts "Saved #{filename}"
  end
  
  audio_file.close
end
```

### Multi-language Content Detection
```ruby
def detect_and_transcribe(audio_file_path)
  audio_file = File.open(audio_file_path, "rb")
  
  # First, transcribe without language specification
  transcription = client.speech_to_text.create(
    "scribe_v1",
    file: audio_file,
    filename: File.basename(audio_file_path),
    timestamps_granularity: "word"
  )
  
  detected_language = transcription['language_code']
  confidence = transcription['language_probability']
  
  puts "Detected language: #{detected_language} (confidence: #{confidence})"
  
  # If confidence is low, you might want to try with explicit language
  if confidence < 0.8
    puts "Low confidence, trying with explicit language setting..."
    
    audio_file.rewind
    transcription = client.speech_to_text.create(
      "scribe_v1",
      file: audio_file,
      filename: File.basename(audio_file_path),
      language_code: detected_language,
      timestamps_granularity: "word"
    )
  end
  
  puts "Final transcript: #{transcription['text']}"
  audio_file.close
end
```

### Batch Processing with Webhooks
```ruby
def batch_transcribe_files(file_paths)
  transcription_jobs = []
  
  file_paths.each_with_index do |file_path, index|
    audio_file = File.open(file_path, "rb")
    
    response = client.speech_to_text.create(
      "scribe_v1",
      file: audio_file,
      filename: File.basename(file_path),
      webhook: true,
      webhook_metadata: {
        batch_id: "batch_#{Time.now.to_i}",
        file_index: index,
        original_path: file_path
      }
    )
    
    transcription_jobs << {
      transcription_id: response['transcription_id'],
      file_path: file_path,
      status: response['status']
    }
    
    audio_file.close
    puts "Submitted #{file_path} for transcription (ID: #{response['transcription_id']})"
  end
  
  transcription_jobs
end

def check_transcription_status(transcription_jobs)
  transcription_jobs.each do |job|
    begin
      transcript = client.speech_to_text.get_transcript(job[:transcription_id])
      puts "#{job[:file_path]}: Completed"
      puts "Text: #{transcript['text'][0..100]}..."
    rescue ElevenlabsClient::NotFoundError
      puts "#{job[:file_path]}: Still processing..."
    end
  end
end
```

## Alias Methods

For convenience, the following alias methods are available:

```ruby
# Aliases for create
client.speech_to_text.transcribe(model_id, **options)

# Aliases for get_transcript
client.speech_to_text.get_transcription(transcription_id)
client.speech_to_text.retrieve_transcript(transcription_id)
```

## File Requirements

### Supported Formats
- **Audio**: MP3, WAV, FLAC, M4A, AAC, OGG
- **Video**: MP4, MOV, AVI, MKV, WEBM
- **Size Limit**: 3GB for file uploads, 2GB for cloud storage URLs
- **Duration**: No specific limit, but longer files take more time to process

### Optimization Tips
- **Quality**: Higher quality audio produces better transcriptions
- **Format**: Use uncompressed formats (WAV, FLAC) for best results
- **Sample Rate**: 16kHz or higher recommended
- **Channels**: Mono preferred, but stereo and multi-channel supported

## Response Format

### Single Channel Response
```json
{
  "language_code": "en",
  "language_probability": 0.98,
  "text": "Hello world!",
  "words": [
    {
      "text": "Hello",
      "start": 0.0,
      "end": 0.5,
      "type": "word",
      "speaker_id": "speaker_1",
      "logprob": -0.124
    }
  ]
}
```

### Multi-Channel Response
```json
{
  "transcripts": [
    {
      "language_code": "en",
      "text": "Channel 1 content",
      "channel_index": 0
    },
    {
      "language_code": "en",
      "text": "Channel 2 content", 
      "channel_index": 1
    }
  ]
}
```

### Webhook Response
```json
{
  "transcription_id": "transcription_123",
  "webhook_id": "webhook_456",
  "status": "processing"
}
```

## Rate Limits

Speech-to-text requests are subject to API rate limits. Processing time varies based on:
- File size and duration
- Model complexity
- Additional features (diarization, multi-channel)
- Current API load

Implement appropriate retry logic and respect rate limit headers in production applications.