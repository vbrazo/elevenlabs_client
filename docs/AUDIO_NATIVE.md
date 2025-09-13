# Audio Native

The Audio Native endpoint allows you to create, manage, and configure Audio Native projects that convert text content into embeddable audio players for websites and applications.

## Usage

### Creating an Audio Native Project

```ruby
require 'elevenlabs_client'

# Initialize the client
client = ElevenlabsClient.new(api_key: "your_api_key")

# Create a basic project
project = client.audio_native.create("My Blog Post")

puts "Project ID: #{project['project_id']}"
puts "HTML Snippet: #{project['html_snippet']}"
```

### Creating a Project with Options

```ruby
# Create a project with full configuration
project = client.audio_native.create(
  "My Article",
  author: "Jane Doe",
  title: "How to Use Audio Native",
  voice_id: "21m00Tcm4TlvDq8ikWAM",
  model_id: "eleven_multilingual_v1",
  text_color: "#333333",
  background_color: "#ffffff",
  auto_convert: true,
  apply_text_normalization: "auto"
)
```

### Creating a Project with Content File

```ruby
# Create project with HTML content
html_content = File.open("article.html", "rb")

project = client.audio_native.create(
  "My Article Project",
  file: html_content,
  filename: "article.html",
  author: "John Doe",
  title: "My Article",
  voice_id: "21m00Tcm4TlvDq8ikWAM",
  auto_convert: true
)

html_content.close
```

### Updating Project Content

```ruby
# Update project content
updated_content = File.open("updated_article.txt", "rb")

result = client.audio_native.update_content(
  project['project_id'],
  file: updated_content,
  filename: "updated_article.txt",
  auto_convert: true,
  auto_publish: false
)

updated_content.close

puts "Converting: #{result['converting']}"
puts "Publishing: #{result['publishing']}"
```

### Getting Project Settings

```ruby
# Retrieve project settings
settings = client.audio_native.get_settings(project['project_id'])

puts "Enabled: #{settings['enabled']}"
puts "Status: #{settings['settings']['status']}"
puts "Audio URL: #{settings['settings']['audio_url']}"
```

## Methods

### `create(name, **options)`

Creates a new Audio Native project.

**Parameters:**
- **name** (String, required): Project name
- **options** (Hash, optional):
  - **image** (String): Image URL for the player (deprecated)
  - **author** (String): Author name displayed in the player
  - **title** (String): Title displayed in the player
  - **small** (Boolean): Use small player layout (deprecated, default: false)
  - **text_color** (String): Text color in hex format (e.g., "#000000")
  - **background_color** (String): Background color in hex format (e.g., "#FFFFFF")
  - **sessionization** (Integer): Session persistence in minutes (deprecated, default: 0)
  - **voice_id** (String): Voice ID for text-to-speech conversion
  - **model_id** (String): TTS model ID to use
  - **file** (IO, File): Text or HTML content file
  - **filename** (String): Original filename (required if file provided)
  - **auto_convert** (Boolean): Automatically convert to audio (default: false)
  - **apply_text_normalization** (String): Text normalization mode
    - `"auto"`: Automatically decide
    - `"on"`: Always apply normalization
    - `"off"`: Skip normalization
    - `"apply_english"`: Apply English normalization

**Returns:** Hash with `project_id`, `converting` status, and `html_snippet`

### `update_content(project_id, **options)`

Updates content for an existing project.

**Parameters:**
- **project_id** (String, required): The project ID
- **options** (Hash, optional):
  - **file** (IO, File): Updated content file
  - **filename** (String): Original filename (required if file provided)
  - **auto_convert** (Boolean): Automatically convert to audio (default: false)
  - **auto_publish** (Boolean): Automatically publish after conversion (default: false)

**Returns:** Hash with `project_id`, `converting`, `publishing` status, and `html_snippet`

### `get_settings(project_id)`

Retrieves project settings and status.

**Parameters:**
- **project_id** (String, required): The project ID

**Returns:** Hash with `enabled` status, `snapshot_id`, and detailed `settings`

## Alias Methods

For convenience, the following alias methods are available:

```ruby
# Aliases for create
client.audio_native.create_project(name, **options)

# Aliases for update_content
client.audio_native.update_project_content(project_id, **options)

# Aliases for get_settings
client.audio_native.project_settings(project_id)
```

