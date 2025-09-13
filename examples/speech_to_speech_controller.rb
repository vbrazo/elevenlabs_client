# frozen_string_literal: true

# Example Rails controller for Speech-to-Speech (Voice Changer) functionality
# This demonstrates how to integrate ElevenLabs Speech-to-Speech API in a Rails application

class SpeechToSpeechController < ApplicationController
  before_action :initialize_client

  # POST /speech_to_speech/convert
  # Convert audio from one voice to another
  def convert
    voice_id = params[:voice_id]
    audio_file = params[:audio_file]

    unless voice_id.present? && audio_file.present?
      return render json: { error: "voice_id and audio_file are required" }, status: :bad_request
    end

    begin
      converted_audio = @client.speech_to_speech.convert(
        voice_id,
        audio_file.tempfile,
        audio_file.original_filename,
        model_id: params[:model_id] || "eleven_multilingual_sts_v2",
        output_format: params[:output_format] || "mp3_44100_128",
        remove_background_noise: params[:remove_background_noise] == "true",
        voice_settings: params[:voice_settings],
        seed: params[:seed]&.to_i
      )

      # Save converted audio to temporary file
      temp_file = Tempfile.new(["converted_audio", ".mp3"])
      temp_file.binmode
      temp_file.write(converted_audio)
      temp_file.rewind

      # Send file to client
      send_file temp_file.path,
                type: "audio/mpeg",
                filename: "converted_#{audio_file.original_filename}",
                disposition: "attachment"

    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::UnprocessableEntityError => e
      render json: { error: "Invalid audio file or parameters", details: e.message }, status: :unprocessable_entity
    rescue ElevenlabsClient::RateLimitError => e
      render json: { error: "Rate limit exceeded", details: e.message }, status: :too_many_requests
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    ensure
      temp_file&.close
      temp_file&.unlink
    end
  end

  # POST /speech_to_speech/convert_stream
  # Stream converted audio in real-time
  def convert_stream
    voice_id = params[:voice_id]
    audio_file = params[:audio_file]

    unless voice_id.present? && audio_file.present?
      return render json: { error: "voice_id and audio_file are required" }, status: :bad_request
    end

    begin
      response.headers["Content-Type"] = "audio/mpeg"
      response.headers["Cache-Control"] = "no-cache"
      response.headers["Connection"] = "keep-alive"

      @client.speech_to_speech.convert_stream(
        voice_id,
        audio_file.tempfile,
        audio_file.original_filename,
        output_format: params[:output_format] || "mp3_44100_128",
        optimize_streaming_latency: params[:optimize_streaming_latency]&.to_i || 2
      ) do |chunk|
        response.stream.write(chunk)
      end

    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::UnprocessableEntityError => e
      render json: { error: "Invalid audio file or parameters", details: e.message }, status: :unprocessable_entity
    rescue ElevenlabsClient::RateLimitError => e
      render json: { error: "Rate limit exceeded", details: e.message }, status: :too_many_requests
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    ensure
      response.stream.close
    end
  end

  # GET /speech_to_speech/voices
  # List available voices for speech-to-speech conversion
  def voices
    begin
      voices_response = @client.voices.list
      
      # Filter voices that support speech-to-speech
      compatible_voices = voices_response["voices"].select do |voice|
        voice["category"] != "premade" || voice["fine_tuning"]&.dig("is_allowed_to_fine_tune")
      end

      render json: {
        voices: compatible_voices,
        total: compatible_voices.length
      }

    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # GET /speech_to_speech/models
  # List available models for speech-to-speech conversion
  def models
    begin
      models_response = @client.models.list
      
      # Filter models that support speech-to-speech
      sts_models = models_response["models"].select do |model|
        model["can_do_voice_conversion"] == true
      end

      render json: {
        models: sts_models,
        total: sts_models.length
      }

    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # POST /speech_to_speech/batch_convert
  # Convert multiple audio files with the same voice
  def batch_convert
    voice_id = params[:voice_id]
    audio_files = params[:audio_files]

    unless voice_id.present? && audio_files.present?
      return render json: { error: "voice_id and audio_files are required" }, status: :bad_request
    end

    results = []
    errors = []

    audio_files.each_with_index do |audio_file, index|
      begin
        converted_audio = @client.speech_to_speech.convert(
          voice_id,
          audio_file.tempfile,
          audio_file.original_filename,
          model_id: params[:model_id] || "eleven_multilingual_sts_v2",
          remove_background_noise: params[:remove_background_noise] == "true"
        )

        # Store in temporary location or cloud storage
        filename = "converted_#{index}_#{audio_file.original_filename}"
        # In production, you'd save to cloud storage (S3, etc.)
        
        results << {
          original_filename: audio_file.original_filename,
          converted_filename: filename,
          size: converted_audio.bytesize,
          status: "success"
        }

      rescue ElevenlabsClient::APIError => e
        errors << {
          filename: audio_file.original_filename,
          error: e.message,
          index: index
        }
      end
    end

    render json: {
      results: results,
      errors: errors,
      total_processed: results.length,
      total_errors: errors.length
    }
  end

  private

  def initialize_client
    @client = ElevenlabsClient.new
  end

  # Strong parameters for speech-to-speech conversion
  def speech_to_speech_params
    params.permit(
      :voice_id,
      :model_id,
      :output_format,
      :remove_background_noise,
      :voice_settings,
      :seed,
      :optimize_streaming_latency,
      :audio_file,
      audio_files: []
    )
  end
end

# Example routes.rb configuration:
#
# Rails.application.routes.draw do
#   namespace :speech_to_speech do
#     post :convert
#     post :convert_stream
#     post :batch_convert
#     get :voices
#     get :models
#   end
# end

# Example usage in views:
#
# <%= form_with url: speech_to_speech_convert_path, multipart: true do |form| %>
#   <%= form.file_field :audio_file, accept: "audio/*", required: true %>
#   <%= form.select :voice_id, options_for_select([
#     ["Professional Female", "21m00Tcm4TlvDq8ikWAM"],
#     ["Casual Male", "pNInz6obpgDQGcFmaJgB"]
#   ]), { prompt: "Select target voice" }, { required: true } %>
#   <%= form.check_box :remove_background_noise %>
#   <%= form.label :remove_background_noise, "Remove background noise" %>
#   <%= form.submit "Convert Voice" %>
# <% end %>
