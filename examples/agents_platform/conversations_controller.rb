# frozen_string_literal: true

# Example usage of ElevenLabs Agents Platform Conversations endpoints
# This file demonstrates how to use the conversations endpoints in a practical application

require 'elevenlabs_client'

class ConversationsController
  def initialize(api_key = nil)
    @client = ElevenlabsClient::Client.new(api_key: api_key)
  end

  # List conversations with various filtering options
  def list_conversations(agent_id: nil, limit: 20, call_status: nil)
    puts "Fetching conversations list..."
    
    options = { page_size: limit, summary_mode: "include" }
    options[:agent_id] = agent_id if agent_id
    options[:call_successful] = call_status if call_status
    
    response = @client.conversations.list(**options)
    conversations = response["conversations"]
    
    puts "\n📋 Found #{conversations.length} conversations:"
    conversations.each do |conv|
      puts "  • #{conv['conversation_id']}"
      puts "    Agent: #{conv['agent_name']} (#{conv['agent_id']})"
      puts "    Status: #{conv['status']} | Success: #{conv['call_successful']}"
      puts "    Duration: #{conv['call_duration_secs']}s | Messages: #{conv['message_count']}"
      puts "    Started: #{Time.at(conv['start_time_unix_secs']).strftime('%Y-%m-%d %H:%M:%S')}"
      puts "    Direction: #{conv['direction']}"
      
      if conv['transcript_summary']
        puts "    Summary: #{conv['transcript_summary']}"
      end
      
      if conv['call_summary_title']
        puts "    Title: #{conv['call_summary_title']}"
      end
      
      puts
    end
    
    if response["has_more"]
      puts "💡 More conversations available. Use cursor: #{response['next_cursor']}"
    end
    
    conversations
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching conversations: #{e.message}"
    []
  end

  # Get detailed conversation information
  def get_conversation_details(conversation_id)
    puts "Fetching details for conversation: #{conversation_id}"
    
    conversation = @client.conversations.get(conversation_id)
    
    puts "\n🗣️ Conversation Details:"
    puts "ID: #{conversation['conversation_id']}"
    puts "Agent: #{conversation['agent_id']}"
    puts "Status: #{conversation['status']}"
    puts "User ID: #{conversation['user_id']}"
    
    # Metadata
    metadata = conversation['metadata']
    puts "\n📊 Metadata:"
    puts "  Start Time: #{Time.at(metadata['start_time_unix_secs']).strftime('%Y-%m-%d %H:%M:%S')}"
    puts "  Duration: #{metadata['call_duration_secs']} seconds"
    puts "  Message Count: #{metadata['message_count']}"
    puts "  Direction: #{metadata['direction']}"
    puts "  Recording: #{metadata['recording_enabled'] ? 'Enabled' : 'Disabled'}"
    
    # Audio availability
    puts "\n🎵 Audio Status:"
    puts "  Has Audio: #{conversation['has_audio'] ? 'Yes' : 'No'}"
    puts "  Has User Audio: #{conversation['has_user_audio'] ? 'Yes' : 'No'}"
    puts "  Has Response Audio: #{conversation['has_response_audio'] ? 'Yes' : 'No'}"
    
    # Analysis if available
    if conversation['analysis']
      analysis = conversation['analysis']
      puts "\n📈 Analysis:"
      puts "  Call Successful: #{analysis['call_successful']}"
      puts "  Summary: #{analysis['transcript_summary']}"
      puts "  Title: #{analysis['call_summary_title']}"
    end
    
    # Transcript
    if conversation['transcript'] && conversation['transcript'].any?
      puts "\n💬 Transcript:"
      conversation['transcript'].each_with_index do |turn, index|
        timestamp = "[#{turn['time_in_call_secs']}s]"
        speaker = turn['role'] == 'user' ? '👤 User' : '🤖 Agent'
        puts "#{index + 1}. #{timestamp} #{speaker}: #{turn['message']}"
      end
    end
    
    conversation
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Conversation not found: #{conversation_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching conversation: #{e.message}"
    nil
  end

  # Download conversation audio
  def download_conversation_audio(conversation_id, output_file = nil)
    output_file ||= "conversation_#{conversation_id}.mp3"
    
    puts "Downloading audio for conversation: #{conversation_id}"
    
    audio_data = @client.conversations.get_audio(conversation_id)
    
    File.open(output_file, "wb") do |file|
      file.write(audio_data)
    end
    
    file_size = File.size(output_file)
    puts "✅ Audio saved to #{output_file} (#{file_size} bytes)"
    
    output_file
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Audio not found for conversation: #{conversation_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error downloading audio: #{e.message}"
    nil
  end

  # Delete a conversation
  def delete_conversation(conversation_id)
    puts "Deleting conversation: #{conversation_id}"
    
    print "Are you sure you want to delete this conversation? (y/N): "
    confirmation = gets.chomp.downcase
    
    return unless confirmation == 'y' || confirmation == 'yes'
    
    @client.conversations.delete(conversation_id)
    puts "✅ Conversation deleted successfully"
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Conversation not found: #{conversation_id}"
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error deleting conversation: #{e.message}"
  end

  # Get a signed URL for starting a conversation
  def get_signed_url(agent_id, include_conversation_id: false)
    puts "Getting signed URL for agent: #{agent_id}"
    
    response = @client.conversations.get_signed_url(
      agent_id,
      include_conversation_id: include_conversation_id
    )
    
    puts "🔗 Signed URL: #{response['signed_url']}"
    
    if include_conversation_id && response['conversation_id']
      puts "📝 Conversation ID: #{response['conversation_id']}"
    end
    
    response
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Agent not found: #{agent_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error getting signed URL: #{e.message}"
    nil
  end

  # Get a WebRTC token for real-time communication
  def get_webrtc_token(agent_id, participant_name: nil)
    puts "Getting WebRTC token for agent: #{agent_id}"
    
    options = {}
    options[:participant_name] = participant_name if participant_name
    
    response = @client.conversations.get_token(agent_id, **options)
    
    puts "🎯 WebRTC Token: #{response['token'][0..20]}..."
    puts "👤 Participant: #{participant_name || 'Default'}"
    
    response
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Agent not found: #{agent_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error getting WebRTC token: #{e.message}"
    nil
  end

  # Send feedback for a conversation
  def send_conversation_feedback(conversation_id, feedback)
    unless %w[like dislike].include?(feedback)
      puts "❌ Invalid feedback. Must be 'like' or 'dislike'"
      return false
    end
    
    puts "Sending #{feedback} feedback for conversation: #{conversation_id}"
    
    @client.conversations.send_feedback(conversation_id, feedback)
    
    emoji = feedback == 'like' ? '👍' : '👎'
    puts "✅ Feedback sent successfully #{emoji}"
    
    true
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Conversation not found: #{conversation_id}"
    false
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error sending feedback: #{e.message}"
    false
  end

  # Filter conversations by date range
  def list_conversations_by_date_range(start_date, end_date, agent_id: nil)
    start_unix = start_date.to_time.to_i
    end_unix = end_date.to_time.to_i
    
    puts "Fetching conversations between #{start_date} and #{end_date}"
    
    options = {
      call_start_after_unix: start_unix,
      call_start_before_unix: end_unix,
      page_size: 50,
      summary_mode: "include"
    }
    options[:agent_id] = agent_id if agent_id
    
    response = @client.conversations.list(**options)
    conversations = response["conversations"]
    
    puts "\n📅 Found #{conversations.length} conversations in date range:"
    
    # Group by date
    conversations_by_date = conversations.group_by do |conv|
      Time.at(conv['start_time_unix_secs']).strftime('%Y-%m-%d')
    end
    
    conversations_by_date.each do |date, convs|
      puts "\n📆 #{date} (#{convs.length} conversations):"
      convs.each do |conv|
        time = Time.at(conv['start_time_unix_secs']).strftime('%H:%M:%S')
        puts "  #{time} - #{conv['agent_name']} - #{conv['status']} (#{conv['call_duration_secs']}s)"
      end
    end
    
    conversations
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching conversations: #{e.message}"
    []
  end

  # Analyze conversation patterns
  def analyze_conversation_patterns(agent_id: nil, days: 7)
    end_time = Time.now
    start_time = end_time - (days * 24 * 60 * 60)
    
    puts "Analyzing conversation patterns for the last #{days} days..."
    
    conversations = list_conversations_by_date_range(start_time, end_time, agent_id: agent_id)
    
    return if conversations.empty?
    
    puts "\n📊 Conversation Analysis:"
    
    # Total stats
    total_conversations = conversations.length
    successful_conversations = conversations.count { |c| c['call_successful'] == 'success' }
    total_duration = conversations.sum { |c| c['call_duration_secs'] || 0 }
    avg_duration = total_duration.to_f / total_conversations
    
    puts "  Total Conversations: #{total_conversations}"
    puts "  Successful: #{successful_conversations} (#{(successful_conversations.to_f / total_conversations * 100).round(1)}%)"
    puts "  Average Duration: #{avg_duration.round(1)} seconds"
    
    # Status breakdown
    status_counts = conversations.group_by { |c| c['status'] }.transform_values(&:count)
    puts "\n📈 Status Breakdown:"
    status_counts.each do |status, count|
      percentage = (count.to_f / total_conversations * 100).round(1)
      puts "  #{status}: #{count} (#{percentage}%)"
    end
    
    # Direction breakdown
    direction_counts = conversations.group_by { |c| c['direction'] }.transform_values(&:count)
    puts "\n📞 Direction Breakdown:"
    direction_counts.each do |direction, count|
      percentage = (count.to_f / total_conversations * 100).round(1)
      puts "  #{direction}: #{count} (#{percentage}%)"
    end
    
    # Hourly patterns
    hourly_counts = conversations.group_by do |conv|
      Time.at(conv['start_time_unix_secs']).hour
    end.transform_values(&:count)
    
    puts "\n🕐 Hourly Distribution:"
    (0..23).each do |hour|
      count = hourly_counts[hour] || 0
      bar = "█" * (count * 20 / total_conversations) if total_conversations > 0
      puts "  #{hour.to_s.rjust(2)}:00 #{bar} (#{count})"
    end
    
    {
      total: total_conversations,
      successful: successful_conversations,
      average_duration: avg_duration,
      status_breakdown: status_counts,
      direction_breakdown: direction_counts,
      hourly_distribution: hourly_counts
    }
  end

  # Complete workflow demonstration
  def demo_workflow(agent_id)
    puts "🚀 Starting Conversations Management Demo"
    puts "=" * 50
    
    # 1. List recent conversations
    puts "\n1️⃣ Listing recent conversations..."
    conversations = list_conversations(agent_id: agent_id, limit: 5)
    
    return if conversations.empty?
    
    conversation_id = conversations.first['conversation_id']
    
    sleep(1)
    
    # 2. Get conversation details
    puts "\n2️⃣ Getting conversation details..."
    get_conversation_details(conversation_id)
    
    sleep(1)
    
    # 3. Download audio if available
    puts "\n3️⃣ Checking audio availability..."
    if conversations.first['has_audio']
      download_conversation_audio(conversation_id)
    else
      puts "⚠️ No audio available for this conversation"
    end
    
    sleep(1)
    
    # 4. Get signed URL for new conversations
    puts "\n4️⃣ Getting signed URL..."
    get_signed_url(agent_id, include_conversation_id: true)
    
    sleep(1)
    
    # 5. Get WebRTC token
    puts "\n5️⃣ Getting WebRTC token..."
    get_webrtc_token(agent_id, participant_name: "Demo Session")
    
    sleep(1)
    
    # 6. Send feedback
    puts "\n6️⃣ Sending feedback..."
    send_conversation_feedback(conversation_id, "like")
    
    sleep(1)
    
    # 7. Analyze patterns
    puts "\n7️⃣ Analyzing conversation patterns..."
    analyze_conversation_patterns(agent_id: agent_id, days: 7)
    
    puts "\n✨ Demo workflow completed successfully!"
    
    conversation_id
  end
end

# Example usage
if __FILE__ == $0
  # Initialize the controller
  controller = ConversationsController.new

  # Example agent ID (replace with a real one)
  agent_id = "your_agent_id_here"

  # Run the demo workflow
  controller.demo_workflow(agent_id)
end
