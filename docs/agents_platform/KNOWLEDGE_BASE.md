# Knowledge Base Management

The knowledge base endpoints allow you to create, manage, and configure documents that agents can use for retrieval-augmented generation (RAG).

## Usage

```ruby
require 'elevenlabs_client'

client = ElevenlabsClient::Client.new(api_key: "your-api-key")
knowledge_base = client.knowledge_base
```

## Available Methods

### List Knowledge Base Documents

Returns a list of all available knowledge base documents in the workspace.

```ruby
# List all documents
documents = client.knowledge_base.list

# List with filters
documents = client.knowledge_base.list(
  page_size: 20,
  search: "product documentation",
  show_only_owned_documents: true,
  types: ["file", "url"],
  sort_by: "created_at",
  sort_direction: "desc"
)

documents["documents"].each do |doc|
  puts "#{doc['id']}: #{doc['name']} (#{doc['type']})"
  puts "  Size: #{doc['metadata']['size_bytes']} bytes"
  puts "  Created: #{Time.at(doc['metadata']['created_at_unix_secs']).strftime('%Y-%m-%d')}"
  puts "  Supported usages: #{doc['supported_usages'].join(', ')}"
  puts
end
```

### Get Knowledge Base Document

Retrieves detailed information about a specific document.

```ruby
document = client.knowledge_base.get("document_id_here")

puts "Name: #{document['name']}"
puts "Type: #{document['type']}"
puts "Size: #{document['metadata']['size_bytes']} bytes"
puts "URL: #{document['url']}" if document['url']
puts "Content: #{document['extracted_inner_html']}" if document['extracted_inner_html']

# Check dependent agents
if document['dependent_agents']&.any?
  puts "Used by #{document['dependent_agents'].length} agents"
end
```

### Create Knowledge Base Documents

#### From URL

Create a document by scraping a webpage.

```ruby
document = client.knowledge_base.create_from_url(
  "https://docs.yourcompany.com/api-guide",
  name: "API Documentation"
)

puts "Created document: #{document['id']}"
puts "Name: #{document['name']}"
```

#### From Text

Create a document from plain text content.

```ruby
text_content = <<~TEXT
  Our company policy on returns:
  
  1. Items can be returned within 30 days of purchase
  2. Items must be in original condition
  3. Refunds are processed within 5-7 business days
  4. Original receipt or order number required
TEXT

document = client.knowledge_base.create_from_text(
  text_content,
  name: "Return Policy"
)

puts "Created document: #{document['id']}"
```

#### From File

Create a document by uploading a file.

```ruby
File.open("user_manual.pdf", "rb") do |file|
  document = client.knowledge_base.create_from_file(
    file_io: file,
    filename: "user_manual.pdf",
    name: "Product User Manual"
  )
  
  puts "Created document: #{document['id']}"
  puts "Name: #{document['name']}"
end
```

### Update Knowledge Base Document

Update the name of an existing document.

```ruby
updated_document = client.knowledge_base.update(
  "document_id_here",
  name: "Updated Product Documentation"
)

puts "Updated document name: #{updated_document['name']}"
```

### Delete Knowledge Base Document

Delete a document from the knowledge base.

```ruby
# Delete document (will fail if used by agents)
client.knowledge_base.delete("document_id_here")

# Force delete (removes from dependent agents)
client.knowledge_base.delete("document_id_here", force: true)
```

## RAG Index Management

### Compute RAG Index

Create or check status of RAG indexing for a document.

```ruby
# Start RAG indexing
rag_index = client.knowledge_base.compute_rag_index(
  "document_id_here",
  model: "e5_mistral_7b_instruct"
)

puts "RAG Index Status: #{rag_index['status']}"
puts "Progress: #{rag_index['progress_percentage']}%"
puts "Model: #{rag_index['model']}"
puts "Used bytes: #{rag_index['document_model_index_usage']['used_bytes']}"
```

### Get RAG Index Information

Get details about all RAG indexes for a document.

