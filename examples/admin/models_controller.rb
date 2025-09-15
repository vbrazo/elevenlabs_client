# frozen_string_literal: true

# Example Rails controller demonstrating ElevenLabs Admin Models API integration
# This controller provides model information and capabilities management
class Admin::ModelsController < ApplicationController
  before_action :initialize_client
  before_action :authenticate_admin # Ensure only admins can access model data
  
  # GET /admin/models
  # List all available models with capabilities
  def index
    @models = @client.models.list
    @model_analysis = analyze_models(@models['models'])
    @model_categories = categorize_models(@models['models'])
    @recommendations = generate_model_recommendations(@models['models'])
    
    respond_to do |format|
      format.html
      format.json { render json: models_index_data }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to load models")
  end
  
  # GET /admin/models/comparison
  # Model comparison and selection guide
  def comparison
    @models = @client.models.list
    @comparison_matrix = build_comparison_matrix(@models['models'])
    @performance_metrics = calculate_performance_metrics(@models['models'])
    @cost_analysis = analyze_model_costs(@models['models'])
    @use_case_recommendations = build_use_case_recommendations(@models['models'])
    
    respond_to do |format|
      format.html
      format.json { render json: comparison_data }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to load model comparison")
  end
  
  # GET /admin/models/capabilities
  # Detailed capabilities analysis
  def capabilities
    @models = @client.models.list
    @capability_matrix = build_capability_matrix(@models['models'])
    @language_support = analyze_language_support(@models['models'])
    @feature_availability = analyze_feature_availability(@models['models'])
    @compatibility_guide = build_compatibility_guide(@models['models'])
    
    respond_to do |format|
      format.html
      format.json { render json: capabilities_data }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to load model capabilities")
  end
  
  # GET /admin/models/selection_guide
  # Interactive model selection guide
  def selection_guide
    @requirements = extract_requirements_from_params
    @recommended_models = recommend_models_for_requirements(@requirements)
    @selection_criteria = build_selection_criteria
    @decision_tree = build_decision_tree
    
    respond_to do |format|
      format.html
      format.json { render json: selection_guide_data }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to load selection guide")
  end
  
  # GET /admin/models/performance
  # Model performance analysis and benchmarks
  def performance
    @models = @client.models.list
    @performance_data = analyze_model_performance(@models['models'])
    @benchmarks = calculate_model_benchmarks(@models['models'])
    @optimization_tips = generate_optimization_tips(@models['models'])
    @performance_trends = analyze_performance_trends(@models['models'])
    
    respond_to do |format|
      format.html
      format.json { render json: performance_data }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to load performance data")
  end
  
  # GET /admin/models/languages
  # Language support and compatibility
  def languages
    @models = @client.models.list
    @language_matrix = build_language_support_matrix(@models['models'])
    @language_quality = analyze_language_quality(@models['models'])
    @multilingual_capabilities = analyze_multilingual_capabilities(@models['models'])
    @language_recommendations = generate_language_recommendations(@models['models'])
    
    respond_to do |format|
      format.html
      format.json { render json: languages_data }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to load language data")
  end
  
  # POST /admin/models/recommend
  # Get model recommendations based on requirements
  def recommend
    requirements = {
      use_case: params[:use_case],
      languages: params[:languages]&.split(','),
      quality_priority: params[:quality_priority], # speed vs quality
      budget_constraint: params[:budget_constraint],
      features_needed: params[:features_needed]&.split(',')
    }
    
    @models = @client.models.list
    @recommendations = generate_personalized_recommendations(@models['models'], requirements)
    @explanation = build_recommendation_explanation(@recommendations, requirements)
    
    respond_to do |format|
      format.html { render :selection_guide }
      format.json { render json: { recommendations: @recommendations, explanation: @explanation } }
    end
  rescue ElevenlabsClient::APIError => e
    handle_api_error(e, "Unable to generate recommendations")
  end
  
  # GET /admin/models/export
  # Export model information and analysis
  def export
    format_type = params[:format] || 'csv'
    
    @models = @client.models.list
    
    case format_type
    when 'csv'
      send_csv_export(@models['models'])
    when 'json'
      send_json_export(@models['models'])
    else
      redirect_to admin_models_path, alert: "Invalid export format"
    end
  rescue ElevenlabsClient::APIError => e
    redirect_to admin_models_path, alert: "Export failed: #{e.message}"
  end
  
  private
  
  def initialize_client
    @client = ElevenlabsClient.new
  end
  
  def authenticate_admin
    # Implement your admin authentication logic here
    # redirect_to root_path unless current_user&.admin?
  end
  
  def analyze_models(models)
    {
      total_models: models.length,
      by_capability: {
        text_to_speech: models.count { |m| m['can_do_text_to_speech'] },
        voice_conversion: models.count { |m| m['can_do_voice_conversion'] },
        finetunable: models.count { |m| m['can_be_finetuned'] },
        style_support: models.count { |m| m['can_use_style'] },
        speaker_boost: models.count { |m| m['can_use_speaker_boost'] }
      },
      cost_range: {
        min_cost_factor: models.map { |m| m['token_cost_factor'] }.min,
        max_cost_factor: models.map { |m| m['token_cost_factor'] }.max,
        avg_cost_factor: (models.sum { |m| m['token_cost_factor'] } / models.length.to_f).round(2)
      },
      language_support: {
        total_languages: models.flat_map { |m| m['languages'] }.map { |l| l['language_id'] }.uniq.length,
        multilingual_models: models.count { |m| m['languages'].length > 1 }
      }
    }
  end
  
  def categorize_models(models)
    {
      by_speed: {
        fastest: models.select { |m| m['token_cost_factor'] < 0.5 },
        balanced: models.select { |m| m['token_cost_factor'].between?(0.5, 1.0) },
        quality: models.select { |m| m['token_cost_factor'] > 1.0 }
      },
      by_capability: {
        basic_tts: models.select { |m| m['can_do_text_to_speech'] && !m['can_use_style'] },
        advanced_tts: models.select { |m| m['can_do_text_to_speech'] && m['can_use_style'] },
        voice_conversion: models.select { |m| m['can_do_voice_conversion'] }
      },
      by_language_support: {
        monolingual: models.select { |m| m['languages'].length == 1 },
        multilingual: models.select { |m| m['languages'].length > 1 }
      }
    }
  end
  
  def generate_model_recommendations(models)
    recommendations = []
    
    # Speed recommendation
    fastest_model = models.min_by { |m| m['token_cost_factor'] }
    recommendations << {
      category: 'speed',
      title: 'Fastest Model',
      model: fastest_model,
      reason: "Lowest cost factor (#{fastest_model['token_cost_factor']}x) for real-time applications"
    }
    
    # Quality recommendation
    quality_models = models.select { |m| m['can_use_style'] && m['can_use_speaker_boost'] }
    if quality_models.any?
      quality_model = quality_models.max_by { |m| m['token_cost_factor'] }
      recommendations << {
        category: 'quality',
        title: 'Highest Quality',
        model: quality_model,
        reason: 'Supports style and speaker boost for premium quality output'
      }
    end
    
    # Multilingual recommendation
    multilingual_models = models.select { |m| m['languages'].length > 5 }
    if multilingual_models.any?
      multilingual_model = multilingual_models.max_by { |m| m['languages'].length }
      recommendations << {
        category: 'multilingual',
        title: 'Best Multilingual Support',
        model: multilingual_model,
        reason: "Supports #{multilingual_model['languages'].length} languages"
      }
    end
    
    recommendations
  end
  
  def build_comparison_matrix(models)
    matrix = []
    
    models.each do |model|
      matrix << {
        model_id: model['model_id'],
        name: model['name'],
        capabilities: {
          text_to_speech: model['can_do_text_to_speech'],
          voice_conversion: model['can_do_voice_conversion'],
          finetunable: model['can_be_finetuned'],
          style_support: model['can_use_style'],
          speaker_boost: model['can_use_speaker_boost']
        },
        performance: {
          cost_factor: model['token_cost_factor'],
          speed_rating: calculate_speed_rating(model['token_cost_factor']),
          quality_rating: calculate_quality_rating(model)
        },
        languages: model['languages'].length,
        character_limits: {
          free_user: model['max_characters_request_free_user'],
          subscribed_user: model['max_characters_request_subscribed_user']
        },
        alpha_access: model['requires_alpha_access']
      }
    end
    
    matrix.sort_by { |m| [m[:performance][:quality_rating], -m[:performance][:cost_factor]] }.reverse
  end
  
  def calculate_performance_metrics(models)
    {
      speed_leader: models.min_by { |m| m['token_cost_factor'] },
      quality_leader: models.select { |m| m['can_use_style'] }.max_by { |m| m['token_cost_factor'] },
      versatility_leader: models.max_by { |m| count_capabilities(m) },
      language_leader: models.max_by { |m| m['languages'].length },
      efficiency_score: calculate_efficiency_scores(models)
    }
  end
  
  def analyze_model_costs(models)
    cost_factors = models.map { |m| m['token_cost_factor'] }
    
    {
      cost_distribution: {
        economy: models.select { |m| m['token_cost_factor'] < 0.5 }.length,
        standard: models.select { |m| m['token_cost_factor'].between?(0.5, 1.0) }.length,
        premium: models.select { |m| m['token_cost_factor'] > 1.0 }.length
      },
      cost_stats: {
        min: cost_factors.min,
        max: cost_factors.max,
        average: (cost_factors.sum / cost_factors.length.to_f).round(2),
        median: cost_factors.sort[cost_factors.length / 2]
      },
      cost_efficiency: calculate_cost_efficiency(models)
    }
  end
  
  def build_use_case_recommendations(models)
    {
      real_time_applications: models.select { |m| m['token_cost_factor'] < 0.5 },
      high_quality_content: models.select { |m| m['can_use_style'] && m['can_use_speaker_boost'] },
      multilingual_projects: models.select { |m| m['languages'].length > 3 },
      voice_cloning: models.select { |m| m['can_be_finetuned'] },
      commercial_use: models.reject { |m| m['requires_alpha_access'] },
      experimental_features: models.select { |m| m['requires_alpha_access'] }
    }
  end
  
  def build_capability_matrix(models)
    capabilities = %w[can_do_text_to_speech can_do_voice_conversion can_be_finetuned can_use_style can_use_speaker_boost serves_pro_voices]
    
    matrix = {}
    
    capabilities.each do |capability|
      matrix[capability] = {
        supporting_models: models.select { |m| m[capability] },
        count: models.count { |m| m[capability] },
        percentage: (models.count { |m| m[capability] }.to_f / models.length * 100).round(1)
      }
    end
    
    matrix
  end
  
  def analyze_language_support(models)
    all_languages = models.flat_map { |m| m['languages'] }.uniq { |l| l['language_id'] }
    
    language_stats = {}
    
    all_languages.each do |lang|
      supporting_models = models.select { |m| m['languages'].any? { |l| l['language_id'] == lang['language_id'] } }
      
      language_stats[lang['language_id']] = {
        name: lang['name'],
        model_count: supporting_models.length,
        models: supporting_models.map { |m| m['model_id'] },
        coverage: (supporting_models.length.to_f / models.length * 100).round(1)
      }
    end
    
    language_stats.sort_by { |_, stats| -stats[:model_count] }.to_h
  end
  
  def analyze_feature_availability(models)
    features = {
      style_control: models.count { |m| m['can_use_style'] },
      speaker_boost: models.count { |m| m['can_use_speaker_boost'] },
      voice_conversion: models.count { |m| m['can_do_voice_conversion'] },
      fine_tuning: models.count { |m| m['can_be_finetuned'] },
      pro_voice_support: models.count { |m| m['serves_pro_voices'] }
    }
    
    total_models = models.length
    
    features.transform_values do |count|
      {
        count: count,
        percentage: (count.to_f / total_models * 100).round(1),
        availability: case (count.to_f / total_models)
                     when 0..0.25 then 'limited'
                     when 0.25..0.75 then 'partial'
                     else 'widespread'
                     end
      }
    end
  end
  
  def build_compatibility_guide(models)
    {
      voice_types: {
        premade_voices: models.select { |m| !m['serves_pro_voices'] },
        professional_voices: models.select { |m| m['serves_pro_voices'] },
        custom_voices: models.select { |m| m['can_be_finetuned'] }
      },
      use_case_compatibility: {
        basic_tts: models.select { |m| m['can_do_text_to_speech'] && !m['requires_alpha_access'] },
        advanced_tts: models.select { |m| m['can_use_style'] || m['can_use_speaker_boost'] },
        voice_transformation: models.select { |m| m['can_do_voice_conversion'] },
        experimental: models.select { |m| m['requires_alpha_access'] }
      }
    }
  end
  
  def extract_requirements_from_params
    {
      use_case: params[:use_case],
      languages: params[:languages]&.split(',') || [],
      quality_priority: params[:quality_priority] || 'balanced',
      speed_priority: params[:speed_priority] || 'balanced',
      budget_constraint: params[:budget_constraint] || 'flexible',
      features_needed: params[:features_needed]&.split(',') || []
    }
  end
  
  def recommend_models_for_requirements(requirements)
    models = @client.models.list['models']
    scored_models = []
    
    models.each do |model|
      score = calculate_model_score(model, requirements)
      scored_models << {
        model: model,
        score: score,
        reasoning: generate_score_reasoning(model, requirements, score)
      }
    end
    
    scored_models.sort_by { |m| -m[:score] }.first(5)
  end
  
  def build_selection_criteria
    {
      use_cases: {
        'real_time' => 'Real-time applications requiring low latency',
        'high_quality' => 'High-quality content production',
        'multilingual' => 'Multiple language support needed',
        'voice_cloning' => 'Custom voice creation and training',
        'commercial' => 'Commercial and production use'
      },
      priorities: {
        'speed' => 'Prioritize fast generation over quality',
        'quality' => 'Prioritize quality over speed',
        'balanced' => 'Balance between speed and quality',
        'cost' => 'Minimize costs while meeting requirements'
      },
      features: {
        'style_control' => 'Ability to control speaking style',
        'speaker_boost' => 'Enhanced voice clarity and presence',
        'voice_conversion' => 'Transform existing audio',
        'fine_tuning' => 'Train custom models',
        'pro_voices' => 'Professional voice actor support'
      }
    }
  end
  
  def build_decision_tree
    {
      root: {
        question: "What is your primary use case?",
        options: {
          'real_time' => {
            question: "Do you need multilingual support?",
            options: {
              'yes' => { recommendation: 'eleven_turbo_v2_multilingual' },
              'no' => { recommendation: 'eleven_turbo_v2' }
            }
          },
          'high_quality' => {
            question: "Do you need style control?",
            options: {
              'yes' => { recommendation: 'eleven_multilingual_v2' },
              'no' => { recommendation: 'eleven_monolingual_v1' }
            }
          },
          'multilingual' => {
            question: "How many languages do you need?",
            options: {
              'few' => { recommendation: 'eleven_multilingual_v1' },
              'many' => { recommendation: 'eleven_multilingual_v2' }
            }
          }
        }
      }
    }
  end
  
  def analyze_model_performance(models)
    performance_data = {}
    
    models.each do |model|
      performance_data[model['model_id']] = {
        speed_score: calculate_speed_score(model),
        quality_score: calculate_quality_score(model),
        versatility_score: calculate_versatility_score(model),
        cost_efficiency: calculate_model_cost_efficiency(model),
        overall_rating: calculate_overall_rating(model)
      }
    end
    
    performance_data
  end
  
  def calculate_model_benchmarks(models)
    {
      speed_benchmark: models.min_by { |m| m['token_cost_factor'] },
      quality_benchmark: models.select { |m| m['can_use_style'] }.max_by { |m| count_capabilities(m) },
      language_benchmark: models.max_by { |m| m['languages'].length },
      versatility_benchmark: models.max_by { |m| count_capabilities(m) }
    }
  end
  
  def generate_optimization_tips(models)
    tips = []
    
    # Speed optimization
    fastest_model = models.min_by { |m| m['token_cost_factor'] }
    tips << {
      category: 'speed',
      tip: "Use #{fastest_model['name']} for real-time applications",
      impact: 'high',
      description: "#{fastest_model['token_cost_factor']}x cost factor provides fastest generation"
    }
    
    # Quality optimization
    quality_models = models.select { |m| m['can_use_style'] && m['can_use_speaker_boost'] }
    if quality_models.any?
      quality_model = quality_models.first
      tips << {
        category: 'quality',
        tip: "Enable style and speaker boost with #{quality_model['name']}",
        impact: 'high',
        description: 'Significantly improves voice quality and naturalness'
      }
    end
    
    # Cost optimization
    tips << {
      category: 'cost',
      tip: 'Choose models based on use case requirements',
      impact: 'medium',
      description: 'Use faster models for drafts, quality models for final output'
    }
    
    tips
  end
  
  def analyze_performance_trends(models)
    {
      speed_trend: 'Models are getting faster with newer versions',
      quality_trend: 'Quality improvements in multilingual models',
      feature_trend: 'More models supporting style control',
      language_trend: 'Expanding language support across models'
    }
  end
  
  def build_language_support_matrix(models)
    matrix = {}
    
    models.each do |model|
      matrix[model['model_id']] = {
        name: model['name'],
        languages: model['languages'].map { |l| { id: l['language_id'], name: l['name'] } },
        language_count: model['languages'].length,
        multilingual: model['languages'].length > 1
      }
    end
    
    matrix
  end
  
  def analyze_language_quality(models)
    quality_analysis = {}
    
    # Group models by language support
    multilingual_models = models.select { |m| m['languages'].length > 1 }
    monolingual_models = models.select { |m| m['languages'].length == 1 }
    
    quality_analysis[:multilingual] = {
      count: multilingual_models.length,
      avg_languages: (multilingual_models.sum { |m| m['languages'].length } / multilingual_models.length.to_f).round(1),
      quality_features: multilingual_models.count { |m| m['can_use_style'] }
    }
    
    quality_analysis[:monolingual] = {
      count: monolingual_models.length,
      quality_features: monolingual_models.count { |m| m['can_use_style'] },
      specialized: true
    }
    
    quality_analysis
  end
  
  def analyze_multilingual_capabilities(models)
    multilingual_models = models.select { |m| m['languages'].length > 1 }
    
    {
      model_count: multilingual_models.length,
      max_languages: multilingual_models.map { |m| m['languages'].length }.max,
      avg_languages: (multilingual_models.sum { |m| m['languages'].length } / multilingual_models.length.to_f).round(1),
      common_languages: find_common_languages(multilingual_models),
      unique_combinations: analyze_language_combinations(multilingual_models)
    }
  end
  
  def generate_language_recommendations(models)
    recommendations = {}
    
    # Find best model for each major language
    major_languages = %w[en es fr de it pt ja zh ko]
    
    major_languages.each do |lang_id|
      supporting_models = models.select { |m| m['languages'].any? { |l| l['language_id'] == lang_id } }
      
      if supporting_models.any?
        best_model = supporting_models.max_by { |m| calculate_quality_score(m) }
        recommendations[lang_id] = {
          model: best_model,
          reason: "Best quality support for #{lang_id}",
          alternatives: supporting_models.reject { |m| m == best_model }.first(2)
        }
      end
    end
    
    recommendations
  end
  
  def generate_personalized_recommendations(models, requirements)
    scored_models = models.map do |model|
      score = calculate_personalized_score(model, requirements)
      {
        model: model,
        score: score,
        match_reasons: generate_match_reasons(model, requirements)
      }
    end
    
    scored_models.sort_by { |m| -m[:score] }.first(3)
  end
  
  def build_recommendation_explanation(recommendations, requirements)
    explanations = []
    
    recommendations.each_with_index do |rec, index|
      rank = index + 1
      model = rec[:model]
      
      explanation = "Rank #{rank}: #{model['name']} - "
      explanation += rec[:match_reasons].join(', ')
      
      explanations << {
        rank: rank,
        model_name: model['name'],
        explanation: explanation,
        key_benefits: rec[:match_reasons]
      }
    end
    
    explanations
  end
  
  def send_csv_export(models)
    require 'csv'
    
    csv_data = CSV.generate(headers: true) do |csv|
      csv << [
        'Model ID', 'Name', 'Text to Speech', 'Voice Conversion', 'Finetunable',
        'Style Support', 'Speaker Boost', 'Pro Voices', 'Cost Factor',
        'Free User Limit', 'Subscribed User Limit', 'Language Count',
        'Alpha Access Required', 'Description'
      ]
      
      models.each do |model|
        csv << [
          model['model_id'],
          model['name'],
          model['can_do_text_to_speech'],
          model['can_do_voice_conversion'],
          model['can_be_finetuned'],
          model['can_use_style'],
          model['can_use_speaker_boost'],
          model['serves_pro_voices'],
          model['token_cost_factor'],
          model['max_characters_request_free_user'],
          model['max_characters_request_subscribed_user'],
          model['languages'].length,
          model['requires_alpha_access'],
          model['description']
        ]
      end
    end
    
    filename = "models_export_#{Date.current}.csv"
    send_data csv_data, type: 'text/csv', filename: filename, disposition: 'attachment'
  end
  
  def send_json_export(models)
    export_data = {
      exported_at: Time.current.iso8601,
      total_models: models.length,
      models: models,
      analysis: analyze_models(models)
    }
    
    filename = "models_export_#{Date.current}.json"
    send_data export_data.to_json, type: 'application/json', filename: filename, disposition: 'attachment'
  end
  
  # Helper methods for calculations
  
  def calculate_speed_rating(cost_factor)
    case cost_factor
    when 0..0.5 then 'very_fast'
    when 0.5..1.0 then 'fast'
    when 1.0..1.5 then 'moderate'
    else 'slow'
    end
  end
  
  def calculate_quality_rating(model)
    score = 0
    score += 2 if model['can_use_style']
    score += 2 if model['can_use_speaker_boost']
    score += 1 if model['can_be_finetuned']
    score += 1 if model['serves_pro_voices']
    score += (model['token_cost_factor'] * 2).to_i
    
    case score
    when 0..3 then 'basic'
    when 4..6 then 'good'
    when 7..9 then 'high'
    else 'premium'
    end
  end
  
  def count_capabilities(model)
    capabilities = %w[can_do_text_to_speech can_do_voice_conversion can_be_finetuned can_use_style can_use_speaker_boost serves_pro_voices]
    capabilities.count { |cap| model[cap] }
  end
  
  def calculate_efficiency_scores(models)
    models.map do |model|
      capability_count = count_capabilities(model)
      efficiency = capability_count / model['token_cost_factor']
      
      {
        model_id: model['model_id'],
        efficiency_score: efficiency.round(2)
      }
    end.sort_by { |m| -m[:efficiency_score] }
  end
  
  def calculate_cost_efficiency(models)
    models.map do |model|
      features = count_capabilities(model)
      languages = model['languages'].length
      total_value = features + (languages * 0.5)
      efficiency = total_value / model['token_cost_factor']
      
      {
        model_id: model['model_id'],
        value_score: total_value.round(2),
        cost_efficiency: efficiency.round(2)
      }
    end.sort_by { |m| -m[:cost_efficiency] }
  end
  
  def calculate_model_score(model, requirements)
    score = 0
    
    # Use case scoring
    case requirements[:use_case]
    when 'real_time'
      score += (2.0 / model['token_cost_factor']) * 20
    when 'high_quality'
      score += 20 if model['can_use_style']
      score += 15 if model['can_use_speaker_boost']
    when 'multilingual'
      score += model['languages'].length * 5
    when 'voice_cloning'
      score += 25 if model['can_be_finetuned']
    end
    
    # Language scoring
    if requirements[:languages].any?
      supported_languages = model['languages'].map { |l| l['language_id'] }
      matching_languages = requirements[:languages] & supported_languages
      score += matching_languages.length * 10
    end
    
    # Feature scoring
    requirements[:features_needed].each do |feature|
      case feature
      when 'style_control'
        score += 15 if model['can_use_style']
      when 'speaker_boost'
        score += 10 if model['can_use_speaker_boost']
      when 'voice_conversion'
        score += 20 if model['can_do_voice_conversion']
      end
    end
    
    score
  end
  
  def generate_score_reasoning(model, requirements, score)
    reasons = []
    
    if requirements[:use_case] == 'real_time' && model['token_cost_factor'] < 0.5
      reasons << "Excellent for real-time applications (#{model['token_cost_factor']}x cost factor)"
    end
    
    if requirements[:use_case] == 'high_quality' && model['can_use_style']
      reasons << "Supports style control for high-quality output"
    end
    
    if requirements[:languages].any?
      supported = model['languages'].map { |l| l['language_id'] } & requirements[:languages]
      reasons << "Supports #{supported.length} of your required languages" if supported.any?
    end
    
    reasons << "Overall compatibility score: #{score.round(1)}"
    
    reasons
  end
  
  def calculate_speed_score(model)
    # Higher score for faster models (lower cost factor)
    [100 - (model['token_cost_factor'] * 50), 0].max.round(1)
  end
  
  def calculate_quality_score(model)
    score = 50 # Base score
    score += 20 if model['can_use_style']
    score += 15 if model['can_use_speaker_boost']
    score += 10 if model['can_be_finetuned']
    score += 5 if model['serves_pro_voices']
    score
  end
  
  def calculate_versatility_score(model)
    count_capabilities(model) * 15 + model['languages'].length * 5
  end
  
  def calculate_model_cost_efficiency(model)
    total_features = count_capabilities(model) + model['languages'].length
    (total_features / model['token_cost_factor']).round(2)
  end
  
  def calculate_overall_rating(model)
    speed = calculate_speed_score(model)
    quality = calculate_quality_score(model)
    versatility = calculate_versatility_score(model)
    
    # Weighted average
    ((speed * 0.3) + (quality * 0.4) + (versatility * 0.3)).round(1)
  end
  
  def find_common_languages(multilingual_models)
    language_counts = Hash.new(0)
    
    multilingual_models.each do |model|
      model['languages'].each do |lang|
        language_counts[lang['language_id']] += 1
      end
    end
    
    language_counts.sort_by { |_, count| -count }.first(10).to_h
  end
  
  def analyze_language_combinations(multilingual_models)
    combinations = multilingual_models.map do |model|
      {
        model_id: model['model_id'],
        languages: model['languages'].map { |l| l['language_id'] }.sort,
        count: model['languages'].length
      }
    end
    
    combinations.group_by { |c| c[:count] }.transform_values(&:length)
  end
  
  def calculate_personalized_score(model, requirements)
    score = calculate_model_score(model, requirements)
    
    # Apply priority modifiers
    case requirements[:quality_priority]
    when 'speed'
      score += calculate_speed_score(model) * 0.5
    when 'quality'
      score += calculate_quality_score(model) * 0.5
    end
    
    # Budget constraint modifier
    case requirements[:budget_constraint]
    when 'tight'
      score -= (model['token_cost_factor'] - 0.5) * 20 if model['token_cost_factor'] > 0.5
    when 'flexible'
      score += (model['token_cost_factor'] * 10) # Reward higher quality regardless of cost
    end
    
    score
  end
  
  def generate_match_reasons(model, requirements)
    reasons = []
    
    # Use case reasons
    case requirements[:use_case]
    when 'real_time'
      reasons << "Fast generation (#{model['token_cost_factor']}x factor)" if model['token_cost_factor'] < 1.0
    when 'high_quality'
      reasons << "Style control available" if model['can_use_style']
      reasons << "Speaker boost supported" if model['can_use_speaker_boost']
    when 'multilingual'
      reasons << "#{model['languages'].length} languages supported"
    end
    
    # Feature reasons
    requirements[:features_needed].each do |feature|
      case feature
      when 'style_control'
        reasons << "Style control supported" if model['can_use_style']
      when 'speaker_boost'
        reasons << "Speaker boost available" if model['can_use_speaker_boost']
      end
    end
    
    reasons
  end
  
  # Data formatting methods
  
  def models_index_data
    {
      models: @models,
      analysis: @model_analysis,
      categories: @model_categories,
      recommendations: @recommendations
    }
  end
  
  def comparison_data
    {
      comparison_matrix: @comparison_matrix,
      performance_metrics: @performance_metrics,
      cost_analysis: @cost_analysis,
      use_case_recommendations: @use_case_recommendations
    }
  end
  
  def capabilities_data
    {
      capability_matrix: @capability_matrix,
      language_support: @language_support,
      feature_availability: @feature_availability,
      compatibility_guide: @compatibility_guide
    }
  end
  
  def selection_guide_data
    {
      requirements: @requirements,
      recommended_models: @recommended_models,
      selection_criteria: @selection_criteria,
      decision_tree: @decision_tree
    }
  end
  
  def performance_data
    {
      performance_data: @performance_data,
      benchmarks: @benchmarks,
      optimization_tips: @optimization_tips,
      performance_trends: @performance_trends
    }
  end
  
  def languages_data
    {
      language_matrix: @language_matrix,
      language_quality: @language_quality,
      multilingual_capabilities: @multilingual_capabilities,
      language_recommendations: @language_recommendations
    }
  end
  
  def handle_api_error(error, default_message)
    Rails.logger.error "ElevenLabs API Error: #{error.message}"
    flash.now[:error] = "#{default_message}: #{error.message}"
    
    # Set fallback data
    @models = { 'models' => [] }
    @model_analysis = {}
    @model_categories = {}
    @recommendations = []
    
    render :index
  end
end
