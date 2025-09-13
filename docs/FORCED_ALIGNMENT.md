# Forced Alignment

The Forced Alignment endpoint allows you to align audio files with text transcripts, providing precise timing information for each character and word in the audio. This is useful for creating subtitles, analyzing speech patterns, or synchronizing text with audio.

## Usage

### Basic Forced Alignment

```ruby
require 'elevenlabs_client'

# Initialize the client
client = ElevenlabsClient.new(api_key: "your_api_key")

# Open an audio file
audio_file = File.open("path/to/your/audio.wav", "rb")

# Text transcript that matches the audio
transcript = "Hello, welcome to our application. How can we help you today?"

# Create forced alignment
alignment = client.forced_alignment.create(audio_file, "audio.wav", transcript)

# Access timing information
alignment['words'].each do |word|
  puts "Word: '#{word['text']}' from #{word['start']}s to #{word['end']}s (confidence: #{1 - word['loss']})"
end

alignment['characters'].each do |char|
  puts "Character: '#{char['text']}' from #{char['start']}s to #{char['end']}s"
end

puts "Overall alignment confidence: #{1 - alignment['loss']}"

audio_file.close
```

### Forced Alignment with Spooled File Processing

For large audio files (approaching 1GB), use the spooled file option for better memory management:

```ruby
large_audio = File.open("large_recording.wav", "rb")

alignment = client.forced_alignment.create(
  large_audio,
  "large_recording.wav",
  transcript,
  enabled_spooled_file: true
)

large_audio.close
```

### Using Alias Methods

```ruby
# Using the 'align' alias
alignment = client.forced_alignment.align(audio_file, "audio.wav", transcript)

# Using the 'force_align' alias
alignment = client.forced_alignment.force_align(audio_file, "audio.wav", transcript)
```

## Parameters

### `create(audio_file, filename, text, **options)`

- **audio_file** (IO, File, required): The audio file to align (must be less than 1GB)
- **filename** (String, required): Original filename for the audio file
- **text** (String, required): The text transcript to align with the audio
- **options** (Hash, optional):
  - **enabled_spooled_file** (Boolean): Stream file in chunks for large files (default: false)

### Alias Methods

- `align(audio_file, filename, text, **options)` - Alias for `create`
- `force_align(audio_file, filename, text, **options)` - Alias for `create`

## Response Format

The forced alignment response contains detailed timing information:

```ruby
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
    }
    # ... more characters
  ],
  "words" => [
    {
      "text" => "Hello",
      "start" => 0.0,
      "end" => 0.5,
      "loss" => 0.1
    },
    {
      "text" => "welcome",
      "start" => 0.6,
      "end" => 1.2,
      "loss" => 0.05
    }
    # ... more words
  ],
  "loss" => 0.075
}
```

### Response Fields

- **characters**: Array of character-level timing information
  - **text**: The character
  - **start**: Start time in seconds
  - **end**: End time in seconds

- **words**: Array of word-level timing information
  - **text**: The word
  - **start**: Start time in seconds
  - **end**: End time in seconds
  - **loss**: Alignment confidence score (lower is better)

- **loss**: Overall alignment confidence score for the entire transcript

## Practical Examples

### Creating Subtitles

```ruby
def create_subtitles(audio_file_path, transcript)
  audio_file = File.open(audio_file_path, "rb")
  
  alignment = client.forced_alignment.create(
    audio_file, 
    File.basename(audio_file_path), 
    transcript
  )
  
  # Generate SRT format subtitles
  subtitles = []
  alignment['words'].each_with_index do |word, index|
    start_time = format_time(word['start'])
    end_time = format_time(word['end'])
    
    subtitles << "#{index + 1}"
    subtitles << "#{start_time} --> #{end_time}"
    subtitles << word['text']
    subtitles << ""
  end
  
  audio_file.close
  subtitles.join("\n")
end

def format_time(seconds)
  hours = (seconds / 3600).to_i
  minutes = ((seconds % 3600) / 60).to_i
  secs = (seconds % 60)
  millisecs = ((secs - secs.to_i) * 1000).to_i
  
  sprintf("%02d:%02d:%02d,%03d", hours, minutes, secs.to_i, millisecs)
end
```

### Analyzing Speech Patterns