```ruby
indexes = client.knowledge_base.get_rag_index("document_id_here")

indexes["indexes"].each do |index|
  puts "Index ID: #{index['id']}"
  puts "Model: #{index['model']}"
  puts "Status: #{index['status']}"
  puts "Progress: #{index['progress_percentage']}%"
  puts
end
```

### Delete RAG Index

Remove a specific RAG index.

```ruby
deleted_index = client.knowledge_base.delete_rag_index(
  "document_id_here",
  "rag_index_id_here"
)

puts "Deleted RAG index: #{deleted_index['id']}"
```

### Get RAG Index Overview

Get total usage statistics for all RAG indexes.

```ruby
overview = client.knowledge_base.get_rag_index_overview

puts "Total used: #{overview['total_used_bytes']} bytes"
puts "Total max: #{overview['total_max_bytes']} bytes"

overview["models"].each do |model_usage|
  puts "#{model_usage['model']}: #{model_usage['used_bytes']} bytes"
end
```

## Document Content and Analysis

### Get Document Content

Retrieve the full content of a document.

```ruby
content = client.knowledge_base.get_content("document_id_here")
puts "Document content: #{content}"
```

### Get Document Chunk

Retrieve a specific chunk used by RAG.

```ruby
chunk = client.knowledge_base.get_chunk("document_id_here", "chunk_id_here")

puts "Chunk ID: #{chunk['id']}"
puts "Chunk name: #{chunk['name']}"
puts "Content: #{chunk['content']}"
```

## Agent Dependencies

### Get Dependent Agents

List all agents that use a specific document.

```ruby
dependent_agents = client.knowledge_base.get_dependent_agents("document_id_here")

puts "Agents using this document:"
dependent_agents["agents"].each do |agent|
  puts "  • #{agent['id']}: #{agent['name']}"
  puts "    Type: #{agent['type']}"
end

if dependent_agents["has_more"]
  puts "More agents available. Use cursor: #{dependent_agents['next_cursor']}"
end
```

### Get Agent Knowledge Base Size

Get the total size of an agent's knowledge base.

```ruby
size_info = client.knowledge_base.get_agent_knowledge_base_size("agent_id_here")
puts "Knowledge base size: #{size_info['number_of_pages']} pages"
```

## Examples

### Complete Document Workflow

```ruby
# 1. Create document from URL
doc = client.knowledge_base.create_from_url(
  "https://docs.yourapi.com/getting-started",
  name: "API Getting Started Guide"
)

document_id = doc["id"]

# 2. Create RAG index
rag_index = client.knowledge_base.compute_rag_index(
  document_id,
  model: "e5_mistral_7b_instruct"
)

# 3. Wait for indexing to complete (in practice, you'd poll this)
loop do
  status = client.knowledge_base.get_rag_index(document_id)
  current_status = status["indexes"].first["status"]
  
  break if current_status == "completed"
  
  puts "Indexing in progress: #{status['indexes'].first['progress_percentage']}%"
  sleep(5)
end

# 4. Check which agents use this document
dependent_agents = client.knowledge_base.get_dependent_agents(document_id)
puts "Document is used by #{dependent_agents['agents'].length} agents"

# 5. Get document content for review
content = client.knowledge_base.get_content(document_id)
puts "Document content preview: #{content[0..200]}..."
```

### Batch Document Creation

```ruby
# Create multiple documents from different sources
documents = []

# From URLs
urls = [
  { url: "https://docs.company.com/faq", name: "FAQ" },
  { url: "https://docs.company.com/troubleshooting", name: "Troubleshooting" },
  { url: "https://docs.company.com/api", name: "API Reference" }
]

urls.each do |url_info|
  doc = client.knowledge_base.create_from_url(
    url_info[:url],
    name: url_info[:name]
  )
  documents << doc
  puts "Created: #{doc['name']} (#{doc['id']})"
end

# From text content
policies = {
  "Return Policy" => "Items can be returned within 30 days...",
  "Shipping Policy" => "We offer free shipping on orders over $50...",
  "Privacy Policy" => "We respect your privacy and protect your data..."
}

policies.each do |name, content|
  doc = client.knowledge_base.create_from_text(content, name: name)
  documents << doc
  puts "Created: #{doc['name']} (#{doc['id']})"
end

# Create RAG indexes for all documents
documents.each do |doc|
  rag_index = client.knowledge_base.compute_rag_index(
    doc["id"],
    model: "e5_mistral_7b_instruct"
  )
  puts "Started RAG indexing for: #{doc['name']}"
end
```

