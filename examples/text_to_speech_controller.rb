# frozen_string_literal: true

# Example Rails controller showing how to use ElevenLabs Text-to-Speech
# Place this in app/controllers/text_to_speech_controller.rb

class TextToSpeechController < ApplicationController
  before_action :validate_params, only: [:create]

  # POST /text_to_speech
  # Convert text to speech and return audio file
  #
  # Parameters:
  #   - voice_id: String (required) - ElevenLabs voice ID
  #   - text: String (required) - Text to convert to speech
  #   - model_id: String (optional) - Model to use (e.g., "eleven_monolingual_v1")
  #   - stability: Float (optional) - Voice stability (0.0-1.0)
  #   - similarity_boost: Float (optional) - Similarity boost (0.0-1.0)
  #   - style: Float (optional) - Style setting (0.0-1.0)
  #   - use_speaker_boost: Boolean (optional) - Enable speaker boost
  #   - optimize_streaming: Boolean (optional) - Optimize for streaming
  def create
    client = ElevenlabsClient.new
    
    options = build_tts_options
    
    audio_data = client.text_to_speech.convert(
      params[:voice_id],
      params[:text],
      **options
    )
    
    # Return the audio file
    send_data audio_data, 
              type: 'audio/mpeg', 
              filename: "speech_#{Time.current.to_i}.mp3",
              disposition: params[:download] ? 'attachment' : 'inline'
              
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
      error: 'Invalid parameters', 
      message: e.message 
    }, status: :bad_request
    
  rescue ElevenlabsClient::APIError => e
    render json: { 
      error: 'API error', 
      message: e.message 
    }, status: :internal_server_error
  end

  # GET /text_to_speech/voices
  # This would be implemented when voice listing endpoint is added
  def voices
    # TODO: Implement when voices endpoint is added to the client
    render json: { message: 'Voices endpoint not yet implemented' }
  end

  private

  def validate_params
    if params[:voice_id].blank?
      render json: { error: 'voice_id is required' }, status: :bad_request
      return
    end

    if params[:text].blank?
      render json: { error: 'text is required' }, status: :bad_request
      return
    end

    if params[:text].length > 5000  # Adjust limit as needed
      render json: { error: 'text is too long (max 5000 characters)' }, status: :bad_request
      return
    end
  end

  def build_tts_options
    options = {}
    
    # Add model if specified
    options[:model_id] = params[:model_id] if params[:model_id].present?
    
    # Add streaming optimization if requested
    options[:optimize_streaming] = true if params[:optimize_streaming] == 'true'
    
    # Build voice settings if any are provided
    voice_settings = {}
    voice_settings[:stability] = params[:stability].to_f if params[:stability].present?
    voice_settings[:similarity_boost] = params[:similarity_boost].to_f if params[:similarity_boost].present?
    voice_settings[:style] = params[:style].to_f if params[:style].present?
    voice_settings[:use_speaker_boost] = params[:use_speaker_boost] == 'true' if params[:use_speaker_boost].present?
    
    options[:voice_settings] = voice_settings if voice_settings.any?
    
    options
  end
end
