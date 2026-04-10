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

Write the comment to a temp file to avoid shell escaping issues:

```bash
cat <<'EOF' > /tmp/praxis-comment.md
{comment}
EOF
jira issue comment add {KEY} --template /tmp/praxis-comment.md
```

### Create a ticket

```bash
jira issue create --type Story --parent {EPIC_KEY} --summary "{SUMMARY}" --body "{DESCRIPTION}" --no-input
```

If `--parent` is not supported (older Jira / classic projects), use epic link:

```bash
jira issue create --type Story --custom epic-link={EPIC_KEY} --summary "{SUMMARY}" --body "{DESCRIPTION}" --no-input
```

The command returns the created ticket key (e.g., `HUB-40001`). Parse it from stdout.

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
