# Provider: Jira

> **Provider contract**: Every provider must implement these sections: Prerequisites, Commands (Fetch a ticket, List children of an epic, Transition a ticket, Post a comment, Create a ticket), Status mapping, URL pattern. Comments must include author and date. See this file as reference implementation.

## Prerequisites

Two transports. Use the **Atlassian connector** (MCP) when its tools are available; fall back to the **`jira` CLI** otherwise.

| Transport | When | Check |
| --------- | ---- | ----- |
| Atlassian connector (MCP, remote endpoint `https://mcp.atlassian.com/v2/mcp`) | Default: full fields, comments with author/date, ADF mentions, transitions by id, Confluence | Its tools are listed (or loadable via ToolSearch, e.g. `getJiraIssue`) |
| `jira` CLI ([jira-cli](https://github.com/ankitpokhrel/jira-cli)) | Fallback when the connector is absent; light JQL listings and scripts (compact plain output) | `which jira && jira me` |

Tool names below are given by suffix (`getJiraIssue`, …): the prefix depends on how the connector is installed (e.g. `mcp__claude_ai_Atlassian_Rovo__`). Load the deferred tools you need in **one** ToolSearch call.

The V2 connector has two layers: **primary tools** called directly (`getJiraIssue`, `searchJiraIssuesUsingJql`, `listJiraIssueComments`, `addOrEditJiraIssueComment`, `transitionJiraIssue`, `createJiraIssue`, `editJiraIssue`), and **catalog operations** run through `executeRead` / `executeWrite` / `executeDestructive({ name, cloudId, inputs })`. Only use an operation name listed here or returned by `discover` — never guess one. `cloudId` goes at the top level, never inside `inputs`.

`cloudId`: the site hostname from `praxis.json#site` works; `getAccessibleAtlassianResources` returns the UUID if needed. Resolve once per run.

If the connector warns that it runs on a deprecated endpoint, relay the warning once to the user (re-adding the connector moves it to the current endpoint) and carry on.

## Commands

### Fetch a ticket

Connector:

```
getJiraIssue(cloudId, issueIdOrKey={KEY}, responseContentFormat="markdown",
  fields=["summary","description","status","priority","issuetype","labels","parent","subtasks","issuelinks","comment","attachment","created","updated"])
```

Without an explicit `fields` list, comments, attachments and links come back **empty without error**. `getJiraIssue` embeds at most 20 comments: beyond that, page them with `listJiraIssueComments(cloudId, issueIdOrKey, startAt)` until `isLast`. A comment's `updated` later than its `created` means it was edited — compare with the local copy, not only the comment count. Attachments (authenticated content, `blob:` URLs) cannot be opened — list them by name and date, never claim to have read them.

CLI fallback:

```bash
jira issue view {KEY} --plain --comments 50
```

Extract: `summary`, `description`, `status.name`, comments (author, date, body).

### List children of an epic

Try these JQL queries in order, stop at the first result:

1. `parent = {KEY} ORDER BY key ASC`
2. `"Epic Link" = {KEY} ORDER BY key ASC`

Connector: `searchJiraIssuesUsingJql(cloudId, jql, maxResults=100, fields=["key","summary","status","priority","assignee","issuetype"])`, then **Fetch a ticket** for each child. The parent's `subtasks` field (above) already lists sub-tasks with their status.

CLI fallback:

```bash
jira issue list -q '{JQL}' --plain --columns key,summary,status,priority,assignee
jira issue view {CHILD_KEY} --plain
```

### Search tickets (used by `/praxis-watch-tickets`)

Connector:

```
searchJiraIssuesUsingJql(cloudId, jql, maxResults=100,
  fields=["key","summary","status","issuetype","parent","updated","created","priority","labels"])
```

Follow `nextPageToken` until a page has none. A scan is **complete** only when every page was read.

CLI fallback:

```bash
jira issue list -q '{JQL}' --plain --columns key,summary,status,updated --paginate 0:100
```

### Transition a ticket

Workflows differ per project: never guess a transition name.

Connector:

1. `executeRead(name="listJiraIssueTransitions", cloudId, inputs={"issueIdOrKey": "{KEY}"})` → available transitions (`id`, `name`, target status)
2. Pick the one whose **target status** matches the Praxis status below (a transition's name is not its target); if none or several match, ask the user
3. `transitionJiraIssue(cloudId, issueIdOrKey={KEY}, transition={"id": "{ID}"})`

A target status may need several hops (e.g. `Backlog → To Do → In Progress`): chain them, re-reading the transitions after each hop. `transitionJiraIssue` returns the status the issue landed in — no read-back needed.

CLI fallback:

```bash
jira issue move {KEY} "{TRANSITION_NAME}"
```

Status mapping (Praxis → target status category):

| Praxis  | Jira target (typical names)       |
|---------|-----------------------------------|
| active  | In Progress                       |
| review  | In Review / Code Review           |
| done    | Done                              |

### Post a comment

> **🛑 MANDATORY — NEVER post a comment without explicit validation.**
>
> A user instruction like "poste un commentaire pour dire X" / "add a comment" / "comment on Jira" is a **drafting request**, NOT a send authorization. Jira comments are public and visible to the team and potentially to the client — once sent, they can only be deleted manually.
>
> **Required 3-step workflow**:
> 1. Write the draft to `/tmp/praxis-comment-{KEY}.md`
> 2. **Display the FULL comment content inline in the chat** (not a summary, not just a path) and explicitly ask: "Je poste ? / Validate to send?"
> 3. Wait for an explicit "ok" / "poste" / "valide" / "envoie" / "yes, send" before sending
>
> Auto mode, praxis workflow, or any other running context does NOT override this rule.

Connector:

```
addOrEditJiraIssueComment(cloudId, issueIdOrKey={KEY}, commentBody={comment})   # markdown by default
```

- **Mentions** need `contentFormat="html"` with `<span data-type="mention" data-user-id="{accountId}">@Name</span>`; `[~accountid:…]` and `@Name` stay plain text in markdown. Resolve the account with `executeRead(name="lookupJiraAccountId", cloudId, inputs={"query": "{name}"})` — never invent an id. Other rich shapes: `executeRead(name="getContentFormatGuide", cloudId, inputs={"toolName": "addOrEditJiraIssueComment"})`.
- **Fix a posted comment** with the same tool and `commentId` (from `listJiraIssueComments`) rather than posting a second one. An edit replaces the whole body; if it holds mentions or media, fetch it with `responseContentFormat="html"` and write it back in HTML, or they are lost.

CLI fallback (no mentions):

```bash
cat <<'EOF' > /tmp/praxis-comment-{KEY}.md
{comment}
EOF
jira issue comment add {KEY} --template /tmp/praxis-comment-{KEY}.md --no-input
```

### Create a ticket

Connector:

```
createJiraIssue(cloudId, projectKey={PROJECT}, issueTypeName="Story", parent={EPIC_KEY},
  summary={SUMMARY}, description={DESCRIPTION}, contentFormat="markdown")
```

For a sub-task, use the project's sub-task type name (`executeRead(name="listJiraProjectIssueTypesMetadata", cloudId, inputs={"projectIdOrKey": "{PROJECT}"})` lists them, with a `subtask` flag). The result carries the new key.

CLI fallback:

```bash
jira issue create --type Story --parent {EPIC_KEY} --summary "{SUMMARY}" --body "{DESCRIPTION}" --no-input
```

If `--parent` is not supported (older Jira / classic projects), use epic link:

```bash
jira issue create --type Story --custom epic-link={EPIC_KEY} --summary "{SUMMARY}" --body "{DESCRIPTION}" --no-input
```

The command returns the created ticket key (e.g., `KEY-40001`). Parse it from stdout.

## Status mapping

Provider status → Praxis status:

| Jira status                      | Praxis  |
| -------------------------------- | ------- |
| To Do / Open / Backlog           | todo    |
| In Progress                      | active  |
| In Review / Review / Code Review | review  |
| Done / Closed / Resolved         | done    |
| Blocked                          | blocked |

With the connector, `status.statusCategory.key` (`new` / `indeterminate` / `done`) disambiguates localized or custom names. If unrecognized → keep original.

## URL pattern

```
https://{site}/browse/{KEY}
```

Where `{site}` comes from `praxis.json#site`.
