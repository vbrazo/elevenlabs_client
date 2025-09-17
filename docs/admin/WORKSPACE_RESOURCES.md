# Admin: Workspace Resources

Get, share, and unshare workspace resources.

## Methods

- `client.workspace_resources.get_resource(resource_id:, resource_type:)`
- `client.workspace_resources.share(resource_id:, role:, resource_type:, user_email: nil, group_id: nil, workspace_api_key_id: nil)`
- `client.workspace_resources.unshare(resource_id:, resource_type:, user_email: nil, group_id: nil, workspace_api_key_id: nil)`

## Examples

```ruby
client = ElevenlabsClient.new

# Get resource metadata
res = client.workspace_resources.get_resource(resource_id: "abc", resource_type: "voice")

# Share with a group
client.workspace_resources.share(resource_id: "abc", role: "editor", resource_type: "voice", group_id: "g1")

# Unshare from a user
client.workspace_resources.unshare(resource_id: "abc", resource_type: "voice", user_email: "user@example.com")
```
