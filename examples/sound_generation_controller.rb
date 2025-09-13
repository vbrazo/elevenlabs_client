# frozen_string_literal: true

# Example Rails controller showing how to use ElevenLabs Sound Generation
# Place this in app/controllers/sound_generation_controller.rb

class SoundGenerationController < ApplicationController
  before_action :validate_sound_params, only: [:create]

  # POST /sound_generation
  # Generate sound effects from text prompts
  #
  # Parameters:
  #   - text: String (required) - Text prompt describing the sound effect
  #   - loop: Boolean (optional) - Whether to create a looping sound effect
  #   - duration_seconds: Float (optional) - Duration in seconds (0.5 to 30)
  #   - prompt_influence: Float (optional) - Prompt influence (0.0 to 1.0)
  #   - output_format: String (optional) - Output format (e.g., "mp3_22050_32")
  #   - format: String (optional) - Response format ("audio" or "json")
  def create
    client = ElevenlabsClient.new
    
    begin
      options = build_sound_options
      
      audio_data = client.sound_generation.generate(params[:text], **options)
      
      if params[:format] == 'json'
        # Return base64 encoded audio for JSON responses
        render json: {
          audio_data: Base64.encode64(audio_data),
          format: determine_audio_format(options[:output_format]),
          size: audio_data.bytesize,
          prompt: params[:text],
          options: options
        }
      else
        # Return raw audio file
        send_data audio_data,
                  type: determine_content_type(options[:output_format]),
                  filename: generate_filename(params[:text], options),
                  disposition: params[:download] == 'true' ? 'attachment' : 'inline'
      end
      
    rescue ElevenlabsClient::AuthenticationError
      render json: { 
        error: 'Authentication failed', 
        message: 'Invalid API key or authentication failed' 
      }, status: :unauthorized
      
    rescue ElevenlabsClient::RateLimitError
      render json: { 
        error: 'Rate limit exceeded', 
        message: 'Too many requests. Please try again later.' 
      }, status: :too_many_requests
      
    rescue ElevenlabsClient::ValidationError => e
      render json: { 
        error: 'Invalid sound generation parameters', 
        message: e.message 
      }, status: :bad_request
      
    rescue ElevenlabsClient::APIError => e
      render json: { 
        error: 'API error', 
        message: e.message 
      }, status: :internal_server_error
    end
  end

  # POST /sound_generation/nature
  # Generate nature sound effects with optimized settings
  def nature
    unless params[:sound_type].present?
      render json: { error: 'sound_type parameter is required' }, status: :bad_request
      return
    end
    
    client = ElevenlabsClient.new
    
    begin
      # Predefined nature sound prompts
      nature_prompts = {
        'rain' => 'Gentle rain falling on leaves in a peaceful forest',
        'ocean' => 'Ocean waves gently lapping against the shore',
        'forest' => 'Birds chirping and wind rustling through tree leaves',
        'thunder' => 'Distant thunder rolling across the sky with light rain',
        'stream' => 'Babbling brook flowing over smooth stones',
        'wind' => 'Gentle wind blowing through tall grass and trees'
      }
      
      prompt = nature_prompts[params[:sound_type]]
      unless prompt
        render json: { 
          error: 'Invalid sound_type', 
          available_types: nature_prompts.keys 
        }, status: :bad_request
        return
      end
      
      # Nature sounds work well with looping and longer duration
      audio_data = client.sound_generation.generate(
        prompt,
        loop: true,
        duration_seconds: params[:duration_seconds]&.to_f || 30.0,
        prompt_influence: 0.6,
        output_format: params[:output_format] || "mp3_44100_128"
      )
      
      send_data audio_data,
                type: 'audio/mpeg',
                filename: "nature_#{params[:sound_type]}.mp3",
                disposition: 'attachment'
                
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # POST /sound_generation/ambient
  # Generate ambient sound effects for backgrounds
  def ambient
    unless params[:environment].present?
      render json: { error: 'environment parameter is required' }, status: :bad_request
      return
    end
    
    client = ElevenlabsClient.new
    
    begin
      # Predefined ambient environment prompts
      ambient_prompts = {
        'cafe' => 'Busy coffee shop with gentle chatter and espresso machine sounds',
        'library' => 'Quiet library with occasional page turning and whispers',
        'office' => 'Modern office with keyboard typing and quiet conversations',
        'city' => 'Urban street with distant traffic and pedestrian sounds',
        'fireplace' => 'Crackling fireplace with gentle wood burning sounds',
        'workshop' => 'Artisan workshop with tools and crafting sounds'
      }
      
      prompt = ambient_prompts[params[:environment]]
      unless prompt
        render json: { 
          error: 'Invalid environment', 
          available_environments: ambient_prompts.keys 
        }, status: :bad_request
        return
      end
      
      # Ambient sounds benefit from looping and moderate prompt influence
      audio_data = client.sound_generation.generate(
        prompt,
        loop: true,
        duration_seconds: params[:duration_seconds]&.to_f || 60.0,
        prompt_influence: 0.5
      )
      
      send_data audio_data,
                type: 'audio/mpeg',
                filename: "ambient_#{params[:environment]}.mp3",
                disposition: 'attachment'
                
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # POST /sound_generation/sfx
  # Generate short sound effects for games, apps, or media
  def sfx
    unless params[:effect_type].present?
      render json: { error: 'effect_type parameter is required' }, status: :bad_request
      return
    end
    
    client = ElevenlabsClient.new
    
    begin
      # Predefined sound effect prompts
      sfx_prompts = {
        'notification' => 'Gentle notification chime, pleasant and attention-getting',
        'success' => 'Positive success sound, uplifting and satisfying',
        'error' => 'Subtle error sound, not harsh but clearly indicating a problem',
        'click' => 'Clean button click sound, crisp and responsive',
        'whoosh' => 'Smooth whoosh transition sound',
        'pop' => 'Light pop sound, playful and quick',
        'ding' => 'Clear bell ding, bright and clean',
        'buzz' => 'Short buzz sound, attention-grabbing but not annoying'
      }
      
      prompt = sfx_prompts[params[:effect_type]]
      unless prompt
        render json: { 
          error: 'Invalid effect_type', 
          available_effects: sfx_prompts.keys 
        }, status: :bad_request
        return
      end
      
      # Sound effects are typically short and don't loop
      audio_data = client.sound_generation.generate(
        prompt,
        loop: false,
        duration_seconds: params[:duration_seconds]&.to_f || 1.0,
        prompt_influence: 0.8  # Higher influence for precise sound effects
      )
      
      send_data audio_data,
                type: 'audio/mpeg',
                filename: "sfx_#{params[:effect_type]}.mp3",
                disposition: 'attachment'
                
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # POST /sound_generation/custom
  # Generate custom sound effects with full parameter control
  def custom
    unless params[:prompt].present?
      render json: { error: 'prompt parameter is required' }, status: :bad_request
      return
    end
    
    client = ElevenlabsClient.new
    
    begin
      options = {}
      options[:loop] = params[:loop] == 'true' if params[:loop].present?
      options[:duration_seconds] = params[:duration_seconds].to_f if params[:duration_seconds].present?
      options[:prompt_influence] = params[:prompt_influence].to_f if params[:prompt_influence].present?
      options[:output_format] = params[:output_format] if params[:output_format].present?
      
      audio_data = client.sound_generation.generate(params[:prompt], **options)
      
      send_data audio_data,
                type: determine_content_type(options[:output_format]),
                filename: "custom_sound_#{Time.current.to_i}.#{file_extension(options[:output_format])}",
                disposition: 'attachment'
                
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # GET /sound_generation/presets
  # List available sound generation presets
  def presets
    render json: {
      nature: {
        description: "Natural environment sounds",
        types: ['rain', 'ocean', 'forest', 'thunder', 'stream', 'wind'],
        recommended_settings: {
          loop: true,
          duration_seconds: 30.0,
          prompt_influence: 0.6
        }
      },
      ambient: {
        description: "Background ambient sounds",
        environments: ['cafe', 'library', 'office', 'city', 'fireplace', 'workshop'],
        recommended_settings: {
          loop: true,
          duration_seconds: 60.0,
          prompt_influence: 0.5
        }
      },
      sfx: {
        description: "Short sound effects",
        effects: ['notification', 'success', 'error', 'click', 'whoosh', 'pop', 'ding', 'buzz'],
        recommended_settings: {
          loop: false,
          duration_seconds: 1.0,
          prompt_influence: 0.8
        }
      },
      output_formats: [
        "mp3_44100_128",
        "mp3_22050_32",
        "pcm_16000",
        "pcm_24000"
      ]
    }
  end

  # POST /sound_generation/batch
  # Generate multiple sound effects in one request
  def batch
    unless params[:sounds].is_a?(Array) && params[:sounds].any?
      render json: { error: 'sounds parameter must be a non-empty array' }, status: :bad_request
      return
    end
    
    client = ElevenlabsClient.new
    results = []
    errors = []
    
    params[:sounds].each_with_index do |sound_params, index|
      begin
        next unless sound_params[:text].present?
        
        options = {}
        options[:loop] = sound_params[:loop] if sound_params[:loop].present?
        options[:duration_seconds] = sound_params[:duration_seconds].to_f if sound_params[:duration_seconds].present?
        options[:prompt_influence] = sound_params[:prompt_influence].to_f if sound_params[:prompt_influence].present?
        options[:output_format] = sound_params[:output_format] if sound_params[:output_format].present?
        
        audio_data = client.sound_generation.generate(sound_params[:text], **options)
        
        results << {
          index: index,
          text: sound_params[:text],
          audio_data: Base64.encode64(audio_data),
          size: audio_data.bytesize,
          options: options
        }
        
      rescue => e
        errors << {
          index: index,
          text: sound_params[:text],
          error: e.message
        }
      end
    end
    
    render json: {
      successful: results,
      failed: errors,
      total_processed: params[:sounds].length
    }
  end

  private

  def validate_sound_params
    unless params[:text].present?
      render json: { error: 'text parameter is required' }, status: :bad_request
      return
    end

    if params[:text].length > 500
      render json: { 
        error: 'Text prompt is too long (max 500 characters)' 
      }, status: :bad_request
      return
    end

    if params[:duration_seconds].present?
      duration = params[:duration_seconds].to_f
      if duration < 0.5 || duration > 30.0
        render json: { 
          error: 'duration_seconds must be between 0.5 and 30.0' 
        }, status: :bad_request
        return
      end
    end

    if params[:prompt_influence].present?
      influence = params[:prompt_influence].to_f
      if influence < 0.0 || influence > 1.0
        render json: { 
          error: 'prompt_influence must be between 0.0 and 1.0' 
        }, status: :bad_request
        return
      end
    end
  end

  def build_sound_options
    options = {}
    
    options[:loop] = params[:loop] == 'true' if params[:loop].present?
    options[:duration_seconds] = params[:duration_seconds].to_f if params[:duration_seconds].present?
    options[:prompt_influence] = params[:prompt_influence].to_f if params[:prompt_influence].present?
    options[:output_format] = params[:output_format] if params[:output_format].present?
    
    options
  end

  def determine_content_type(output_format)
    case output_format
    when /^mp3_/
      'audio/mpeg'
    when /^pcm_/
      'audio/wav'
    else
      'audio/mpeg'
    end
  end

  def determine_audio_format(output_format)
    case output_format
    when /^mp3_/
      'mp3'
    when /^pcm_/
      'wav'
    else
      'mp3'
    end
  end

  def file_extension(output_format)
    case output_format
    when /^mp3_/
      'mp3'
    when /^pcm_/
      'wav'
    else
      'mp3'
    end
  end

  def generate_filename(text, options)
    # Create a safe filename from the text prompt
    safe_text = text.gsub(/[^a-zA-Z0-9\s]/, '').strip.gsub(/\s+/, '_').downcase
    safe_text = safe_text[0..30] if safe_text.length > 30
    
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    extension = file_extension(options[:output_format])
    
    "sound_#{safe_text}_#{timestamp}.#{extension}"
  end
end
