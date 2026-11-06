---
title: Ontology Query DSL
sidebar_label: Ontology Query DSL
sidebar_position: 5
description: Query DSL syntax to list, filter, search, aggregate, and traverse links between object types, with JSON request and response examples.
---

Query DSL is a JSON format for querying records by ontology without writing SQL. This page is for application developers; endpoints and authentication are in [Ontology API](ontology-api.md).

The planner checks each request against the declared properties and capabilities, then generates the query. A request cannot send free-form SQL. Property names must use the exact API names in the published definition; the examples below assume the object type `Customer` with the properties shown in the examples.

## General conventions

The base path is `/api/v1/ontology/query`. Send `Authorization: Bearer <JWT>` and `?workspace=<slug>` when multiple workspaces are published. Queries run on behalf of the caller.

| Element | Rule |
|---|---|
| Flat filter | `[{"property":"branch_code","op":"eq","value":"001"}]`, combined with AND. |
| Operators | `eq`, `neq`, `gt`, `gte`, `lt`, `lte`, `in`, `contains`, `is_null`, `not_null`. |
| Condition tree | `node_type` is `group` or `clause`; a group has `combinator` (`and`, `or`), `negated`, `children`. |
| Operators in a tree | Adds `between` (two values); `in` needs a non-empty `values`; null operators take no value. |
| Tree limits | Maximum depth 6, maximum 100 nodes. |
| Field source | `source` is `base` or `linked`; `linked` is valid only when the operation has a join. |
| Sort | `[{"property":"name","dir":"asc","source":"base"}]`; the system adds the primary key automatically to keep the order stable. |
| Date | `as_of_date` follows the object type's date policy; it does not apply to search. |

A property must have the corresponding capability enabled: `filterable` for filter, `sortable` for sort, `searchable` for search, `aggregatable` for grouping and aggregation.

The `contains` operator matches substrings, is case-insensitive, and creates one condition per keyword, combined with AND. It differs from prefix search.

## List and keyset pagination

```http
POST /api/v1/ontology/query/objects/Customer/list?workspace=banking
Authorization: Bearer <JWT>
Content-Type: application/json
```

```json
{
  "filters": [{"property": "branch_code", "op": "eq", "value": "001"}],
  "sort": [{"property": "customer_id", "dir": "asc"}],
  "page_size": 20,
  "direction": "first",
  "include_linked_columns": true
}
```

Response:

```json
{
  "items": [{"customer_id": "C001", "name": "Customer A", "branch_code": "001"}],
  "next_cursor": null,
  "previous_cursor": null,
  "has_next": false,
  "has_previous": false
}
```

| Parameter | Description |
|---|---|
| `page_size` | Default 20; there is a configurable cap, default 200. |
| `direction` | `first`, `next`, `previous`, or `last`. |
| `cursor` | An opaque string taken from `next_cursor` or `previous_cursor` of the previous response. |

To go to the next page, resend the same filter and sort, with `direction: "next"` and the `cursor` you received. Do not build a cursor or OFFSET yourself. If you change the filter or sort, go back to `direction: "first"`.

Read a single record by key: `GET /objects/Customer/C001`. The response is the record's object, without a pagination envelope.

## Advanced filters

Use `filter_expression` instead of `filters` when you need OR, NOT, or nesting.

```json
{
  "filter_expression": {
    "node_type": "group", "combinator": "and", "negated": false,
    "children": [
      {"node_type": "clause", "property": "branch_code", "operator": "in", "values": ["001", "002"]},
      {"node_type": "group", "combinator": "or", "children": [
        {"node_type": "clause", "property": "age", "operator": "between", "values": [30, 50]},
        {"node_type": "clause", "property": "segment", "operator": "eq", "value": "VIP"}
      ]}
    ]
  },
  "page_size": 20
}
```

## Search

Search finds records by prefix on `searchable` properties.

```http
POST /api/v1/ontology/query/objects/Customer/search
```

```json
{"q": "Ng", "page_size": 20}
```

