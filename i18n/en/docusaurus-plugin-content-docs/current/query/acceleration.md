---
title: Accelerate queries with Reflections
sidebar_label: Reflections
sidebar_position: 4
description: Use Raw and Aggregation Reflections to speed up repeated queries, configure refresh, and monitor status.
---

A Reflection is an optimized copy of data that the query engine uses automatically when planning queries. Users still query the original table or view; the engine picks a suitable Reflection if one exists. This page is for data engineers and administrators who need to improve the performance of repeated queries.

## Concepts

| Type | What it stores | When to use |
|---|---|---|
| Raw Reflection | A subset of the dataset's columns, optionally re-sorted and re-partitioned. | Queries that select many columns, filter on specific columns, or hit a slow source. |
| Aggregation Reflection | Aggregated results by dimension and measure. | Dashboards and reports that repeat `GROUP BY`, `SUM`, and `COUNT` operations. |

You can create Reflections on both tables and views. A Reflection does not replace Iceberg table maintenance; see [Iceberg tables](iceberg-tables.md).

## Prerequisites

:::note Requirements

You need administrative permission on the dataset to create or edit a Reflection. Reflections consume storage and refresh resources, so create them only for queries that truly repeat.

:::

## Create a Reflection

1. Open the dataset in **SQL Studio** or the data tree and select the acceleration settings (Acceleration).
2. Select the **Raw Reflections** or **Aggregation Reflections** tab.
3. For Raw, select the display columns and the sort and partition options. For Aggregation, select dimensions and measures.
4. Enable the Reflection and save.

You can also create one with SQL:

```sql
ALTER TABLE gold.retail.active_account
    CREATE RAW REFLECTION active_account_raw
    USING DISPLAY (account_id, customer_id, segment);
```

The `DIMENSIONS` and `MEASURES` clauses are used for Aggregation Reflections.

## Refresh

A Reflection is refreshed according to the dataset's policy: on a schedule or when source data changes, depending on configuration. To refresh manually:

```sql
ALTER TABLE gold.retail.active_account REFRESH REFLECTIONS;
```

Data in a Reflection can be older than the source until the next refresh. For reports that need real-time data, check the refresh policy before relying on a Reflection.

## Monitor

The system table `sys.reflections` lists Reflections with their status:

```sql
SELECT * FROM sys.reflections;
```

The Reflection administration page in Hanas Console shows the type, dataset, refresh status, errors, size, and usage. In the details of a [job](jobs.md), the Reflection section shows whether the query used a Reflection.

:::caution Current limitations

The Performance page may show sample data when no real data exists yet. Do not use the figures there as evidence of performance; cross-check against `sys.reflections` and the job profile.

:::

## Troubleshooting

| Symptom | What to check |
|---|---|
| Reflection is in an error state | See the error message on the Reflection page and the corresponding refresh job. |
| Query does not use a Reflection | Check that the columns, dimensions, and measures cover the query, and that the Reflection is enabled. |
| Data is stale | Check the time of the last refresh; run a manual refresh if needed. |
| Storage grows quickly | Delete rarely used Reflections; narrow the columns or dimensions. |

## Next steps

- [Job history](jobs.md).
- [Engines, queues, and workload management](workload-management.md).
- [Workspaces, folders, and views](spaces-and-views.md).
