# frozen_string_literal: true

RSpec.describe ElevenlabsClient::Admin::PronunciationDictionaries do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test_api_key") }
  let(:endpoint) { client.pronunciation_dictionaries }

  describe "#add_from_file" do
    let(:name) { "My Dictionary" }

    context "with name only (no file)" do
      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/pronunciation-dictionaries/add-from-file")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(status: 200, body: { id: "dict_1", name: name }.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "creates the dictionary" do
        result = endpoint.add_from_file(name: name)
        expect(result["id"]).to eq("dict_1")
      end
    end

    context "with file upload" do
      let(:file_path) { File.expand_path("../../../../fixtures/sample.pls", __FILE__) }

      before do
        stub_request(:post, "https://api.elevenlabs.io/v1/pronunciation-dictionaries/add-from-file")
          .with(headers: { "xi-api-key" => "test_api_key" })
          .to_return(status: 200, body: { id: "dict_2", name: name }.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "uploads the file when provided" do
        io = StringIO.new("<lexicon></lexicon>")
        result = endpoint.add_from_file(name: name, file_io: io, filename: "sample.pls")
        expect(result["id"]).to eq("dict_2")
      end
    end

    it "requires name" do
      expect { endpoint.add_from_file(name: nil) }.to raise_error(ArgumentError)
    end
  end

  describe "#add_from_rules" do
    let(:name) { "My Dictionary" }
    let(:rules) { [{ "string_to_replace" => "a", "type" => "alias", "alias" => "b" }] }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/pronunciation-dictionaries/add-from-rules")
        .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" })
        .to_return(status: 200, body: { id: "dict_3", name: name }.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "creates from rules" do
      result = endpoint.add_from_rules(name: name, rules: rules)
      expect(result["id"]).to eq("dict_3")
    end

    it "requires name" do
      expect { endpoint.add_from_rules(name: "", rules: rules) }.to raise_error(ArgumentError)
    end

    it "requires non-empty rules array" do
      expect { endpoint.add_from_rules(name: name, rules: []) }.to raise_error(ArgumentError)
    end
  end

  describe "#get_pronunciation_dictionary" do
    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/pronunciation-dictionaries/dict_1")
        .with(headers: { "xi-api-key" => "test_api_key" })
        .to_return(status: 200, body: { id: "dict_1", name: "My Dictionary" }.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "fetches dictionary by id" do
      result = endpoint.get_pronunciation_dictionary("dict_1")
      expect(result["id"]).to eq("dict_1")
    end

    it "requires id" do
      expect { endpoint.get_pronunciation_dictionary("") }.to raise_error(ArgumentError)
    end
  end

  describe "#update_pronunciation_dictionary" do
    before do
      stub_request(:patch, "https://api.elevenlabs.io/v1/pronunciation-dictionaries/dict_1")
        .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" })
        .to_return(status: 200, body: { id: "dict_1", name: "Renamed" }.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "updates dictionary" do
      result = endpoint.update_pronunciation_dictionary("dict_1", name: "Renamed")
      expect(result["name"]).to eq("Renamed")
    end

    it "requires id" do
      expect { endpoint.update_pronunciation_dictionary(nil, name: "x") }.to raise_error(ArgumentError)
    end
  end

  describe "#download_pronunciation_dictionary_version" do
    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/pronunciation-dictionaries/dict_1/ver_1/download")
        .with(headers: { "xi-api-key" => "test_api_key" })
        .to_return(status: 200, body: "<lexicon></lexicon>", headers: { "Content-Type" => "application/pls+xml" })
    end

    it "downloads PLS content" do
      result = endpoint.download_pronunciation_dictionary_version(dictionary_id: "dict_1", version_id: "ver_1")
      expect(result).to include("<lexicon>")
    end

    it "requires dictionary_id" do
      expect { endpoint.download_pronunciation_dictionary_version(dictionary_id: nil, version_id: "v") }.to raise_error(ArgumentError)
    end

    it "requires version_id" do
      expect { endpoint.download_pronunciation_dictionary_version(dictionary_id: "d", version_id: nil) }.to raise_error(ArgumentError)
    end
  end

  describe "#list_pronunciation_dictionaries" do
    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/pronunciation-dictionaries")
        .with(headers: { "xi-api-key" => "test_api_key" })
        .to_return(status: 200, body: { "pronunciation_dictionaries" => [], "has_more" => false }.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "lists dictionaries" do
      result = endpoint.list_pronunciation_dictionaries
      expect(result).to have_key("pronunciation_dictionaries")
    end
  end
end


