---
title: Safety and access control in Kapas
sidebar_label: Safety
sidebar_position: 4
description: Which identity Kapas uses to query data, how read-only SQL is controlled, the role of the sandbox, and the administration limits to know.
---

This page honestly describes how Kapas protects data and where you should not make assumptions. Administrators should read it before giving Kapas to many users.

## Principles

Kapas does not grant data permissions on its own. Table, row, and column permissions are decided by the query engine, Ontology, Superset, and dbt Studio. Kapas tries to call these services with your identity; some paths have exceptions, listed below.

## Query identity

| Integration | Runs as | Notes |
|---|---|---|
| query engine (Kapas Console) | End user | Kapas uses your query engine token, or exchanges your Keycloak token for a query engine token (RFC 8693). A missing or expired token produces an error; there is no fallback service account. |
| Ontology (objects, metrics, Concept, Mapping) | End user | Your JWT is forwarded; Ontology checks workspace permissions. |
| Superset | End user | Your token or a token exchanged for Superset; Superset must accept this token. |
| Knowledge Platform | End user | The token is exchanged for a dedicated audience; the search scope is limited by the target service. |
| Hanas Catalog | May be a shared account | If the token cannot be exchanged, Kapas signs in with a service account. This path cannot attribute actions to individuals. |
| dbt Studio | End user, with an exception | When the token is missing or the connection cannot be resolved, a legacy fallback path uses the token of a service account. |
| Embedded applications and the synchronous API | Depends on the host application | See below. |

:::caution Current limitations

With embedded integration, Kapas does not automatically forward the query engine token as Console does. The host application must send the end user's correct token in the request. If the host sends the wrong token or shares one token, queries run with that token's permissions. See [Embed Kapas](../develop/kapas-embed.md).

A Kapas API key represents a service account and does not act as a specific user. Do not use one shared key for the chats of multiple users.

Scheduled jobs have no user session; see [Reports and schedules](reports-and-schedules.md).

:::

Each user has a separate workspace, chat history, and memory. Kapas separates data per user, not per organization; colleagues do not automatically share agents or conversations.

## Read-only SQL

The query tools of Hanas Analyst and SQL Copilot accept only `SELECT` or `WITH` statements:

1. Keywords that change data or permissions (such as `INSERT`, `UPDATE`, `DELETE`, `DROP`, `CREATE`, `ALTER`, `TRUNCATE`, `MERGE`, `GRANT`, `REVOKE`) are blocked.
2. A statement without `LIMIT` gets `LIMIT 100` added.
3. `EXPLAIN` runs first, then execution; both steps have a timeout.

This is a string-pattern check, not a full SQL parser, and `LIMIT 100` is not a hard cap. The real protection is still your account's permissions in the query engine: if you have read-only permission, you cannot write even if a statement passes the check. Use workload management to limit resources, see [Engines, queues, and workload orchestration](../query/workload-management.md).

Tools that write to other systems (creating dashboards, editing metadata, writing dbt files) exist in the corresponding agents and are not bound by this read-only rule.

## Sandbox

There are two different layers:

| Layer | Purpose | Default in Hanas Helm |
|---|---|---|
| OS-level sandbox for tools | Restricts tools that run commands and access files | Production policy requires it to be on |
| Per-user remote execution space | Runs agent code in a dedicated Pod with resource and network limits | **Off** |

When the remote execution space is off, you should not describe the deployment as isolating every user at the container level. Enabling it requires a suitable runtime, storage, and network policy, and the default network policy may block access to internal endpoints.

Most Hanas data agents turn off shell, Python, file, and browser tools in their templates. Hanas Analyst's declaration is incomplete, so it may use some default tools such as running Python; administrators should review the tools enabled for each agent in Kapas Console.

## Approval and tool control

Kapas has a policy mechanism for tools with the outcomes allow, deny, and ask for confirmation. The approval level depends on the execution configuration:

- An instruction such as "always ask before creating" in a prompt only guides the model; it is not a mandatory gate.
- Many write tools default to allow. If the approval level is set to off, permission checks are skipped.
- Embedded applications receive approval request events through SSE and must display them to the user, see [Kapas API](../develop/kapas-api.md).

If you need a reliable confirmation gate for write operations, configure the approval level at the deployment level and test it before real use.

## Content guardrails

Kapas has a guardrails module (PII masking, input and output checks) and a configuration screen. This module is off by default and is not officially supported on the main chat flow. Do not treat it as a layer that blocks sensitive data.

## Administration limits

:::caution Current limitations

- Kapas does not contain row access or masking policies. Configure them in the query engine, see [Data access control](../govern/access-control.md).
- The catalog metadata and schema cache (300 seconds) is shared within one process and is not partitioned by user. In a multi-user environment, cached metadata may be returned to another user. Assess this risk before using it with sensitive metadata.
- The default deployment runs a single replica; request limits and token budgets apply per process and are soft limits.
- Agent access is a shared list granted by administrators; if the database fails while loading the list, the system may allow access instead of denying it.
- The administrator role is taken from the Keycloak role when a user is first created; later role changes may not sync immediately. Check again after changing a role, see [User management](../operate/user-management.md).
- Langfuse can be enabled for tracing; it is left empty by default, so it does not run.

:::

## Recommendations for administrators

1. Use Keycloak SSO for all Kapas users; do not use shared accounts.
2. Keep data permissions tight in the query engine; treat Kapas as having exactly the permissions of the user who is asking.
3. Review the tools enabled for each agent; turn off tools that are not needed.
4. For embedded integrations, verify the host sends the end user's correct token.
5. Monitor token usage and job history in the query engine for audit.

## Next

- [Authentication and SSO with Keycloak](../operate/identity.md)
- [Configure AI models](../operate/ai-models.md)
- [Data access control](../govern/access-control.md)