A search request has only `q`, `page_size`, `cursor`, and `direction`; it has no filter or date. The response has the same form as list.

## Aggregate

Aggregate groups records and calculates measures.

```http
POST /api/v1/ontology/query/objects/Customer/aggregate?workspace=banking
```

```json
{
  "group_by": [{"property": "branch_code", "bucket": "exact"}],
  "metrics": [{"op": "count"}],
  "max_buckets": 100
}
```

```json
{
  "group_by": ["branch_code"],
  "metrics": ["count"],
  "buckets": [{"key": {"branch_code": "001"}, "metrics": {"count": 42}}]
}
```

| Element | Values |
|---|---|
| `bucket` | `exact`, `by_day`, `by_week`, `by_month`, `by_quarter`, `by_year`, `by_ranges`. |
| Inline metric | `op` is `count`, `sum`, `avg`, `min`, `max`, or `cardinality`, with `property` and `source`. |
| Named metric | `{"metric": "total_balance"}`; do not combine with `op` or `property`. |
| Limit | `max_buckets` defaults to 100. |

The metric keys in the response are generated by the system from `op` and the property; for count, the key is `count`. A named metric can be used only when the metric is `executable` and fits the operation; see [Metrics](../ontology/metrics.md).

Simple histogram form:

```json
{"property": "branch_code", "top_k": 20}
```

```json
{"property": "branch_code", "buckets": [{"value": "001", "cnt": 42}]}
```

## Traverse links

One hop, from one record, with filter, sort, and cursor:

```http
POST /api/v1/ontology/query/objects/Customer/C001/links/customer_accounts/query
```

```json
{"q": "SAV", "page_size": 20, "direction": "first"}
```

Two hops use `mid_filters` to filter the intermediate step; filter, sort, group, and metric apply to the target:

```http
POST /api/v1/ontology/query/objects/Customer/C001/links/customer_accounts/account_transactions/query
```

```json
{"mid_filters": [{"property": "status", "op": "eq", "value": "ACTIVE"}], "page_size": 20}
```

A list at the object type level with the linked dataset uses `/objects/Customer/links/customer_accounts/list`, where filter and sort can set `source` to `linked`. Aggregation after a link uses the corresponding `.../aggregate` endpoints; see [Ontology API](ontology-api.md).

## Interface

```http
POST /api/v1/ontology/query/interfaces/Account/list
```

The result contains the shared property columns and a `__type` field that shows each record's object type.

:::caution Current limitations

An interface query is a bounded list that uses only flat filters on shared properties. The request's cursor, sort, `filter_expression`, and `page_size` are not yet applied as they are for object type queries.

:::

## Errors

Returned errors keep `detail` and add `code`, `message`, and `request_id`; the `X-Request-ID` header has the same value.

```json
{
  "detail": "Property 'age' is not filterable",
  "code": "validation_error",
  "message": "Property 'age' is not filterable",
  "request_id": "<request-id>"
}
```

| Code | Common cause |
|---|---|
| 401 | Missing or expired token. |
| 403 | Missing role. |
| 404 | The object type, record, or link does not exist in the workspace. |
| 409 | State conflict. |
| 422 | Invalid DSL: property lacks the capability, invalid operator, or tree too deep or too large. |
| 429 | Request budget exhausted. |
| 502, 503, 504 | Query engine or service error or timeout; retry according to `Retry-After` if present. |

The `code` values and `message` text in the examples are illustrative only; use the HTTP code to handle errors.

## Troubleshooting

| Symptom | Resolution |
|---|---|
| 422 with a valid property | Check the property's capabilities in the definition. |
| Cursor rejected | Reuse the same filter and sort as the request that produced the cursor. |
| Empty result on a snapshot dataset | Pass `as_of_date` or check the latest date. |
| Multiple workspaces, missing scope error | Add `?workspace=<slug>`. |

## Next steps

- [Ontology API](ontology-api.md) for the endpoint list.
- [Explore objects](../ontology/explore.md) for the interface experience.
- [Metrics](../ontology/metrics.md) for named metrics.
