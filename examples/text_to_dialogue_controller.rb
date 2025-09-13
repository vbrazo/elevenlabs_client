# frozen_string_literal: true

# Example Rails controller showing how to use ElevenLabs Text-to-Dialogue
# Place this in app/controllers/text_to_dialogue_controller.rb

class TextToDialogueController < ApplicationController
  before_action :validate_dialogue_params, only: [:create]

  # POST /text_to_dialogue
  # Convert dialogue inputs to speech
  #
  # Parameters:
  #   - dialogue: Array (required) - Array of dialogue inputs
  #     Each input should have:
  #     - text: String (required) - The text to convert
  #     - voice_id: String (required) - The voice ID to use
  #   - model_id: String (optional) - Model to use
  #   - settings: Hash (optional) - Dialogue settings
  #     - stability: Float (optional) - Voice stability (0.0-1.0)
  #     - use_speaker_boost: Boolean (optional) - Enable speaker boost
  #   - seed: Integer (optional) - Deterministic seed
  #   - format: String (optional) - Response format ("audio" or "json")
  def create
    client = ElevenlabsClient.new
    
    begin
      dialogue_inputs = build_dialogue_inputs
      options = build_dialogue_options
      
      audio_data = client.text_to_dialogue.convert(dialogue_inputs, **options)
      
      if params[:format] == 'json'
        # Return base64 encoded audio for JSON responses
        render json: {
          audio_data: Base64.encode64(audio_data),
          format: 'mp3',
          size: audio_data.bytesize,
          dialogue_count: dialogue_inputs.length
        }
      else
        # Return raw audio file
        send_data audio_data,
                  type: 'audio/mpeg',
                  filename: generate_filename,
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
        error: 'Invalid dialogue parameters', 
        message: e.message 
      }, status: :bad_request
      
    rescue ElevenlabsClient::APIError => e
      render json: { 
        error: 'API error', 
        message: e.message 
      }, status: :internal_server_error
    end
  end

  # POST /text_to_dialogue/preview
  # Generate a preview of the dialogue (first 3 inputs only)
  def preview
    unless params[:dialogue].is_a?(Array) && params[:dialogue].any?
      render json: { error: 'dialogue parameter is required and must be a non-empty array' }, status: :bad_request
      return
    end
    
    client = ElevenlabsClient.new
    
    begin
      # Take only first 3 dialogue inputs for preview
      preview_inputs = params[:dialogue].first(3).map do |input|
        {
          text: input[:text],
          voice_id: input[:voice_id]
        }
      end
      
      audio_data = client.text_to_dialogue.convert(preview_inputs)
      
      send_data audio_data,
                type: 'audio/mpeg',
                filename: 'dialogue_preview.mp3',
                disposition: 'inline'
                
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # POST /text_to_dialogue/customer_service
  # Specialized endpoint for customer service dialogues
  def customer_service
    unless params[:agent_voice_id] && params[:customer_voice_id] && params[:conversation]
      render json: { 
        error: 'agent_voice_id, customer_voice_id, and conversation are required' 
      }, status: :bad_request
      return
    end
    
    client = ElevenlabsClient.new
    
    begin
      dialogue_inputs = params[:conversation].map do |message|
        voice_id = message[:speaker] == 'agent' ? params[:agent_voice_id] : params[:customer_voice_id]
        {
          text: message[:text],
          voice_id: voice_id
        }
      end
      
      audio_data = client.text_to_dialogue.convert(
        dialogue_inputs,
        model_id: params[:model_id] || "eleven_multilingual_v1",
        settings: {
          stability: 0.6,
          use_speaker_boost: true
        }
      )
      
      send_data audio_data,
                type: 'audio/mpeg',
                filename: 'customer_service_dialogue.mp3',
                disposition: 'attachment'
                
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # POST /text_to_dialogue/story
  # Specialized endpoint for storytelling with multiple characters
  def story
    unless params[:characters] && params[:script]
      render json: { 
        error: 'characters and script parameters are required' 
      }, status: :bad_request
      return
    end
    
    client = ElevenlabsClient.new
    
    begin
      # Map character names to voice IDs
      character_voices = params[:characters].to_h { |char| [char[:name], char[:voice_id]] }
      
      dialogue_inputs = params[:script].map do |line|
        voice_id = character_voices[line[:character]] || character_voices['narrator']
        {
          text: line[:text],
          voice_id: voice_id
        }
      end
      
      audio_data = client.text_to_dialogue.convert(
        dialogue_inputs,
        model_id: params[:model_id] || "eleven_multilingual_v1",
        settings: {
          stability: params[:stability]&.to_f || 0.7,
          use_speaker_boost: false
        },
        seed: params[:seed]&.to_i
      )
      
      send_data audio_data,
                type: 'audio/mpeg',
                filename: "story_#{params[:title]&.parameterize || 'untitled'}.mp3",
                disposition: 'attachment'
                
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # POST /text_to_dialogue/educational
  # Specialized endpoint for educational content with teacher-student dialogue
  def educational
    unless params[:teacher_voice_id] && params[:student_voice_id] && params[:lesson]
      render json: { 
        error: 'teacher_voice_id, student_voice_id, and lesson are required' 
      }, status: :bad_request
      return
    end
    
    client = ElevenlabsClient.new
    
    begin
      dialogue_inputs = params[:lesson].map do |exchange|
        voice_id = case exchange[:speaker]
                   when 'teacher' then params[:teacher_voice_id]
                   when 'student' then params[:student_voice_id]
                   else params[:narrator_voice_id] || params[:teacher_voice_id]
                   end
        
        {
          text: exchange[:text],
          voice_id: voice_id
        }
      end
      
      audio_data = client.text_to_dialogue.convert(
        dialogue_inputs,
        model_id: "eleven_multilingual_v1",
        settings: {
          stability: 0.8,  # Higher stability for educational content
          use_speaker_boost: true
        }
      )
      
      send_data audio_data,
                type: 'audio/mpeg',
                filename: "lesson_#{params[:subject]&.parameterize || 'educational'}.mp3",
                disposition: 'attachment'
                
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # GET /text_to_dialogue/voices
  # Helper endpoint to list available voices (you'd need to implement this)
  def voices
    # This would typically fetch from your voice management system
    # or from ElevenLabs voices API if available
    render json: {
      voices: [
        { id: "21m00Tcm4TlvDq8ikWAM", name: "Rachel", gender: "female", accent: "american" },
        { id: "pNInz6obpgDQGcFmaJgB", name: "Adam", gender: "male", accent: "american" },
        { id: "yoZ06aMxZJJ28mfd3POQ", name: "Sam", gender: "male", accent: "american" }
      ]
    }
  end

  private

  def validate_dialogue_params
    unless params[:dialogue].is_a?(Array) && params[:dialogue].any?
      render json: { error: 'dialogue parameter is required and must be a non-empty array' }, status: :bad_request
      return
    end

    params[:dialogue].each_with_index do |input, index|
      unless input[:text].present? && input[:voice_id].present?
        render json: { 
          error: "dialogue[#{index}] must have both text and voice_id" 
        }, status: :bad_request
        return
      end
      
      if input[:text].length > 1000
        render json: { 
          error: "dialogue[#{index}] text is too long (max 1000 characters)" 
        }, status: :bad_request
        return
      end
    end

    if params[:dialogue].length > 50
      render json: { 
        error: 'Too many dialogue inputs (max 50)' 
      }, status: :bad_request
      return
    end
  end

  def build_dialogue_inputs
    params[:dialogue].map do |input|
      {
        text: input[:text],
        voice_id: input[:voice_id]
      }
    end
  end

  def build_dialogue_options
    options = {}
    
    options[:model_id] = params[:model_id] if params[:model_id].present?
    options[:seed] = params[:seed].to_i if params[:seed].present?
    
    if params[:settings].present?
      settings = {}
      settings[:stability] = params[:settings][:stability].to_f if params[:settings][:stability].present?
      settings[:use_speaker_boost] = params[:settings][:use_speaker_boost] == 'true' if params[:settings][:use_speaker_boost].present?
      options[:settings] = settings if settings.any?
    end
    
    options
  end

  def generate_filename
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    dialogue_count = params[:dialogue].length
    "dialogue_#{dialogue_count}_voices_#{timestamp}.mp3"
  end
end
