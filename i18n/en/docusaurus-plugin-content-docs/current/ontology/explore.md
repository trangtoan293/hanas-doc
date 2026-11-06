---
title: Explore objects
sidebar_label: Explore objects
sidebar_position: 5
description: Find object types, filter and search records, build quick charts, and view record details, relationships, and graphs.
---

**Explore** is where business users read data published through the ontology, without writing SQL. This page shows you how to find objects, filter lists, view details, and follow relationships between records.

## Requirements

- The `ontology-viewer` role or higher, and data read permission in the query engine.
- The workspace has an active deployment; object types are mapped.
- When multiple workspaces are published, select the correct workspace before browsing.

Explore runs queries with your identity. Row access and masking in the query engine still apply.

## Catalog

Open **Explore** to select a project and view the catalog of published objects.

- Search by name, description, field, or metric. This filters metadata; it is not a full-text search over records.
- Filter by the **All**, **Object**, or **Snapshot** group.
- View the card for each object type, along with a panel that explains fields, relationships, and metrics.
- Open an object type to go to its record list. The ontology graph at the type level shows how object types are linked to each other; it is not a record graph.

## Record list

1. Select an object type to open the record table.
2. Enter a keyword to search across `searchable` properties.
3. Add simple filters or build an AND, OR, NOT condition tree.
4. Choose the sort column and page size.
5. Use the first, previous, next, and last page buttons to browse.

Pagination uses a keyset cursor, so results stay stable as you move between pages. When you select a relationship, the table shows additional columns from the linked record and lets you filter or sort by data on that side.

:::note Requirements

An object type with `require_filter` enabled does not open its list until a valid condition is set, to avoid scanning the entire dataset.

:::

### Facets

The facet panel lists the values of dimension properties with their counts. Select a value to add it as a filter. Search mode has limits when combined with facets, charts, and filters; if a combination is unavailable, the UI does not let you run them together.

### Saved object sets

You can save a query and its display state as an object set, either private or shared within the tenant. When you reopen it, the query reruns with the reader's identity and the cursor returns to the first page. If a change to the ontology definition makes the query invalid, the set is marked `broken` instead of keeping stale data.

## Quick charts

The **Quick chart** dialog offers the following templates, chosen according to the property type and capabilities.

| Chart | Use for |
|---|---|
| Pie, bar | Distribution by one group. |
| Trend (area) | Trend by day, week, month, quarter, or year. |
| Histogram | Distribution of numbers by range. |
| Stacked | Distribution by two groups. |
| Scatter | Relationship between two measured values. |

Aggregate charts use the current filters and can use the selected linked dataset. Scatter and histogram ranges are derived from the sample rows of the current page, so they do not reflect all the data. Selecting a chart column can add a corresponding filter.

## Record details

Open a row to view the detail page: title and identity, property summary, subtype badge, and the metrics [placed](metrics.md) on the detail page. The action area appears when the object type has actions; see [Actions](actions.md).

For snapshot data, select a date to view the record and metrics for that date. The system suggests the latest date that has data.

## Relationships and linked records

The **Relationships 360** section lists the record's link types, with forward and reverse labels. A self-link has two separate directions.

1. Open a relationship to view the linked records.
2. Filter, search, sort, and paginate that list, or view the aggregate.
3. Expand a second relationship from the linked record to go up to two hops.

Not seeing a linked record may mean the ontology has not declared the relationship, or the mapping does not cover the data. It does not prove from a business standpoint that no relationship exists.

## Record graph

Open **Graph** from the detail page to view a graph centered on the record, with relationship ports and neighboring records.

- Only the links that the graph policy allows are shown.
- Click to expand gradually; the system avoids repeating the same record.
- Choose the forward or reverse direction, inspect a record, change the graph center, and go back to the previous record.
- Select a date or snapshot when the data has date context.

The UI currently fetches up to 8 neighboring records per expansion and 20 records per page of related lists.

## Limitations

:::caution Current limitations

Catalog search only filters metadata. Scatter and histogram are based on the page's sample rows. The UI currently has no shortest-path feature on the record graph.

:::

## Troubleshooting

| Symptom | Resolution |
|---|---|
| Object type not visible | Check the correct workspace and serving deployment. |
| List requires a filter | The object type has `require_filter` enabled; add a condition. |
| Empty list | Check data read permission, filters, and the snapshot date. |
| Object set reports `broken` | Reopen it and fix the query according to the new definition. |

## Next steps

- [Metrics](metrics.md) to understand the numbers on a record.
- [Actions and change requests](actions.md).
- [Ontology Query DSL](../develop/ontology-query-dsl.md) to reproduce the same query through the API.
