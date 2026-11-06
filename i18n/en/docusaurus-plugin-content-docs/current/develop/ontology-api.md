---
title: Ontology API
sidebar_label: Ontology API
sidebar_position: 4
description: Ontology API reference for application integration, including authentication, base paths, and endpoint groups with cURL examples.
---

The Ontology API lets applications read ontology definitions, query records, calculate metrics, manage drafts and deployments, import and export definitions, and submit action requests. This page is for integration developers and lists the business endpoints; query syntax is in [Ontology Query DSL](ontology-query-dsl.md).

## Authentication

Every request sends the header `Authorization: Bearer <JWT>` with a token issued by Keycloak. See [Integration overview](index.md) for how to get a token. The tenant and user come from the token and are not sent in the body.

| Element | Usage |
|---|---|
| Token | Header `Authorization: Bearer <JWT>`; an expired token returns 401. |
| Role | `ontology-viewer`, `ontology-editor`, `ontology-admin`; missing permission returns 403. |
| Workspace | Parameter `?workspace=<slug>` for runtime endpoints when multiple workspaces are published. |
| Data | Queries run on behalf of the caller; the query engine's row access and masking still apply. |

When multiple workspaces are published and the request does not specify a workspace, the API can reject the request instead of choosing implicitly.

## Base paths

Endpoints use the common prefixes below, placed after your deployment's gateway domain.

| Group | Prefix |
|---|---|
| Definitions, queries, authoring | `/api/v1/ontology` |
| Runtime metrics | `/api/v1/runtime` |
| System administration (workspaces, templates) | `/api/v1/system` |

In the tables below, `{type_name}` is the API name of the object type, `{pk}` is the primary key, `{workspace}` is the slug, and `{link_name}` is the link type name. Paths in the tables are relative to the prefix `/api/v1/ontology` unless noted otherwise.

## cURL examples

```bash
curl -s "https://<HANAS_HOST>/api/v1/ontology/object-types" \
  -H "Authorization: Bearer $TOKEN"
```

```bash
curl -s -X POST \
  "https://<HANAS_HOST>/api/v1/ontology/query/objects/Customer/list?workspace=banking" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"filters":[{"property":"branch_code","op":"eq","value":"001"}],"page_size":20,"direction":"first"}'
```

Returned errors always include `detail`, `code`, `message`, and `request_id`; the `X-Request-ID` header has the same value. See the errors section in [Query DSL](ontology-query-dsl.md).

## Definition

Read published definitions.

| Method | Path | Purpose |
|---|---|---|
| GET | `/object-types` | Catalog of object types and properties. |
| GET | `/object-types/{type_id}` | One object type by UUID. |
| GET | `/links` | Link types; can be filtered by object type. |
| GET | `/shared-property-types` | Shared property types. |
| GET | `/interfaces` | Interfaces and the object types that implement them. |
| GET | `/action-types` | Action definitions. |
| GET | `/metrics` | Metric catalog. |
| GET | `/audit-log` | Tenant audit log (admin). |
| POST | `/inspect-dataset` | Dataset columns, with optional data sample and a bounded key profile. |
| GET | `/metadata/datasets` | List of datasets. |
| GET | `/metadata/sources`, `/metadata/schemas`, `/metadata/tables`, `/metadata/views` | Browse sources, schemas, tables, views. |

Definition responses have an ETag and `Cache-Control: private, no-cache`.

## Query

Prefix `/query`. The bodies and examples for these endpoints are in [Query DSL](ontology-query-dsl.md).

