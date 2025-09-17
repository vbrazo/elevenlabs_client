# frozen_string_literal: true

# Example usage of ElevenLabs Agents Platform Knowledge Base endpoints
# This file demonstrates how to use the knowledge base endpoints in a practical application

require 'elevenlabs_client'
require 'tempfile'
require 'net/http'

class KnowledgeBaseController
  def initialize(api_key = nil)
    @client = ElevenlabsClient::Client.new(api_key: api_key)
  end

  # List knowledge base documents with various filtering options
  def list_documents(search: nil, types: nil, owned_only: false, limit: 20)
    puts "Fetching knowledge base documents..."
    
    options = { page_size: limit }
    options[:search] = search if search
    options[:types] = types if types
    options[:show_only_owned_documents] = owned_only
    options[:sort_by] = "created_at"
    options[:sort_direction] = "desc"
    
    response = @client.knowledge_base.list(**options)
    documents = response["documents"]
    
    puts "\n📚 Found #{documents.length} documents:"
    documents.each do |doc|
      metadata = doc['metadata']
      access_info = doc['access_info']
      
      puts "  • #{doc['id']}"
      puts "    Name: #{doc['name']}"
      puts "    Type: #{doc['type']}"
      puts "    Size: #{format_bytes(metadata['size_bytes'])}"
      puts "    Created: #{Time.at(metadata['created_at_unix_secs']).strftime('%Y-%m-%d %H:%M:%S')}"
      puts "    Updated: #{Time.at(metadata['last_updated_at_unix_secs']).strftime('%Y-%m-%d %H:%M:%S')}"
      puts "    Creator: #{access_info['creator_name']} (#{access_info['creator_email']})"
      puts "    Supported usages: #{doc['supported_usages'].join(', ')}"
      
      if doc['url']
        puts "    URL: #{doc['url']}"
      end
      
      if doc['dependent_agents']&.any?
        puts "    Used by: #{doc['dependent_agents'].length} agents"
      end
      
      puts
    end
    
    if response["has_more"]
      puts "💡 More documents available. Use cursor: #{response['next_cursor']}"
    end
    
    documents
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching documents: #{e.message}"
    []
  end

  # Get detailed information about a specific document
  def get_document_details(document_id, agent_id: nil)
    puts "Fetching details for document: #{document_id}"
    
    document = @client.knowledge_base.get(document_id, agent_id: agent_id)
    metadata = document['metadata']
    access_info = document['access_info']
    
    puts "\n📄 Document Details:"
    puts "ID: #{document['id']}"
    puts "Name: #{document['name']}"
    puts "Type: #{document['type']}"
    puts "Size: #{format_bytes(metadata['size_bytes'])}"
    
    puts "\n📅 Timestamps:"
    puts "  Created: #{Time.at(metadata['created_at_unix_secs']).strftime('%Y-%m-%d %H:%M:%S')}"
    puts "  Updated: #{Time.at(metadata['last_updated_at_unix_secs']).strftime('%Y-%m-%d %H:%M:%S')}"
    
    puts "\n👤 Access Information:"
    puts "  Creator: #{access_info['creator_name']} (#{access_info['creator_email']})"
    puts "  Role: #{access_info['role']}"
    puts "  Is Creator: #{access_info['is_creator']}"
    
    puts "\n⚙️ Configuration:"
    puts "  Supported usages: #{document['supported_usages'].join(', ')}"
    
    if document['url']
      puts "  Source URL: #{document['url']}"
    end
    
    if document['extracted_inner_html']
      content_preview = document['extracted_inner_html'][0..200]
      puts "  Content preview: #{content_preview}#{'...' if document['extracted_inner_html'].length > 200}"
    end
    
    document
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Document not found: #{document_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching document: #{e.message}"
    nil
  end

  # Create a document from a URL
  def create_document_from_url(url, name: nil)
    puts "Creating document from URL: #{url}"
    
    response = @client.knowledge_base.create_from_url(url, name: name)
    
    puts "✅ Document created from URL!"
    puts "Document ID: #{response['id']}"
    puts "Name: #{response['name']}"
    
    response
  rescue ElevenlabsClient::ValidationError => e
    puts "❌ Validation error: #{e.message}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ API error: #{e.message}"
    nil
  end

  # Create a document from text content
  def create_document_from_text(text, name: nil)
    puts "Creating document from text content..."
    
    response = @client.knowledge_base.create_from_text(text, name: name)
    
    puts "✅ Document created from text!"
    puts "Document ID: #{response['id']}"
    puts "Name: #{response['name']}"
    puts "Content length: #{text.length} characters"
    
    response
  rescue ElevenlabsClient::ValidationError => e
    puts "❌ Validation error: #{e.message}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ API error: #{e.message}"
    nil
  end

  # Create a document from a file
  def create_document_from_file(file_path, name: nil)
    puts "Creating document from file: #{file_path}"
    
    unless File.exist?(file_path)
      puts "❌ File not found: #{file_path}"
      return nil
    end
    
    File.open(file_path, "rb") do |file|
      filename = File.basename(file_path)
      response = @client.knowledge_base.create_from_file(
        file_io: file,
        filename: filename,
        name: name
      )
      
      puts "✅ Document created from file!"
      puts "Document ID: #{response['id']}"
      puts "Name: #{response['name']}"
      puts "File size: #{format_bytes(File.size(file_path))}"
      
      response
    end
  rescue ElevenlabsClient::ValidationError => e
    puts "❌ Validation error: #{e.message}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ API error: #{e.message}"
    nil
  end

  # Update a document's name
  def update_document(document_id, new_name)
    puts "Updating document: #{document_id}"
    
    response = @client.knowledge_base.update(document_id, name: new_name)
    
    puts "✅ Document updated successfully!"
    puts "New name: #{response['name']}"
    
    response
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Document not found: #{document_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error updating document: #{e.message}"
    nil
  end

  # Delete a document
  def delete_document(document_id, force: false)
    puts "Deleting document: #{document_id}"
    
    # Check for dependent agents first unless force is true
    unless force
      dependent_agents = get_dependent_agents(document_id)
      
      if dependent_agents && dependent_agents["agents"].any?
        puts "⚠️ Warning: This document is used by #{dependent_agents['agents'].length} agent(s):"
        dependent_agents["agents"].each do |agent|
          puts "  • #{agent['id']}: #{agent['name']}"
        end
        
        print "Delete anyway and remove from agents? (y/N): "
        confirmation = gets.chomp.downcase
        
        force = (confirmation == 'y' || confirmation == 'yes')
        return unless force
      end
    end
    
    @client.knowledge_base.delete(document_id, force: force)
    puts "✅ Document deleted successfully"
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Document not found: #{document_id}"
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error deleting document: #{e.message}"
  end

  # Create or check RAG index for a document
  def compute_rag_index(document_id, model: "e5_mistral_7b_instruct")
    puts "Computing RAG index for document: #{document_id}"
    puts "Model: #{model}"
    
    response = @client.knowledge_base.compute_rag_index(document_id, model: model)
    
    puts "🤖 RAG Index Information:"
    puts "  Index ID: #{response['id']}"
    puts "  Model: #{response['model']}"
    puts "  Status: #{response['status']}"
    puts "  Progress: #{response['progress_percentage']}%"
    
    if response['document_model_index_usage']
      usage = response['document_model_index_usage']
      puts "  Used bytes: #{format_bytes(usage['used_bytes'])}"
    end
    
    response
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Document not found: #{document_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error computing RAG index: #{e.message}"
    nil
  end

  # Get RAG index status for a document
  def get_rag_index_status(document_id)
    puts "Fetching RAG index status for document: #{document_id}"
    
    response = @client.knowledge_base.get_rag_index(document_id)
    indexes = response["indexes"]
    
    if indexes.any?
      puts "\n🤖 RAG Indexes:"
      indexes.each_with_index do |index, i|
        puts "#{i + 1}. Index ID: #{index['id']}"
        puts "   Model: #{index['model']}"
        puts "   Status: #{index['status']}"
        puts "   Progress: #{index['progress_percentage']}%"
        
        if index['document_model_index_usage']
          puts "   Used bytes: #{format_bytes(index['document_model_index_usage']['used_bytes'])}"
        end
        puts
      end
    else
      puts "📭 No RAG indexes found for this document"
    end
    
    response
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Document not found: #{document_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error getting RAG index status: #{e.message}"
    nil
  end

  # Delete a specific RAG index
  def delete_rag_index(document_id, rag_index_id)
    puts "Deleting RAG index: #{rag_index_id} for document: #{document_id}"
    
    response = @client.knowledge_base.delete_rag_index(document_id, rag_index_id)
    
    puts "✅ RAG index deleted successfully!"
    puts "Index ID: #{response['id']}"
    puts "Model: #{response['model']}"
    
    response
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Document or RAG index not found"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error deleting RAG index: #{e.message}"
    nil
  end

  # Get RAG index overview for the entire workspace
  def get_rag_overview
    puts "Fetching RAG index overview..."
    
    overview = @client.knowledge_base.get_rag_index_overview
    
    puts "\n🤖 RAG Index Overview:"
    puts "Total used: #{format_bytes(overview['total_used_bytes'])}"
    puts "Total available: #{format_bytes(overview['total_max_bytes'])}"
    
    usage_percent = (overview['total_used_bytes'].to_f / overview['total_max_bytes'] * 100).round(1)
    puts "Usage: #{usage_percent}%"
    
    if overview['models']&.any?
      puts "\nBy model:"
      overview['models'].each do |model_usage|
        puts "  #{model_usage['model']}: #{format_bytes(model_usage['used_bytes'])}"
      end
    end
    
    overview
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error getting RAG overview: #{e.message}"
    nil
  end

  # Get agents that depend on a document
  def get_dependent_agents(document_id, page_size: 20)
    puts "Fetching dependent agents for document: #{document_id}"
    
    response = @client.knowledge_base.get_dependent_agents(document_id, page_size: page_size)
    agents = response["agents"]
    
    if agents.any?
      puts "\n🤖 Found #{agents.length} dependent agents:"
      agents.each do |agent|
        puts "  • #{agent['id']}"
        puts "    Name: #{agent['name']}" if agent['name']
        puts "    Type: #{agent['type']}"
        puts
      end
      
      if response["has_more"]
        puts "💡 More agents available. Use cursor: #{response['next_cursor']}"
      end
    else
      puts "✅ No agents depend on this document"
    end
    
    response
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Document not found: #{document_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching dependent agents: #{e.message}"
    nil
  end

  # Get document content
  def get_document_content(document_id)
    puts "Fetching content for document: #{document_id}"
    
    content = @client.knowledge_base.get_content(document_id)
    
    puts "📄 Document Content:"
    puts "Length: #{content.length} characters"
    puts "Preview: #{content[0..300]}#{'...' if content.length > 300}"
    
    content
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Document not found: #{document_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching document content: #{e.message}"
    nil
  end

  # Get a specific document chunk
  def get_document_chunk(document_id, chunk_id)
    puts "Fetching chunk: #{chunk_id} from document: #{document_id}"
    
    chunk = @client.knowledge_base.get_chunk(document_id, chunk_id)
    
    puts "📄 Chunk Details:"
    puts "ID: #{chunk['id']}"
    puts "Name: #{chunk['name']}"
    puts "Content length: #{chunk['content'].length} characters"
    puts "Content preview: #{chunk['content'][0..200]}#{'...' if chunk['content'].length > 200}"
    
    chunk
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Document or chunk not found"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching document chunk: #{e.message}"
    nil
  end

  # Get knowledge base size for an agent
  def get_agent_knowledge_base_size(agent_id)
    puts "Fetching knowledge base size for agent: #{agent_id}"
    
    size_info = @client.knowledge_base.get_agent_knowledge_base_size(agent_id)
    
    puts "📊 Agent Knowledge Base Size:"
    puts "Number of pages: #{size_info['number_of_pages']}"
    
    size_info
  rescue ElevenlabsClient::NotFoundError
    puts "❌ Agent not found: #{agent_id}"
    nil
  rescue ElevenlabsClient::APIError => e
    puts "❌ Error fetching knowledge base size: #{e.message}"
    nil
  end

  # Create sample documents for demonstration
  def create_sample_documents
    puts "Creating sample knowledge base documents..."
    
    documents = []
    
    # 1. Create from URL
    puts "\n1️⃣ Creating document from URL..."
    url_doc = create_document_from_url(
      "https://docs.ruby-lang.org/en/3.3/doc/syntax/methods_rdoc.html",
      name: "Ruby Methods Documentation"
    )
    documents << url_doc if url_doc
    
    sleep(1)
    
    # 2. Create from text - Company policies
    puts "\n2️⃣ Creating document from text content..."
    policy_text = <<~TEXT
      Customer Support Best Practices
      
      1. Response Time Standards
         - Email inquiries: Respond within 24 hours
         - Live chat: Respond within 2 minutes
         - Phone calls: Answer within 3 rings
      
      2. Communication Guidelines
         - Always greet customers by name
         - Listen actively to understand their needs
         - Provide clear, concise explanations
         - Follow up to ensure satisfaction
      
      3. Escalation Procedures
         - Level 1: Technical issues, billing questions
         - Level 2: Complex technical problems, account modifications
         - Level 3: Legal issues, executive complaints
      
      4. Knowledge Base Usage
         - Always search existing articles first
         - Create new articles for common issues
         - Update outdated information immediately
         - Tag articles with relevant keywords
    TEXT
    
    text_doc = create_document_from_text(policy_text, name: "Customer Support Guidelines")
    documents << text_doc if text_doc
    
    sleep(1)
    
    # 3. Create from text - Product information
    puts "\n3️⃣ Creating product information document..."
    product_text = <<~TEXT
      Product Catalog - Tech Gadgets 2024
      
      Smartphones:
      - TechPhone Pro: $899, 128GB storage, 48MP camera, 5G enabled
      - TechPhone Lite: $499, 64GB storage, 24MP camera, 4G/5G
      - TechPhone Mini: $299, 32GB storage, 12MP camera, 4G
      
      Laptops:
      - TechBook Pro 15": $1,499, Intel i7, 16GB RAM, 512GB SSD
      - TechBook Air 13": $999, Intel i5, 8GB RAM, 256GB SSD
      - TechBook Basic 14": $599, Intel i3, 4GB RAM, 128GB SSD
      
      Accessories:
      - Wireless Earbuds: $149, Noise canceling, 24hr battery
      - Smartphone Case: $29, Drop protection, Multiple colors
      - Laptop Charger: $79, Fast charging, Universal compatibility
      
      Warranty Information:
      - All products include 1-year manufacturer warranty
      - Extended warranty available for additional cost
      - Accidental damage protection plans available
    TEXT
    
    product_doc = create_document_from_text(product_text, name: "Product Catalog 2024")
    documents << product_doc if product_doc
    
    puts "\n✅ Sample documents created successfully!"
    puts "Created #{documents.compact.length} documents"
    
    documents.compact
  end

  # Comprehensive knowledge base analytics
  def analyze_knowledge_base
    puts "📊 Knowledge Base Analytics"
    puts "=" * 50
    
    # Get all documents
    all_docs = list_documents(limit: 100)
    return if all_docs.empty?
    
    puts "\n📈 Statistics:"
    
    # Basic stats
    total_size = all_docs.sum { |doc| doc['metadata']['size_bytes'] || 0 }
    puts "Total documents: #{all_docs.length}"
    puts "Total size: #{format_bytes(total_size)}"
    puts "Average size: #{format_bytes(total_size / all_docs.length)}"
    
    # By type
    by_type = all_docs.group_by { |doc| doc['type'] }
    puts "\n📋 By Type:"
    by_type.each do |type, docs|
      type_size = docs.sum { |doc| doc['metadata']['size_bytes'] || 0 }
      puts "  #{type}: #{docs.length} documents (#{format_bytes(type_size)})"
    end
    
    # By creator
    by_creator = all_docs.group_by { |doc| doc['access_info']['creator_name'] }
    puts "\n👥 By Creator:"
    by_creator.each do |creator, docs|
      puts "  #{creator}: #{docs.length} documents"
    end
    
    # Largest documents
    largest_docs = all_docs.sort_by { |doc| -(doc['metadata']['size_bytes'] || 0) }
    puts "\n📊 Largest Documents:"
    largest_docs.first(5).each_with_index do |doc, index|
      size = format_bytes(doc['metadata']['size_bytes'] || 0)
      puts "#{index + 1}. #{doc['name']}: #{size}"
    end
    
    # RAG overview
    puts "\n🤖 RAG Index Overview:"
    rag_overview = get_rag_overview
    
    # Usage analysis
    puts "\n📅 Recent Activity:"
    recent_docs = all_docs.sort_by { |doc| -doc['metadata']['last_updated_at_unix_secs'] }
    puts "Most recently updated:"
    recent_docs.first(3).each_with_index do |doc, index|
      updated = Time.at(doc['metadata']['last_updated_at_unix_secs']).strftime('%Y-%m-%d %H:%M')
      puts "#{index + 1}. #{doc['name']} (#{updated})"
    end
    
    {
      total_documents: all_docs.length,
      total_size: total_size,
      by_type: by_type.transform_values(&:length),
      by_creator: by_creator.transform_values(&:length),
      largest_documents: largest_docs.first(5).map { |d| { name: d['name'], size: d['metadata']['size_bytes'] } }
    }
  end

  # Complete workflow demonstration
  def demo_workflow
    puts "🚀 Starting Knowledge Base Management Demo"
    puts "=" * 50
    
    # 1. Create sample documents
    puts "\n1️⃣ Creating sample documents..."
    documents = create_sample_documents
    
    return if documents.empty?
    
    sample_doc_id = documents.first["id"]
    
    sleep(2)
    
    # 2. Get document details
    puts "\n2️⃣ Getting document details..."
    get_document_details(sample_doc_id)
    
    sleep(1)
    
    # 3. Create RAG index
    puts "\n3️⃣ Creating RAG index..."
    compute_rag_index(sample_doc_id)
    
    sleep(2)
    
    # 4. Check RAG index status
    puts "\n4️⃣ Checking RAG index status..."
    get_rag_index_status(sample_doc_id)
    
    sleep(1)
    
    # 5. Get document content
    puts "\n5️⃣ Getting document content..."
    get_document_content(sample_doc_id)
    
    sleep(1)
    
    # 6. Check dependent agents
    puts "\n6️⃣ Checking dependent agents..."
    get_dependent_agents(sample_doc_id)
    
    sleep(1)
    
    # 7. Update document
    puts "\n7️⃣ Updating document..."
    update_document(sample_doc_id, "Updated #{documents.first['name']}")
    
    sleep(1)
    
    # 8. Get RAG overview
    puts "\n8️⃣ Getting RAG overview..."
    get_rag_overview
    
    sleep(1)
    
    # 9. Analyze knowledge base
    puts "\n9️⃣ Analyzing knowledge base..."
    analyze_knowledge_base
    
    puts "\n✨ Demo workflow completed successfully!"
    puts "Sample document ID for further testing: #{sample_doc_id}"
    
    sample_doc_id
  end

  private

  def format_bytes(bytes)
    return "0 B" if bytes.nil? || bytes == 0
    
    units = ['B', 'KB', 'MB', 'GB', 'TB']
    size = bytes.to_f
    unit_index = 0
    
    while size >= 1024 && unit_index < units.length - 1
      size /= 1024.0
      unit_index += 1
    end
    
    if unit_index == 0
      "#{size.to_i} #{units[unit_index]}"
    else
      "#{size.round(2)} #{units[unit_index]}"
    end
  end
end

# Example usage
if __FILE__ == $0
  # Initialize the controller
  controller = KnowledgeBaseController.new

  # Run the demo workflow
  controller.demo_workflow
end
