# Widgets Management

The widgets endpoints allow you to configure agent widgets and upload custom avatars for the conversational AI interface.

## Usage

```ruby
require 'elevenlabs_client'

client = ElevenlabsClient::Client.new(api_key: "your-api-key")
widgets = client.widgets
```

## Available Methods

### Get Widget Configuration

Retrieve the widget configuration for an agent, including styling, behavior, and customization options.

```ruby
widget_config = client.widgets.get("agent_id_here")

puts "Agent ID: #{widget_config['agent_id']}"
puts "Widget Language: #{widget_config['widget_config']['language']}"
puts "Widget Variant: #{widget_config['widget_config']['variant']}"
puts "Placement: #{widget_config['widget_config']['placement']}"

# Access styling options
styles = widget_config['widget_config']['styles']
puts "Base Color: #{styles['base']}" if styles

# Access text content
text_contents = widget_config['widget_config']['text_contents']
puts "Main Label: #{text_contents['main_label']}" if text_contents
```

### Get Widget with Conversation Signature

Retrieve widget configuration with an optional conversation signature for secure access.

```ruby
widget_config = client.widgets.get(
  "agent_id_here",
  conversation_signature: "your_conversation_signature_token"
)

puts "Widget configured with conversation signature"
puts "First Message: #{widget_config['widget_config']['first_message']}"
```

### Create/Upload Agent Avatar

Upload a custom avatar image for an agent that will be displayed in the widget.

```ruby
# Upload avatar from file
File.open("avatar.png", "rb") do |file|
  avatar_response = client.widgets.create_avatar(
    "agent_id_here",
    avatar_file_io: file,
    filename: "avatar.png"
  )
  
  puts "Avatar uploaded successfully!"
  puts "Agent ID: #{avatar_response['agent_id']}"
  puts "Avatar URL: #{avatar_response['avatar_url']}"
end

# Upload avatar from memory
avatar_data = File.read("custom_avatar.jpg")
StringIO.open(avatar_data, "rb") do |file_io|
  avatar_response = client.widgets.create_avatar(
    "agent_id_here",
    avatar_file_io: file_io,
    filename: "custom_avatar.jpg"
  )
  
  puts "Custom avatar uploaded: #{avatar_response['avatar_url']}"
end
```

## Widget Configuration Examples

### Analyzing Widget Settings

```ruby
def analyze_widget_config(agent_id)
  config = client.widgets.get(agent_id)
  widget = config['widget_config']
  
  puts "🎨 Widget Configuration Analysis"
  puts "=" * 40
  puts "Agent: #{config['agent_id']}"
  
  # Basic settings
  puts "\n📱 Basic Settings:"
  puts "  Language: #{widget['language']}"
  puts "  Variant: #{widget['variant']}"
  puts "  Placement: #{widget['placement']}"
  puts "  Expandable: #{widget['expandable']}"
  puts "  Text Only: #{widget['text_only']}"
  puts "  Supports Text Only: #{widget['supports_text_only']}"
  puts "  Use RTC: #{widget['use_rtc']}"
  
  # Avatar settings
  if widget['avatar']
    avatar = widget['avatar']
    puts "\n👤 Avatar Settings:"
    puts "  Type: #{avatar['type']}"
    puts "  Color 1: #{avatar['color_1']}"
    puts "  Color 2: #{avatar['color_2']}"
  end
  
  # Display settings
  puts "\n🎯 Display Settings:"
  puts "  Show Avatar When Collapsed: #{widget['show_avatar_when_collapsed']}"
  puts "  Default Expanded: #{widget['default_expanded']}"
  puts "  Always Expanded: #{widget['always_expanded']}"
  puts "  Disable Banner: #{widget['disable_banner']}"
  
  # Features
  puts "\n⚙️ Features:"
  puts "  Mic Muting Enabled: #{widget['mic_muting_enabled']}"
  puts "  Transcript Enabled: #{widget['transcript_enabled']}"
  puts "  Text Input Enabled: #{widget['text_input_enabled']}"
  puts "  Feedback Mode: #{widget['feedback_mode']}"
  
  # Colors and styling
  puts "\n🎨 Colors:"
  puts "  Background: #{widget['bg_color']}"
  puts "  Text: #{widget['text_color']}"
  puts "  Button: #{widget['btn_color']}"
  puts "  Button Text: #{widget['btn_text_color']}"
  puts "  Border: #{widget['border_color']}"
  puts "  Focus: #{widget['focus_color']}"
  
  # Border radius
  puts "\n📐 Border Radius:"
  puts "  General: #{widget['border_radius']}"
  puts "  Button: #{widget['btn_radius']}"
  
  # Text customization
  if widget['text_contents']
    text = widget['text_contents']
    puts "\n📝 Text Customization:"
    puts "  Main Label: #{text['main_label']}"
    puts "  Start Call: #{text['start_call']}"
    puts "  Start Chat: #{text['start_chat']}"
    puts "  End Call: #{text['end_call']}"
    puts "  Input Placeholder: #{text['input_placeholder']}"
  end
  
  # Language support
  if widget['supported_language_overrides']&.any?
    puts "\n🌍 Supported Languages:"
    widget['supported_language_overrides'].each do |lang|
      puts "  - #{lang}"
    end
  end
  
  # Advanced styling
  if widget['styles']
    styles = widget['styles']
    puts "\n🎭 Advanced Styling:"
    puts "  Base: #{styles['base']}"
    puts "  Accent: #{styles['accent']}"
    puts "  Button Radius: #{styles['button_radius']}"
    puts "  Input Radius: #{styles['input_radius']}"
    puts "  Bubble Radius: #{styles['bubble_radius']}"
  end
end

# Usage
analyze_widget_config("your_agent_id")
```

