# Admin: Workspace Members

Update workspace member attributes.

## Methods

- `client.workspace_members.update_member(email:, is_locked: nil, workspace_role: nil)`

## Example

```ruby
client = ElevenlabsClient.new

client.workspace_members.update_member(
  email: "user@example.com",
  is_locked: true,
  workspace_role: "workspace_admin"
)
```

## Notes

- Only specified fields are updated; others remain unchanged.
- Requires workspace admin permissions.
