---
title: Kapas API and SSE
sidebar_label: Kapas API
sidebar_position: 5
description: Authentication, the main Kapas endpoints, and the SSE event contract (contract v1) for integrating Kapas chat into your application.
---

This page is for developers who integrate Kapas over HTTP. It explains how to authenticate, create an agent for a context, send a message, and read the SSE event stream.

## Concepts

- **agent_id**: the identifier of the calling user's agent. You receive it from the API; you do not set it yourself.
- **session_id**: the conversation session. For templates that have a binding, Kapas creates it from the application context you send in `meta.app`.
- **meta.app**: the application context (for example, the current project). It is not an access permission; your application and the target service must still check permissions.
- All paths are under the `/api` prefix of the Kapas server. Access it through the gateway at the Kapas domain; see [API gateway and domain names](../operate/gateway.md).

## Authentication

Every request sends `Authorization: Bearer <token>`. Kapas accepts:

| Type | Used for |
|---|---|
| User Keycloak JWT | Standard integration, preserving the end-user identity. |
| API key (prefix `qpaw_`) | Service integration. The key belongs to a service account created by an admin and does not act as a specific user. |

The host application's backend authenticates the user first and then calls Kapas; do not let the browser hold a service key. For PATs and the platform's other authentication methods, see [Integration overview](index.md).

:::caution Current limitations

Kapas does not forward the query engine token for embedded requests. Send the end user's token in `meta.user_token` so downstream tools run with that person's permissions, and keep it consistent with the Bearer token. See [Safety in Kapas](../kapas/safety.md).

:::

## Main endpoints

| Purpose | Method and path |
|---|---|
| List agent templates | `GET /api/agents/templates` |
| Create an agent for a context (idempotent) | `POST /api/agents/ensure` |
| Compute IDs, create nothing | `POST /api/agents/resolve` |
| Streaming chat (SSE) | `POST /api/agents/{agentId}/embed/chat` |
| Stop a chat turn | `POST /api/agents/{agentId}/embed/chat/stop?chat_id=...` |
| Session history | `GET /api/agents/{agentId}/embed/sessions/{sessionId}/messages` |
| Session execution level | `GET`/`PUT /api/agents/{agentId}/embed/session/{sessionId}/execution-level` |
| Approve or deny a tool | `POST /api/approval/approve`, `POST /api/approval/deny`, `GET /api/approval/pending` |
| Synchronous call, returns JSON | `POST /api/agent/sync` |
| Liveness check | `GET /api/healthz` |

OpenAPI documentation (`/docs`) is usually disabled in production; this does not mean the API does not exist. The `healthz` endpoint reflects only that Kapas has started; it does not confirm that the query engine or Superset is running.

### Create an agent

```bash
curl -s -X POST "https://<kapas-host>/api/agents/ensure" \
  -H "Authorization: Bearer <end-user-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "template_id": "project-copilot",
    "meta": {"app": {"project_id": "project-123"}}
  }'
```

```json
{
  "agent_id": "project-copilot",
  "session_id": "project-project-123",
  "chat_id": null,
  "agent_created": true,
  "session_created": true
}
```

`ensure` only creates the agent. The chat is created at the first message, so `chat_id` can be `null`. Use the exact `agent_id` and `session_id` that are returned; do not assemble them yourself.

### Send a message

```bash
curl -N -X POST "https://<kapas-host>/api/agents/project-copilot/embed/chat" \
  -H "Authorization: Bearer <end-user-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Explain the model that is open",
    "session_id": "<session_id-from-ensure>",
    "stream": true,
    "meta": {
      "user_token": "<end-user-token>",
      "app": {"project_id": "project-123"}
    }
  }'
```

A template can require `meta.app` parameters; for example, Project Copilot needs `project_id`. Every template accepts `meta.app` after its type and characters are checked.

:::note Requirements

The embed channel exists only on agents that declare the `embed` channel: all system agents except Hanas Analyst. Hanas Analyst is used only in Kapas Console.

:::

## SSE contract v1

