# frozen_string_literal: true

require_relative "../../lib/elevenlabs_client"

class WidgetsController
  def initialize
    @client = ElevenlabsClient::Client.new(api_key: ENV["ELEVENLABS_API_KEY"])
  end

  def run_examples
    puts "🎨 Widget Management Examples"
    puts "=" * 40

    # Get agent ID from environment or use a default
    agent_id = ENV["AGENT_ID"] || "your_agent_id_here"

    example_get_widget_config(agent_id)
    example_upload_avatar(agent_id)
    example_analyze_widget_settings(agent_id)
    example_widget_customization_workflow(agent_id)
    example_bulk_avatar_upload
    example_widget_theme_analysis
  end

  private

  def example_get_widget_config(agent_id)
    puts "\n1️⃣ Getting Widget Configuration"
    puts "-" * 35

    begin
      # Get basic widget configuration
      widget_config = @client.widgets.get(agent_id)
      
      puts "✅ Widget configuration retrieved:"
      puts "Agent ID: #{widget_config['agent_id']}"
      
      widget = widget_config['widget_config']
      puts "Language: #{widget['language']}"
      puts "Variant: #{widget['variant']}"
      puts "Placement: #{widget['placement']}"
      puts "Expandable: #{widget['expandable']}"
      puts "Text Input Enabled: #{widget['text_input_enabled']}"
      puts "Transcript Enabled: #{widget['transcript_enabled']}"
      
      # Display color scheme
      puts "\nColor Scheme:"
      puts "  Background: #{widget['bg_color']}"
      puts "  Text: #{widget['text_color']}"
      puts "  Button: #{widget['btn_color']}"
      puts "  Border: #{widget['border_color']}"
      
      # Display avatar settings if available
      if widget['avatar']
        avatar = widget['avatar']
        puts "\nAvatar Settings:"
        puts "  Type: #{avatar['type']}"
        puts "  Color 1: #{avatar['color_1']}"
        puts "  Color 2: #{avatar['color_2']}"
      end
      
      # Get widget configuration with conversation signature (if available)
      if ENV["CONVERSATION_SIGNATURE"]
        puts "\n🔐 Getting widget with conversation signature..."
        secure_config = @client.widgets.get(
          agent_id,
          conversation_signature: ENV["CONVERSATION_SIGNATURE"]
        )
        puts "✅ Secure widget configuration retrieved"
      end
      
    rescue ElevenlabsClient::NotFoundError
      puts "❌ Agent not found: #{agent_id}"
    rescue ElevenlabsClient::APIError => e
      puts "❌ API Error: #{e.message}"
    end
  end

  def example_upload_avatar(agent_id)
    puts "\n2️⃣ Uploading Agent Avatar"
    puts "-" * 30

    # Create a simple test image file if it doesn't exist
    avatar_path = "test_avatar.png"
    create_test_avatar(avatar_path) unless File.exist?(avatar_path)

    if File.exist?(avatar_path)
      begin
        File.open(avatar_path, "rb") do |file|
          avatar_response = @client.widgets.create_avatar(
            agent_id,
            avatar_file_io: file,
            filename: "test_avatar.png"
          )
          
          puts "✅ Avatar uploaded successfully!"
          puts "Agent ID: #{avatar_response['agent_id']}"
          puts "Avatar URL: #{avatar_response['avatar_url']}"
        end
        
        # Clean up test file
        File.delete(avatar_path) if File.exist?(avatar_path)
        
      rescue ElevenlabsClient::ValidationError => e
        puts "❌ Invalid avatar file: #{e.message}"
      rescue ElevenlabsClient::APIError => e
        puts "❌ Upload failed: #{e.message}"
      end
    else
      puts "⚠️ No avatar file found for upload example"
    end
  end

  def example_analyze_widget_settings(agent_id)
    puts "\n3️⃣ Analyzing Widget Settings"
    puts "-" * 35

    begin
      config = @client.widgets.get(agent_id)
      widget = config['widget_config']
      
      puts "🎨 Widget Analysis for Agent: #{config['agent_id']}"
      
      # Basic settings analysis
      puts "\n📱 Basic Configuration:"
      puts "  Language: #{widget['language']}"
      puts "  Variant: #{widget['variant']} (#{get_variant_description(widget['variant'])})"
      puts "  Placement: #{widget['placement']} (#{get_placement_description(widget['placement'])})"
      puts "  Expandable: #{widget['expandable']}"
      
      # Feature analysis
      puts "\n⚙️ Features:"
      features = [
        ["Text Input", widget['text_input_enabled']],
        ["Transcript", widget['transcript_enabled']],
        ["Mic Muting", widget['mic_muting_enabled']],
        ["Text Only Mode", widget['text_only']],
        ["RTC Support", widget['use_rtc']]
      ]
      
      features.each do |feature_name, enabled|
        status = enabled ? "✅ Enabled" : "❌ Disabled"
        puts "  #{feature_name}: #{status}"
      end
      
      # UI/UX analysis
      puts "\n🎭 UI/UX Settings:"
      puts "  Default Expanded: #{widget['default_expanded'] ? 'Yes' : 'No'}"
      puts "  Always Expanded: #{widget['always_expanded'] ? 'Yes' : 'No'}"
      puts "  Show Avatar When Collapsed: #{widget['show_avatar_when_collapsed'] ? 'Yes' : 'No'}"
      puts "  Disable Banner: #{widget['disable_banner'] ? 'Yes' : 'No'}"
      
      # Color accessibility check
      puts "\n🌈 Color Accessibility:"
      analyze_color_contrast(widget)
      
      # Language support
      if widget['supported_language_overrides']&.any?
        puts "\n🌍 Supported Languages:"
        widget['supported_language_overrides'].each do |lang|
          puts "  - #{lang}"
        end
      end
      
    rescue ElevenlabsClient::APIError => e
      puts "❌ Analysis failed: #{e.message}"
    end
  end

  def example_widget_customization_workflow(agent_id)
    puts "\n4️⃣ Widget Customization Workflow"
    puts "-" * 40

    begin
      # Step 1: Get current configuration
      puts "Step 1: Analyzing current widget configuration..."
      current_config = @client.widgets.get(agent_id)
      widget = current_config['widget_config']
      
      puts "Current settings:"
      puts "  Variant: #{widget['variant']}"
      puts "  Placement: #{widget['placement']}"
      puts "  Background Color: #{widget['bg_color']}"
      puts "  Text Input: #{widget['text_input_enabled'] ? 'Enabled' : 'Disabled'}"
      
      # Step 2: Demonstrate avatar upload workflow
      puts "\nStep 2: Avatar customization workflow..."
      demonstrate_avatar_workflow(agent_id)
      
      # Step 3: Configuration recommendations
      puts "\nStep 3: Configuration recommendations..."
      provide_configuration_recommendations(widget)
      
      # Step 4: Best practices
      puts "\nStep 4: Best practices checklist..."
      check_best_practices(widget)
      
    rescue ElevenlabsClient::APIError => e
      puts "❌ Workflow failed: #{e.message}"
    end
  end

  def example_bulk_avatar_upload
    puts "\n5️⃣ Bulk Avatar Upload Example"
    puts "-" * 35

    # Simulate multiple agents (in a real scenario, you'd have actual agent IDs)
    agent_avatar_pairs = [
      { agent_id: "agent_1", avatar_name: "avatar_1.png" },
      { agent_id: "agent_2", avatar_name: "avatar_2.png" },
      { agent_id: "agent_3", avatar_name: "avatar_3.png" }
    ]

    puts "📸 Simulating bulk avatar upload workflow..."
    puts "Agents to process: #{agent_avatar_pairs.length}"
    
    results = []
    
    agent_avatar_pairs.each_with_index do |pair, index|
      puts "\n#{index + 1}/#{agent_avatar_pairs.length}: Processing #{pair[:agent_id]}"
      
      # Create test avatar file
      avatar_path = pair[:avatar_name]
      create_test_avatar(avatar_path)
      
      if File.exist?(avatar_path)
        begin
          # Simulate upload (would normally use real agent IDs)
          puts "  📤 Would upload #{avatar_path} for #{pair[:agent_id]}"
          
          # In real implementation:
          # File.open(avatar_path, "rb") do |file|
          #   result = @client.widgets.create_avatar(
          #     pair[:agent_id],
          #     avatar_file_io: file,
          #     filename: avatar_path
          #   )
          #   results << { agent_id: pair[:agent_id], success: true, url: result['avatar_url'] }
          # end
          
          results << { 
            agent_id: pair[:agent_id], 
            success: true, 
            filename: avatar_path,
            simulated: true
          }
          
          puts "  ✅ Simulated upload successful"
          
        rescue => e
          puts "  ❌ Upload failed: #{e.message}"
          results << { 
            agent_id: pair[:agent_id], 
            success: false, 
            error: e.message 
          }
        ensure
          # Clean up test file
          File.delete(avatar_path) if File.exist?(avatar_path)
        end
      end
      
      sleep(0.5) # Rate limiting
    end
    
    # Summary
    successful = results.count { |r| r[:success] }
    puts "\n📊 Bulk Upload Results:"
    puts "Successful: #{successful}/#{results.length}"
    puts "Failed: #{results.length - successful}"
  end

  def example_widget_theme_analysis
    puts "\n6️⃣ Widget Theme Analysis"
    puts "-" * 30

    # Simulate analysis of multiple widget themes
    puts "🎨 Analyzing widget themes across agents..."
    
    sample_themes = [
      {
        name: "Modern Dark",
        variant: "tiny",
        placement: "bottom-right",
        colors: { bg: "#1a1a1a", text: "#ffffff", button: "#007bff" },
        usage_count: 15
      },
      {
        name: "Classic Light",
        variant: "compact",
        placement: "bottom-left",
        colors: { bg: "#ffffff", text: "#333333", button: "#28a745" },
        usage_count: 8
      },
      {
        name: "Brand Custom",
        variant: "large",
        placement: "top-right",
        colors: { bg: "#f8f9fa", text: "#212529", button: "#dc3545" },
        usage_count: 3
      }
    ]
    
    puts "\n📊 Theme Distribution:"
    total_usage = sample_themes.sum { |theme| theme[:usage_count] }
    
    sample_themes.sort_by { |theme| -theme[:usage_count] }.each_with_index do |theme, index|
      percentage = (theme[:usage_count].to_f / total_usage * 100).round(1)
      medal = index == 0 ? "🥇" : index == 1 ? "🥈" : index == 2 ? "🥉" : "  "
      
      puts "#{medal} #{theme[:name]}:"
      puts "    Usage: #{theme[:usage_count]} agents (#{percentage}%)"
      puts "    Variant: #{theme[:variant]}"
      puts "    Placement: #{theme[:placement]}"
      puts "    Colors: BG #{theme[:colors][:bg]}, Text #{theme[:colors][:text]}, Button #{theme[:colors][:button]}"
      puts
    end
    
    # Recommendations
    puts "💡 Theme Recommendations:"
    most_popular = sample_themes.max_by { |theme| theme[:usage_count] }
    puts "  • Most popular theme: #{most_popular[:name]}"
    puts "  • Consider standardizing on popular themes for consistency"
    puts "  • Ensure all themes meet accessibility standards"
  end

  # Helper methods

  def create_test_avatar(filename)
    # Create a simple 100x100 PNG image for testing
    # This is a minimal PNG file (just for demonstration)
    png_data = [
      "\x89PNG\r\n\x1A\n",
      "\x00\x00\x00\rIHDR",
      "\x00\x00\x00d\x00\x00\x00d",
      "\x08\x02\x00\x00\x00\xFF\x80\x02\x03",
      "\x00\x00\x00\x0CIDAT",
      "x\x9C\xED\xC1\x01\r\x00\x00\x00\xC2\xA0\xF7Om\x0E7\xA0\x00\x00\x00\x00\x00\x00\x00\x00\xBE\r!\x00\x00\x01",
      "\x00\x00\x00\x00IEND\xAE""B`\x82"
    ].join

    File.binwrite(filename, png_data)
    puts "  📄 Created test avatar file: #{filename}"
  end

  def get_variant_description(variant)
    case variant
    when "tiny" then "Minimal widget size"
    when "compact" then "Small but functional"
    when "large" then "Full-featured widget"
    else "Unknown variant"
    end
  end

  def get_placement_description(placement)
    case placement
    when "bottom-right" then "Bottom right corner (default)"
    when "bottom-left" then "Bottom left corner"
    when "top-right" then "Top right corner"
    when "top-left" then "Top left corner"
    else "Custom placement"
    end
  end

  def analyze_color_contrast(widget)
    bg_color = widget['bg_color']
    text_color = widget['text_color']
    
    puts "  Background: #{bg_color}"
    puts "  Text: #{text_color}"
    
    # Simple contrast check (in production, you'd use proper contrast calculation)
    if (bg_color == "#ffffff" && text_color == "#000000") ||
       (bg_color == "#000000" && text_color == "#ffffff")
      puts "  ✅ High contrast (good accessibility)"
    elsif bg_color == text_color
      puts "  ❌ Poor contrast (accessibility issue)"
    else
      puts "  ⚠️ Moderate contrast (check accessibility)"
    end
  end

  def demonstrate_avatar_workflow(agent_id)
    puts "  🖼️ Avatar customization workflow:"
    puts "    1. Create or select avatar image"
    puts "    2. Optimize image size and format"
    puts "    3. Upload via widgets.create_avatar()"
    puts "    4. Verify avatar appears in widget"
    puts "    5. Test across different widget variants"
    puts "  💡 Best practices:"
    puts "    • Use square images (1:1 aspect ratio)"
    puts "    • Keep file size under 1MB"
    puts "    • Use PNG or JPG format"
    puts "    • Ensure avatar works on both light and dark backgrounds"
  end

  def provide_configuration_recommendations(widget)
    recommendations = []
    
    # Analyze current settings and provide recommendations
    if widget['variant'] == "tiny" && widget['text_input_enabled']
      recommendations << "Consider 'compact' variant for better text input experience"
    end
    
    if widget['bg_color'] == widget['text_color']
      recommendations << "⚠️ Background and text colors are identical - fix contrast issue"
    end
    
    if !widget['transcript_enabled'] && widget['text_input_enabled']
      recommendations << "Enable transcript for better user experience with text input"
    end
    
    if widget['always_expanded'] && widget['placement'] == "top-left"
      recommendations << "Consider bottom placement for always-expanded widgets"
    end
    
    if recommendations.any?
      puts "💡 Configuration Recommendations:"
      recommendations.each { |rec| puts "  • #{rec}" }
    else
      puts "✅ Configuration looks good!"
    end
  end

  def check_best_practices(widget)
    checks = [
      {
        name: "Text input enabled for better accessibility",
        passing: widget['text_input_enabled']
      },
      {
        name: "Appropriate placement for user experience",
        passing: ["bottom-right", "bottom-left"].include?(widget['placement'])
      },
      {
        name: "Transcript enabled for conversation history",
        passing: widget['transcript_enabled']
      },
      {
        name: "Mic muting available for user control",
        passing: widget['mic_muting_enabled']
      }
    ]
    
    passing_checks = checks.count { |check| check[:passing] }
    
    puts "📋 Best Practices Checklist (#{passing_checks}/#{checks.length}):"
    checks.each do |check|
      status = check[:passing] ? "✅" : "❌"
      puts "  #{status} #{check[:name]}"
    end
    
    if passing_checks == checks.length
      puts "🎉 All best practices followed!"
    else
      puts "⚠️ Consider implementing missing best practices"
    end
  end
end

# Run examples if this file is executed directly
if __FILE__ == $0
  controller = WidgetsController.new
  controller.run_examples
end