### Widget Customization Workflow

```ruby
def customize_agent_widget(agent_id)
  puts "🎨 Customizing Agent Widget"
  puts "=" * 30
  
  # Step 1: Get current configuration
  puts "1️⃣ Getting current widget configuration..."
  current_config = client.widgets.get(agent_id)
  
  puts "Current variant: #{current_config['widget_config']['variant']}"
  puts "Current placement: #{current_config['widget_config']['placement']}"
  
  # Step 2: Upload custom avatar
  puts "\n2️⃣ Uploading custom avatar..."
  
  # Create a simple avatar programmatically or use existing file
  if File.exist?("custom_avatar.png")
    File.open("custom_avatar.png", "rb") do |file|
      avatar_result = client.widgets.create_avatar(
        agent_id,
        avatar_file_io: file,
        filename: "custom_avatar.png"
      )
      
      puts "✅ Avatar uploaded successfully!"
      puts "Avatar URL: #{avatar_result['avatar_url']}"
    end
  else
    puts "⚠️ No custom avatar file found (custom_avatar.png)"
  end
  
  # Step 3: Get updated configuration
  puts "\n3️⃣ Verifying widget configuration..."
  updated_config = client.widgets.get(agent_id)
  
  # Compare configurations
  puts "\n📊 Configuration Summary:"
  widget = updated_config['widget_config']
  puts "Language: #{widget['language']}"
  puts "Expandable: #{widget['expandable']}"
  puts "Text Input: #{widget['text_input_enabled'] ? 'Enabled' : 'Disabled'}"
  puts "Transcript: #{widget['transcript_enabled'] ? 'Enabled' : 'Disabled'}"
  puts "Mic Muting: #{widget['mic_muting_enabled'] ? 'Enabled' : 'Disabled'}"
  
  puts "\n✅ Widget customization complete!"
  
  updated_config
end

# Usage
customize_agent_widget("your_agent_id")
```

### Bulk Avatar Upload

```ruby
def bulk_upload_avatars(agent_avatar_pairs)
  puts "📸 Bulk Avatar Upload"
  puts "=" * 20
  
  results = []
  
  agent_avatar_pairs.each_with_index do |pair, index|
    agent_id = pair[:agent_id]
    avatar_path = pair[:avatar_path]
    
    puts "\n#{index + 1}/#{agent_avatar_pairs.length}: Uploading avatar for agent #{agent_id}"
    
    begin
      File.open(avatar_path, "rb") do |file|
        filename = File.basename(avatar_path)
        
        avatar_result = client.widgets.create_avatar(
          agent_id,
          avatar_file_io: file,
          filename: filename
        )
        
        results << {
          agent_id: agent_id,
          success: true,
          avatar_url: avatar_result['avatar_url'],
          filename: filename
        }
        
        puts "✅ Success: #{avatar_result['avatar_url']}"
      end
    rescue => e
      puts "❌ Failed: #{e.message}"
      results << {
        agent_id: agent_id,
        success: false,
        error: e.message,
        filename: File.basename(avatar_path)
      }
    end
    
    sleep(0.5) # Rate limiting
  end
  
  # Summary
  successful = results.count { |r| r[:success] }
  puts "\n📊 Bulk Upload Results:"
  puts "Successful: #{successful}/#{results.length}"
  puts "Failed: #{results.length - successful}"
  
  results
end

# Usage
avatar_pairs = [
  { agent_id: "agent1", avatar_path: "avatars/agent1.png" },
  { agent_id: "agent2", avatar_path: "avatars/agent2.jpg" },
  { agent_id: "agent3", avatar_path: "avatars/agent3.png" }
]

bulk_upload_avatars(avatar_pairs)
```

