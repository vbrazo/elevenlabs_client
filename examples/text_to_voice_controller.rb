# Example Rails controller demonstrating Text-to-Voice functionality
# This controller provides endpoints for designing voices, creating voices, and managing voice collections

class TextToVoiceController < ApplicationController
  before_action :initialize_client
  
  # POST /text_to_voice/design
  # Design a voice from a text description
  def design
    result = @client.text_to_voice.design(
      params[:voice_description],
      design_options
    )
    
    render json: {
      success: true,
      previews: format_previews(result["previews"]),
      generated_text: result["text"],
      message: "Voice design completed successfully"
    }
    
  rescue ElevenlabsClient::ValidationError => e
    render json: { 
      success: false, 
      error: "Invalid voice description", 
      details: e.message 
    }, status: :bad_request
  rescue ElevenlabsClient::RateLimitError
    render json: { 
      success: false, 
      error: "Rate limit exceeded. Please try again later." 
    }, status: :too_many_requests
  rescue ElevenlabsClient::APIError => e
    render json: { 
      success: false, 
      error: "Voice design failed", 
      details: e.message 
    }, status: :unprocessable_entity
  end
  
  # POST /text_to_voice/create
  # Create a permanent voice from a generated voice ID
  def create_voice
    result = @client.text_to_voice.create(
      params[:voice_name],
      params[:voice_description],
      params[:generated_voice_id],
      creation_options
    )
    
    render json: {
      success: true,
      voice_id: result["voice_id"],
      name: result["name"],
      category: result["category"],
      message: "Voice created successfully"
    }
    
  rescue ElevenlabsClient::ValidationError => e
    render json: { 
      success: false, 
      error: "Invalid voice creation parameters", 
      details: e.message 
    }, status: :bad_request
  rescue ElevenlabsClient::APIError => e
    render json: { 
      success: false, 
      error: "Voice creation failed", 
      details: e.message 
    }, status: :unprocessable_entity
  end
  
  # GET /text_to_voice/voices
  # List all available voices
  def list_voices
    voices = @client.text_to_voice.list_voices
    
    # Filter and categorize voices
    categorized_voices = categorize_voices(voices["voices"])
    
    render json: {
      success: true,
      voices: categorized_voices,
      total_count: voices["voices"].length,
      categories: categorized_voices.keys
    }
    
  rescue ElevenlabsClient::APIError => e
    render json: { 
      success: false, 
      error: "Failed to retrieve voices", 
      details: e.message 
    }, status: :service_unavailable
  end
  
  # POST /text_to_voice/design_business_voice
  # Specialized endpoint for business voice design
  def design_business_voice
    business_description = generate_business_description(params)
    
    result = @client.text_to_voice.design(
      business_description,
      model_id: "eleven_multilingual_ttv_v2",
      auto_generate_text: true,
      loudness: 0.6,
      guidance_scale: 6.0,
      seed: params[:seed]&.to_i
    )
    
    render json: {
      success: true,
      voice_description: business_description,
      previews: format_previews(result["previews"]),
      business_context: {
        industry: params[:industry],
        tone: params[:tone],
        use_case: params[:use_case]
      }
    }
  end
  
  # POST /text_to_voice/design_character_voice
  # Specialized endpoint for character/gaming voice design
  def design_character_voice
    character_description = generate_character_description(params)
    
    result = @client.text_to_voice.design(
      character_description,
      model_id: "eleven_ttv_v3",
      auto_generate_text: false,
      text: params[:sample_dialogue] || "Greetings, adventurer! What brings you to these lands?",
      loudness: params[:loudness]&.to_f || 0.7,
      guidance_scale: params[:guidance_scale]&.to_f || 8.0,
      quality: 0.9
    )
    
    render json: {
      success: true,
      character_description: character_description,
      previews: format_previews(result["previews"]),
      character_context: {
        character_type: params[:character_type],
        personality: params[:personality],
        age_range: params[:age_range],
        accent: params[:accent]
      }
    }
  end
  
  # POST /text_to_voice/design_with_reference
  # Design voice using reference audio (requires eleven_ttv_v3)
  def design_with_reference
    unless params[:reference_audio].present?
      return render json: { 
        success: false, 
        error: "Reference audio is required" 
      }, status: :bad_request
    end
    
    # Convert uploaded file to base64
    reference_audio_base64 = Base64.encode64(params[:reference_audio].read)
    
    result = @client.text_to_voice.design(
      params[:voice_description],
      model_id: "eleven_ttv_v3",
      reference_audio_base64: reference_audio_base64,
      prompt_strength: params[:prompt_strength]&.to_f || 0.7,
      quality: params[:quality]&.to_f || 0.8,
      text: params[:text],
      guidance_scale: params[:guidance_scale]&.to_f || 7.0
    )
    
    render json: {
      success: true,
      previews: format_previews(result["previews"]),
      reference_used: true,
      prompt_strength: params[:prompt_strength]&.to_f || 0.7
    }
    
  rescue => e
    render json: { 
      success: false, 
      error: "Reference audio processing failed", 
      details: e.message 
    }, status: :unprocessable_entity
  end
  
  # POST /text_to_voice/batch_create
  # Create multiple voices from a batch of designs
  def batch_create
    voices_data = params[:voices] || []
    results = []
    errors = []
    
    voices_data.each_with_index do |voice_data, index|
      begin
        result = @client.text_to_voice.create(
          voice_data[:voice_name],
          voice_data[:voice_description],
          voice_data[:generated_voice_id],
          labels: voice_data[:labels] || {}
        )
        
        results << {
          index: index,
          success: true,
          voice_id: result["voice_id"],
          name: result["name"]
        }
      rescue ElevenlabsClient::APIError => e
        errors << {
          index: index,
          voice_name: voice_data[:voice_name],
          error: e.message
        }
      end
    end
    
    render json: {
      success: errors.empty?,
      created_voices: results,
      errors: errors,
      summary: {
        total: voices_data.length,
        successful: results.length,
        failed: errors.length
      }
    }
  end
  
  # GET /text_to_voice/voice_preview/:generated_voice_id
  # Stream audio preview for a generated voice
  def voice_preview
    generated_voice_id = params[:generated_voice_id]
    
    unless generated_voice_id.present?
      return render json: { 
        success: false, 
        error: "generated_voice_id parameter is required" 
      }, status: :bad_request
    end

    begin
      response.headers["Content-Type"] = "audio/mpeg"
      response.headers["Cache-Control"] = "no-cache"
      response.headers["Connection"] = "keep-alive"

      @client.text_to_voice.stream_preview(generated_voice_id) do |chunk|
        response.stream.write(chunk)
      end

    rescue ElevenlabsClient::NotFoundError => e
      render json: { 
        success: false, 
        error: "Generated voice not found", 
        details: e.message 
      }, status: :not_found
    rescue ElevenlabsClient::UnprocessableEntityError => e
      render json: { 
        success: false, 
        error: "Invalid generated voice ID", 
        details: e.message 
      }, status: :unprocessable_entity
    rescue ElevenlabsClient::AuthenticationError => e
      render json: { 
        success: false, 
        error: "Authentication failed", 
        details: e.message 
      }, status: :unauthorized
    rescue ElevenlabsClient::APIError => e
      render json: { 
        success: false, 
        error: "Preview streaming failed", 
        details: e.message 
      }, status: :internal_server_error
    ensure
      response.stream.close
    end
  end
  
  # DELETE /text_to_voice/voices/:voice_id
  # Delete a custom voice (Note: This would require additional ElevenLabs API endpoints)
  def delete_voice
    # This is a placeholder - actual voice deletion would depend on ElevenLabs API
    render json: {
      success: false,
      error: "Voice deletion not implemented",
      message: "Contact ElevenLabs support to delete custom voices"
    }, status: :not_implemented
  end
  
  private
  
  def initialize_client
    @client = ElevenlabsClient.new
  end
  
  def design_options
    {
      model_id: params[:model_id] || "eleven_multilingual_ttv_v2",
      text: params[:text],
      auto_generate_text: params[:auto_generate_text] == 'true',
      loudness: params[:loudness]&.to_f,
      seed: params[:seed]&.to_i,
      guidance_scale: params[:guidance_scale]&.to_f,
      stream_previews: params[:stream_previews] == 'true',
      output_format: params[:output_format],
      quality: params[:quality]&.to_f,
      prompt_strength: params[:prompt_strength]&.to_f
    }.compact
  end
  
  def creation_options
    {
      labels: params[:labels] || {},
      played_not_selected_voice_ids: params[:played_not_selected_voice_ids] || []
    }
  end
  
  def format_previews(previews)
    previews.map do |preview|
      {
        generated_voice_id: preview["generated_voice_id"],
        audio_data_url: "data:audio/mpeg;base64,#{preview['audio_base_64']}",
        text: preview["text"],
        duration_estimate: estimate_duration(preview["text"])
      }
    end
  end
  
  def categorize_voices(voices)
    voices.group_by { |voice| voice["category"] }
          .transform_values do |category_voices|
            category_voices.map do |voice|
              {
                voice_id: voice["voice_id"],
                name: voice["name"],
                labels: voice["labels"] || {},
                preview_url: voice["preview_url"]
              }
            end
          end
  end
  
  def generate_business_description(params)
    industry = params[:industry] || "corporate"
    tone = params[:tone] || "professional"
    gender = params[:gender] || "neutral"
    accent = params[:accent] || "American"
    use_case = params[:use_case] || "presentations"
    
    "#{tone.capitalize} #{gender} voice with #{accent} accent, ideal for #{industry} #{use_case}. " \
    "Clear articulation and confident delivery suitable for business communications."
  end
  
  def generate_character_description(params)
    character_type = params[:character_type] || "hero"
    personality = params[:personality] || "brave"
    age_range = params[:age_range] || "adult"
    accent = params[:accent] || "neutral"
    
    "#{personality.capitalize} #{age_range} #{character_type} with #{accent} accent. " \
    "Distinctive voice suitable for gaming and storytelling applications."
  end
  
  def estimate_duration(text)
    # Rough estimate: average speaking rate is about 150 words per minute
    words = text.split.length
    duration_seconds = (words / 150.0) * 60
    duration_seconds.round(1)
  end
