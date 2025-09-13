# frozen_string_literal: true

# Example Rails controller for Forced Alignment functionality
# This demonstrates how to integrate ElevenLabs Forced Alignment API in a Rails application

class ForcedAlignmentController < ApplicationController
  before_action :initialize_client

  # POST /forced_alignment/align
  # Create forced alignment for audio and text
  def align
    audio_file = params[:audio_file]
    transcript_text = params[:transcript]

    unless audio_file.present? && transcript_text.present?
      return render json: { error: "audio_file and transcript are required" }, status: :bad_request
    end

    begin
      alignment = @client.forced_alignment.create(
        audio_file.tempfile,
        audio_file.original_filename,
        transcript_text,
        enabled_spooled_file: params[:enabled_spooled_file] == "true"
      )

      # Process alignment data for easier consumption
      processed_alignment = process_alignment_data(alignment)

      render json: {
        alignment_id: alignment["alignment_id"],
        transcript: transcript_text,
        total_words: alignment["words"]&.length || 0,
        total_duration: calculate_total_duration(alignment["words"]),
        words: alignment["words"],
        processed_data: processed_alignment,
        statistics: generate_alignment_statistics(alignment["words"])
      }

    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::UnprocessableEntityError => e
      render json: { error: "Invalid audio file or transcript", details: e.message }, status: :unprocessable_entity
    rescue ElevenlabsClient::RateLimitError => e
      render json: { error: "Rate limit exceeded", details: e.message }, status: :too_many_requests
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # POST /forced_alignment/align_srt
  # Create forced alignment and return SRT subtitle format
  def align_srt
    audio_file = params[:audio_file]
    transcript_text = params[:transcript]

    unless audio_file.present? && transcript_text.present?
      return render json: { error: "audio_file and transcript are required" }, status: :bad_request
    end

    begin
      alignment = @client.forced_alignment.create(
        audio_file.tempfile,
        audio_file.original_filename,
        transcript_text
      )

      # Generate SRT format
      srt_content = generate_srt_from_alignment(alignment["words"])

      send_data srt_content,
                type: "text/plain",
                filename: "alignment_#{Time.current.to_i}.srt",
                disposition: "attachment"

    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::UnprocessableEntityError => e
      render json: { error: "Invalid audio file or transcript", details: e.message }, status: :unprocessable_entity
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # POST /forced_alignment/align_vtt
  # Create forced alignment and return WebVTT subtitle format
  def align_vtt
    audio_file = params[:audio_file]
    transcript_text = params[:transcript]

    unless audio_file.present? && transcript_text.present?
      return render json: { error: "audio_file and transcript are required" }, status: :bad_request
    end

    begin
      alignment = @client.forced_alignment.create(
        audio_file.tempfile,
        audio_file.original_filename,
        transcript_text
      )

      # Generate WebVTT format
      vtt_content = generate_vtt_from_alignment(alignment["words"])

      send_data vtt_content,
                type: "text/vtt",
                filename: "alignment_#{Time.current.to_i}.vtt",
                disposition: "attachment"

    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::UnprocessableEntityError => e
      render json: { error: "Invalid audio file or transcript", details: e.message }, status: :unprocessable_entity
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # POST /forced_alignment/batch_align
  # Process multiple audio files with their transcripts
  def batch_align
    alignments_data = params[:alignments]

    unless alignments_data.present?
      return render json: { error: "alignments data is required" }, status: :bad_request
    end

    results = []
    errors = []

    alignments_data.each_with_index do |alignment_data, index|
      begin
        audio_file = alignment_data[:audio_file]
        transcript = alignment_data[:transcript]

        unless audio_file.present? && transcript.present?
          errors << {
            index: index,
            error: "Missing audio_file or transcript",
            filename: audio_file&.original_filename || "unknown"
          }
          next
        end

        alignment = @client.forced_alignment.create(
          audio_file.tempfile,
          audio_file.original_filename,
          transcript
        )

        results << {
          filename: audio_file.original_filename,
          transcript: transcript,
          word_count: alignment["words"]&.length || 0,
          duration: calculate_total_duration(alignment["words"]),
          alignment_data: alignment["words"],
          status: "success"
        }

      rescue ElevenlabsClient::APIError => e
        errors << {
          filename: alignment_data[:audio_file]&.original_filename || "unknown",
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
        total_words: results.sum { |r| r[:word_count] },
        total_duration: results.sum { |r| r[:duration] }
      }
    }
  end

  # POST /forced_alignment/analyze_timing
  # Analyze timing accuracy and speech patterns
  def analyze_timing
    audio_file = params[:audio_file]
    transcript_text = params[:transcript]

    unless audio_file.present? && transcript_text.present?
      return render json: { error: "audio_file and transcript are required" }, status: :bad_request
    end

    begin
      alignment = @client.forced_alignment.create(
        audio_file.tempfile,
        audio_file.original_filename,
        transcript_text
      )

      words = alignment["words"] || []
      
      # Analyze speech patterns
      analysis = {
        timing_analysis: analyze_speech_timing(words),
        word_analysis: analyze_word_patterns(words),
        pause_analysis: analyze_pauses(words),
        speed_analysis: analyze_speech_speed(words),
        confidence_analysis: analyze_confidence_scores(words)
      }

      render json: {
        filename: audio_file.original_filename,
        total_words: words.length,
        total_duration: calculate_total_duration(words),
        analysis: analysis,
        recommendations: generate_timing_recommendations(analysis)
      }

    rescue ElevenlabsClient::AuthenticationError => e
      render json: { error: "Authentication failed", details: e.message }, status: :unauthorized
    rescue ElevenlabsClient::UnprocessableEntityError => e
      render json: { error: "Invalid audio file or transcript", details: e.message }, status: :unprocessable_entity
    rescue ElevenlabsClient::APIError => e
      render json: { error: "API error occurred", details: e.message }, status: :internal_server_error
    end
  end

  # GET /forced_alignment/info
  # Get information about forced alignment capabilities
  def info
    render json: {
      supported_formats: {
        audio: ["wav", "mp3", "flac", "m4a", "aac"],
        output: ["json", "srt", "vtt", "txt"]
      },
      use_cases: [
        "Subtitle generation for videos",
        "Podcast chapter markers",
        "Language learning applications",
        "Accessibility features",
        "Audio editing synchronization",
        "Speech analysis and research"
      ],
      best_practices: [
        "Ensure transcript text matches audio content exactly",
        "Use high-quality audio recordings for better accuracy",
        "Clean background noise can improve alignment precision",
        "Shorter audio segments (< 10 minutes) typically work better",
        "Include punctuation in transcripts for natural pauses"
      ],
      timing_accuracy: {
        typical_precision: "±50ms for clear speech",
        factors_affecting_accuracy: [
          "Audio quality",
          "Background noise",
          "Speaker clarity",
          "Transcript accuracy",
          "Language and accent"
        ]
      }
    }
  end

  private

  def initialize_client
    @client = ElevenlabsClient.new
  end

  def process_alignment_data(alignment)
    words = alignment["words"] || []
    
    {
      sentences: group_words_into_sentences(words),
      paragraphs: group_words_into_paragraphs(words),
      timeline: create_timeline_markers(words)
    }
  end

  def calculate_total_duration(words)
    return 0.0 if words.nil? || words.empty?
    
    last_word = words.last
    return 0.0 unless last_word && last_word["end"]
    
    last_word["end"].to_f
  end

  def generate_alignment_statistics(words)
    return {} if words.nil? || words.empty?

    durations = words.map { |w| w["end"].to_f - w["start"].to_f }
    
    {
      average_word_duration: durations.sum / durations.length,
      shortest_word: durations.min,
      longest_word: durations.max,
      words_per_minute: calculate_words_per_minute(words),
      total_speech_time: calculate_total_duration(words)
    }
  end

  def calculate_words_per_minute(words)
    return 0 if words.nil? || words.empty?
    
    total_duration_minutes = calculate_total_duration(words) / 60.0
    return 0 if total_duration_minutes == 0
    
    (words.length / total_duration_minutes).round(1)
  end

  def generate_srt_from_alignment(words)
    return "" if words.nil? || words.empty?

    srt_content = ""
    subtitle_index = 1
    
    # Group words into subtitle chunks (every 8-10 words or 3-4 seconds)
    word_chunks = chunk_words_for_subtitles(words)
    
    word_chunks.each do |chunk|
      start_time = format_srt_time(chunk.first["start"])
      end_time = format_srt_time(chunk.last["end"])
      text = chunk.map { |w| w["text"] }.join(" ")
      
      srt_content += "#{subtitle_index}\n"
      srt_content += "#{start_time} --> #{end_time}\n"
      srt_content += "#{text}\n\n"
      
      subtitle_index += 1
    end
    
    srt_content
  end

  def generate_vtt_from_alignment(words)
    return "WEBVTT\n\n" if words.nil? || words.empty?

    vtt_content = "WEBVTT\n\n"
    
    word_chunks = chunk_words_for_subtitles(words)
    
    word_chunks.each do |chunk|
      start_time = format_vtt_time(chunk.first["start"])
      end_time = format_vtt_time(chunk.last["end"])
      text = chunk.map { |w| w["text"] }.join(" ")
      
      vtt_content += "#{start_time} --> #{end_time}\n"
      vtt_content += "#{text}\n\n"
    end
    
    vtt_content
  end

  def chunk_words_for_subtitles(words, max_duration: 4.0, max_words: 10)
    chunks = []
    current_chunk = []
    
    words.each do |word|
      current_chunk << word
      
      chunk_duration = word["end"].to_f - current_chunk.first["start"].to_f
      
      if current_chunk.length >= max_words || chunk_duration >= max_duration
        chunks << current_chunk
        current_chunk = []
      end
    end
    
    chunks << current_chunk unless current_chunk.empty?
    chunks
  end

  def format_srt_time(seconds)
    total_seconds = seconds.to_f
    hours = (total_seconds / 3600).to_i
    minutes = ((total_seconds % 3600) / 60).to_i
    secs = (total_seconds % 60).to_i
    milliseconds = ((total_seconds % 1) * 1000).to_i
    
    sprintf("%02d:%02d:%02d,%03d", hours, minutes, secs, milliseconds)
  end

  def format_vtt_time(seconds)
    total_seconds = seconds.to_f
    hours = (total_seconds / 3600).to_i
    minutes = ((total_seconds % 3600) / 60).to_i
    secs = (total_seconds % 60).to_i
    milliseconds = ((total_seconds % 1) * 1000).to_i
    
    sprintf("%02d:%02d:%02d.%03d", hours, minutes, secs, milliseconds)
  end

  def group_words_into_sentences(words)
    # Simple sentence grouping based on punctuation
    sentences = []
    current_sentence = []
    
    words.each do |word|
      current_sentence << word
      
      if word["text"].match?(/[.!?]$/)
        sentences << {
          text: current_sentence.map { |w| w["text"] }.join(" "),
          start: current_sentence.first["start"],
          end: current_sentence.last["end"],
          words: current_sentence.dup
        }
        current_sentence = []
      end
    end
    
    # Add remaining words as final sentence
    unless current_sentence.empty?
      sentences << {
        text: current_sentence.map { |w| w["text"] }.join(" "),
        start: current_sentence.first["start"],
        end: current_sentence.last["end"],
        words: current_sentence
      }
    end
    
    sentences
  end

  def group_words_into_paragraphs(words)
    # Simple paragraph grouping (every 5-7 sentences or long pauses)
    sentences = group_words_into_sentences(words)
    paragraphs = []
    current_paragraph = []
    
    sentences.each_with_index do |sentence, index|
      current_paragraph << sentence
      
      # Check for long pause or paragraph break
      next_sentence = sentences[index + 1]
      if next_sentence.nil? || 
         (next_sentence["start"] - sentence["end"]) > 2.0 || 
         current_paragraph.length >= 6
        
        paragraphs << {
          text: current_paragraph.map { |s| s[:text] }.join(" "),
          start: current_paragraph.first[:start],
          end: current_paragraph.last[:end],
          sentences: current_paragraph.dup
        }
        current_paragraph = []
      end
    end
    
    paragraphs
  end

  def create_timeline_markers(words)
    # Create timeline markers every 10 seconds
    return [] if words.nil? || words.empty?
    
    total_duration = calculate_total_duration(words)
    markers = []
    
    (0..total_duration.to_i).step(10) do |time|
      # Find words around this time
      nearby_words = words.select do |word|
        word["start"].to_f <= time && word["end"].to_f >= time
      end
      
      if nearby_words.any?
        markers << {
          time: time,
          text: nearby_words.map { |w| w["text"] }.join(" "),
          word_count: nearby_words.length
        }
      end
    end
    
    markers
  end

  def analyze_speech_timing(words)
    return {} if words.nil? || words.empty?
    
    durations = words.map { |w| w["end"].to_f - w["start"].to_f }
    
    {
      average_word_duration: durations.sum / durations.length,
      median_word_duration: durations.sort[durations.length / 2],
      duration_variance: calculate_variance(durations),
      fastest_words: words.select { |w| (w["end"].to_f - w["start"].to_f) < 0.1 },
      slowest_words: words.select { |w| (w["end"].to_f - w["start"].to_f) > 0.8 }
    }
  end

  def analyze_word_patterns(words)
    return {} if words.nil? || words.empty?
    
    word_lengths = words.map { |w| w["text"].length }
    
    {
      average_word_length: word_lengths.sum.to_f / word_lengths.length,
      shortest_words: words.select { |w| w["text"].length <= 2 },
      longest_words: words.select { |w| w["text"].length >= 8 },
      punctuation_words: words.select { |w| w["text"].match?(/[.!?,:;]/) }
    }
  end

  def analyze_pauses(words)
    return {} if words.nil? || words.length < 2
    
    pauses = []
    words.each_cons(2) do |word1, word2|
      pause_duration = word2["start"].to_f - word1["end"].to_f
      pauses << pause_duration if pause_duration > 0.1
    end
    
    return {} if pauses.empty?
    
    {
      total_pauses: pauses.length,
      average_pause_duration: pauses.sum / pauses.length,
      longest_pause: pauses.max,
      short_pauses: pauses.count { |p| p < 0.5 },
      long_pauses: pauses.count { |p| p > 2.0 }
    }
  end

  def analyze_speech_speed(words)
    return {} if words.nil? || words.empty?
    
    total_duration = calculate_total_duration(words)
    return {} if total_duration == 0
    
    {
      words_per_minute: (words.length / (total_duration / 60.0)).round(1),
      characters_per_minute: (words.sum { |w| w["text"].length } / (total_duration / 60.0)).round(1),
      speech_density: (words.length / total_duration).round(2)
    }
  end

  def analyze_confidence_scores(words)
    # Mock confidence analysis (ElevenLabs doesn't provide confidence scores)
    # In a real implementation, you might calculate this based on timing consistency
    {
      note: "Confidence scores not provided by ElevenLabs Forced Alignment API",
      timing_consistency: calculate_timing_consistency(words)
    }
  end

  def calculate_timing_consistency(words)
    return 0 if words.nil? || words.length < 2
    
    durations = words.map { |w| w["end"].to_f - w["start"].to_f }
    variance = calculate_variance(durations)
    mean = durations.sum / durations.length
    
    # Lower variance relative to mean indicates more consistent timing
    consistency_score = 1.0 - (variance / (mean * mean)).clamp(0, 1)
    (consistency_score * 100).round(1)
  end

  def calculate_variance(values)
    return 0 if values.empty?
    
    mean = values.sum.to_f / values.length
    sum_of_squares = values.sum { |v| (v - mean) ** 2 }
    sum_of_squares / values.length
  end

  def generate_timing_recommendations(analysis)
    recommendations = []
    
    if analysis[:speech_speed] && analysis[:speech_speed][:words_per_minute]
      wpm = analysis[:speech_speed][:words_per_minute]
      if wpm > 180
        recommendations << "Speech rate is quite fast (#{wpm} WPM). Consider slowing down for better clarity."
      elsif wpm < 120
        recommendations << "Speech rate is slow (#{wpm} WPM). This may be good for accessibility but could be sped up for general audiences."
      end
    end
    
    if analysis[:pause_analysis] && analysis[:pause_analysis][:long_pauses]
      long_pauses = analysis[:pause_analysis][:long_pauses]
      if long_pauses > 5
        recommendations << "Multiple long pauses detected. Consider editing for smoother flow."
      end
    end
    
    recommendations << "Timing alignment appears consistent" if recommendations.empty?
    recommendations
  end

  # Strong parameters for forced alignment
  def forced_alignment_params
    params.permit(
      :audio_file,
      :transcript,
      :enabled_spooled_file,
      alignments: [:audio_file, :transcript]
    )
  end
end

# Example routes.rb configuration:
#
# Rails.application.routes.draw do
#   namespace :forced_alignment do
#     post :align
#     post :align_srt
#     post :align_vtt
#     post :batch_align
#     post :analyze_timing
#     get :info
#   end
# end

# Example usage in views:
#
# <%= form_with url: forced_alignment_align_path, multipart: true do |form| %>
#   <%= form.file_field :audio_file, accept: "audio/*", required: true %>
#   <%= form.text_area :transcript, placeholder: "Enter transcript text...", required: true, rows: 5 %>
#   <%= form.check_box :enabled_spooled_file %>
#   <%= form.label :enabled_spooled_file, "Enable spooled file processing" %>
#   <%= form.submit "Generate Alignment" %>
# <% end %>
#
# <!-- Download buttons for different formats -->
# <%= link_to "Download SRT", forced_alignment_align_srt_path, 
#     method: :post, 
#     params: { audio_file: @audio_file, transcript: @transcript },
#     class: "btn btn-primary" %>
# <%= link_to "Download VTT", forced_alignment_align_vtt_path, 
#     method: :post, 
#     params: { audio_file: @audio_file, transcript: @transcript },
#     class: "btn btn-secondary" %>