| Method | Path | Purpose |
|---|---|---|
| POST | `/query/objects/{type_name}/list` | List, filter, sort, paginate. |
| POST | `/query/objects/{type_name}/search` | Prefix search on `searchable` properties. |
| POST | `/query/objects/{type_name}/aggregate` | Histogram or multi-metric aggregation by group. |
| GET | `/query/objects/{type_name}/{pk}` | Read one record. |
| GET | `/query/objects/{type_name}/{pk}/latest-date` | Latest date related to the record. |
| POST | `/query/objects/{type_name}/{pk}/links/{link_name}/query` | Traverse one link hop. |
| POST | `/query/objects/{type_name}/links/{link_name}/list` | List records with the linked dataset. |
| POST | `/query/objects/{type_name}/{pk}/links/{link_name}/aggregate` | Aggregate the target set after one hop. |
| POST | `/query/objects/{type_name}/links/{link_name}/aggregate` | Join aggregation at the object type level. |
| POST | `/query/objects/{type_name}/{pk}/links/{link1}/{link2}/query` | Traverse two link hops. |
| POST | `/query/objects/{type_name}/{pk}/links/{link1}/{link2}/aggregate` | Aggregate after two hops. |
| POST | `/query/interfaces/{interface_name}/list` | List across the object types that implement the interface. |

There are also GET endpoints for quick one-hop and two-hop link reads, and date context endpoints for the record graph (`graph/date-context`, `graph/resolve-snapshot`).

:::note Requirements

The graph expansion endpoint `graph/expand` requires the corresponding graph feature to be enabled in the deployment.

:::

### Object set

| Method | Path | Purpose |
|---|---|---|
| GET, POST | `/object-sets` | List or save object sets. |
| GET, PUT, DELETE | `/object-sets/{set_id}` | Open, edit, or delete, based on ownership. |

## Metrics

| Method | Path | Purpose |
|---|---|---|
| GET | `/api/v1/runtime/object-types/{type_name}/metric-placements` | Where metrics are displayed in lists and details. |
| POST | `/api/v1/runtime/object-types/{type_name}/metrics/aggregate` | Calculate one metric by filter and context. |
| POST | `/api/v1/runtime/object-types/{type_name}/{pk}/metrics` | Calculate metrics for one record and a selected date. |

## Workspace authoring

Prefix `/workspaces/{workspace}`. Requires `ontology-editor` unless noted otherwise.

| Method | Path | Purpose |
|---|---|---|
| GET | `/workspace` | Authoring state and revision pointer. |
| GET | `/workflow` | Summary of draft, readiness, and runtime. |
| GET | `/revisions`, `/revisions/{revision_id}` | List and content of revisions. |
| POST | `/drafts` | Save a draft with revision control and checksum. |
| POST | `/drafts/blank`, `/drafts/import` | Create a blank draft or import YAML or JSON. |
| POST | `/templates/{template_id}/instantiate` | Create a draft from a template. |
| POST | `/revisions/{revision_id}/draft` | Create a change draft from a revision. |
| DELETE | `/drafts/{draft_id}` | Discard an open draft. |
| POST | `/drafts/{draft_id}/mapping` | Save the mapping document and manifest. |
| POST | `/drafts/{draft_id}/automap` | Automatically propose sources, columns, keys, and relationships. |
| POST | `/drafts/{draft_id}/source-proposals`, `/mapping-analysis`, `/mapping-preview` | Propose sources, analyze, and preview mapping. |
| POST | `/validate-preview`, `/drafts/{draft_id}/validate` | Validate unsaved content or a draft. |
| POST | `/drafts/{draft_id}/preview/{concept}/records` | Preview a list of records based on the draft. |
| PUT, DELETE | `/metrics/{name}` | Create, edit, or delete a metric in the draft. |
| POST | `/metrics/{name}/validate`, `/metrics/{name}/compile-preview` | Validate and compile-preview a metric. |
| POST | `/drafts/{draft_id}/preview-publish` | Check the release and its impact. |
| POST | `/drafts/{draft_id}/submit` | Submit the draft for approval. |
| POST | `/drafts/{draft_id}/withdraw` | Withdraw a submitted draft. |
| POST | `/drafts/{draft_id}/reject` | Reject a draft (admin). |
| POST | `/drafts/{draft_id}/publish` | Approve and activate (admin). |
| POST | `/revisions/{revision_id}/rollback` | Roll back through the release gate (admin). |