end

# Example routes for config/routes.rb:
#
# Rails.application.routes.draw do
#   namespace :text_to_voice do
#     post :design
#     post :create_voice
#     get :voices, to: :list_voices
#     post :design_business_voice
#     post :design_character_voice
#     post :design_with_reference
#     post :batch_create
#     get 'voice_preview/:generated_voice_id', to: :voice_preview
#     delete 'voices/:voice_id', to: :delete_voice
#   end
# end

# Example usage in JavaScript:
#
# // Design a voice
# fetch('/text_to_voice/design', {
#   method: 'POST',
#   headers: { 'Content-Type': 'application/json' },
#   body: JSON.stringify({
#     voice_description: 'Warm, friendly female voice for customer service',
#     model_id: 'eleven_multilingual_ttv_v2',
#     auto_generate_text: true,
#     loudness: 0.6
#   })
# })
# .then(response => response.json())
# .then(data => {
#   if (data.success) {
#     // Display previews to user
#     data.previews.forEach(preview => {
#       const audio = new Audio(preview.audio_data_url);
#       // Add to UI for user to listen and select
#     });
#   }
# });
#
# // Create voice from selected preview
# fetch('/text_to_voice/create_voice', {
#   method: 'POST',
#   headers: { 'Content-Type': 'application/json' },
#   body: JSON.stringify({
#     voice_name: 'Customer Service Voice',
#     voice_description: 'Warm, friendly female voice for customer service',
#     generated_voice_id: 'selected_preview_id',
#     labels: {
#       use_case: 'customer_service',
#       tone: 'friendly',
#       department: 'support'
#     }
#   })
# })
# .then(response => response.json())
# .then(data => {
#   if (data.success) {
#     console.log('Voice created:', data.voice_id);
#     // Now you can use this voice_id with text-to-speech
#   }
# });