### Knowledge Base Analytics

```ruby
# Get comprehensive overview
puts "📚 Knowledge Base Analytics"
puts "=" * 40

# List all documents
all_docs = client.knowledge_base.list(page_size: 100)
documents = all_docs["documents"]

puts "\n📊 Document Statistics:"
puts "Total documents: #{documents.length}"

# Analyze by type
by_type = documents.group_by { |doc| doc["type"] }
by_type.each do |type, docs|
  total_size = docs.sum { |doc| doc["metadata"]["size_bytes"] || 0 }
  puts "  #{type}: #{docs.length} documents (#{total_size} bytes)"
end

# Find largest documents
largest_docs = documents.sort_by { |doc| -(doc["metadata"]["size_bytes"] || 0) }
puts "\n📈 Largest Documents:"
largest_docs.first(5).each_with_index do |doc, index|
  size_mb = (doc["metadata"]["size_bytes"] || 0) / 1024.0 / 1024.0
  puts "#{index + 1}. #{doc['name']}: #{size_mb.round(2)} MB"
end

# RAG index overview
rag_overview = client.knowledge_base.get_rag_index_overview
puts "\n🤖 RAG Index Overview:"
puts "Total used: #{rag_overview['total_used_bytes']} bytes"
puts "Total available: #{rag_overview['total_max_bytes']} bytes"
usage_percent = (rag_overview['total_used_bytes'].to_f / rag_overview['total_max_bytes'] * 100).round(1)
puts "Usage: #{usage_percent}%"
```

### Document Content Analysis

```ruby
# Analyze document content and chunks
document_id = "your_document_id"

# Get full content
content = client.knowledge_base.get_content(document_id)
word_count = content.split.length
puts "Document word count: #{word_count}"

# Get RAG indexes
indexes = client.knowledge_base.get_rag_index(document_id)
indexes["indexes"].each do |index|
  if index["status"] == "completed"
    puts "\nRAG Index: #{index['model']}"
    puts "Progress: #{index['progress_percentage']}%"
    
    # Note: In a real implementation, you would need chunk IDs
    # This is just an example of how you might iterate through chunks
    puts "Chunks available for analysis"
  end
end

# Check usage by agents
dependent_agents = client.knowledge_base.get_dependent_agents(document_id)
puts "\nDocument Usage:"
puts "Used by #{dependent_agents['agents'].length} agents"
dependent_agents['agents'].each do |agent|
  puts "  • #{agent['name']} (#{agent['id']})"
end
```

## Error Handling

```ruby
begin
  document = client.knowledge_base.create_from_url("invalid-url")
rescue ElevenlabsClient::ValidationError => e
  puts "Invalid URL or parameters: #{e.message}"
rescue ElevenlabsClient::NotFoundError => e
  puts "Document not found: #{e.message}"
rescue ElevenlabsClient::APIError => e
  puts "API error: #{e.message}"
end
```

## Best Practices

### Document Management

1. **Meaningful Names**: Use descriptive names for easy identification
2. **Regular Updates**: Keep documents current with your latest information
3. **Size Management**: Monitor document sizes and RAG index usage
4. **Organization**: Use consistent naming conventions and tags

### RAG Optimization

1. **Model Selection**: Choose appropriate embedding models for your content
2. **Content Quality**: Ensure documents are well-structured and relevant
3. **Index Monitoring**: Regularly check RAG index status and performance
4. **Usage Analysis**: Monitor which documents are most valuable to agents

## API Reference

For detailed API documentation, visit: [ElevenLabs Knowledge Base API Reference](https://elevenlabs.io/docs/api-reference/convai/knowledge-base)
