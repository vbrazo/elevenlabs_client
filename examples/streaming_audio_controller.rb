# frozen_string_literal: true

# Example Rails controller showing how to use ElevenLabs Text-to-Speech Streaming
# Place this in app/controllers/streaming_audio_controller.rb

class StreamingAudioController < ApplicationController
  include ActionController::Live

  before_action :validate_streaming_params, only: [:stream_text_to_speech]

  # GET /streaming_audio/stream
  # Stream text-to-speech audio in real-time
  #
  # Parameters:
  #   - voice_id: String (required) - ElevenLabs voice ID
  #   - text: String (required) - Text to convert to speech
  #   - model_id: String (optional) - Model to use (defaults to "eleven_multilingual_v2")
  #   - output_format: String (optional) - Output format (defaults to "mp3_44100_128")
  #   - stability: Float (optional) - Voice stability (0.0-1.0)
  #   - similarity_boost: Float (optional) - Similarity boost (0.0-1.0)
  def stream_text_to_speech
    # Set streaming headers
    response.headers['Content-Type'] = 'audio/mpeg'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['Transfer-Encoding'] = 'chunked'
    response.headers['Access-Control-Allow-Origin'] = '*' # Adjust for your needs
    
    client = ElevenlabsClient.new
    options = build_streaming_options
    
    begin
      client.text_to_speech_stream.stream(
        params[:voice_id],
        params[:text],
        **options
      ) do |chunk|
        response.stream.write(chunk)
      end
      
    rescue ElevenlabsClient::AuthenticationError
      response.stream.write("Authentication failed")
      
    rescue ElevenlabsClient::RateLimitError
      response.stream.write("Rate limit exceeded")
      
    rescue ElevenlabsClient::ValidationError => e
      response.stream.write("Validation error: #{e.message}")
      
    rescue IOError
      # Client disconnected - this is normal
      Rails.logger.info "Client disconnected during streaming"
      
    rescue => e
      Rails.logger.error "Streaming error: #{e.message}"
      response.stream.write("Streaming error occurred")
      
    ensure
      response.stream.close
    end
  end

  # POST /streaming_audio/websocket_stream
  # Example of streaming to WebSocket (requires ActionCable)
  def websocket_stream
    client = ElevenlabsClient.new
    options = build_streaming_options
    
    begin
      client.text_to_speech_stream.stream(
        params[:voice_id],
        params[:text],
        **options
      ) do |chunk|
        # Stream to WebSocket channel
        ActionCable.server.broadcast(
          "audio_stream_#{params[:session_id]}", 
          { type: 'audio_chunk', data: Base64.encode64(chunk) }
        )
      end
      
      # Signal completion
      ActionCable.server.broadcast(
        "audio_stream_#{params[:session_id]}", 
        { type: 'stream_complete' }
      )
      
      render json: { status: 'streaming_started' }
      
    rescue => e
      ActionCable.server.broadcast(
        "audio_stream_#{params[:session_id]}", 
        { type: 'error', message: e.message }
      )
      
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # POST /streaming_audio/save_and_stream
  # Stream audio while simultaneously saving to file
  def save_and_stream
    response.headers['Content-Type'] = 'audio/mpeg'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['Transfer-Encoding'] = 'chunked'
    
    client = ElevenlabsClient.new
    options = build_streaming_options
    
    # Create temporary file for saving
    temp_file = Tempfile.new(['tts_audio', '.mp3'])
    
    begin
      client.text_to_speech_stream.stream(
        params[:voice_id],
        params[:text],
        **options
      ) do |chunk|
        # Stream to client
        response.stream.write(chunk)
        
        # Simultaneously save to file
        temp_file.write(chunk)
      end
      
      temp_file.close
      
      # Optionally save to permanent storage
      if params[:save_permanently]
        final_path = Rails.root.join('public', 'audio', "#{SecureRandom.uuid}.mp3")
        FileUtils.mv(temp_file.path, final_path)
        Rails.logger.info "Audio saved to #{final_path}"
      end
      
    rescue IOError
      Rails.logger.info "Client disconnected during save and stream"
    ensure
      response.stream.close
      temp_file.unlink if temp_file
    end
  end

  private

  def validate_streaming_params
    if params[:voice_id].blank?
      render json: { error: 'voice_id is required' }, status: :bad_request
      return
    end

    if params[:text].blank?
      render json: { error: 'text is required' }, status: :bad_request
      return
    end

    if params[:text].length > 5000
      render json: { error: 'text is too long (max 5000 characters)' }, status: :bad_request
      return
    end
  end

  def build_streaming_options
    options = {}
    
    # Add model if specified
    options[:model_id] = params[:model_id] if params[:model_id].present?
    
    # Add output format if specified
    options[:output_format] = params[:output_format] if params[:output_format].present?
    
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
