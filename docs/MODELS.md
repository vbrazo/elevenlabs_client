# Models API

Retrieve information about available ElevenLabs models, including their capabilities, supported languages, and usage limits.

## Available Methods

- `client.models.list()` - List all available models
- `client.models.list_models()` - Alias for list method

## Usage Examples

### Basic Model Listing

```ruby
# Get all available models
models = client.models.list

models["models"].each do |model|
  puts "#{model['name']} (#{model['model_id']})"
  puts "  Description: #{model['description']}"
  puts "  Languages: #{model['languages'].map { |l| l['name'] }.join(', ')}"
  puts "  Can use style: #{model['can_use_style']}"
  puts "  Token cost factor: #{model['token_cost_factor']}"
  puts
end
```

### Model Selection for Text-to-Speech

```ruby
# Find the best model for your use case
models = client.models.list

# Find fastest model (lowest token cost)
fastest_model = models["models"].min_by { |m| m["token_cost_factor"] }
puts "Fastest model: #{fastest_model['name']} (#{fastest_model['token_cost_factor']}x cost)"

# Find models that support style
style_models = models["models"].select { |m| m["can_use_style"] }
puts "Models with style support:"
style_models.each { |m| puts "  - #{m['name']}" }

# Find multilingual models
multilingual_models = models["models"].select { |m| m["languages"].length > 1 }
puts "Multilingual models:"
multilingual_models.each do |model|
  languages = model["languages"].map { |l| l["name"] }.join(", ")
  puts "  - #{model['name']}: #{languages}"
end
```

### Language-Specific Model Selection

```ruby
# Find models that support Spanish
spanish_models = models["models"].select do |model|
  model["languages"].any? { |lang| lang["language_id"] == "es" }
end

puts "Models supporting Spanish:"
spanish_models.each { |m| puts "  - #{m['name']}" }

# Find models for specific language combinations
def supports_languages?(model, language_codes)
  supported_codes = model["languages"].map { |l| l["language_id"] }
  language_codes.all? { |code| supported_codes.include?(code) }
end

# Find models that support both English and French
en_fr_models = models["models"].select { |m| supports_languages?(m, ["en", "fr"]) }
puts "Models supporting English and French:"
en_fr_models.each { |m| puts "  - #{m['name']}" }
```

### Model Capabilities Analysis

```ruby
models = client.models.list

puts "Model Capabilities Summary:"
puts "=" * 50

models["models"].each do |model|
  puts "#{model['name']}:"
  puts "  Text-to-Speech: #{model['can_do_text_to_speech'] ? '✓' : '✗'}"
  puts "  Voice Conversion: #{model['can_do_voice_conversion'] ? '✓' : '✗'}"
  puts "  Fine-tuning: #{model['can_be_finetuned'] ? '✓' : '✗'}"
  puts "  Style Control: #{model['can_use_style'] ? '✓' : '✗'}"
  puts "  Speaker Boost: #{model['can_use_speaker_boost'] ? '✓' : '✗'}"
  puts "  Pro Voices: #{model['serves_pro_voices'] ? '✓' : '✗'}"
  puts "  Alpha Access: #{model['requires_alpha_access'] ? 'Required' : 'Not required'}"
  puts
end
```

### Usage Limits Information

```ruby
models = client.models.list

puts "Usage Limits by Model:"
puts "=" * 50

models["models"].each do |model|
  puts "#{model['name']}:"
  puts "  Free user limit: #{model['max_characters_request_free_user']} chars/request"
  puts "  Subscribed user limit: #{model['max_characters_request_subscribed_user']} chars/request"
  puts "  Maximum text length: #{model['maximum_text_length_per_request']} chars"
  puts "  Token cost factor: #{model['token_cost_factor']}x"
  puts
end
```

## Model Information Structure

Each model in the response contains the following information:

### Basic Information
- `model_id` (String) - Unique identifier for the model
- `name` (String) - Human-readable name
- `description` (String) - Detailed description of the model

### Capabilities
- `can_be_finetuned` (Boolean) - Whether the model supports fine-tuning
- `can_do_text_to_speech` (Boolean) - Whether the model supports TTS
- `can_do_voice_conversion` (Boolean) - Whether the model supports voice conversion
- `can_use_style` (Boolean) - Whether the model supports style parameters
- `can_use_speaker_boost` (Boolean) - Whether the model supports speaker boost
- `serves_pro_voices` (Boolean) - Whether the model works with professional voices

### Usage Information
- `token_cost_factor` (Float) - Cost multiplier for API usage
- `requires_alpha_access` (Boolean) - Whether alpha access is required
- `max_characters_request_free_user` (Integer) - Character limit for free users
- `max_characters_request_subscribed_user` (Integer) - Character limit for subscribers
- `maximum_text_length_per_request` (Integer) - Maximum text length per request

### Language Support
- `languages` (Array) - List of supported languages
  - `language_id` (String) - Language code (e.g., "en", "es", "fr")
  - `name` (String) - Language name (e.g., "English", "Spanish", "French")

## Common Models

### Eleven Monolingual v1
- **Best for**: English-only applications requiring high quality
- **Features**: Fine-tuning support, speaker boost
- **Languages**: English only
- **Use cases**: English podcasts, audiobooks, professional narration

### Eleven Multilingual v1
- **Best for**: Multi-language applications
- **Features**: Multiple language support, fine-tuning
- **Languages**: English, Spanish, French, German, Italian, Portuguese, and more
- **Use cases**: International content, language learning, global applications