### Widget Theme Analysis

```ruby
def analyze_widget_themes
  puts "🎨 Widget Theme Analysis"
  puts "=" * 30
  
  # Get multiple agent widgets to analyze themes
  agent_ids = ["agent1", "agent2", "agent3"] # Replace with actual agent IDs
  
  themes = {}
  
  agent_ids.each do |agent_id|
    begin
      config = client.widgets.get(agent_id)
      widget = config['widget_config']
      
      theme_key = "#{widget['variant']}_#{widget['placement']}"
      
      themes[theme_key] ||= {
        variant: widget['variant'],
        placement: widget['placement'],
        agents: [],
        colors: {
          bg_colors: [],
          text_colors: [],
          btn_colors: []
        }
      }
      
      themes[theme_key][:agents] << agent_id
      themes[theme_key][:colors][:bg_colors] << widget['bg_color']
      themes[theme_key][:colors][:text_colors] << widget['text_color']
      themes[theme_key][:colors][:btn_colors] << widget['btn_color']
      
    rescue => e
      puts "⚠️ Skipping agent #{agent_id}: #{e.message}"
    end
  end
  
  # Analyze themes
  puts "\n📊 Theme Distribution:"
  themes.each do |theme_key, data|
    puts "\n#{theme_key.gsub('_', ' - ').upcase}:"
    puts "  Agents: #{data[:agents].length}"
    puts "  Agent IDs: #{data[:agents].join(', ')}"
    
    # Find most common colors
    bg_colors = data[:colors][:bg_colors].uniq
    text_colors = data[:colors][:text_colors].uniq
    btn_colors = data[:colors][:btn_colors].uniq
    
    puts "  Background Colors: #{bg_colors.join(', ')}"
    puts "  Text Colors: #{text_colors.join(', ')}"
    puts "  Button Colors: #{btn_colors.join(', ')}"
  end
  
  # Find most popular configurations
  most_popular = themes.max_by { |_, data| data[:agents].length }
  
  if most_popular
    puts "\n🏆 Most Popular Configuration:"
    puts "Theme: #{most_popular[0].gsub('_', ' - ')}"
    puts "Used by #{most_popular[1][:agents].length} agents"
  end
  
  themes
end

# Usage
analyze_widget_themes
```

### Widget Configuration Export/Import

