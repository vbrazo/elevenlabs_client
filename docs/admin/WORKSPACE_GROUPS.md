# Admin: Workspace Groups

Manage workspace user groups: search groups, add and remove members.

## Methods

- `client.workspace_groups.search(name:)` — Search workspace groups by name
- `client.workspace_groups.add_member(group_id:, email:)` — Add a member to a group
- `client.workspace_groups.remove_member(group_id:, email:)` — Remove a member from a group

## Examples

```ruby
client = ElevenlabsClient.new

# Search for a group
groups = client.workspace_groups.search(name: "Engineering")
groups.each { |g| puts "#{g['name']} (#{g['id']})" }

# Add member
client.workspace_groups.add_member(group_id: "group_123", email: "user@example.com")

# Remove member
client.workspace_groups.remove_member(group_id: "group_123", email: "user@example.com")
```

## Errors

- 401 AuthenticationError
- 404 NotFoundError
- 422 UnprocessableEntityError
- 429 RateLimitError
- 5xx APIError