### Eleven Multilingual v2
- **Best for**: Latest multilingual applications with style control
- **Features**: Style parameters, improved quality, multiple languages
- **Languages**: Enhanced language support with better quality
- **Use cases**: Advanced voice synthesis, character voices, styled speech

### Eleven Turbo v2
- **Best for**: Real-time applications requiring speed
- **Features**: Fastest generation, optimized for streaming
- **Languages**: English
- **Use cases**: Live applications, chatbots, real-time voice responses
- **Cost**: 0.3x token cost factor (70% cheaper)

## Rails Integration

```ruby
class ModelsController < ApplicationController
  def index
    client = ElevenlabsClient.new
    models = client.models.list
    
    render json: {
      models: models["models"].map do |model|
        {
          id: model["model_id"],
          name: model["name"],
          description: model["description"],
          capabilities: {
            text_to_speech: model["can_do_text_to_speech"],
            voice_conversion: model["can_do_voice_conversion"],
            fine_tuning: model["can_be_finetuned"],
            style_control: model["can_use_style"],
            speaker_boost: model["can_use_speaker_boost"]
          },
          languages: model["languages"],
          limits: {
            free_user: model["max_characters_request_free_user"],
            subscribed_user: model["max_characters_request_subscribed_user"],
            max_text_length: model["maximum_text_length_per_request"]
          },
          cost_factor: model["token_cost_factor"],
          requires_alpha: model["requires_alpha_access"]
        }
      end
    }
    
  rescue ElevenlabsClient::APIError => e
    render json: { error: e.message }, status: :service_unavailable
  end
  
  def best_for_language
    client = ElevenlabsClient.new
    language_code = params[:language_code]
    
    models = client.models.list
    
    # Find models that support the requested language
    compatible_models = models["models"].select do |model|
      model["languages"].any? { |lang| lang["language_id"] == language_code }
    end
    
    if compatible_models.empty?
      render json: { error: "No models found for language: #{language_code}" }, status: :not_found
      return
    end
    
    # Sort by quality (higher token cost usually means better quality)
    best_models = compatible_models.sort_by { |m| -m["token_cost_factor"] }
    
    render json: {
      language_code: language_code,
      recommended_models: best_models.map do |model|
        {
          id: model["model_id"],
          name: model["name"],
          description: model["description"],
          cost_factor: model["token_cost_factor"],
          features: {
            style_control: model["can_use_style"],
            fine_tuning: model["can_be_finetuned"]
          }
        }
      end
    }
  end
  
  def fastest
    client = ElevenlabsClient.new
    models = client.models.list
    
    # Find the fastest model (lowest token cost factor)
    fastest = models["models"].min_by { |m| m["token_cost_factor"] }
    
    render json: {
      model: {
        id: fastest["model_id"],
        name: fastest["name"],
        description: fastest["description"],
        cost_factor: fastest["token_cost_factor"],
        languages: fastest["languages"]
      },
      message: "This is the fastest available model"
    }
  end
end
```

## Model Selection Guide

### For Real-time Applications
```ruby
# Choose fastest model
models = client.models.list
fastest = models["models"].min_by { |m| m["token_cost_factor"] }
model_id = fastest["model_id"]  # Use this for TTS calls
```

### For High-Quality Content
```ruby
# Choose highest quality model
models = client.models.list
highest_quality = models["models"].max_by { |m| m["token_cost_factor"] }
model_id = highest_quality["model_id"]
```

### For Multilingual Applications
```ruby
# Find best multilingual model
models = client.models.list
multilingual = models["models"]
  .select { |m| m["languages"].length > 3 }  # At least 4 languages
  .max_by { |m| m["token_cost_factor"] }     # Best quality
model_id = multilingual["model_id"]
```

### For Style Control
```ruby
# Find models with style support
models = client.models.list
style_models = models["models"].select { |m| m["can_use_style"] }
model_id = style_models.first["model_id"]  # Use first available
```

## Error Handling

```ruby
begin
  models = client.models.list
rescue ElevenlabsClient::AuthenticationError
  puts "Invalid API key"
rescue ElevenlabsClient::RateLimitError
  puts "Rate limit exceeded"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Caching Recommendations

Since model information doesn't change frequently, consider caching the results:

```ruby
class ModelCache
  def self.get_models
    @models ||= fetch_models
  end
  
  def self.refresh!
    @models = nil
    get_models
  end
  
  private
  
  def self.fetch_models
    client = ElevenlabsClient.new
    client.models.list
  end
end

# Usage
models = ModelCache.get_models
```

## Use Cases

- **Model Selection UI** - Show users available models with capabilities
- **Dynamic Model Selection** - Choose optimal model based on requirements
- **Cost Optimization** - Select models based on cost factors
- **Language Support** - Filter models by language requirements
- **Feature Requirements** - Find models with specific capabilities
- **Usage Planning** - Understand character limits and restrictions

## Best Practices

1. **Cache Results** - Model information changes infrequently
2. **Filter by Requirements** - Select models based on your specific needs
3. **Consider Cost** - Balance quality vs. cost based on use case
4. **Language Planning** - Verify language support before implementation
5. **Feature Checking** - Confirm required features are supported
6. **Limit Awareness** - Respect character limits for different user types

The Models API provides essential information for making informed decisions about which ElevenLabs models to use for your specific applications and requirements.
