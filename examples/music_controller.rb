# Example Rails controller demonstrating Music generation functionality
# This controller provides endpoints for AI music composition and streaming

class MusicController < ApplicationController
  before_action :initialize_client
  
  # POST /music/generate
  # Generate music from a text prompt
  def generate
    prompt = params[:prompt]
    duration = params[:duration_ms]&.to_i || 30000
    output_format = params[:output_format] || "mp3_44100_128"
    
    unless prompt.present?
      return render json: { 
        success: false, 
        error: "Prompt is required" 
      }, status: :bad_request
    end
    
    audio_data = @client.music.compose(
      prompt: prompt,
      music_length_ms: duration,
      output_format: output_format,
      model_id: params[:model_id]
    )
    
    # Send audio directly to client
    send_data audio_data,
              type: "audio/mpeg",
              filename: generate_filename(prompt),
              disposition: params[:download] == "true" ? "attachment" : "inline"
              
  rescue ElevenlabsClient::BadRequestError => e
    render json: { 
      success: false, 
      error: "Invalid parameters", 
      details: e.message 
    }, status: :bad_request
  rescue ElevenlabsClient::RateLimitError => e
    render json: { 
      success: false, 
      error: "Rate limit exceeded", 
      details: "Please try again later" 
    }, status: :too_many_requests
  rescue ElevenlabsClient::APIError => e
    render json: { 
      success: false, 
      error: "Music generation failed", 
      details: e.message 
    }, status: :service_unavailable
  end
  
  # POST /music/stream
  # Generate and stream music in real-time
  def stream
    prompt = params[:prompt]
    duration = params[:duration_ms]&.to_i || 60000
    
    unless prompt.present?
      return render json: { error: "Prompt is required" }, status: :bad_request
    end
    
    # Set streaming headers
    response.headers['Content-Type'] = 'audio/mpeg'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['Connection'] = 'keep-alive'
    response.headers['Transfer-Encoding'] = 'chunked'
    
    begin
      @client.music.compose_stream(
        prompt: prompt,
        music_length_ms: duration,
        output_format: params[:output_format] || "mp3_44100_128"
      ) do |chunk|
        # Stream each chunk to the client
        response.stream.write(chunk)
      end
      
    rescue ElevenlabsClient::APIError => e
      # If streaming fails, send error as JSON
      response.headers['Content-Type'] = 'application/json'
      response.stream.write({ error: e.message }.to_json)
    ensure
      response.stream.close
    end
  end
  
  # POST /music/detailed
  # Generate music with detailed metadata response
  def detailed
    prompt = params[:prompt]
    
    unless prompt.present?
      return render json: { 
        success: false, 
        error: "Prompt is required" 
      }, status: :bad_request
    end
    
    multipart_response = @client.music.compose_detailed(
      prompt: prompt,
      music_length_ms: params[:duration_ms]&.to_i,
      composition_plan: parse_composition_plan(params[:composition_plan]),
      output_format: params[:output_format]
    )
    
    # Parse multipart response to extract metadata and audio
    metadata, audio_data = parse_multipart_response(multipart_response)
    
    # Store composition if requested
    if params[:save] == "true"
      composition = save_composition(prompt, metadata, audio_data)
      
      render json: {
        success: true,
        composition_id: composition.id,
        metadata: metadata,
        audio_url: composition_audio_path(composition),
        download_url: download_composition_path(composition)
      }
    else
      # Return metadata and send audio
      response.headers['X-Composition-Metadata'] = metadata.to_json
      send_data audio_data,
                type: "audio/mpeg",
                filename: generate_filename(prompt)
    end
    
  rescue ElevenlabsClient::APIError => e
    render json: { 
      success: false, 
      error: "Detailed composition failed", 
      details: e.message 
    }, status: :service_unavailable
  end
  
  # POST /music/plan
  # Create a composition plan for structured music
  def create_plan
    prompt = params[:prompt]
    duration = params[:duration_ms]&.to_i
    
    unless prompt.present?
      return render json: { 
        success: false, 
        error: "Prompt is required" 
      }, status: :bad_request
    end
    
    plan = @client.music.create_plan(
      prompt: prompt,
      music_length_ms: duration,
      source_composition_plan: parse_composition_plan(params[:source_plan]),
      model_id: params[:model_id]
    )
    
    render json: {
      success: true,
      plan: plan,
      sections: plan["sections"],
      total_duration_ms: plan["total_duration_ms"],
      composition_plan_id: plan["composition_plan_id"]
    }
    
  rescue ElevenlabsClient::APIError => e
    render json: { 
      success: false, 
      error: "Plan creation failed", 
      details: e.message 
    }, status: :service_unavailable
  end
  
  # POST /music/compose_with_plan
  # Generate music using a pre-created composition plan
  def compose_with_plan
    prompt = params[:prompt]
    plan_id = params[:plan_id]
    
    unless prompt.present?
      return render json: { 
        success: false, 
        error: "Prompt is required" 
      }, status: :bad_request
    end
    
    # Retrieve stored plan or use provided plan data
    composition_plan = if plan_id.present?
                        retrieve_stored_plan(plan_id)
                      else
                        parse_composition_plan(params[:composition_plan])
                      end
    
    unless composition_plan.present?
      return render json: { 
        success: false, 
        error: "Composition plan is required" 
      }, status: :bad_request
    end
    
    audio_data = @client.music.compose(
      prompt: prompt,
      composition_plan: composition_plan["sections"] || composition_plan,
      music_length_ms: composition_plan["total_duration_ms"],
      output_format: params[:output_format] || "mp3_44100_128"
    )
    
    send_data audio_data,
              type: "audio/mpeg",
              filename: generate_filename("#{prompt}_structured")
              
  rescue ElevenlabsClient::APIError => e
    render json: { 
      success: false, 
      error: "Structured composition failed", 
      details: e.message 
    }, status: :service_unavailable
  end
  
  # GET /music/genres
  # Get available music genres and styles
  def genres
    render json: {
      success: true,
      genres: {
        electronic: [
          "EDM", "House", "Techno", "Trance", "Dubstep",
          "Ambient", "Chillout", "Synthwave", "Drum and Bass"
        ],
        orchestral: [
          "Classical", "Film Score", "Epic Orchestral", 
          "Chamber Music", "Baroque", "Romantic"
        ],
        popular: [
          "Pop", "Rock", "Alternative", "Hip-Hop", 
          "R&B", "Country", "Folk", "Indie"
        ],
        jazz: [
          "Traditional Jazz", "Smooth Jazz", "Blues", 
          "Soul", "Fusion", "Bebop"
        ],
        world: [
          "Celtic", "Medieval", "World Fusion", 
          "New Age", "Meditation", "Ethnic"
        ]
      },
      moods: [
        "Happy", "Sad", "Energetic", "Calm", "Mysterious",
        "Dramatic", "Peaceful", "Intense", "Uplifting", "Dark"
      ],
      instruments: [
        "Piano", "Guitar", "Violin", "Drums", "Synthesizer",
        "Orchestra", "Saxophone", "Flute", "Cello", "Trumpet"
      ]
    }
  end
  
  # POST /music/batch_generate
  # Generate multiple music tracks from a list of prompts
  def batch_generate
    prompts = params[:prompts] || []
    
    if prompts.empty?
      return render json: { 
        success: false, 
        error: "At least one prompt is required" 
      }, status: :bad_request
    end
    
    results = []
    errors = []
    
    prompts.each_with_index do |prompt_config, index|
      begin
        prompt = prompt_config[:prompt] || prompt_config["prompt"]
        duration = prompt_config[:duration_ms] || prompt_config["duration_ms"] || 30000
        
        audio_data = @client.music.compose(
          prompt: prompt,
          music_length_ms: duration,
          output_format: "mp3_44100_128"
        )
        
        # Save to temporary file
        filename = "batch_#{index}_#{generate_filename(prompt)}"
        filepath = Rails.root.join("tmp", filename)
        
        File.open(filepath, "wb") { |f| f.write(audio_data) }
        
        results << {
          index: index,
          prompt: prompt,
          filename: filename,
          file_size: audio_data.bytesize,
          duration_ms: duration,
          download_url: "/music/download/#{filename}"
        }
        
      rescue ElevenlabsClient::APIError => e
        errors << {
          index: index,
          prompt: prompt_config[:prompt],
          error: e.message
        }
      end
    end
    
    render json: {
      success: errors.empty?,
      results: results,
      errors: errors,
      summary: {
        total: prompts.length,
        successful: results.length,
        failed: errors.length
      }
    }
  end
  
  # GET /music/download/:filename
  # Download a generated music file
  def download
    filename = params[:filename]
    filepath = Rails.root.join("tmp", filename)
    
    unless File.exist?(filepath)
      return render json: { 
        success: false, 
        error: "File not found" 
      }, status: :not_found
    end
    
    send_file filepath,
              type: "audio/mpeg",
              filename: filename,
              disposition: "attachment"
  end
  
  # POST /music/interactive
  # Generate adaptive music based on user preferences
  def interactive
    base_prompt = params[:base_prompt]
    preferences = params[:preferences] || {}
    
    unless base_prompt.present?
      return render json: { 
        success: false, 
        error: "Base prompt is required" 
      }, status: :bad_request
    end
    
    # Enhance prompt with user preferences
    enhanced_prompt = enhance_prompt_with_preferences(base_prompt, preferences)
    
    # Create adaptive composition plan
    plan = @client.music.create_plan(
      prompt: enhanced_prompt,
      music_length_ms: preferences[:duration_ms] || 60000
    )
    
    # Modify plan based on preferences
    adapted_plan = adapt_plan_to_preferences(plan, preferences)
    
    # Generate final music
    audio_data = @client.music.compose(
      prompt: enhanced_prompt,
      composition_plan: adapted_plan["sections"],
      music_length_ms: adapted_plan["total_duration_ms"]
    )
    
    render json: {
      success: true,
      enhanced_prompt: enhanced_prompt,
      adapted_plan: adapted_plan,
      audio_size: audio_data.bytesize
    }
    
    # Also send the audio
    response.headers['X-Enhanced-Prompt'] = enhanced_prompt
    send_data audio_data,
              type: "audio/mpeg",
              filename: generate_filename("interactive_#{base_prompt}")
              
  rescue ElevenlabsClient::APIError => e
    render json: { 
      success: false, 
      error: "Interactive generation failed", 
      details: e.message 
    }, status: :service_unavailable
  end
  
  # GET /music/library
  # Generate a collection of music variations on a theme
  def library
    theme = params[:theme]
    count = [params[:count]&.to_i || 5, 10].min  # Max 10 variations
    
    unless theme.present?
      return render json: { 
        success: false, 
        error: "Theme is required" 
      }, status: :bad_request
    end
    
    variations = generate_music_variations(theme, count)
    
    render json: {
      success: true,
      theme: theme,
      variations: variations.map do |variation|
        {
          mood: variation[:mood],
          prompt: variation[:prompt],
          filename: variation[:filename],
          file_size: variation[:audio_data].bytesize,
          download_url: "/music/download/#{variation[:filename]}"
        }
      end,
      total_count: variations.length
    }
  end
  
  private
  
  def initialize_client
    @client = ElevenlabsClient.new
  end
  
  def generate_filename(prompt)
    # Create safe filename from prompt
    safe_name = prompt.gsub(/[^a-zA-Z0-9\s]/, "")
                     .strip
                     .gsub(/\s+/, "_")
                     .downcase[0..50]  # Limit length
    
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    "#{safe_name}_#{timestamp}.mp3"
  end
  
  def parse_composition_plan(plan_param)
    return nil unless plan_param.present?
    
    case plan_param
    when String
      JSON.parse(plan_param)
    when Hash
      plan_param
    else
      nil
    end
  rescue JSON::ParserError
    nil
  end
  
  def parse_multipart_response(multipart_data)
    # Simple multipart parser - in production, use a proper multipart parser
    parts = multipart_data.split(/--[\w\-]+/)
    
    metadata = nil
    audio_data = nil
    
    parts.each do |part|
      if part.include?("Content-Type: application/json")
        json_start = part.index("{")
        json_data = part[json_start..-1] if json_start
        metadata = JSON.parse(json_data) if json_data
      elsif part.include?("Content-Type: audio/mpeg")
        # Extract binary audio data
        audio_start = part.index("\r\n\r\n")
        audio_data = part[audio_start + 4..-1] if audio_start
      end
    end
    
    [metadata || {}, audio_data || ""]
  rescue => e
    Rails.logger.error "Failed to parse multipart response: #{e.message}"
    [{}, multipart_data]  # Return raw data if parsing fails
  end
  
  def save_composition(prompt, metadata, audio_data)
    # Example composition model - adjust based on your schema
    Composition.create!(
      prompt: prompt,
      metadata: metadata,
      audio_data: audio_data,
      file_size: audio_data.bytesize,
      duration_ms: metadata["duration_ms"],
      created_at: Time.current
    )
  end
  
  def retrieve_stored_plan(plan_id)
    # Retrieve from database, cache, or external service
    # This is a placeholder - implement based on your storage strategy
    Rails.cache.read("composition_plan_#{plan_id}")
  end
  
  def enhance_prompt_with_preferences(base_prompt, preferences)
    enhancements = []
    
    enhancements << "with #{preferences[:mood]} mood" if preferences[:mood]
    enhancements << "featuring #{preferences[:instruments]}" if preferences[:instruments]
    enhancements << "at #{preferences[:tempo]} tempo" if preferences[:tempo]
    enhancements << "in #{preferences[:key]} key" if preferences[:key]
    enhancements << "with #{preferences[:energy_level]} energy" if preferences[:energy_level]
    
    [base_prompt, *enhancements].join(" ")
  end
  
  def adapt_plan_to_preferences(plan, preferences)
    return plan unless preferences.present?
    
    plan["sections"].each do |section|
      # Adjust tempo based on energy level
      if preferences[:energy_level]
        multiplier = case preferences[:energy_level]
                    when "low" then 0.8
                    when "high" then 1.3
                    else 1.0
                    end
        section["tempo"] = (section["tempo"] * multiplier).to_i
      end
      
      # Filter instruments based on preference
      if preferences[:instrument_preference] && section["instruments"]
        preferred = preferences[:instrument_preference]
        section["instruments"] = section["instruments"].select { |inst| inst.include?(preferred) }
      end
    end
    
    plan
  end
  
  def generate_music_variations(theme, count)
    moods = [
      "upbeat and energetic",
      "calm and relaxing", 
      "dramatic and intense",
      "mysterious and atmospheric",
      "happy and uplifting",
      "dark and brooding",
      "peaceful and serene",
      "exciting and adventurous"
    ]
    
    variations = []
    
    moods.first(count).each_with_index do |mood, index|
      prompt = "#{theme} music that is #{mood}"
      
      audio_data = @client.music.compose(
        prompt: prompt,
        music_length_ms: 30000,  # 30 seconds each
        output_format: "mp3_44100_128"
      )
      
      filename = "#{theme.downcase.gsub(' ', '_')}_#{mood.downcase.gsub(' ', '_')}_#{Time.current.to_i}.mp3"
      filepath = Rails.root.join("tmp", filename)
      
      # Save to temporary file
      File.open(filepath, "wb") { |f| f.write(audio_data) }
      
      variations << {
        mood: mood,
        prompt: prompt,
        filename: filename,
        audio_data: audio_data
      }
    end
    
    variations
  end
