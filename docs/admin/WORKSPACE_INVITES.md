# Admin: Workspace Invites

Invite single or multiple users to your workspace and revoke invitations.

## Methods

- `client.workspace_invites.invite(email:, group_ids: nil, workspace_permission: nil)`
- `client.workspace_invites.invite_bulk(emails:, group_ids: nil)`
- `client.workspace_invites.delete_invite(email:)`

## Examples

```ruby
client = ElevenlabsClient.new

# Invite single user
client.workspace_invites.invite(email: "john.doe@testmail.com")

# Invite multiple users
client.workspace_invites.invite_bulk(emails: ["a@b.com", "c@d.com"])

# Delete invite
client.workspace_invites.delete_invite(email: "john.doe@testmail.com")
```

## Errors

- 401 AuthenticationError
- 404 NotFoundError
- 422 UnprocessableEntityError
- 429 RateLimitError
- 5xx APIError