```ruby
def export_widget_config(agent_id, output_file)
  puts "📤 Exporting widget configuration for agent #{agent_id}"
  
  config = client.widgets.get(agent_id)
  widget_config = config['widget_config']
  
  # Create exportable configuration
  export_data = {
    agent_id: config['agent_id'],
    exported_at: Time.now.iso8601,
    widget_config: {
      # Core settings
      language: widget_config['language'],
      variant: widget_config['variant'],
      placement: widget_config['placement'],
      expandable: widget_config['expandable'],
      
      # Features
      text_input_enabled: widget_config['text_input_enabled'],
      transcript_enabled: widget_config['transcript_enabled'],
      mic_muting_enabled: widget_config['mic_muting_enabled'],
      
      # Colors
      bg_color: widget_config['bg_color'],
      text_color: widget_config['text_color'],
      btn_color: widget_config['btn_color'],
      btn_text_color: widget_config['btn_text_color'],
      border_color: widget_config['border_color'],
      focus_color: widget_config['focus_color'],
      
      # Border radius
      border_radius: widget_config['border_radius'],
      btn_radius: widget_config['btn_radius'],
      
      # Text customization
      text_contents: widget_config['text_contents'],
      
      # Avatar (excluding URL as it's agent-specific)
      avatar_type: widget_config['avatar']&.dig('type'),
      avatar_color_1: widget_config['avatar']&.dig('color_1'),
      avatar_color_2: widget_config['avatar']&.dig('color_2')
    }
  }
  
  File.write(output_file, JSON.pretty_generate(export_data))
  puts "✅ Configuration exported to #{output_file}"
  
  export_data
end

def analyze_widget_consistency(agent_ids)
  puts "🔍 Widget Configuration Consistency Analysis"
  puts "=" * 50
  
  configs = []
  
  # Collect all configurations
  agent_ids.each do |agent_id|
    begin
      config = client.widgets.get(agent_id)
      configs << {
        agent_id: agent_id,
        config: config['widget_config']
      }
    rescue => e
      puts "⚠️ Failed to get config for #{agent_id}: #{e.message}"
    end
  end
  
  if configs.empty?
    puts "❌ No configurations retrieved"
    return
  end
  
  # Analyze consistency
  puts "\n📊 Configuration Analysis:"
  
  # Check variants
  variants = configs.map { |c| c[:config]['variant'] }.uniq
  puts "Variants used: #{variants.join(', ')}"
  puts "Consistent variants: #{variants.length == 1 ? '✅' : '❌'}"
  
  # Check placements
  placements = configs.map { |c| c[:config]['placement'] }.uniq
  puts "Placements used: #{placements.join(', ')}"
  puts "Consistent placements: #{placements.length == 1 ? '✅' : '❌'}"
  
  # Check colors
  bg_colors = configs.map { |c| c[:config]['bg_color'] }.uniq
  puts "Background colors: #{bg_colors.join(', ')}"
  puts "Consistent background: #{bg_colors.length == 1 ? '✅' : '❌'}"
  
  # Check features
  text_input = configs.map { |c| c[:config]['text_input_enabled'] }.uniq
  puts "Text input settings: #{text_input.join(', ')}"
  puts "Consistent text input: #{text_input.length == 1 ? '✅' : '❌'}"
  
  # Find inconsistencies
  puts "\n⚠️ Inconsistencies Found:" if variants.length > 1 || placements.length > 1 || bg_colors.length > 1
  
  if variants.length > 1
    puts "- Multiple variants in use"
    configs.group_by { |c| c[:config]['variant'] }.each do |variant, agents|
      puts "  #{variant}: #{agents.map { |a| a[:agent_id] }.join(', ')}"
    end
  end
  
  {
    total_agents: configs.length,
    variants: variants,
    placements: placements,
    bg_colors: bg_colors,
    consistent: variants.length == 1 && placements.length == 1 && bg_colors.length == 1
  }
end

# Usage
export_widget_config("agent_id", "widget_config.json")
analyze_widget_consistency(["agent1", "agent2", "agent3"])
```

## Error Handling

```ruby
begin
  widget_config = client.widgets.get("agent_id")
rescue ElevenlabsClient::NotFoundError
  puts "Agent not found"
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end

begin
  File.open("avatar.png", "rb") do |file|
    avatar_result = client.widgets.create_avatar(
      "agent_id",
      avatar_file_io: file,
      filename: "avatar.png"
    )
  end
rescue ElevenlabsClient::ValidationError => e
  puts "Invalid avatar file: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "Upload failed: #{e.message}"
end
```

## Best Practices

### Widget Configuration

1. **Consistent Branding**: Maintain consistent colors and styling across all agent widgets
2. **Accessibility**: Choose color combinations that meet accessibility standards
3. **User Experience**: Configure appropriate placement and expandable behavior
4. **Language Support**: Set up proper language overrides for international users

### Avatar Management

1. **Image Quality**: Use high-quality images optimized for web display
2. **File Size**: Keep avatar files reasonably sized (< 1MB recommended)
3. **Format Support**: Use common formats like PNG, JPG, or GIF
4. **Consistent Style**: Maintain visual consistency across agent avatars

### Performance Optimization

1. **Configuration Caching**: Cache widget configurations to reduce API calls
2. **Batch Operations**: Group avatar uploads when updating multiple agents
3. **Error Handling**: Implement robust error handling for file uploads
4. **Rate Limiting**: Respect API rate limits during bulk operations

## API Reference

For detailed API documentation, visit: [ElevenLabs Widgets API Reference](https://elevenlabs.io/docs/api-reference/convai/widgets)
