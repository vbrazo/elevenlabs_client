# Admin: Pronunciation Dictionaries

This document describes the administrative Pronunciation Dictionaries API.

## Endpoints

- Create from file (multipart): `client.pronunciation_dictionaries.add_from_file(name:, file_io: nil, filename: nil, description: nil, workspace_access: nil)`
- Create from rules (JSON): `client.pronunciation_dictionaries.add_from_rules(name:, rules:, description: nil, workspace_access: nil)`
- Get dictionary: `client.pronunciation_dictionaries.get(pronunciation_dictionary_id)`
- Update dictionary: `client.pronunciation_dictionaries.update(pronunciation_dictionary_id, **attributes)`
- Download version (PLS): `client.pronunciation_dictionaries.download_pronunciation_dictionary_version(dictionary_id:, version_id:)`
- List dictionaries: `client.pronunciation_dictionaries.list_pronunciation_dictionaries(cursor: nil, page_size: nil, sort: nil, sort_direction: nil)`

## Examples

```ruby
client = ElevenlabsClient.new

# From file
File.open("lexicon.pls", "rb") do |f|
  dict = client.pronunciation_dictionaries.add_from_file(
    name: "My Dictionary",
    file_io: f,
    filename: "lexicon.pls",
    description: "Lexicon rules"
  )
end

# From rules
rules = [
  { string_to_replace: "a", type: "alias", alias: "b" }
]
dict = client.pronunciation_dictionaries.add_from_rules(
  name: "Rules Dictionary",
  rules: rules
)

# Get
client.pronunciation_dictionaries.get("dict_id")

# Update
client.pronunciation_dictionaries.update("dict_id", name: "Renamed")

# Download version
pls = client.pronunciation_dictionaries.download_pronunciation_dictionary_version(dictionary_id: "dict_id", version_id: "ver_id")

# List
client.pronunciation_dictionaries.list_pronunciation_dictionaries(page_size: 10)
```

## Errors

- 401 AuthenticationError
- 404 NotFoundError
- 422 UnprocessableEntityError
- 429 RateLimitError
- 5xx APIError