## Content File Formats

### HTML Format
```html
<html>
  <body>
    <div>
      <h1>Article Title</h1>
      <p>Your content here</p>
      <h3>Section Header</h3>
      <p>More content</p>
    </div>
  </body>
</html>
```

### Text Format
```
Article Title

Your content here.

Section Header

More content here.
```

## Complete Workflow Example

```ruby
# Step 1: Create project with content
html_file = File.open("blog_post.html", "rb")

project = client.audio_native.create(
  "My Blog Post",
  file: html_file,
  filename: "blog_post.html",
  author: "Jane Smith",
  title: "Understanding AI",
  voice_id: "21m00Tcm4TlvDq8ikWAM",
  model_id: "eleven_multilingual_v1",
  text_color: "#2c3e50",
  background_color: "#ecf0f1",
  auto_convert: false,
  apply_text_normalization: "auto"
)

html_file.close
project_id = project['project_id']

# Step 2: Update content and trigger conversion
updated_file = File.open("updated_post.html", "rb")

updated_project = client.audio_native.update_content(
  project_id,
  file: updated_file,
  filename: "updated_post.html",
  auto_convert: true,
  auto_publish: false
)

updated_file.close

# Step 3: Monitor conversion status
settings = client.audio_native.get_settings(project_id)

while settings['settings']['status'] == 'converting'
  sleep(5)
  settings = client.audio_native.get_settings(project_id)
  puts "Status: #{settings['settings']['status']}"
end

# Step 4: Get the embeddable HTML snippet
if settings['settings']['status'] == 'ready'
  puts "Audio ready!"
  puts "Embed this HTML: #{project['html_snippet']}"
  puts "Audio URL: #{settings['settings']['audio_url']}"
end
```

## Error Handling

```ruby
begin
  project = client.audio_native.create("My Project")
rescue ElevenlabsClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ElevenlabsClient::UnprocessableEntityError => e
  puts "Invalid project data: #{e.message}"
rescue ElevenlabsClient::NotFoundError => e
  puts "Project not found: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Player Customization

### Colors
```ruby
project = client.audio_native.create(
  "Styled Project",
  text_color: "#2c3e50",      # Dark blue-gray text
  background_color: "#ecf0f1"  # Light gray background
)
```

### Voice and Model Selection
```ruby
project = client.audio_native.create(
  "Custom Voice Project",
  voice_id: "pNInz6obpgDQGcFmaJgB",     # Different voice
  model_id: "eleven_multilingual_v1"     # Multilingual model
)
```

## Text Normalization Options

- **auto**: System automatically decides whether to normalize text (recommended)
- **on**: Always apply text normalization (numbers become words, etc.)
- **off**: Skip text normalization entirely
- **apply_english**: Apply normalization assuming English text

```ruby
project = client.audio_native.create(
  "Technical Article",
  apply_text_normalization: "on"  # "API 2.0" becomes "API two point zero"
)
```

## Best Practices

1. **Content Preparation**:
   - Use well-structured HTML with proper headings
   - Keep paragraphs reasonably sized
   - Include clear section breaks

2. **Voice Selection**:
   - Choose voices appropriate for your content type
   - Test different voices for your audience

3. **Auto-conversion**:
   - Set `auto_convert: false` for draft content
   - Use `auto_convert: true` when content is final

4. **Publishing Workflow**:
   - Use `auto_publish: false` to review before going live
   - Monitor conversion status before publishing

5. **Error Handling**:
   - Always check project status before assuming success
   - Implement retry logic for network errors

## Response Formats

### Create Response
```json
{
  "project_id": "JBFqnCBsd6RMkjVDRZzb",
  "converting": false,
  "html_snippet": "<div id='audio-native-player'></div>"
}
```

### Update Response
```json
{
  "project_id": "JBFqnCBsd6RMkjVDRZzb",
  "converting": true,
  "publishing": false,
  "html_snippet": "<div id='audio-native-player'></div>"
}
```

### Settings Response
```json
{
  "enabled": true,
  "snapshot_id": "snapshot123",
  "settings": {
    "title": "My Project",
    "author": "John Doe",
    "status": "ready",
    "audio_url": "https://example.com/audio.mp3"
  }
}
```