## Deployment

Prefix `/workspaces/{workspace}/deployments`. Requires `ontology-admin`.

| Method | Path | Purpose |
|---|---|---|
| POST | `/prepare` | Prepare a deployment from an approved revision; requires the `Idempotency-Key` header. |
| POST | `/{deployment_id}/health-check` | Check the status. |
| GET | `/{deployment_id}/preview-activate` | View the activation impact. |
| POST | `/{deployment_id}/activate` | Activate, with a generation check. |

## Portability

| Method | Path | Purpose |
|---|---|---|
| POST | `/workspaces/{workspace}/exports/{package_type}` | Export a `ossie`, `mapping`, or `bundle` package. |
| POST | `/workspaces/{workspace}/imports` | Upload a package and create an import session. |
| GET | `/workspaces/{workspace}/imports/{session_id}` | View the session and reconciliation decisions. |
| PATCH | `/workspaces/{workspace}/imports/{session_id}/decisions/{decision_id}` | Choose how to handle one resource. |
| POST | `/workspaces/{workspace}/imports/{session_id}/decisions/bulk` | Apply decisions in bulk. |
| POST | `/workspaces/{workspace}/imports/{session_id}/apply` | Apply the import to a draft. |

Export responses have the header `X-Package-Checksum`. For the process, see [Ontology governance](../ontology/governance.md).

## System workspaces and templates

Prefix `/api/v1/system`, requires `ontology-admin`.

| Method | Path | Purpose |
|---|---|---|
| GET, POST | `/workspaces` | List or create workspaces. |
| GET, PATCH | `/workspaces/{workspace}` | Read or edit metadata. |
| POST | `/workspaces/{workspace}/archive`, `/workspaces/{workspace}/unarchive` | Archive or restore. |
| GET, POST | `/ossie-templates` | List or create templates. |
| POST | `/ossie-templates/{template_id}/versions` | Upload a version. |

## Action request

| Method | Path | Purpose |
|---|---|---|
| POST | `/query/objects/{type_name}/{pk}/actions/{action_name}/requests` | Submit a request for a record. |
| GET | `/query/objects/{type_name}/{pk}/action-requests` | Requests of a record. |
| GET | `/action-requests/mine` | Your requests. |
| GET | `/action-requests/approvals` | Approval inbox. |
| POST | `/action-requests/{request_id}/approve`, `/reject`, `/cancel` | Approve, reject, cancel. |
| GET | `/action-requests/external` | Approved requests for workers. |
| POST | `/action-requests/{request_id}/claim`, `/complete`, `/fail`, `/retry` | Worker processing cycle. |

The legacy action execution endpoint is blocked; see [Actions](../ontology/actions.md).

## Agent

A reduced set of endpoints for assistants and agents. They use the same permissions as regular queries.

| Method | Path | Purpose |
|---|---|---|
| GET | `/agent/catalog` | Compact catalog; searches and ranks metadata. |
| POST | `/agent/query` | List, filter, sort. |
| POST | `/agent/search` | Prefix search. |
| POST | `/agent/aggregate` | Aggregate by group. |
| GET | `/agent/get/{type_name}/{pk}` | Read one record. |
| POST | `/agent/traverse` | Traverse one link hop. |

## Error codes

| Code | Meaning |
|---|---|
| 401 | Missing or expired token. |
| 403 | Missing role. |
| 404 | Resource does not exist. |
| 409 | State or revision conflict. |
| 422 | Invalid DSL or validation failure in the request. |
| 429 | Request budget exhausted. |
| 502, 503, 504 | Service error or timeout; some include `retryable` and `Retry-After`. |

## Next steps

- [Ontology Query DSL](ontology-query-dsl.md).
- [Integration overview](index.md) for how to get a token.
- [Ontology Workspace](../ontology/workspace.md) for the authoring flow.
