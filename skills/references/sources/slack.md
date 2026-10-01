# Source: Slack

> **Source contract**: Every chat source implements Prerequisites, Read channel history, Read a thread, Draft a message, Author identity. Writes other than drafts are out of contract — a watcher never sends a chat message.

## Prerequisites

The claude.ai Slack connector (`mcp__claude_ai_Slack__*`). Load the tools with one `ToolSearch` call: `select:mcp__claude_ai_Slack__slack_read_channel,mcp__claude_ai_Slack__slack_read_thread`.

If a call fails (connector disconnected, auth expired): say so **once** in one line, skip the chat phase, keep the scan cursor unchanged so nothing is lost. The rest of the pass runs.

## Read channel history

```
mcp__claude_ai_Slack__slack_read_channel(channel_id="{channel}", oldest="{lastScanTs}", limit=100, response_format="concise")
```

Messages come newest first, each with author display name, email and local timestamp. Keep only messages strictly newer than `lastScanTs`. Follow `cursor` when `pagination_info` says more are available.

Scan cursor: the Slack `ts` of the newest message seen. When only a local timestamp is returned, convert it: `date -j -f "%Y-%m-%d %H:%M:%S" "<local>" +%s` → append `.000000`.

## Read a thread

```
mcp__claude_ai_Slack__slack_read_thread(channel_id="{channel}", message_ts="{slackTs}")
```

## Draft a message

`mcp__claude_ai_Slack__slack_send_message_draft` — a draft the user sends themselves. Never `slack_send_message`.

## Author identity

The display handle shown in the channel (the email local part, e.g. `jane.doe`) is what the user recognises. Store it as `slackUser`. It never maps reliably to a GitHub login; never derive one from the other.
