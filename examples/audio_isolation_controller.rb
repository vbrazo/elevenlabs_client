# frozen_string_literal: true

# Example Rails controller for Audio Isolation functionality
# This demonstrates how to integrate ElevenLabs Audio Isolation API in a Rails application

class AudioIsolationController < ApplicationController
  before_action :initialize_client

  # POST /audio_isolation/isolate
  # Remove background noise from audio file
  def isolate
    audio_file = params[:audio_file]

    unless audio_file.present?
      return render json: { error: "audio_file is required" }, status: :bad_request
    end

    begin
      isolated_audio = @client.audio_isolation.isolate(
        audio_file.tempfile,
        audio_file.original_filename,
        file_format: params[:file_format] || "other"
      )

      # Save isolated audio to temporary file
      temp_file = Tempfile.new(["isolated_audio", File.extname(audio_file.original_filename)])
      temp_file.binmode
      temp_file.write(isolated_audio)
      temp_file.rewind

      # Send file to client
      send_file temp_file.path,
                type: "audio/mpeg",
                filename: "isolated_#{audio_file.original_filename}",
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

  # POST /audio_isolation/isolate_stream
  # Stream isolated audio in real-time
  def isolate_stream
    audio_file = params[:audio_file]

    unless audio_file.present?
      return render json: { error: "audio_file is required" }, status: :bad_request
    end

    begin
      response.headers["Content-Type"] = "audio/mpeg"
      response.headers["Cache-Control"] = "no-cache"
      response.headers["Connection"] = "keep-alive"

      @client.audio_isolation.isolate_stream(
        audio_file.tempfile,
        audio_file.original_filename,
        file_format: params[:file_format] || "other"
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

  # POST /audio_isolation/batch_isolate
  # Process multiple audio files for noise removal
  def batch_isolate
    audio_files = params[:audio_files]

    unless audio_files.present?
      return render json: { error: "audio_files are required" }, status: :bad_request
    end

    results = []
    errors = []

    audio_files.each_with_index do |audio_file, index|
      begin
        isolated_audio = @client.audio_isolation.isolate(
          audio_file.tempfile,
          audio_file.original_filename,
          file_format: params[:file_format] || "other"
        )

        # In production, you'd save to cloud storage (S3, etc.)
        filename = "isolated_#{index}_#{audio_file.original_filename}"
        
        results << {
          original_filename: audio_file.original_filename,
          isolated_filename: filename,
          original_size: audio_file.size,
          isolated_size: isolated_audio.bytesize,
          compression_ratio: (audio_file.size.to_f / isolated_audio.bytesize).round(2),
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
      total_errors: errors.length,
      summary: {
        total_original_size: results.sum { |r| r[:original_size] || 0 },
        total_isolated_size: results.sum { |r| r[:isolated_size] || 0 }
      }
    }
  end

  # POST /audio_isolation/compare
  # Compare original and isolated audio quality
  def compare
    audio_file = params[:audio_file]

    unless audio_file.present?
      return render json: { error: "audio_file is required" }, status: :bad_request
    end

    begin
      # Process with different file formats for comparison
      formats = ["other", "pcm_s16le_16"]
      results = {}

      formats.each do |format|
        start_time = Time.current
        
        isolated_audio = @client.audio_isolation.isolate(
          audio_file.tempfile,
          audio_file.original_filename,
          file_format: format
        )
        
        processing_time = Time.current - start_time
        
        results[format] = {
          processing_time: processing_time.round(3),
          output_size: isolated_audio.bytesize,
          format_description: format_description(format)
        }
        
        # Reset file pointer for next iteration
        audio_file.tempfile.rewind
      end

      render json: {
        original_filename: audio_file.original_filename,
        original_size: audio_file.size,
        format_comparison: results,
        recommendation: recommend_format(results)
      }

    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::UnprocessableEntityError => e
      render json: { error: "Invalid audio file", details: e.message }, status: :unprocessable_entity
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # GET /audio_isolation/info
  # Get information about audio isolation capabilities
  def info
    render json: {
      supported_formats: {
        input: ["mp3", "wav", "flac", "m4a", "aac", "ogg"],
        file_format_options: {
          "other" => {
            description: "Standard format for all audio types",
            latency: "higher",
            compatibility: "excellent"
          },
          "pcm_s16le_16" => {
            description: "16-bit PCM, 16kHz, mono, little-endian",
            latency: "lower",
            compatibility: "limited",
            requirements: "Specific format requirements"
          }
        }
      },
      use_cases: [
        "Podcast cleanup",
        "Voice message enhancement", 
        "Meeting recording improvement",
        "Music vocal isolation",
        "Real-time audio processing"
      ],
      best_practices: [
        "Use 'pcm_s16le_16' for real-time applications requiring low latency",
        "Use 'other' for general-purpose audio isolation with various formats",
        "Higher quality input audio produces better isolation results",
        "Consider file size vs quality trade-offs"
      ]
    }
  end

  private

  def initialize_client
    @client = ElevenlabsClient.new
  end

  def format_description(format)
    case format
    when "pcm_s16le_16"
      "16-bit PCM at 16kHz sample rate, mono, little-endian (lower latency)"
    when "other"
      "Standard format for encoded audio files (higher compatibility)"
    else
      "Unknown format"
    end
  end

  def recommend_format(results)
    pcm_result = results["pcm_s16le_16"]
    other_result = results["other"]

    if pcm_result && other_result
      if pcm_result[:processing_time] < other_result[:processing_time] * 0.7
        {
          format: "pcm_s16le_16",
          reason: "Significantly faster processing time",
          speed_improvement: "#{((other_result[:processing_time] / pcm_result[:processing_time] - 1) * 100).round(1)}% faster"
        }
      else
        {
          format: "other",
          reason: "Better compatibility with various audio formats",
          note: "Minimal performance difference"
        }
      end
    else
      {
        format: "other",
        reason: "Default recommendation for general use"
      }
    end
  end

  # Strong parameters for audio isolation
  def audio_isolation_params
    params.permit(
      :audio_file,
      :file_format,
      audio_files: []
    )
  end
end

# Example routes.rb configuration:
#
# Rails.application.routes.draw do
#   namespace :audio_isolation do
#     post :isolate
#     post :isolate_stream
#     post :batch_isolate
#     post :compare
#     get :info
#   end
# end

# Example usage in views:
#
# <%= form_with url: audio_isolation_isolate_path, multipart: true do |form| %>
#   <%= form.file_field :audio_file, accept: "audio/*", required: true %>
#   <%= form.select :file_format, options_for_select([
#     ["Standard (recommended)", "other"],
#     ["PCM 16kHz (low latency)", "pcm_s16le_16"]
#   ]), { selected: "other" } %>
#   <%= form.submit "Remove Background Noise" %>
# <% end %>
#
# <!-- Batch processing form -->
# <%= form_with url: audio_isolation_batch_isolate_path, multipart: true do |form| %>
#   <%= form.file_field :audio_files, multiple: true, accept: "audio/*", required: true %>
#   <%= form.submit "Process Multiple Files" %>
# <% end %>