Each event line has the form `data: <json>` and ends with a blank line. The JSON is an envelope:

```json
{
  "contract_version": 1,
  "type": "token",
  "seq": 0,
  "session_id": "<session_id>",
  "data": {"text": "A piece of text"}
}
```

`seq` increases from 0 and never skips a number within a stream. Use it to detect lost events and drop duplicates. The client must ignore unknown `type` values and fields.

| `type` | `data` | Meaning |
|---|---|---|
| `token` | `{text}` | An incremental piece of text; concatenate in order to display the answer. |
| `tool_call` | `{call_id, tool, args}` | The agent is about to run a tool. |
| `tool_result` | `{call_id, ok, detail}` | The tool finished. `ok: false` means the tool failed but the agent continues. |
| `effect` | `{name, value}` | A declared effect, for example a request for the application to refresh the file list. |
| `approval_request` | `{request_id, tool, severity, params, timeout_seconds, ...}` | The stream pauses and waits for approval. |
| `ping` | `{}` | Keep-alive; ignore. |
| `error` | `{code, message}` | Stream-level error, terminal; always followed by `done`. |
| `done` | `{status, usage}` | End of stream, always the last event. |

`done.status` values: `completed`, `error`, `cancelled`, `incomplete`. The TypeScript SDK also generates the last two itself when you cancel the stream or the connection drops.

Example of a turn that calls a tool:

```text
data: {"contract_version":1,"type":"tool_call","seq":0,"session_id":"s1","data":{"call_id":"c1","tool":"list_boards","args":{}}}

data: {"contract_version":1,"type":"tool_result","seq":1,"session_id":"s1","data":{"call_id":"c1","ok":true,"detail":{}}}

data: {"contract_version":1,"type":"token","seq":2,"session_id":"s1","data":{"text":"The project has 2 boards."}}

data: {"contract_version":1,"type":"done","seq":3,"session_id":"s1","data":{"status":"completed","usage":{"total_tokens":0}}}
```

Order: `tool_call` comes before the `tool_result` with the same `call_id`; `effect` (if any) comes after `tool_result`. There is exactly one final `done` per stream.

### Approve a tool

When you receive `approval_request`, the stream waits until you call approve or deny:

```bash
curl -X POST "https://<kapas-host>/api/approval/approve" \
  -H "Authorization: Bearer <end-user-token>" \
  -H "Content-Type: application/json" \
  -d '{"request_id": "<request_id>", "session_id": "<session_id>"}'
```

Use `/api/approval/deny` with an optional `reason` to deny. Show the approval request to a real user; do not approve automatically.

### History

History differs from the live stream: each message has a `role` of `user`, `assistant`, or `tool`. Read it again when the user opens the session.

## Client implementation notes

:::caution Current limitations

- `tool_result.ok` can be `true` even when the embedded tool returns an error in its content. For write operations, check `detail` instead of relying only on this flag.
- Kapas does not reconnect automatically. When the stream drops, the client must reconnect and drop duplicates by `seq`, then read the history to get the missing part.
- The `error.message` text is meant to be safe for users, but it can contain error content from the model provider; do not display it verbatim if you do not want to expose details.
- An API key represents a service account. Do not share it across the chats of multiple users.

:::

## Troubleshooting

| Symptom | Common cause | Resolution |
|---|---|---|
| `401` | Token is expired or has the wrong audience | Get a new token from Keycloak. |
| `ensure` fails with missing parameters | The template requires `meta.app` | Send the full `meta.app` for the template. |
| Stream stalls, receiving `ping` | Waiting for an `approval_request` | Call approve or deny. |
| Tool reports a missing token | `meta.user_token` was not sent | Send the end user's token. |
| Stream is cut off midway | The gateway or proxy limits timeout or buffering | Turn off SSE buffering and increase the timeout; see [API gateway](../operate/gateway.md). |

## Next steps

- [Embed Kapas in your application](kapas-embed.md)
- [Safety in Kapas](../kapas/safety.md)
- [Integration overview](index.md)
