# frozen_string_literal: true

# Example Rails controller for Speech-to-Text functionality
# This demonstrates how to integrate ElevenLabs Speech-to-Text API in a Rails application

class SpeechToTextController < ApplicationController
  before_action :initialize_client

  # POST /speech_to_text/transcribe
  # Transcribe an audio or video file
  def transcribe
    audio_file = params[:audio_file]
    model_id = params[:model_id] || "scribe_v1"

    unless audio_file.present?
      return render json: { error: "audio_file is required" }, status: :bad_request
    end

    begin
      transcription = @client.speech_to_text.create(
        model_id,
        file: audio_file.tempfile,
        filename: audio_file.original_filename,
        language_code: params[:language_code],
        diarize: params[:diarize] == "true",
        num_speakers: params[:num_speakers]&.to_i,
        timestamps_granularity: params[:timestamps_granularity] || "word",
        tag_audio_events: params[:tag_audio_events] != "false",
        temperature: params[:temperature]&.to_f || 0.0,
        seed: params[:seed]&.to_i
      )

      render json: {
        transcription_id: transcription["transcription_id"],
        text: transcription["text"],
        language_code: transcription["language_code"],
        language_probability: transcription["language_probability"],
        words: transcription["words"],
        processing_time: transcription["processing_time"]
      }

    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::UnprocessableEntityError => e
      render json: { error: "Invalid audio file or parameters", details: e.message }, status: :unprocessable_entity
    rescue ElevenlabsClient::RateLimitError => e
      render json: { error: "Rate limit exceeded", details: e.message }, status: :too_many_requests
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # POST /speech_to_text/transcribe_url
  # Transcribe audio from a cloud storage URL
  def transcribe_url
    cloud_url = params[:cloud_storage_url]
    model_id = params[:model_id] || "scribe_v1"

    unless cloud_url.present?
      return render json: { error: "cloud_storage_url is required" }, status: :bad_request
    end

    begin
      transcription = @client.speech_to_text.create(
        model_id,
        cloud_storage_url: cloud_url,
        language_code: params[:language_code],
        diarize: params[:diarize] == "true",
        num_speakers: params[:num_speakers]&.to_i,
        timestamps_granularity: params[:timestamps_granularity] || "word"
      )

      render json: {
        transcription_id: transcription["transcription_id"],
        text: transcription["text"],
        language_code: transcription["language_code"],
        words: transcription["words"]
      }

    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::UnprocessableEntityError => e
      render json: { error: "Invalid URL or parameters", details: e.message }, status: :unprocessable_entity
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # POST /speech_to_text/transcribe_webhook
  # Submit transcription for webhook processing (async)
  def transcribe_webhook
    audio_file = params[:audio_file]
    model_id = params[:model_id] || "scribe_v1"
    webhook_id = params[:webhook_id]

    unless audio_file.present?
      return render json: { error: "audio_file is required" }, status: :bad_request
    end

    begin
      webhook_metadata = {
        user_id: current_user&.id,
        session_id: session.id,
        original_filename: audio_file.original_filename,
        uploaded_at: Time.current.iso8601
      }

      response = @client.speech_to_text.create(
        model_id,
        file: audio_file.tempfile,
        filename: audio_file.original_filename,
        webhook: true,
        webhook_id: webhook_id,
        webhook_metadata: webhook_metadata,
        language_code: params[:language_code],
        diarize: params[:diarize] == "true",
        additional_formats: parse_additional_formats
      )

      render json: {
        transcription_id: response["transcription_id"],
        status: response["status"],
        webhook_id: response["webhook_id"],
        message: "Transcription submitted for processing"
      }

    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::UnprocessableEntityError => e
      render json: { error: "Invalid audio file or parameters", details: e.message }, status: :unprocessable_entity
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # GET /speech_to_text/transcript/:id
  # Retrieve a completed transcription
  def show
    transcription_id = params[:id]

    begin
      transcript = @client.speech_to_text.get_transcript(transcription_id)

      render json: {
        transcription_id: transcript["transcription_id"],
        text: transcript["text"],
        language_code: transcript["language_code"],
        language_probability: transcript["language_probability"],
        words: transcript["words"],
        additional_formats: transcript["additional_formats"],
        channel_index: transcript["channel_index"]
      }

    rescue ElevenlabsClient::NotFoundError => e
      render json: { error: "Transcript not found", details: e.message }, status: :not_found
    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # GET /speech_to_text/transcript/:id/download/:format
  # Download transcript in specific format (SRT, VTT, TXT)
  def download
    transcription_id = params[:id]
    format = params[:format]&.downcase

    unless %w[srt vtt txt].include?(format)
      return render json: { error: "Invalid format. Supported: srt, vtt, txt" }, status: :bad_request
    end

    begin
      transcript = @client.speech_to_text.get_transcript(transcription_id)
      
      additional_format = transcript["additional_formats"]&.find do |fmt|
        fmt["requested_format"] == format
      end

      unless additional_format
        return render json: { error: "Format not available for this transcript" }, status: :not_found
      end

      send_data additional_format["content"],
                type: additional_format["content_type"],
                filename: "transcript_#{transcription_id}.#{additional_format['file_extension']}",
                disposition: "attachment"

    rescue ElevenlabsClient::NotFoundError => e
      render json: { error: "Transcript not found", details: e.message }, status: :not_found
    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # POST /speech_to_text/batch_transcribe
  # Transcribe multiple files
  def batch_transcribe
    audio_files = params[:audio_files]
    model_id = params[:model_id] || "scribe_v1"

    unless audio_files.present?
      return render json: { error: "audio_files are required" }, status: :bad_request
    end

    results = []
    errors = []

    audio_files.each_with_index do |audio_file, index|
      begin
        transcription = @client.speech_to_text.create(
          model_id,
          file: audio_file.tempfile,
          filename: audio_file.original_filename,
          language_code: params[:language_code],
          diarize: params[:diarize] == "true",
          webhook: params[:use_webhook] == "true",
          webhook_metadata: {
            batch_id: "batch_#{Time.current.to_i}",
            file_index: index,
            original_filename: audio_file.original_filename
          }
        )

        results << {
          filename: audio_file.original_filename,
          transcription_id: transcription["transcription_id"],
          text: transcription["text"],
          language_code: transcription["language_code"],
          status: "completed"
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

  # GET /speech_to_text/speakers/:id
  # Get speaker-separated transcript
  def speakers
    transcription_id = params[:id]

    begin
      transcript = @client.speech_to_text.get_transcript(transcription_id)
      
      # Group words by speaker
      speakers = {}
      transcript["words"]&.each do |word|
        speaker_id = word["speaker_id"] || "unknown"
        speakers[speaker_id] ||= { words: [], total_duration: 0 }
        speakers[speaker_id][:words] << word
        speakers[speaker_id][:total_duration] += (word["end"] - word["start"])
      end

      # Format speaker data
      speaker_data = speakers.map do |speaker_id, data|
        {
          speaker_id: speaker_id,
          text: data[:words].map { |w| w["text"] }.join(" "),
          word_count: data[:words].length,
          total_duration: data[:total_duration].round(2),
          words: data[:words]
        }
      end

      render json: {
        transcription_id: transcription_id,
        total_speakers: speaker_data.length,
        speakers: speaker_data
      }

    rescue ElevenlabsClient::NotFoundError => e
      render json: { error: "Transcript not found", details: e.message }, status: :not_found
    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  private

  def initialize_client
    @client = ElevenlabsClient.new
  end

  def parse_additional_formats
    return nil unless params[:additional_formats].present?

    formats = params[:additional_formats].split(",").map(&:strip)
    formats.map do |format|
      {
        "requested_format" => format,
        "file_extension" => format,
        "content_type" => content_type_for_format(format)
      }
    end
  end

  def content_type_for_format(format)
    case format.downcase
    when "srt" then "text/plain"
    when "vtt" then "text/vtt"
    when "txt" then "text/plain"
    else "text/plain"
    end
  end

  # Strong parameters for speech-to-text
  def speech_to_text_params
    params.permit(
      :audio_file,
      :cloud_storage_url,
      :model_id,
      :language_code,
      :diarize,
      :num_speakers,
      :timestamps_granularity,
      :tag_audio_events,
      :temperature,
      :seed,
      :webhook_id,
      :use_webhook,
      :additional_formats,
      audio_files: []
    )
  end
end

# Example routes.rb configuration:
#
# Rails.application.routes.draw do
#   namespace :speech_to_text do
#     post :transcribe
#     post :transcribe_url
#     post :transcribe_webhook
#     post :batch_transcribe
#     get 'transcript/:id', to: :show
#     get 'transcript/:id/download/:format', to: :download
#     get 'speakers/:id', to: :speakers
#   end
# end

# Example usage in views:
#
# <%= form_with url: speech_to_text_transcribe_path, multipart: true do |form| %>
#   <%= form.file_field :audio_file, accept: "audio/*,video/*", required: true %>
#   <%= form.select :language_code, options_for_select([
#     ["Auto-detect", ""],
#     ["English", "en"],
#     ["Spanish", "es"],
#     ["French", "fr"]
#   ]), { prompt: "Select language" } %>
#   <%= form.check_box :diarize %>
#   <%= form.label :diarize, "Identify speakers" %>
#   <%= form.text_field :additional_formats, placeholder: "srt,vtt,txt" %>
#   <%= form.submit "Transcribe" %>
# <% end %>
