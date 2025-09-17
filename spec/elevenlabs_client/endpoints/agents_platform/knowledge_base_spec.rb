# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Endpoints::AgentsPlatform::KnowledgeBase do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }
  let(:knowledge_base) { described_class.new(client) }

  describe "#list" do
    let(:list_response) do
      {
        "documents" => [
          {
            "id" => "doc123",
            "name" => "API Documentation",
            "metadata" => {
              "created_at_unix_secs" => 1716153600,
              "last_updated_at_unix_secs" => 1716240000,
              "size_bytes" => 50000
            },
            "supported_usages" => ["prompt"],
            "access_info" => {
              "is_creator" => true,
              "creator_name" => "John Doe",
              "creator_email" => "john@example.com",
              "role" => "admin"
            },
            "dependent_agents" => [],
            "type" => "url",
            "url" => "https://docs.example.com/api"
          }
        ],
        "has_more" => false,
        "next_cursor" => nil
      }
    end

    context "without parameters" do
      before do
        allow(client).to receive(:get).with("/v1/convai/knowledge-base")
                                     .and_return(list_response)
      end

      it "lists documents successfully" do
        result = knowledge_base.list
        expect(result).to eq(list_response)
        expect(client).to have_received(:get).with("/v1/convai/knowledge-base")
      end
    end

    context "with parameters" do
      let(:params) do
        {
          page_size: 10,
          search: "api",
          types: ["url", "file"],
          show_only_owned_documents: true,
          sort_by: "created_at",
          sort_direction: "desc"
        }
      end

      before do
        allow(client).to receive(:get).with("/v1/convai/knowledge-base?page_size=10&search=api&types=url&types=file&show_only_owned_documents=true&sort_by=created_at&sort_direction=desc")
                                     .and_return(list_response)
      end

      it "lists documents with query parameters" do
        result = knowledge_base.list(**params)
        expect(result).to eq(list_response)
        expect(client).to have_received(:get).with("/v1/convai/knowledge-base?page_size=10&search=api&types=url&types=file&show_only_owned_documents=true&sort_by=created_at&sort_direction=desc")
      end
    end
  end

  describe "#get" do
    let(:document_id) { "doc123" }
    let(:document_response) do
      {
        "id" => document_id,
        "name" => "API Documentation",
        "metadata" => {
          "created_at_unix_secs" => 1716153600,
          "last_updated_at_unix_secs" => 1716240000,
          "size_bytes" => 50000
        },
        "supported_usages" => ["prompt"],
        "access_info" => {
          "is_creator" => true,
          "creator_name" => "John Doe",
          "creator_email" => "john@example.com",
          "role" => "admin"
        },
        "extracted_inner_html" => "<h1>API Documentation</h1><p>Welcome to our API...</p>",
        "type" => "url",
        "url" => "https://docs.example.com/api"
      }
    end

    context "without agent_id" do
      before do
        allow(client).to receive(:get).with("/v1/convai/knowledge-base/#{document_id}")
                                     .and_return(document_response)
      end

      it "retrieves document details successfully" do
        result = knowledge_base.get(document_id)
        expect(result).to eq(document_response)
        expect(client).to have_received(:get).with("/v1/convai/knowledge-base/#{document_id}")
      end
    end

    context "with agent_id" do
      let(:agent_id) { "agent456" }

      before do
        allow(client).to receive(:get).with("/v1/convai/knowledge-base/#{document_id}?agent_id=#{agent_id}")
                                     .and_return(document_response)
      end

      it "retrieves document details with agent context" do
        result = knowledge_base.get(document_id, agent_id: agent_id)
        expect(result).to eq(document_response)
        expect(client).to have_received(:get).with("/v1/convai/knowledge-base/#{document_id}?agent_id=#{agent_id}")
      end
    end
  end

  describe "#update" do
    let(:document_id) { "doc123" }
    let(:new_name) { "Updated API Documentation" }
    let(:update_response) do
      {
        "id" => document_id,
        "name" => new_name,
        "metadata" => {
          "created_at_unix_secs" => 1716153600,
          "last_updated_at_unix_secs" => 1716240000,
          "size_bytes" => 50000
        }
      }
    end

    before do
      allow(client).to receive(:patch).with("/v1/convai/knowledge-base/#{document_id}", { name: new_name })
                                     .and_return(update_response)
    end

    it "updates document name successfully" do
      result = knowledge_base.update(document_id, name: new_name)
      expect(result).to eq(update_response)
      expect(client).to have_received(:patch).with("/v1/convai/knowledge-base/#{document_id}", { name: new_name })
    end
  end

  describe "#delete" do
    let(:document_id) { "doc123" }
    let(:delete_response) { {} }

    context "without force" do
      before do
        allow(client).to receive(:delete).with("/v1/convai/knowledge-base/#{document_id}")
                                        .and_return(delete_response)
      end

      it "deletes document successfully" do
        result = knowledge_base.delete(document_id)
        expect(result).to eq(delete_response)
        expect(client).to have_received(:delete).with("/v1/convai/knowledge-base/#{document_id}")
      end
    end

    context "with force" do
      before do
        allow(client).to receive(:delete).with("/v1/convai/knowledge-base/#{document_id}?force=true")
                                        .and_return(delete_response)
      end

      it "force deletes document successfully" do
        result = knowledge_base.delete(document_id, force: true)
        expect(result).to eq(delete_response)
        expect(client).to have_received(:delete).with("/v1/convai/knowledge-base/#{document_id}?force=true")
      end
    end
  end

  describe "#create_from_url" do
    let(:url) { "https://docs.example.com/api" }
    let(:create_response) do
      {
        "id" => "doc123",
        "name" => "API Documentation"
      }
    end

    context "without name" do
      before do
        allow(client).to receive(:post).with("/v1/convai/knowledge-base/url", { url: url })
                                      .and_return(create_response)
      end

      it "creates document from URL successfully" do
        result = knowledge_base.create_from_url(url)
        expect(result).to eq(create_response)
        expect(client).to have_received(:post).with("/v1/convai/knowledge-base/url", { url: url })
      end
    end

    context "with name" do
      let(:name) { "Custom API Docs" }

      before do
        allow(client).to receive(:post).with("/v1/convai/knowledge-base/url", { url: url, name: name })
                                      .and_return(create_response)
      end

      it "creates document from URL with custom name" do
        result = knowledge_base.create_from_url(url, name: name)
        expect(result).to eq(create_response)
        expect(client).to have_received(:post).with("/v1/convai/knowledge-base/url", { url: url, name: name })
      end
    end
  end

  describe "#create_from_text" do
    let(:text) { "This is sample documentation content..." }
    let(:create_response) do
      {
        "id" => "doc123",
        "name" => "Text Document"
      }
    end

    context "without name" do
      before do
        allow(client).to receive(:post).with("/v1/convai/knowledge-base/text", { text: text })
                                      .and_return(create_response)
      end

      it "creates document from text successfully" do
        result = knowledge_base.create_from_text(text)
        expect(result).to eq(create_response)
        expect(client).to have_received(:post).with("/v1/convai/knowledge-base/text", { text: text })
      end
    end

    context "with name" do
      let(:name) { "Custom Text Document" }

      before do
        allow(client).to receive(:post).with("/v1/convai/knowledge-base/text", { text: text, name: name })
                                      .and_return(create_response)
      end

      it "creates document from text with custom name" do
        result = knowledge_base.create_from_text(text, name: name)
        expect(result).to eq(create_response)
        expect(client).to have_received(:post).with("/v1/convai/knowledge-base/text", { text: text, name: name })
      end
    end
  end

  describe "#create_from_file" do
    let(:file_io) { StringIO.new("file content") }
    let(:filename) { "document.pdf" }
    let(:create_response) do
      {
        "id" => "doc123",
        "name" => "document.pdf"
      }
    end

    context "without name" do
      before do
        allow(client).to receive(:file_part).with(file_io, filename).and_return("file_part_mock")
        allow(client).to receive(:post_multipart).with("/v1/convai/knowledge-base/file", { "file" => "file_part_mock" })
                                                 .and_return(create_response)
      end

      it "creates document from file successfully" do
        result = knowledge_base.create_from_file(file_io: file_io, filename: filename)
        expect(result).to eq(create_response)
        expect(client).to have_received(:post_multipart).with("/v1/convai/knowledge-base/file", { "file" => "file_part_mock" })
      end
    end

    context "with name" do
      let(:name) { "Custom Document" }

      before do
        allow(client).to receive(:file_part).with(file_io, filename).and_return("file_part_mock")
        allow(client).to receive(:post_multipart).with("/v1/convai/knowledge-base/file", { "file" => "file_part_mock", "name" => name })
                                                 .and_return(create_response)
      end

      it "creates document from file with custom name" do
        result = knowledge_base.create_from_file(file_io: file_io, filename: filename, name: name)
        expect(result).to eq(create_response)
        expect(client).to have_received(:post_multipart).with("/v1/convai/knowledge-base/file", { "file" => "file_part_mock", "name" => name })
      end
    end
  end

  describe "#compute_rag_index" do
    let(:document_id) { "doc123" }
    let(:model) { "e5_mistral_7b_instruct" }
    let(:rag_response) do
      {
        "id" => "rag456",
        "model" => model,
        "status" => "processing",
        "progress_percentage" => 50.0,
        "document_model_index_usage" => {
          "used_bytes" => 10000
        }
      }
    end

    before do
      allow(client).to receive(:post).with("/v1/convai/knowledge-base/#{document_id}/rag-index", { model: model })
                                    .and_return(rag_response)
    end

    it "computes RAG index successfully" do
      result = knowledge_base.compute_rag_index(document_id, model: model)
      expect(result).to eq(rag_response)
      expect(client).to have_received(:post).with("/v1/convai/knowledge-base/#{document_id}/rag-index", { model: model })
    end
  end

  describe "#get_rag_index" do
    let(:document_id) { "doc123" }
    let(:rag_index_response) do
      {
        "indexes" => [
          {
            "id" => "rag456",
            "model" => "e5_mistral_7b_instruct",
            "status" => "completed",
            "progress_percentage" => 100.0,
            "document_model_index_usage" => {
              "used_bytes" => 10000
            }
          }
        ]
      }
    end

    before do
      allow(client).to receive(:get).with("/v1/convai/knowledge-base/#{document_id}/rag-index")
                                   .and_return(rag_index_response)
    end

    it "gets RAG index information successfully" do
      result = knowledge_base.get_rag_index(document_id)
      expect(result).to eq(rag_index_response)
      expect(client).to have_received(:get).with("/v1/convai/knowledge-base/#{document_id}/rag-index")
    end
  end

  describe "#delete_rag_index" do
    let(:document_id) { "doc123" }
    let(:rag_index_id) { "rag456" }
    let(:delete_rag_response) do
      {
        "id" => rag_index_id,
        "model" => "e5_mistral_7b_instruct",
        "status" => "deleted",
        "progress_percentage" => 100.0,
        "document_model_index_usage" => {
          "used_bytes" => 0
        }
      }
    end

    before do
      allow(client).to receive(:delete).with("/v1/convai/knowledge-base/#{document_id}/rag-index/#{rag_index_id}")
                                      .and_return(delete_rag_response)
    end

    it "deletes RAG index successfully" do
      result = knowledge_base.delete_rag_index(document_id, rag_index_id)
      expect(result).to eq(delete_rag_response)
      expect(client).to have_received(:delete).with("/v1/convai/knowledge-base/#{document_id}/rag-index/#{rag_index_id}")
    end
  end

  describe "#get_rag_index_overview" do
    let(:overview_response) do
      {
        "total_used_bytes" => 100000,
        "total_max_bytes" => 1000000,
        "models" => [
          {
            "model" => "e5_mistral_7b_instruct",
            "used_bytes" => 75000
          },
          {
            "model" => "multilingual_e5_large_instruct",
            "used_bytes" => 25000
          }
        ]
      }
    end

    before do
      allow(client).to receive(:get).with("/v1/convai/knowledge-base/rag-index")
                                   .and_return(overview_response)
    end

    it "gets RAG index overview successfully" do
      result = knowledge_base.get_rag_index_overview
      expect(result).to eq(overview_response)
      expect(client).to have_received(:get).with("/v1/convai/knowledge-base/rag-index")
    end
  end

  describe "#get_dependent_agents" do
    let(:document_id) { "doc123" }
    let(:dependent_agents_response) do
      {
        "agents" => [
          {
            "id" => "agent456",
            "name" => "Support Agent",
            "type" => "conversational"
          }
        ],
        "has_more" => false,
        "next_cursor" => nil
      }
    end

    context "without parameters" do
      before do
        allow(client).to receive(:get).with("/v1/convai/knowledge-base/#{document_id}/dependent-agents")
                                     .and_return(dependent_agents_response)
      end

      it "gets dependent agents successfully" do
        result = knowledge_base.get_dependent_agents(document_id)
        expect(result).to eq(dependent_agents_response)
        expect(client).to have_received(:get).with("/v1/convai/knowledge-base/#{document_id}/dependent-agents")
      end
    end

    context "with parameters" do
      let(:params) { { page_size: 10, cursor: "cursor123" } }

      before do
        allow(client).to receive(:get).with("/v1/convai/knowledge-base/#{document_id}/dependent-agents?page_size=10&cursor=cursor123")
                                     .and_return(dependent_agents_response)
      end

      it "gets dependent agents with query parameters" do
        result = knowledge_base.get_dependent_agents(document_id, **params)
        expect(result).to eq(dependent_agents_response)
        expect(client).to have_received(:get).with("/v1/convai/knowledge-base/#{document_id}/dependent-agents?page_size=10&cursor=cursor123")
      end
    end
  end

  describe "#get_content" do
    let(:document_id) { "doc123" }
    let(:content_response) { "This is the full content of the document..." }

    before do
      allow(client).to receive(:get).with("/v1/convai/knowledge-base/#{document_id}/content")
                                   .and_return(content_response)
    end

    it "gets document content successfully" do
      result = knowledge_base.get_content(document_id)
      expect(result).to eq(content_response)
      expect(client).to have_received(:get).with("/v1/convai/knowledge-base/#{document_id}/content")
    end
  end

  describe "#get_chunk" do
    let(:document_id) { "doc123" }
    let(:chunk_id) { "chunk456" }
    let(:chunk_response) do
      {
        "id" => chunk_id,
        "name" => "Introduction Section",
        "content" => "This is the content of the chunk..."
      }
    end

    before do
      allow(client).to receive(:get).with("/v1/convai/knowledge-base/#{document_id}/chunk/#{chunk_id}")
                                   .and_return(chunk_response)
    end

    it "gets document chunk successfully" do
      result = knowledge_base.get_chunk(document_id, chunk_id)
      expect(result).to eq(chunk_response)
      expect(client).to have_received(:get).with("/v1/convai/knowledge-base/#{document_id}/chunk/#{chunk_id}")
    end
  end

  describe "#get_agent_knowledge_base_size" do
    let(:agent_id) { "agent123" }
    let(:size_response) do
      {
        "number_of_pages" => 42.5
      }
    end

    before do
      allow(client).to receive(:get).with("/v1/convai/agent/#{agent_id}/knowledge-base/size")
                                   .and_return(size_response)
    end

    it "gets agent knowledge base size successfully" do
      result = knowledge_base.get_agent_knowledge_base_size(agent_id)
      expect(result).to eq(size_response)
      expect(client).to have_received(:get).with("/v1/convai/agent/#{agent_id}/knowledge-base/size")
    end
  end

  describe "error handling" do
    let(:document_id) { "nonexistent_document" }

    context "when document is not found" do
      before do
        allow(client).to receive(:get).with("/v1/convai/knowledge-base/#{document_id}")
                                     .and_raise(ElevenlabsClient::NotFoundError, "Document not found")
      end

      it "raises NotFoundError" do
        expect { knowledge_base.get(document_id) }.to raise_error(ElevenlabsClient::NotFoundError, "Document not found")
      end
    end

    context "when validation fails for URL creation" do
      let(:invalid_url) { "invalid-url" }

      before do
        allow(client).to receive(:post).with("/v1/convai/knowledge-base/url", { url: invalid_url })
                                      .and_raise(ElevenlabsClient::UnprocessableEntityError, "Invalid URL format")
      end

      it "raises UnprocessableEntityError" do
        expect { knowledge_base.create_from_url(invalid_url) }
          .to raise_error(ElevenlabsClient::UnprocessableEntityError, "Invalid URL format")
      end
    end

    context "when authentication fails" do
      before do
        allow(client).to receive(:get).with("/v1/convai/knowledge-base")
                                     .and_raise(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end

      it "raises AuthenticationError" do
        expect { knowledge_base.list }.to raise_error(ElevenlabsClient::AuthenticationError, "Invalid API key")
      end
    end
  end

  describe "parameter handling" do
    describe "#list" do
      context "with nil parameters" do
        let(:params) { { page_size: 10, search: nil, types: ["url"] } }
        let(:expected_query) { "page_size=10&types=url" }

        before do
          allow(client).to receive(:get).with("/v1/convai/knowledge-base?#{expected_query}")
                                       .and_return({ "documents" => [], "has_more" => false })
        end

        it "filters out nil parameters" do
          knowledge_base.list(**params)
          expect(client).to have_received(:get).with("/v1/convai/knowledge-base?#{expected_query}")
        end
      end
    end

    describe "#get_dependent_agents" do
      let(:document_id) { "doc123" }

      context "with nil parameters" do
        let(:params) { { page_size: 10, cursor: nil } }
        let(:expected_query) { "page_size=10" }

        before do
          allow(client).to receive(:get).with("/v1/convai/knowledge-base/#{document_id}/dependent-agents?#{expected_query}")
                                       .and_return({ "agents" => [], "has_more" => false })
        end

        it "filters out nil parameters" do
          knowledge_base.get_dependent_agents(document_id, **params)
          expect(client).to have_received(:get).with("/v1/convai/knowledge-base/#{document_id}/dependent-agents?#{expected_query}")
        end
      end
    end
  end

  describe "RAG model validation" do
    let(:document_id) { "doc123" }

    describe "#compute_rag_index" do
      context "with valid model" do
        it "accepts e5_mistral_7b_instruct" do
          allow(client).to receive(:post).with("/v1/convai/knowledge-base/#{document_id}/rag-index", { model: "e5_mistral_7b_instruct" })
                                        .and_return({ "id" => "rag123" })

          result = knowledge_base.compute_rag_index(document_id, model: "e5_mistral_7b_instruct")
          expect(result["id"]).to eq("rag123")
        end

        it "accepts multilingual_e5_large_instruct" do
          allow(client).to receive(:post).with("/v1/convai/knowledge-base/#{document_id}/rag-index", { model: "multilingual_e5_large_instruct" })
                                        .and_return({ "id" => "rag123" })

          result = knowledge_base.compute_rag_index(document_id, model: "multilingual_e5_large_instruct")
          expect(result["id"]).to eq("rag123")
        end
      end
    end
  end
end
