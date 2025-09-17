# Conversations Management

The conversations endpoints allow you to manage and interact with agent conversations.

## Usage

```ruby
require 'elevenlabs_client'

client = ElevenlabsClient::Client.new(api_key: "your-api-key")
conversations = client.conversations
```

## Available Methods

### List Conversations

Returns a list of conversations for agents you own.

```ruby
# List all conversations
conversations = client.conversations.list

# List with filters
conversations = client.conversations.list(
  agent_id: "agent_id_here",
  page_size: 20,
  call_successful: "success",
  summary_mode: "include"
)

conversations["conversations"].each do |conv|
  puts "#{conv['conversation_id']}: #{conv['agent_name']} - #{conv['status']}"
end
```

### Get Conversation Details

Retrieves detailed information about a specific conversation.

```ruby
conversation = client.conversations.get("conversation_id_here")

puts "Agent: #{conversation['agent_id']}"
puts "Status: #{conversation['status']}"
puts "Duration: #{conversation['metadata']['call_duration_secs']} seconds"

# View transcript
conversation["transcript"].each do |turn|
  puts "#{turn['role']}: #{turn['message']}"
end
```

### Delete Conversation

Permanently deletes a conversation.

```ruby
client.conversations.delete("conversation_id_here")
```

### Get Conversation Audio

Downloads the audio recording of a conversation.

```ruby
audio_data = client.conversations.get_audio("conversation_id_here")

# Save to file
File.open("conversation.mp3", "wb") do |file|
  file.write(audio_data)
end
```

### Get Signed URL

Gets a signed URL to start a conversation with an agent that requires authorization.

```ruby
signed_url_info = client.conversations.get_signed_url(
  "agent_id_here",
  include_conversation_id: true
)

puts "Conversation URL: #{signed_url_info['signed_url']}"
```

### Get WebRTC Token

Gets a WebRTC session token for real-time communication.

```ruby
token_info = client.conversations.get_token(
  "agent_id_here",
  participant_name: "Customer Support Session"
)

puts "WebRTC Token: #{token_info['token']}"
```

### Send Conversation Feedback

Provides feedback (like/dislike) for a conversation.

```ruby
# Like the conversation
client.conversations.send_feedback("conversation_id_here", "like")

# Dislike the conversation
client.conversations.send_feedback("conversation_id_here", "dislike")
```

## Examples

### Monitoring Conversation Quality

```ruby
# Get recent conversations for an agent
conversations = client.conversations.list(
  agent_id: "agent_id_here",
  page_size: 50,
  call_start_after_unix: Time.now.to_i - 86400  # Last 24 hours
)

# Calculate success rate
total_conversations = conversations["conversations"].length
successful_conversations = conversations["conversations"].count do |conv|
  conv["call_successful"] == "success"
end

success_rate = (successful_conversations.to_f / total_conversations * 100).round(1)

puts "Success Rate: #{success_rate}%"
puts "Total Conversations: #{total_conversations}"
puts "Successful: #{successful_conversations}"
```

### Downloading Conversation Audio

```ruby
conversations = client.conversations.list(agent_id: "agent_id_here")

conversations["conversations"].each do |conv|
  conversation_id = conv["conversation_id"]
  
  # Download audio
  audio_data = client.conversations.get_audio(conversation_id)
  
  # Save with timestamp
  timestamp = Time.at(conv["call_start_time_unix_secs"]).strftime("%Y%m%d_%H%M%S")
  filename = "conversation_#{timestamp}_#{conversation_id}.mp3"
  
  File.open(filename, "wb") do |file|
    file.write(audio_data)
  end
  
  puts "Saved: #{filename}"
end
```

### Real-time Conversation Setup

```ruby
# Get WebRTC token for real-time conversation
token_info = client.conversations.get_token(
  "agent_id_here",
  participant_name: "Live Customer Session"
)

puts "WebRTC Configuration:"
puts "Token: #{token_info['token']}"
puts "Room: #{token_info['room_name']}"
puts "Participant: #{token_info['participant_name']}"

# Token can be used with WebRTC clients to establish real-time audio/video calls
```

### Conversation Analytics

```ruby
# Analyze conversation patterns
conversations = client.conversations.list(
  agent_id: "agent_id_here",
  page_size: 100
)

# Group by time of day
hourly_distribution = Hash.new(0)
conversations["conversations"].each do |conv|
  hour = Time.at(conv["call_start_time_unix_secs"]).hour
  hourly_distribution[hour] += 1
end

puts "📊 Hourly Distribution:"
hourly_distribution.sort.each do |hour, count|
  puts "#{hour}:00 - #{count} conversations"
end

# Average duration
durations = conversations["conversations"].map do |conv|
  conv["metadata"]["call_duration_secs"] || 0
end

avg_duration = durations.sum / durations.length.to_f
puts "Average Duration: #{avg_duration.round(1)} seconds"

# Success patterns
success_by_duration = conversations["conversations"].group_by do |conv|
  duration = conv["metadata"]["call_duration_secs"] || 0
  case duration
  when 0..30 then "0-30s"
  when 31..120 then "30s-2m"
  when 121..300 then "2m-5m"
  else "5m+"
  end
end

puts "\n📈 Success by Duration:"
success_by_duration.each do |duration_range, convs|
  successful = convs.count { |c| c["call_successful"] == "success" }
  total = convs.length
  rate = (successful.to_f / total * 100).round(1)
  puts "#{duration_range}: #{rate}% (#{successful}/#{total})"
end
```

## Error Handling

```ruby
begin
  conversation = client.conversations.get("conversation_id")
rescue ElevenlabsClient::NotFoundError
  puts "Conversation not found"
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## API Reference

For detailed API documentation, visit: [ElevenLabs Conversations API Reference](https://elevenlabs.io/docs/api-reference/convai/conversations)
