# frozen_string_literal: true

# Example Rails controller demonstrating ElevenLabs Admin Voice Library API integration
# This controller provides community voice browsing and management functionality
class Admin::VoiceLibraryController < ApplicationController
  before_action :initialize_client
  before_action :authenticate_admin # Ensure only admins can access voice library
  
  # GET /admin/voice_library
  # Main voice library browser with filtering and search
  def index
    @filters = extract_filters_from_params
    @voices = fetch_voices_with_filters(@filters)
    @filter_options = build_filter_options
    @pagination = build_pagination_data(@voices)
    
    respond_to do |format|
      format.html
      format.json { render json: voice_library_data }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to load voice library")
  end
  
  # GET /admin/voice_library/search
  # Advanced voice search with recommendations
  def search
    @query = params[:q] || ''
    @filters = extract_filters_from_params
    @search_results = perform_voice_search(@query, @filters)
    @recommendations = generate_voice_recommendations(@query, @filters)
    @search_suggestions = generate_search_suggestions(@query)
    
    respond_to do |format|
      format.html { render :index }
      format.json { render json: search_results_data }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Search failed")
  end
  
  # GET /admin/voice_library/featured
  # Browse featured and trending voices
  def featured
    @featured_voices = fetch_featured_voices
    @trending_voices = fetch_trending_voices
    @popular_voices = fetch_popular_voices
    @categories = analyze_voice_categories(@featured_voices['voices'] + @trending_voices['voices'])
    
    respond_to do |format|
      format.html
      format.json { render json: featured_voices_data }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to load featured voices")
  end
  
  # GET /admin/voice_library/:voice_id
  # Voice details and preview
  def show
    @voice_id = params[:voice_id]
    @voice = find_voice_by_id(@voice_id)
    
    if @voice
      @voice_details = analyze_voice_details(@voice)
      @similar_voices = find_similar_voices(@voice)
      @usage_stats = calculate_voice_usage_stats(@voice)
      @can_add = can_add_voice?(@voice)
    else
      redirect_to admin_voice_library_path, alert: "Voice not found"
      return
    end
    
    respond_to do |format|
      format.html
      format.json { render json: voice_details_data }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to load voice details")
  end
  
  # POST /admin/voice_library/:voice_id/add
  # Add a shared voice to the user's collection
  def add_voice
    @voice_id = params[:voice_id]
    @voice = find_voice_by_id(@voice_id)
    
    unless @voice
      redirect_to admin_voice_library_path, alert: "Voice not found"
      return
    end
    
    custom_name = params[:custom_name] || "Shared #{@voice['name']}"
    
    result = @client.voice_library.add_shared_voice(
      public_user_id: @voice['public_owner_id'],
      voice_id: @voice['voice_id'],
      new_name: custom_name
    )
    
    # Log the addition for tracking
    log_voice_addition(@voice, result['voice_id'], custom_name)
    
    respond_to do |format|
      format.html do
        redirect_to admin_voice_library_path(@voice_id), 
                   notice: "Voice '#{custom_name}' added successfully! New voice ID: #{result['voice_id']}"
      end
      format.json { render json: { success: true, voice_id: result['voice_id'], message: "Voice added successfully" } }
    end
    
  rescue ElevenlabsClient::UnprocessableEntityError => e
    handle_add_voice_error(e, "Cannot add voice")
  rescue ElevenlabsClient::NotFoundError
    handle_add_voice_error(StandardError.new("Voice not available"), "Voice not found")
  rescue ElevenlabsClient::APIError => e
    handle_add_voice_error(e, "Failed to add voice")
  end
  
  # POST /admin/voice_library/bulk_add
  # Add multiple voices to collection
  def bulk_add
    voice_ids = params[:voice_ids] || []
    naming_pattern = params[:naming_pattern] || "Shared %{name}"
    
    if voice_ids.empty?
      redirect_to admin_voice_library_path, alert: "No voices selected"
      return
    end
    
    @bulk_results = perform_bulk_voice_addition(voice_ids, naming_pattern)
    
    respond_to do |format|
      format.html { render :bulk_results }
      format.json { render json: @bulk_results }
    end
  end
  
  # GET /admin/voice_library/collections
  # Curated voice collections and themes
  def collections
    @collections = {
      narration: curate_narration_collection,
      characters: curate_character_collection,
      professional: curate_professional_collection,
      languages: curate_language_collections
    }
    
    @collection_stats = calculate_collection_stats(@collections)
    
    respond_to do |format|
      format.html
      format.json { render json: { collections: @collections, stats: @collection_stats } }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to load collections")
  end
  
  # POST /admin/voice_library/collections/:theme/add_all
  # Add an entire curated collection
  def add_collection
    theme = params[:theme]
    max_voices = params[:max_voices]&.to_i || 10
    
    unless %w[narration characters professional].include?(theme)
      redirect_to admin_voice_library_collections_path, alert: "Invalid collection theme"
      return
    end
    
    @collection_results = add_curated_collection(theme, max_voices)
    
    respond_to do |format|
      format.html { render :collection_results }
      format.json { render json: @collection_results }
    end
  end
  
  # GET /admin/voice_library/analytics
  # Voice library analytics and insights
  def analytics
    @analytics = {
      popular_categories: analyze_popular_categories,
      trending_voices: analyze_trending_voices,
      usage_patterns: analyze_usage_patterns,
      recommendation_metrics: calculate_recommendation_metrics
    }
    
    @insights = generate_voice_insights(@analytics)
    
    respond_to do |format|
      format.html
      format.json { render json: { analytics: @analytics, insights: @insights } }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to load analytics")
  end
  
  # GET /admin/voice_library/export
  # Export voice library data
  def export
    format_type = params[:format] || 'csv'
    filters = extract_filters_from_params
    
    voices_data = fetch_voices_for_export(filters)
    
    case format_type
    when 'csv'
      send_csv_export(voices_data)
    when 'json'
      send_json_export(voices_data)
    else
      redirect_to admin_voice_library_path, alert: "Invalid export format"
    end
  rescue ElevenlabsClient::APIError => e
    redirect_to admin_voice_library_path, alert: "Export failed: #{e.message}"
  end
  
  private
  
  def initialize_client
    @client = ElevenlabsClient.new
  end
  
  def authenticate_admin
    # Implement your admin authentication logic here
    # redirect_to root_path unless current_user&.admin?
  end
  
  def extract_filters_from_params
    {
      category: params[:category],
      gender: params[:gender],
      age: params[:age],
      accent: params[:accent],
      language: params[:language],
      locale: params[:locale],
      search: params[:search],
      use_cases: params[:use_cases]&.split(','),
      descriptives: params[:descriptives]&.split(','),
      featured: params[:featured] == 'true',
      min_notice_period_days: params[:min_notice_period_days]&.to_i,
      include_custom_rates: params[:include_custom_rates] == 'true',
      include_live_moderated: params[:include_live_moderated] == 'true',
      reader_app_enabled: params[:reader_app_enabled] == 'true',
      owner_id: params[:owner_id],
      sort: params[:sort],
      page_size: [params[:page_size]&.to_i || 30, 100].min,
      page: params[:page]&.to_i || 0
    }.compact
  end
  
  def fetch_voices_with_filters(filters)
    @client.voice_library.get_shared_voices(**filters)
  end
  
  def build_filter_options
    {
      categories: %w[professional famous high_quality],
      genders: %w[Male Female],
      ages: %w[young middle_aged old],
      accents: %w[american british australian canadian irish],
      languages: %w[en es fr de it pt ja zh ko],
      use_cases: %w[narration characters_animation news audiobook conversational asmr meditation],
      descriptives: %w[calm energetic authoritative friendly professional dramatic warm clear]
    }
  end
  
  def build_pagination_data(voices_data)
    {
      current_page: params[:page]&.to_i || 0,
      page_size: params[:page_size]&.to_i || 30,
      has_more: voices_data['has_more'],
      total_voices: voices_data['voices'].length,
      last_sort_id: voices_data['last_sort_id']
    }
  end
  
  def perform_voice_search(query, filters)
    search_filters = filters.merge(search: query)
    @client.voice_library.get_shared_voices(**search_filters)
  end
  
  def generate_voice_recommendations(query, filters)
    # Simple recommendation logic based on query and filters
    recommendations = []
    
    if query.downcase.include?('narrator') || query.downcase.include?('audiobook')
      recommendations << {
        title: 'Try Narration Voices',
        description: 'Explore voices specifically designed for narration',
        filters: { use_cases: ['narration', 'audiobook'], descriptives: ['calm', 'clear'] }
      }
    end
    
    if query.downcase.include?('character') || query.downcase.include?('animation')
      recommendations << {
        title: 'Character Voices',
        description: 'Find expressive voices perfect for character work',
        filters: { use_cases: ['characters_animation'], descriptives: ['expressive', 'dramatic'] }
      }
    end
    
    if filters[:language] && filters[:language] != 'en'
      recommendations << {
        title: 'Native Speakers',
        description: "Find native #{filters[:language]} speakers",
        filters: { language: filters[:language], accent: 'native' }
      }
    end
    
    recommendations
  end
  
  def generate_search_suggestions(query)
    return [] if query.length < 2
    
    # Simple suggestions based on common terms
    suggestions = []
    
    if query.match?(/narr/i)
      suggestions << 'narrator', 'narration', 'audiobook narrator'
    end
    
    if query.match?(/prof/i)
      suggestions << 'professional', 'professional voice', 'business professional'
    end
    
    if query.match?(/char/i)
      suggestions << 'character', 'character voice', 'animation character'
    end
    
    suggestions.uniq.first(5)
  end
  
  def fetch_featured_voices
    @client.voice_library.get_shared_voices(
      featured: true,
      page_size: 20,
      sort: 'featured_date_desc'
    )
  end
  
  def fetch_trending_voices
    @client.voice_library.get_shared_voices(
      sort: 'usage_7d_desc',
      page_size: 15
    )
  end
  
  def fetch_popular_voices
    @client.voice_library.get_shared_voices(
      sort: 'cloned_count_desc',
      page_size: 15
    )
  end
  
  def analyze_voice_categories(voices)
    category_stats = Hash.new(0)
    gender_stats = Hash.new(0)
    language_stats = Hash.new(0)
    
    voices.each do |voice|
      category_stats[voice['category']] += 1
      gender_stats[voice['gender']] += 1
      language_stats[voice['language']] += 1
    end
    
    {
      by_category: category_stats,
      by_gender: gender_stats,
      by_language: language_stats
    }
  end
  
  def find_voice_by_id(voice_id)
    # Since there's no direct get method, search through results
    # In a real implementation, you might want to cache this or use a more efficient lookup
    voices = @client.voice_library.get_shared_voices(page_size: 100)
    voices['voices'].find { |v| v['voice_id'] == voice_id }
  end
  
  def analyze_voice_details(voice)
    {
      basic_info: {
        name: voice['name'],
        category: voice['category'],
        gender: voice['gender'],
        age: voice['age'],
        accent: voice['accent'],
        language: voice['language']
      },
      characteristics: {
        descriptive: voice['descriptive'],
        use_case: voice['use_case'],
        description: voice['description']
      },
      availability: {
        free_users_allowed: voice['free_users_allowed'],
        live_moderation_enabled: voice['live_moderation_enabled'],
        rate: voice['rate']
      },
      popularity: {
        cloned_by_count: voice['cloned_by_count'],
        usage_1y: voice['usage_character_count_1y'],
        usage_7d: voice['usage_character_count_7d']
      },
      technical: {
        verified_languages: voice['verified_languages'],
        preview_url: voice['preview_url']
      }
    }
  end
  
  def find_similar_voices(voice)
    # Find voices with similar characteristics
    similar_filters = {
      category: voice['category'],
      gender: voice['gender'],
      age: voice['age'],
      language: voice['language'],
      page_size: 10
    }
    
    similar_voices = @client.voice_library.get_shared_voices(**similar_filters)
    
    # Remove the current voice from results
    similar_voices['voices'].reject { |v| v['voice_id'] == voice['voice_id'] }
  end
  
  def calculate_voice_usage_stats(voice)
    {
      popularity_score: calculate_popularity_score(voice),
      usage_trend: calculate_usage_trend(voice),
      clone_rate: voice['cloned_by_count'],
      recent_activity: voice['usage_character_count_7d']
    }
  end
  
  def can_add_voice?(voice)
    # Check if voice can be added (basic validation)
    voice['free_users_allowed'] || voice['rate'] <= 1
  end
  
  def log_voice_addition(voice, new_voice_id, custom_name)
    Rails.logger.info "Voice added: #{voice['name']} -> #{custom_name} (#{new_voice_id})"
    # Here you might want to log to database, analytics, etc.
  end
  
  def perform_bulk_voice_addition(voice_ids, naming_pattern)
    results = {
      successful: [],
      failed: [],
      skipped: []
    }
    
    voice_ids.each do |voice_id|
      voice = find_voice_by_id(voice_id)
      next unless voice
      
      custom_name = naming_pattern % { name: voice['name'], category: voice['category'] }
      
      begin
        result = @client.voice_library.add_shared_voice(
          public_user_id: voice['public_owner_id'],
          voice_id: voice['voice_id'],
          new_name: custom_name
        )
        
        results[:successful] << {
          original_name: voice['name'],
          custom_name: custom_name,
          new_voice_id: result['voice_id']
        }
        
      rescue ElevenlabsClient::UnprocessableEntityError => e
        results[:skipped] << {
          original_name: voice['name'],
          reason: e.message
        }
      rescue ElevenlabsClient::APIError => e
        results[:failed] << {
          original_name: voice['name'],
          error: e.message
        }
      end
    end
    
    results
  end
  
  def curate_narration_collection
    @client.voice_library.get_shared_voices(
      use_cases: ['narration', 'audiobook'],
      descriptives: ['calm', 'clear', 'professional'],
      category: 'professional',
      page_size: 20
    )['voices']
  end
  
  def curate_character_collection
    @client.voice_library.get_shared_voices(
      use_cases: ['characters_animation'],
      descriptives: ['expressive', 'dramatic', 'energetic'],
      page_size: 20
    )['voices']
  end
  
  def curate_professional_collection
    @client.voice_library.get_shared_voices(
      category: 'professional',
      featured: true,
      page_size: 15
    )['voices']
  end
  
  def curate_language_collections
    languages = %w[en es fr de it pt]
    collections = {}
    
    languages.each do |lang|
      collections[lang] = @client.voice_library.get_shared_voices(
        language: lang,
        page_size: 10
      )['voices']
    end
    
    collections
  end
  
  def calculate_collection_stats(collections)
    stats = {}
    
    collections.each do |theme, voices|
      if theme == :languages
        stats[theme] = voices.map { |lang, voice_list| [lang, voice_list.length] }.to_h
      else
        stats[theme] = {
          total_voices: voices.length,
          categories: voices.group_by { |v| v['category'] }.transform_values(&:length),
          genders: voices.group_by { |v| v['gender'] }.transform_values(&:length)
        }
      end
    end
    
    stats
  end
  
  def add_curated_collection(theme, max_voices)
    collection_voices = case theme
                       when 'narration' then curate_narration_collection
                       when 'characters' then curate_character_collection
                       when 'professional' then curate_professional_collection
                       end
    
    # Select diverse subset
    selected_voices = select_diverse_voices(collection_voices, max_voices)
    
    # Add voices
    perform_bulk_voice_addition(
      selected_voices.map { |v| v['voice_id'] },
      "#{theme.capitalize} %{name}"
    )
  end
  
  def select_diverse_voices(voices, max_count)
    # Ensure diversity across gender, age, accent
    selected = []
    used_combinations = Set.new
    
    # Sort by popularity first
    sorted_voices = voices.sort_by { |v| -(v['cloned_by_count'] + v['usage_character_count_1y'] * 0.001) }
    
    sorted_voices.each do |voice|
      combination = "#{voice['gender']}_#{voice['age']}_#{voice['accent']}"
      
      if !used_combinations.include?(combination) && selected.length < max_count
        selected << voice
        used_combinations.add(combination)
      end
      
      break if selected.length >= max_count
    end
    
    # Fill remaining slots with best available
    if selected.length < max_count
      remaining = max_count - selected.length
      additional = (sorted_voices - selected).first(remaining)
      selected.concat(additional)
    end
    
    selected
  end
  
  def analyze_popular_categories
    voices = @client.voice_library.get_shared_voices(page_size: 100)
    
    category_usage = Hash.new { |h, k| h[k] = { count: 0, total_clones: 0, avg_usage: 0 } }
    
    voices['voices'].each do |voice|
      cat = voice['category']
      category_usage[cat][:count] += 1
      category_usage[cat][:total_clones] += voice['cloned_by_count']
      category_usage[cat][:avg_usage] += voice['usage_character_count_1y']
    end
    
    category_usage.transform_values do |stats|
      stats[:avg_clones] = stats[:total_clones].to_f / stats[:count]
      stats[:avg_usage] = stats[:avg_usage].to_f / stats[:count]
      stats
    end
  end
  
  def analyze_trending_voices
    # Get voices with high recent usage
    trending = @client.voice_library.get_shared_voices(
      sort: 'usage_7d_desc',
      page_size: 50
    )['voices']
    
    trending.map do |voice|
      {
        name: voice['name'],
        category: voice['category'],
        recent_usage: voice['usage_character_count_7d'],
        total_usage: voice['usage_character_count_1y'],
        clone_count: voice['cloned_by_count'],
        trend_score: calculate_trend_score(voice)
      }
    end.sort_by { |v| -v[:trend_score] }.first(10)
  end
  
  def analyze_usage_patterns
    voices = @client.voice_library.get_shared_voices(page_size: 100)['voices']
    
    {
      high_usage: voices.select { |v| v['usage_character_count_1y'] > 50000 }.length,
      medium_usage: voices.select { |v| v['usage_character_count_1y'].between?(10000, 50000) }.length,
      low_usage: voices.select { |v| v['usage_character_count_1y'] < 10000 }.length,
      avg_clones_per_voice: voices.sum { |v| v['cloned_by_count'] }.to_f / voices.length
    }
  end
  
  def calculate_recommendation_metrics
    # This would typically analyze user behavior and preferences
    {
      most_recommended_category: 'professional',
      trending_use_cases: %w[narration characters_animation conversational],
      popular_combinations: [
        { gender: 'Female', age: 'middle_aged', category: 'professional' },
        { gender: 'Male', age: 'young', category: 'high_quality' }
      ]
    }
  end
  
  def generate_voice_insights(analytics)
    insights = []
    
    # Category insights
    popular_cat = analytics[:popular_categories].max_by { |_, stats| stats[:avg_clones] }
    insights << "#{popular_cat[0].capitalize} voices are most popular with #{popular_cat[1][:avg_clones].round(1)} average clones"
    
    # Usage insights
    if analytics[:usage_patterns][:high_usage] > analytics[:usage_patterns][:low_usage]
      insights << "More voices show high usage patterns, indicating active community engagement"
    end
    
    # Trending insights
    top_trending = analytics[:trending_voices].first
    if top_trending
      insights << "#{top_trending[:name]} is currently trending with #{top_trending[:recent_usage]} recent characters"
    end
    
    insights
  end
  
  def fetch_voices_for_export(filters)
    all_voices = []
    page = 0
    
    loop do
      result = @client.voice_library.get_shared_voices(**filters.merge(page: page, page_size: 100))
      all_voices.concat(result['voices'])
      
      break unless result['has_more']
      page += 1
      
      # Safety limit
      break if page > 10
    end
    
    all_voices
  end
  
  def send_csv_export(voices_data)
    require 'csv'
    
    csv_data = CSV.generate(headers: true) do |csv|
      csv << [
        'Voice ID', 'Name', 'Category', 'Gender', 'Age', 'Accent', 'Language',
        'Use Case', 'Descriptive', 'Cloned Count', 'Usage 1Y', 'Usage 7D',
        'Free Users Allowed', 'Rate', 'Featured', 'Description'
      ]
      
      voices_data.each do |voice|
        csv << [
          voice['voice_id'],
          voice['name'],
          voice['category'],
          voice['gender'],
          voice['age'],
          voice['accent'],
          voice['language'],
          voice['use_case'],
          voice['descriptive'],
          voice['cloned_by_count'],
          voice['usage_character_count_1y'],
          voice['usage_character_count_7d'],
          voice['free_users_allowed'],
          voice['rate'],
          voice['featured'],
          voice['description']
        ]
      end
    end
    
    filename = "voice_library_export_#{Date.current}.csv"
    send_data csv_data, type: 'text/csv', filename: filename, disposition: 'attachment'
  end
  
  def send_json_export(voices_data)
    export_data = {
      exported_at: Time.current.iso8601,
      total_voices: voices_data.length,
      voices: voices_data
    }
    
    filename = "voice_library_export_#{Date.current}.json"
    send_data export_data.to_json, type: 'application/json', filename: filename, disposition: 'attachment'
  end
  
  def calculate_popularity_score(voice)
    # Weighted popularity score
    clone_score = voice['cloned_by_count'] * 2
    usage_score = voice['usage_character_count_1y'] * 0.001
    recent_score = voice['usage_character_count_7d'] * 0.01
    featured_bonus = voice['featured'] ? 50 : 0
    
    (clone_score + usage_score + recent_score + featured_bonus).round(2)
  end
  
  def calculate_usage_trend(voice)
    recent = voice['usage_character_count_7d']
    yearly = voice['usage_character_count_1y']
    
    return 'stable' if yearly.zero?
    
    weekly_average = yearly / 52.0
    
    if recent > weekly_average * 1.5
      'increasing'
    elsif recent < weekly_average * 0.5
      'decreasing'
    else
      'stable'
    end
  end
  
  def calculate_trend_score(voice)
    # Score based on recent activity vs historical
    recent = voice['usage_character_count_7d']
    yearly = voice['usage_character_count_1y']
    clones = voice['cloned_by_count']
    
    weekly_avg = yearly / 52.0
    trend_multiplier = weekly_avg > 0 ? (recent / weekly_avg) : 1
    
    base_score = recent + (clones * 10)
    (base_score * trend_multiplier).round(2)
  end
  
  def voice_library_data
    {
      voices: @voices,
      filters: @filters,
      filter_options: @filter_options,
      pagination: @pagination
    }
  end
  
  def search_results_data
    {
      query: @query,
      results: @search_results,
      recommendations: @recommendations,
      suggestions: @search_suggestions
    }
  end
  
  def featured_voices_data
    {
      featured: @featured_voices,
      trending: @trending_voices,
      popular: @popular_voices,
      categories: @categories
    }
  end
  
  def voice_details_data
    {
      voice: @voice,
      details: @voice_details,
      similar_voices: @similar_voices,
      usage_stats: @usage_stats,
      can_add: @can_add
    }
  end
  
  def handle_api_error(error, default_message)
    Rails.logger.error "ElevenLabs API Error: #{error.message}"
    flash.now[:error] = "#{default_message}: #{error.message}"
    
    # Set fallback data
    @voices = { 'voices' => [], 'has_more' => false }
    @search_results = @voices
    @featured_voices = @voices
    @trending_voices = @voices
    @popular_voices = @voices
    
    render :index
  end
  
  def handle_add_voice_error(error, default_message)
    error_message = "#{default_message}: #{error.message}"
    
    respond_to do |format|
      format.html do
        redirect_to admin_voice_library_path(@voice_id), alert: error_message
      end
      format.json do
        render json: { success: false, error: error_message }, status: :unprocessable_entity
      end
    end
  end
end
