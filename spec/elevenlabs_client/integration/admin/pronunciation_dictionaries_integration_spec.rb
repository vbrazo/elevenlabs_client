# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admin::PronunciationDictionaries Integration" do
  let(:client) { ElevenlabsClient::Client.new(api_key: "test_api_key") }

  describe "create from file" do
    it "creates a dictionary with just a name" do
      stub_request(:post, "https://api.elevenlabs.io/v1/pronunciation-dictionaries/add-from-file")
        .with(headers: { "xi-api-key" => "test_api_key" })
        .to_return(status: 200, body: { id: "dict_1", name: "My Dictionary" }.to_json, headers: { "Content-Type" => "application/json" })

      result = client.pronunciation_dictionaries.add_from_file(name: "My Dictionary")
      expect(result["id"]).to eq("dict_1")
    end

    it "handles validation errors from API" do
      stub_request(:post, "https://api.elevenlabs.io/v1/pronunciation-dictionaries/add-from-file")
        .with(headers: { "xi-api-key" => "test_api_key" })
        .to_return(status: 422, body: { detail: "Invalid name" }.to_json, headers: { "Content-Type" => "application/json" })

      expect {
        client.pronunciation_dictionaries.add_from_file(name: "bad")
      }.to raise_error(ElevenlabsClient::UnprocessableEntityError)
    end

    it "raises ArgumentError for missing name before request" do
      expect {
        client.pronunciation_dictionaries.add_from_file(name: "")
      }.to raise_error(ArgumentError)
    end
  end

  describe "create from rules" do
    it "creates a dictionary from rules" do
      stub_request(:post, "https://api.elevenlabs.io/v1/pronunciation-dictionaries/add-from-rules")
        .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" })
        .to_return(status: 200, body: { id: "dict_2", name: "Rules Dict" }.to_json, headers: { "Content-Type" => "application/json" })

      rules = [{ "string_to_replace" => "a", "type" => "alias", "alias" => "b" }]
      result = client.pronunciation_dictionaries.add_from_rules(name: "Rules Dict", rules: rules)
      expect(result["id"]).to eq("dict_2")
    end

    it "requires non-empty rules" do
      expect {
        client.pronunciation_dictionaries.add_from_rules(name: "x", rules: [])
      }.to raise_error(ArgumentError)
    end
  end

  describe "get dictionary" do
    it "retrieves a dictionary by id" do
      stub_request(:get, "https://api.elevenlabs.io/v1/pronunciation-dictionaries/dict_1")
        .with(headers: { "xi-api-key" => "test_api_key" })
        .to_return(status: 200, body: { id: "dict_1", name: "My Dict" }.to_json, headers: { "Content-Type" => "application/json" })

      result = client.pronunciation_dictionaries.get("dict_1")
      expect(result["name"]).to eq("My Dict")
    end
  end

  describe "update dictionary" do
    it "updates dictionary fields" do
      stub_request(:patch, "https://api.elevenlabs.io/v1/pronunciation-dictionaries/dict_1")
        .with(headers: { "xi-api-key" => "test_api_key", "Content-Type" => "application/json" })
        .to_return(status: 200, body: { id: "dict_1", name: "Renamed" }.to_json, headers: { "Content-Type" => "application/json" })

      result = client.pronunciation_dictionaries.update("dict_1", name: "Renamed")
      expect(result["name"]).to eq("Renamed")
    end
  end

  describe "download version" do
    it "downloads PLS file contents" do
      stub_request(:get, "https://api.elevenlabs.io/v1/pronunciation-dictionaries/dict_1/ver_1/download")
        .with(headers: { "xi-api-key" => "test_api_key" })
        .to_return(status: 200, body: "<lexicon></lexicon>", headers: { "Content-Type" => "application/pls+xml" })

      body = client.pronunciation_dictionaries.download_pronunciation_dictionary_version(dictionary_id: "dict_1", version_id: "ver_1")
      expect(body).to include("<lexicon>")
    end
  end

  describe "list dictionaries" do
    it "lists with pagination params" do
      stub_request(:get, "https://api.elevenlabs.io/v1/pronunciation-dictionaries")
        .with(headers: { "xi-api-key" => "test_api_key" }, query: { page_size: 10, sort: "creation_time_unix", sort_direction: "descending" })
        .to_return(status: 200, body: { "pronunciation_dictionaries" => [], "has_more" => false, "next_cursor" => nil }.to_json, headers: { "Content-Type" => "application/json" })

      result = client.pronunciation_dictionaries.list_pronunciation_dictionaries(page_size: 10, sort: "creation_time_unix", sort_direction: "descending")
      expect(result).to have_key("pronunciation_dictionaries")
    end
  end
end


