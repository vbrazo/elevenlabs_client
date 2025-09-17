# frozen_string_literal: true

RSpec.describe "ElevenlabsClient Knowledge Base Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { ElevenlabsClient::Client.new(api_key: api_key) }

  describe "client.knowledge_base accessor" do
    it "provides access to knowledge base endpoint" do
      expect(client.knowledge_base).to be_an_instance_of(ElevenlabsClient::Endpoints::AgentsPlatform::KnowledgeBase)
    end
  end

  describe "knowledge base management functionality via client" do
    let(:document_id) { "doc123" }

    describe "listing documents" do
      let(:documents_response) do
        {
          "documents" => [
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
              "dependent_agents" => [],
              "type" => "url",
              "url" => "https://docs.example.com/api"
            }
          ],
          "has_more" => false,
          "next_cursor" => nil
        }
      end

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: documents_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "lists documents through client interface" do
        result = client.knowledge_base.list

        expect(result).to eq(documents_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "getting document details" do
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

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: document_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "gets document details through client interface" do
        result = client.knowledge_base.get(document_id)

        expect(result).to eq(document_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "creating document from URL" do
      let(:url) { "https://docs.example.com/api" }
      let(:create_response) do
        {
          "id" => "doc456",
          "name" => "API Documentation"
        }
      end

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/knowledge-base/url")
          .with(
            body: { url: url }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 200,
            body: create_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "creates document from URL through client interface" do
        result = client.knowledge_base.create_from_url(url)

        expect(result).to eq(create_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/knowledge-base/url")
          .with(
            body: { url: url }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
      end
    end

    describe "creating document from text" do
      let(:text) { "This is sample documentation content..." }
      let(:name) { "Custom Text Document" }
      let(:create_response) do
        {
          "id" => "doc456",
          "name" => name
        }
      end

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/knowledge-base/text")
          .with(
            body: { text: text, name: name }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 200,
            body: create_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "creates document from text through client interface" do
        result = client.knowledge_base.create_from_text(text, name: name)

        expect(result).to eq(create_response)
        expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/knowledge-base/text")
          .with(
            body: { text: text, name: name }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
      end
    end

    describe "creating document from file" do
      let(:filename) { "document.pdf" }
      let(:file_content) { "PDF file content" }
      let(:create_response) do
        {
          "id" => "doc456",
          "name" => filename
        }
      end

      before do
        # Mock the multipart form data request
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/knowledge-base/file")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: create_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "creates document from file through client interface" do
        file_io = StringIO.new(file_content)
        
        # Mock the file_part method
        allow(client).to receive(:file_part).with(file_io, filename).and_return("file_part_mock")
        allow(client).to receive(:post_multipart).with("/v1/convai/knowledge-base/file", { "file" => "file_part_mock" })
                                                 .and_return(create_response)

        result = client.knowledge_base.create_from_file(file_io: file_io, filename: filename)

        expect(result).to eq(create_response)
        expect(client).to have_received(:post_multipart).with("/v1/convai/knowledge-base/file", { "file" => "file_part_mock" })
      end
    end

    describe "updating document" do
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
        stub_request(:patch, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}")
          .with(
            body: { name: new_name }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 200,
            body: update_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "updates document through client interface" do
        result = client.knowledge_base.update(document_id, name: new_name)

        expect(result).to eq(update_response)
        expect(WebMock).to have_requested(:patch, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}")
          .with(
            body: { name: new_name }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
      end
    end

    describe "deleting document" do
      before do
        stub_request(:delete, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: "{}",
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "deletes document through client interface" do
        result = client.knowledge_base.delete(document_id)

        expect(result).to eq({})
        expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "RAG index management" do
      describe "computing RAG index" do
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
          stub_request(:post, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}/rag-index")
            .with(
              body: { model: model }.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
            .to_return(
              status: 200,
              body: rag_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "computes RAG index through client interface" do
          result = client.knowledge_base.compute_rag_index(document_id, model: model)

          expect(result).to eq(rag_response)
          expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}/rag-index")
            .with(
              body: { model: model }.to_json,
              headers: {
                "Content-Type" => "application/json",
                "xi-api-key" => api_key
              }
            )
        end
      end

      describe "getting RAG index status" do
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
          stub_request(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}/rag-index")
            .with(headers: { "xi-api-key" => api_key })
            .to_return(
              status: 200,
              body: rag_index_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "gets RAG index status through client interface" do
          result = client.knowledge_base.get_rag_index(document_id)

          expect(result).to eq(rag_index_response)
          expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}/rag-index")
            .with(headers: { "xi-api-key" => api_key })
        end
      end

      describe "deleting RAG index" do
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
          stub_request(:delete, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}/rag-index/#{rag_index_id}")
            .with(headers: { "xi-api-key" => api_key })
            .to_return(
              status: 200,
              body: delete_rag_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "deletes RAG index through client interface" do
          result = client.knowledge_base.delete_rag_index(document_id, rag_index_id)

          expect(result).to eq(delete_rag_response)
          expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}/rag-index/#{rag_index_id}")
            .with(headers: { "xi-api-key" => api_key })
        end
      end

      describe "getting RAG index overview" do
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
          stub_request(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/rag-index")
            .with(headers: { "xi-api-key" => api_key })
            .to_return(
              status: 200,
              body: overview_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "gets RAG index overview through client interface" do
          result = client.knowledge_base.get_rag_index_overview

          expect(result).to eq(overview_response)
          expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/rag-index")
            .with(headers: { "xi-api-key" => api_key })
        end
      end
    end

    describe "getting dependent agents" do
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
          stub_request(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}/dependent-agents")
            .with(headers: { "xi-api-key" => api_key })
            .to_return(
              status: 200,
              body: dependent_agents_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "gets dependent agents through client interface" do
          result = client.knowledge_base.get_dependent_agents(document_id)

          expect(result).to eq(dependent_agents_response)
          expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}/dependent-agents")
            .with(headers: { "xi-api-key" => api_key })
        end
      end

      context "with query parameters" do
        let(:query_params) { "page_size=10&cursor=cursor123" }

        before do
          stub_request(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}/dependent-agents?#{query_params}")
            .with(headers: { "xi-api-key" => api_key })
            .to_return(
              status: 200,
              body: dependent_agents_response.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "gets dependent agents with parameters through client interface" do
          result = client.knowledge_base.get_dependent_agents(document_id, page_size: 10, cursor: "cursor123")

          expect(result).to eq(dependent_agents_response)
          expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}/dependent-agents?#{query_params}")
            .with(headers: { "xi-api-key" => api_key })
        end
      end
    end

    describe "getting document content" do
      let(:content_response) { "This is the full content of the document..." }

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}/content")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: content_response,
            headers: { "Content-Type" => "text/plain" }
          )
      end

      it "gets document content through client interface" do
        result = client.knowledge_base.get_content(document_id)

        expect(result).to eq(content_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}/content")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "getting document chunk" do
      let(:chunk_id) { "chunk456" }
      let(:chunk_response) do
        {
          "id" => chunk_id,
          "name" => "Introduction Section",
          "content" => "This is the content of the chunk..."
        }
      end

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}/chunk/#{chunk_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: chunk_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "gets document chunk through client interface" do
        result = client.knowledge_base.get_chunk(document_id, chunk_id)

        expect(result).to eq(chunk_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}/chunk/#{chunk_id}")
          .with(headers: { "xi-api-key" => api_key })
      end
    end

    describe "getting agent knowledge base size" do
      let(:agent_id) { "agent123" }
      let(:size_response) do
        {
          "number_of_pages" => 42.5
        }
      end

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/agent/#{agent_id}/knowledge-base/size")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 200,
            body: size_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "gets agent knowledge base size through client interface" do
        result = client.knowledge_base.get_agent_knowledge_base_size(agent_id)

        expect(result).to eq(size_response)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/agent/#{agent_id}/knowledge-base/size")
          .with(headers: { "xi-api-key" => api_key })
      end
    end
  end

  describe "error handling integration" do
    let(:document_id) { "nonexistent_document" }

    describe "handling 404 errors" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 404,
            body: { "detail" => "Document not found" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises NotFoundError for missing document" do
        expect { client.knowledge_base.get(document_id) }.to raise_error(ElevenlabsClient::NotFoundError)
      end
    end

    describe "handling 401 authentication errors" do
      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base")
          .with(headers: { "xi-api-key" => api_key })
          .to_return(
            status: 401,
            body: { "detail" => "Invalid API key" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises AuthenticationError for invalid API key" do
        expect { client.knowledge_base.list }.to raise_error(ElevenlabsClient::AuthenticationError)
      end
    end

    describe "handling 422 validation errors" do
      let(:invalid_url) { "invalid-url" }

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/convai/knowledge-base/url")
          .with(
            body: { url: invalid_url }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "xi-api-key" => api_key
            }
          )
          .to_return(
            status: 422,
            body: { "detail" => "Invalid URL format" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises UnprocessableEntityError for validation failures" do
        expect { client.knowledge_base.create_from_url(invalid_url) }
          .to raise_error(ElevenlabsClient::UnprocessableEntityError)
      end
    end
  end

  describe "full workflow integration" do
    let(:document_id) { "doc123" }
    let(:new_document_id) { "doc456" }
    let(:rag_index_id) { "rag789" }

    it "supports complete knowledge base lifecycle" do
      # List documents
      stub_request(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base")
        .to_return(
          status: 200,
          body: { "documents" => [{ "id" => document_id, "name" => "Existing Doc" }], "has_more" => false }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Create document from URL
      url = "https://docs.example.com/new"
      stub_request(:post, "https://api.elevenlabs.io/v1/convai/knowledge-base/url")
        .to_return(
          status: 200,
          body: { "id" => new_document_id, "name" => "New API Documentation" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Get document details
      stub_request(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{new_document_id}")
        .to_return(
          status: 200,
          body: { "id" => new_document_id, "name" => "New API Documentation", "type" => "url" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Compute RAG index
      stub_request(:post, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{new_document_id}/rag-index")
        .to_return(
          status: 200,
          body: { "id" => rag_index_id, "model" => "e5_mistral_7b_instruct", "status" => "processing" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Update document
      stub_request(:patch, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{new_document_id}")
        .to_return(
          status: 200,
          body: { "id" => new_document_id, "name" => "Updated API Documentation" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Get dependent agents
      stub_request(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{new_document_id}/dependent-agents")
        .to_return(
          status: 200,
          body: { "agents" => [], "has_more" => false }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Get document content
      stub_request(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{new_document_id}/content")
        .to_return(
          status: 200,
          body: "Full document content here...",
          headers: { "Content-Type" => "text/plain" }
        )

      # Delete document
      stub_request(:delete, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{new_document_id}")
        .to_return(
          status: 200,
          body: "{}",
          headers: { "Content-Type" => "application/json" }
        )

      # Execute workflow
      list_result = client.knowledge_base.list
      expect(list_result["documents"].first["id"]).to eq(document_id)

      create_result = client.knowledge_base.create_from_url(url)
      expect(create_result["id"]).to eq(new_document_id)

      get_result = client.knowledge_base.get(new_document_id)
      expect(get_result["id"]).to eq(new_document_id)

      rag_result = client.knowledge_base.compute_rag_index(new_document_id, model: "e5_mistral_7b_instruct")
      expect(rag_result["id"]).to eq(rag_index_id)

      update_result = client.knowledge_base.update(new_document_id, name: "Updated API Documentation")
      expect(update_result["name"]).to eq("Updated API Documentation")

      agents_result = client.knowledge_base.get_dependent_agents(new_document_id)
      expect(agents_result["agents"]).to eq([])

      content_result = client.knowledge_base.get_content(new_document_id)
      expect(content_result).to eq("Full document content here...")

      delete_result = client.knowledge_base.delete(new_document_id)
      expect(delete_result).to eq({})

      # Verify all requests were made
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base")
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/knowledge-base/url")
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{new_document_id}")
      expect(WebMock).to have_requested(:post, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{new_document_id}/rag-index")
      expect(WebMock).to have_requested(:patch, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{new_document_id}")
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{new_document_id}/dependent-agents")
      expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{new_document_id}/content")
      expect(WebMock).to have_requested(:delete, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{new_document_id}")
    end
  end

  describe "query parameter encoding" do
    let(:document_id) { "doc123" }

    context "list with special characters in search" do
      let(:search_term) { "API documentation & guides" }
      let(:encoded_search) { "page_size=20&search=API+documentation+%26+guides" }

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base?#{encoded_search}")
          .to_return(
            status: 200,
            body: { "documents" => [], "has_more" => false }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "properly encodes query parameters" do
        client.knowledge_base.list(page_size: 20, search: search_term)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base?#{encoded_search}")
      end
    end

    context "get_dependent_agents with cursor containing special characters" do
      let(:cursor) { "cursor_with_special+chars=" }
      let(:encoded_cursor) { "cursor=cursor_with_special%2Bchars%3D" }

      before do
        stub_request(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}/dependent-agents?#{encoded_cursor}")
          .to_return(
            status: 200,
            body: { "agents" => [], "has_more" => false }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "properly encodes cursor parameter" do
        client.knowledge_base.get_dependent_agents(document_id, cursor: cursor)
        expect(WebMock).to have_requested(:get, "https://api.elevenlabs.io/v1/convai/knowledge-base/#{document_id}/dependent-agents?#{encoded_cursor}")
      end
    end
  end
end