```ruby
def analyze_speech_timing(audio_file_path, transcript)
  audio_file = File.open(audio_file_path, "rb")
  
  alignment = client.forced_alignment.create(
    audio_file, 
    File.basename(audio_file_path), 
    transcript
  )
  
  # Calculate speaking rate (words per minute)
  total_duration = alignment['words'].last['end'] - alignment['words'].first['start']
  word_count = alignment['words'].length
  wpm = (word_count / total_duration) * 60
  
  # Find pauses between words
  pauses = []
  alignment['words'].each_cons(2) do |current_word, next_word|
    pause_duration = next_word['start'] - current_word['end']
    if pause_duration > 0.1  # Pauses longer than 100ms
      pauses << {
        after_word: current_word['text'],
        duration: pause_duration,
        start_time: current_word['end']
      }
    end
  end
  
  audio_file.close
  
  {
    speaking_rate_wpm: wpm.round(2),
    total_duration: total_duration.round(2),
    word_count: word_count,
    pauses: pauses,
    average_confidence: (1 - alignment['loss']).round(3)
  }
end
```

### Synchronizing Text Highlights

```ruby
def create_text_sync_data(audio_file_path, transcript)
  audio_file = File.open(audio_file_path, "rb")
  
  alignment = client.forced_alignment.create(
    audio_file, 
    File.basename(audio_file_path), 
    transcript
  )
  
  # Create data for real-time text highlighting
  sync_data = alignment['words'].map do |word|
    {
      text: word['text'],
      start: (word['start'] * 1000).to_i,  # Convert to milliseconds
      end: (word['end'] * 1000).to_i,
      confidence: (1 - word['loss']).round(3)
    }
  end
  
  audio_file.close
  sync_data
end
```

## Error Handling

```ruby
begin
  alignment = client.forced_alignment.create(audio_file, filename, transcript)
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Invalid file or transcript: #{e.message}"
rescue ElevenlabsClient::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## File Requirements

### Audio File Requirements
- **Size**: Must be less than 1GB
- **Formats**: Supports all major audio formats (MP3, WAV, FLAC, M4A, etc.)
- **Quality**: Higher quality audio produces better alignment results
- **Language**: Works with various languages, but accuracy may vary

### Text Requirements
- **Accuracy**: Text should closely match the spoken content in the audio
- **Format**: Plain text format (punctuation is handled automatically)
- **Length**: Should correspond to the audio duration
- **Diarization**: Not currently supported (single speaker assumed)

## Best Practices

1. **Audio Quality**:
   - Use clear, high-quality audio recordings
   - Minimize background noise
   - Ensure consistent volume levels

2. **Transcript Accuracy**:
   - Ensure the transcript closely matches the spoken words
   - Include all spoken words, but punctuation is optional
   - Remove filler words if they're not clearly audible

3. **File Size Management**:
   - For files approaching 1GB, use `enabled_spooled_file: true`
   - Consider splitting very long audio files for better processing

4. **Confidence Scores**:
   - Lower loss values indicate better alignment confidence
   - Word-level loss scores help identify problematic sections
   - Overall loss score indicates transcript-audio match quality

5. **Performance Optimization**:
   - Process audio files in appropriate chunks for your use case
   - Cache alignment results for repeated use
   - Consider preprocessing audio for optimal quality

## Common Use Cases

### Podcast Transcription with Timestamps
```ruby
podcast_file = File.open("podcast_episode.mp3", "rb")
transcript = "Welcome to our podcast. Today we're discussing..."

alignment = client.forced_alignment.create(
  podcast_file, 
  "podcast_episode.mp3", 
  transcript
)

# Generate timestamped transcript
timestamped_transcript = alignment['words'].map do |word|
  timestamp = Time.at(word['start']).utc.strftime("%M:%S")
  "[#{timestamp}] #{word['text']}"
end.join(" ")

podcast_file.close
```

### Educational Content Synchronization
```ruby
lecture_file = File.open("lecture.wav", "rb")
lecture_script = "Today's lesson covers the fundamentals of..."

alignment = client.forced_alignment.create(
  lecture_file, 
  "lecture.wav", 
  lecture_script
)

# Create chapter markers
chapters = []
current_chapter = nil

alignment['words'].each do |word|
  if word['text'].downcase.include?('chapter') || word['text'].downcase.include?('section')
    if current_chapter
      current_chapter[:end_time] = word['start']
      chapters << current_chapter
    end
    current_chapter = {
      title: word['text'],
      start_time: word['start'],
      end_time: nil
    }
  end
end

lecture_file.close
```

## Rate Limits

Forced alignment requests are subject to API rate limits. The processing time depends on audio file size and complexity. Implement appropriate retry logic and respect rate limit headers in production applications.
