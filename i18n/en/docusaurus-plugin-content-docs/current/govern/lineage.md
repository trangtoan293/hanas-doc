---
title: Lineage
sidebar_label: Lineage
sidebar_position: 4
description: View upstream and downstream relationships between data assets, the sources that produce lineage, and current limitations.
---

Lineage shows where a dataset's data comes from and where it is used. You use it to assess impact before changing a schema and to trace discrepancies back to the source.

## Concepts

- Upstream: the assets that a dataset depends on.
- Downstream: the assets that use this dataset, such as views, dbt models, or dashboards.
- Table-level lineage connects datasets to each other. Column-level lineage connects each output column to its source columns, when enough data is available.

## View lineage

1. Find and open the dataset in Hanas Catalog. See [Catalog](catalog.md).
2. Open the **Lineage** tab; a summary also appears in the Summary section.
3. Select a node to see details and expand the graph step by step.
4. Use filters to narrow the related assets when you analyze impact.

For column-level lineage, open a column in the Schema tab to see the source columns when data is available.

## Where lineage comes from

| Source | Content |
|---|---|
| Metadata ingestion | Connectors bring relationships between datasets, jobs, and dashboards when the source provides them. See [Metadata ingestion](metadata-ingestion.md). |
| dbt | Relationships between models and sources, built from the project's dbt manifest. |
| View and job SQL | Hanas Catalog can infer table-level and column-level lineage from SQL statements. |
| Manual declaration | Editors can add lineage through the catalog API. See [Hanas Catalog API](../develop/catalog-api.md). |

## Current limitations

:::caution Current limitations

- Lineage only reflects what has been collected or declared. A dataset that is not in the catalog has no lineage node.
- In dbt Studio, the project lineage is built from the manifest and is at the table level only. The column-level lineage returned by the dbt runner is currently empty. Column-level lineage in Hanas Catalog is a separate flow and exists only when metadata ingestion or SQL provides enough data.
- It is not confirmed that loading data with Ingestion automatically produces end-to-end lineage in Hanas Catalog. Treat the lineage of a loading flow as available only when a metadata collection source covers it.
- Dataset lineage on some query engine screens uses its own source, so it can differ from the graph in Hanas Catalog.

:::

## Troubleshooting

| Symptom | Resolution |
|---|---|
| The Lineage tab is empty | Run metadata ingestion for the related source, including dbt if you use it. |
| Column lineage is missing | Check that the source brings column-level information; remember the dbt runner limitation above. |
| A node is hidden | You do not have permission to view that asset on its source. |

## Next steps

- [Metadata ingestion](metadata-ingestion.md)
- [Run, test, and schedule dbt](../transform/dbt-runs.md)
- [Hanas Catalog API](../develop/catalog-api.md)
