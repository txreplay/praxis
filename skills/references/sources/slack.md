# Source: Slack

> **Source contract**: Every chat source implements Prerequisites, Read channel history, Read a thread, Draft a message, React to a message, Author identity. Writes other than drafts and reactions are out of contract — a watcher never sends a chat message.

## Prerequisites

The claude.ai Slack connector (`mcp__claude_ai_Slack__*`). Load the tools with one `ToolSearch` call: `select:mcp__claude_ai_Slack__slack_read_channel,mcp__claude_ai_Slack__slack_read_thread`.

If a call fails (connector disconnected, auth expired): say so **once** in one line, skip the chat phase, keep the scan cursor unchanged so nothing is lost. The rest of the pass runs.

## Read channel history

```
mcp__claude_ai_Slack__slack_read_channel(channel_id="{channel}", oldest="{lastScanTs}", limit=100, response_format="concise")
```

Messages come newest first, each with author display name, email and local timestamp. Keep only messages strictly newer than `lastScanTs`. Follow `cursor` when `pagination_info` says more are available.

Scan cursor: the Slack `ts` of the newest message seen. When only a local timestamp is returned, convert it: `date -j -f "%Y-%m-%d %H:%M:%S" "<local>" +%s 2>/dev/null || date -d "<local>" +%s` (BSD, then GNU) → append `.000000`.

A converted timestamp is good enough for the scan cursor, never for a message reference: replies and reactions need the exact `ts`, microseconds included. `response_format="concise"` drops it; `"detailed"` prints `Message TS: <ts>` for each message. Store `slackTs` from the detailed form. A `slackTs` ending in `.000000` is a converted one: recover the exact value with `mcp__claude_ai_Slack__slack_search_public(keywords=["<PR number>"], filters="in:<#{channel}>")`, which returns `Message_ts`.

## Read a thread

```
mcp__claude_ai_Slack__slack_read_thread(channel_id="{channel}", message_ts="{slackTs}", oldest="{lastThreadTs}", response_format="detailed")
```

The channel history (above) returns only top-level messages newer than the cursor: a reply posted today in the thread of yesterday's request never shows up there. Reading the thread is the only way to see it. `oldest` keeps only newer replies, but the parent message comes back too — drop it (its `ts` equals `message_ts`). `"detailed"` gives each reply's exact `Message TS`, which becomes the new `lastThreadTs`.

## Draft a message

`mcp__claude_ai_Slack__slack_send_message_draft` — a draft the user sends themselves. Never `slack_send_message`.

## React to a message

```
mcp__claude_ai_Slack__slack_add_reaction(channel_id="{channel}", message_ts="{slackTs}", emoji="<name without colons>")
```

Emoji names, not characters: `eyes`, `speech_balloon`, `white_check_mark`, `x`. Adding a reaction already there succeeds silently. `mcp__claude_ai_Slack__slack_get_reactions` reads them back. The connector has **no tool to remove a reaction**: a reaction, once added, stays until someone removes it by hand. The reaction is posted as the connected user.

## Author identity

The display handle shown in the channel (the email local part, e.g. `jane.doe`) is what the user recognises. Store it as `slackUser`. It never maps reliably to a GitHub login; never derive one from the other.