end

# Example routes for config/routes.rb:
#
# Rails.application.routes.draw do
#   scope '/music' do
#     post 'generate', to: 'music#generate'
#     post 'stream', to: 'music#stream'
#     post 'detailed', to: 'music#detailed'
#     post 'plan', to: 'music#create_plan'
#     post 'compose_with_plan', to: 'music#compose_with_plan'
#     post 'batch_generate', to: 'music#batch_generate'
#     post 'interactive', to: 'music#interactive'
#     get 'genres', to: 'music#genres'
#     get 'library', to: 'music#library'
#     get 'download/:filename', to: 'music#download'
#   end
# end

# Example usage in JavaScript:
#
# // Generate basic music
# fetch('/music/generate', {
#   method: 'POST',
#   headers: { 'Content-Type': 'application/json' },
#   body: JSON.stringify({
#     prompt: 'Upbeat electronic dance music',
#     duration_ms: 45000,
#     output_format: 'mp3_44100_128'
#   })
# })
# .then(response => response.blob())
# .then(audioBlob => {
#   const audioUrl = URL.createObjectURL(audioBlob);
#   const audio = new Audio(audioUrl);
#   audio.play();
# });
#
# // Stream music in real-time
# fetch('/music/stream', {
#   method: 'POST',
#   headers: { 'Content-Type': 'application/json' },
#   body: JSON.stringify({
#     prompt: 'Relaxing ambient music',
#     duration_ms: 60000
#   })
# })
# .then(response => {
#   const reader = response.body.getReader();
#   const audioContext = new AudioContext();
#   
#   function readChunk() {
#     reader.read().then(({ done, value }) => {
#       if (!done) {
#         // Process audio chunk
#         audioContext.decodeAudioData(value.buffer).then(audioBuffer => {
#           // Play the chunk
#           const source = audioContext.createBufferSource();
#           source.buffer = audioBuffer;
#           source.connect(audioContext.destination);
#           source.start();
#         });
#         readChunk();
#       }
#     });
#   }
#   readChunk();
# });
#
# // Create composition plan
# fetch('/music/plan', {
#   method: 'POST',
#   headers: { 'Content-Type': 'application/json' },
#   body: JSON.stringify({
#     prompt: 'Epic orchestral soundtrack',
#     duration_ms: 120000
#   })
# })
# .then(response => response.json())
# .then(data => {
#   console.log('Composition plan:', data.plan);
#   console.log('Sections:', data.sections);
# });
#
# // Generate music library
# fetch('/music/library?theme=Fantasy Adventure&count=5')
#   .then(response => response.json())
#   .then(data => {
#     console.log('Music variations:', data.variations);
#     data.variations.forEach(variation => {
#       console.log(`${variation.mood}: ${variation.download_url}`);
#     });
#   });
