# Provider: Jira

> **Provider contract**: Every provider must implement these sections: Prerequisites, Commands (Fetch a ticket, List children of an epic, Transition a ticket, Post a comment, Create a ticket), Status mapping, URL pattern. Comments must include author and date. See this file as reference implementation.

## Prerequisites

- `jira` CLI installed and authenticated ([go-jira](https://github.com/ankitpokhrel/jira-cli))
- Verify: `which jira && jira me`

## Commands

### Fetch a ticket

```bash
jira issue view {KEY} --plain
```

Extract: `summary`, `description`, `status.name`, comments.

### List children of an epic

Try these JQL queries in order, stop at the first result:

1. `parent = {KEY} ORDER BY key ASC`
2. `"Epic Link" = {KEY} ORDER BY key ASC`

```bash
jira issue list -q '{JQL}' --plain --columns key,summary,status,priority,assignee
```

For each child, fetch details:

```bash
jira issue view {CHILD_KEY} --plain
```

### Transition a ticket

```bash
jira issue move {KEY} "{STATUS_EN}"
```

Status mapping (Praxis → Jira transition name):

| Praxis  | Jira transition |
|---------|----------------|
| active  | In Progress    |
| review  | In Review      |
| done    | Done           |

### Post a comment

> **🛑 MANDATORY — NEVER run `jira issue comment add` without explicit validation.**
>
> A user instruction like "poste un commentaire pour dire X" / "add a comment" / "comment on Jira" is a **drafting request**, NOT a send authorization. Jira comments are public and visible to the team and potentially to the client — once sent, they can only be deleted manually.
>
> **Required 3-step workflow**:
> 1. Write the draft to `/tmp/praxis-comment-{KEY}.md`
> 2. **Display the FULL comment content inline in the chat** (not a summary, not just a path) and explicitly ask: "Je poste ? / Validate to send?"
> 3. Wait for an explicit "ok" / "poste" / "valide" / "envoie" / "yes, send" before running `jira issue comment add`
>
> Auto mode, praxis workflow, or any other running context does NOT override this rule.

Write the comment to a temp file to avoid shell escaping issues:

```bash
cat <<'EOF' > /tmp/praxis-comment-{KEY}.md
{comment}
EOF
```

**Then display the full content to the user and ask for validation.** Only after explicit confirmation:

```bash
jira issue comment add {KEY} --template /tmp/praxis-comment-{KEY}.md --no-input
```

### Create a ticket

```bash
jira issue create --type Story --parent {EPIC_KEY} --summary "{SUMMARY}" --body "{DESCRIPTION}" --no-input
```

If `--parent` is not supported (older Jira / classic projects), use epic link:

```bash
jira issue create --type Story --custom epic-link={EPIC_KEY} --summary "{SUMMARY}" --body "{DESCRIPTION}" --no-input
```

The command returns the created ticket key (e.g., `KEY-40001`). Parse it from stdout.

### Search tickets (used by `/praxis-watch-tickets`)

Preferred when the Atlassian connector is available — it returns status categories, priorities and paging:

```
mcp__claude_ai_Atlassian_Rovo__getAccessibleAtlassianResources      → cloudId (once per pass; the site hostname also works)
mcp__claude_ai_Atlassian_Rovo__searchJiraIssuesUsingJql(cloudId, jql, maxResults=100,
  fields=["key","summary","status","issuetype","parent","updated","created","priority","labels"])
```

Follow `nextPageToken` until a page has none. A scan is **complete** only when every page was read.

CLI fallback:

```bash
jira issue list -q '{JQL}' --plain --columns key,summary,status,updated --paginate 0:100
```

### Fetch a ticket in full (connector)

```
mcp__claude_ai_Atlassian_Rovo__getJiraIssue(cloudId, issueIdOrKey,
  fields=["summary","description","status","priority","issuetype","labels","parent","issuelinks","comment","attachment","created","updated"])
```

Without an explicit `fields` list, comments, attachments and links come back **empty without error**. Attachments (authenticated content, `blob:` URLs) cannot be opened — list them by name and date, never claim to have read them.

### Post a comment (connector)

`mcp__claude_ai_Atlassian_Rovo__addCommentToJiraIssue` — same 3-step validation as above. Mentions need ADF (`[~accountid:…]` stays plain text in markdown).

## Status mapping

Provider status → Praxis status:

| Jira status                      | Praxis  |
| -------------------------------- | ------- |
| To Do / Open / Backlog           | todo    |
| In Progress                      | active  |
| In Review / Review / Code Review | review  |
| Done / Closed / Resolved         | done    |
| Blocked                          | blocked |

If unrecognized → keep original.

## URL pattern

```
https://{site}/browse/{KEY}
```

Where `{site}` comes from `praxis.json#site`.
