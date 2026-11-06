---
title: Hanas Catalog API
sidebar_label: Catalog API
sidebar_position: 6
description: The endpoint groups of the Hanas Catalog API, including search, entity details, lineage, glossary, tags, and metadata ingestion.
---

The Hanas Catalog API is the REST API of the Hanas Catalog service. You use it to search data assets, read schema and lineage, manage glossary, tags, and ownership, and configure metadata ingestion. Hanas Console uses these same endpoints.

## Concepts

All endpoints are under `/api/v1`, and the service is served under the prefix `/catalog-api`. Through the gateway, the URL has the form `https://<host>/catalog-api/api/v1/...`; the service listens on port 8091 in the cluster.

- Entities are identified by `urn`. JSON data uses camelCase; times are epoch milliseconds.
- Reading catalog data is at the viewer level: any signed-in account can search, but results include only assets that the account is allowed to see in the query engine.
- Interactive OpenAPI documentation is at `/catalog-api/docs`; the health check is at `/catalog-api/health` (no token needed).

## Authentication and permissions

| Requirement | Details |
|---|---|
| Keycloak access token | Header `Authorization: Bearer <access_token>` for every endpoint except health. |
| Query engine session | A query engine session header (see the example below) when you read or modify query engine assets; a missing or expired session returns 401. |
| Role | Derived from the Keycloak roles `data-governance-*`: `viewer` (default, no role needed), `editor`, `admin`. |

Metadata ingestion and secret endpoints require the `admin` level; endpoints that write descriptions, tags, glossary, owners, and lineage require the `editor` level or higher. See [Data access control](../govern/access-control.md) and [Authentication and SSO](../operate/identity.md).

You can confirm your current role with `GET /api/v1/me`, which returns `username`, `displayName`, `role`, and the two flags `canManageIngestion` and `canManageSecrets`.

## Search and browse

| Endpoint | Function |
|---|---|
| `POST /catalog/search` | Full-text search with filters, sorting, pagination, and facets. |
| `POST /catalog/browse` | Browse the tree level by level (source, space, container). |
| `GET /catalog/display-name` | Display name from a `urn`. |
| `GET /catalog/tags` | Tags that exist in the store. |

```bash
curl -s -X POST "https://<host>/catalog-api/api/v1/catalog/search" \
  -H "Authorization: Bearer <access_token>" \
  -H "X-Dremio-Token: <session_token>" \
  -H "Content-Type: application/json" \
  -d '{"query": "transactions", "start": 0, "count": 10,
       "filters": [{"field": "_entityType", "values": ["DATASET"]}]}'
```

A request with an empty `query` or `*` returns everything; multiple keywords are combined with AND and match as prefixes on name, path, description, and column names. Set `count` to 0 if you need only the total and facets. The `filters` support fields such as entity type, platform, tag, owner, parent container, and description. The response contains `total`, the `entities` list, and `facets`.

## Entity details and lineage

| Endpoint | Function |
|---|---|
| `GET /catalog/entity?urn=...` | Details: schema, description, owner, tags, terms, view definition, profile. |
| `POST /catalog/entities` | Fetch multiple entities at once. |
| `POST /catalog/lineage` | Read the upstream and downstream lineage graph. |
| `GET /catalog/entity/assertions`, `GET /catalog/entity/runs` | Data quality check results and run history, when the connector brings in this data. |
| `GET /lineage/edges` | Lineage edges written through the API. |

Lineage written through the API takes two forms.

| Endpoint | Function |
|---|---|
| `POST /lineage` | Add or remove lineage edges as a patch, up to 1000 edges per call; supports `dryRun`. |
| `POST /lineage/sql` | Submit an executed SQL statement so the server parses table and column lineage from it. |

Lineage written through the API is not overwritten by a later metadata ingestion run. Automatically generated edges (for example, from a view definition) cannot be removed with `edgesToRemove`. See also [Lineage](../govern/lineage.md).

## Glossary, tags, and ownership

| Group | Endpoints |
|---|---|
| Tag | `GET/POST/PUT/DELETE /tags`, `GET /tags/detail`, `GET /tags/applied`, `PUT /tags/color` |
| Glossary | `GET /glossary/nodes`, `GET /glossary/children`, `GET /glossary/entity`, `GET /glossary/terms`, `POST/DELETE /glossary`, `PUT /glossary/name`, `PUT /glossary/parent`, `POST /glossary/related` |
| Attach to entity | `PUT /entity/description`, `POST /entity/tags`, `POST /entity/terms`, `POST /entity/owners`, `POST /entity/links` |
| Bulk descriptions | `POST /entity/descriptions` |

Attaching tags, terms, and owners accepts a list of entities in one request and has an optional `remove` flag to detach. See [Glossary, tags, and ownership](../govern/glossary-and-tags.md).

## Metadata ingestion

| Endpoint | Function |
|---|---|
| `GET /ingestion/source-types` | Available connector types. |
| `GET/POST /ingestion/sources`, `GET/PUT/DELETE /ingestion/sources/{id}` | Manage sources and recipes, including cron schedules. |
| `POST /ingestion/test-connection` | Test a connection with a recipe; returns an `id` to track it. |
| `POST /ingestion/sources/{id}/executions` | Run manually. |
| `GET /ingestion/executions`, `GET /ingestion/executions/{id}` | List and details of runs, status, and report. |
| `POST /ingestion/executions/{id}/cancel`, `.../rollback` | Cancel or roll back a run. |
| `POST /ingestion/sources/{id}/delete-data-preview`, `.../delete-data` | Preview and delete data that a source has written. |
| `GET/POST/PUT/DELETE /secrets` | Manage secrets used in recipes; values are never returned. |

The API does not run connectors directly: a request creates an execution, and a runner picks it up and processes it in the background. You track it by fetching the execution again until `status` is a final state such as `SUCCESS`, `FAILURE`, `CANCELLED`, or `TIMEOUT`. See [Metadata ingestion](../govern/metadata-ingestion.md).

:::caution Current limitations

Deleting a source's data returns 409 when the source is running or rolling back. Deletion requires the `admin` role and can be rejected if there are assets that the account cannot view.

:::

## Error conventions

```json
{ "status": 409, "message": "...", "detail": "..." }
```

401 when the token is missing or expired, 403 when below the required permission level, 404 when the entity does not exist (or you cannot view it), 409 when the name is a duplicate or another operation is writing. Repeating a lineage edge that already exists or removing an edge that does not exist is skipped, so it is safe to resend the whole request.

## Next steps

- [Search and discover data assets](../govern/catalog.md).
- [Integration overview and authentication](index.md).
- [Ports and endpoints](../reference/ports-and-endpoints.md).
