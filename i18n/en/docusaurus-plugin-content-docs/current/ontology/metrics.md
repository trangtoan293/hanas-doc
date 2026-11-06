---
title: Metrics
sidebar_label: Metrics
sidebar_position: 4
description: Define simple, ratio, and derived metrics, and understand additivity, time semantics, and where metrics appear in Explore.
---

A metric is a business indicator with a name, description, unit, and execution configuration, for example total outstanding loans or the non-performing loan ratio. This page is for ontology authors who need to define standard indicators and for users who want to understand the numbers they see.

Metrics are an optional step in [Ontology Workspace](workspace.md). An object type can still be released without a metric.

## Metric types

| Type | Structure | Example |
|---|---|---|
| `simple` | A single aggregate `formula` over the source, with no references. | Total balance of deposit accounts. |
| `ratio` | A numerator and a denominator, each referencing a metric of an object type. | Group 3 and above outstanding loans divided by total outstanding loans. |
| `derived` | An arithmetic expression over inputs that are other metrics. | The difference between interest income and interest expense. |

A `derived` expression allows only numbers, input names, and the operators `+ - * /` with unary signs. Function calls, property access, or names outside the input list are rejected.

A ratio must be computed from components in the same valid scope. The system does not add up per-record ratios to produce an overall ratio.

## Additivity

Additivity indicates whether a metric can be summed along a grouping dimension.

| Value | Meaning |
|---|---|
| `additive` | Can be summed across business dimensions, for example total balance by branch. |
| `semi_additive` | Can be summed across business dimensions but not across time; use the end-of-period, start-of-period, or average value. |
| `non_additive` | Cannot be summed, for example average, distinct count, and ratio. |

At compile time, the system infers additivity from the execution plan and time policy instead of trusting a manual declaration. Count, sum, regular min and max, and conditional aggregates are classified as additive across business dimensions. Average, distinct count, arithmetic operations, ratio, and period comparison are classified as non-additive. If the time policy fixes a point in time, an additive group becomes semi-additive with a time rollup of `last`.

Do not add overlapping windows such as MTD and YTD, and do not treat min or max as additive.

## Time semantics

A metric has its own time configuration, separate from the object type's date policy.

| `as_of_policy` | How data is selected |
|---|---|
| `latest` | The latest snapshot. |
| `selected_date` | The snapshot of the date the user selects; a date is required. |
| `period_end` | The snapshot no later than the requested date, or the latest if no date is selected. |
| `wtd`, `mtd`, `qtd`, `ytd`, `itd` | The range from the start of the week, month, quarter, or year, or from inception, to the selected date. |

When there is no date, cumulative policies do not add a range filter on their own. A metric can also be configured with a `growth_rate` comparison against `previous_snapshot` and `partition_by`.

## Execution configuration

A metric's execution includes the following choices.

1. Choose the source dataset and the relationship path if the metric spans multiple object types.
2. Choose the `direct` or `aggregate_then_join` mode.
3. Declare the fields allowed to inherit filters from the context. A metric does not automatically accept every filter of the list.
4. Choose the time dimension and `as_of_policy`.

## Steps to create a metric

1. Choose **Open Build** on the project (or open **Ontology** > **Workbench**), then open **Metrics**.
2. Enter the name, description, unit, and formula or references.
3. Configure execution, context, and placement.
4. Select **Validate**, then review the **compile preview**.
5. Save to the draft and continue to **Release**.

## Status and where metrics appear

A metric that cannot be compiled into an execution plan has the `catalog_only` status: it appears in the catalog but does not compute a value. Only `executable` metrics can be computed.

**Placement** determines where a metric appears: the record list or the record detail page, component, order, visibility, format, filter scope, and date context. Users see metrics in [Explore objects](explore.md). Integrated applications call the aggregate metric or a record's metric through the [Ontology API](../develop/ontology-api.md), or use the named metric in the [Query DSL](../develop/ontology-query-dsl.md).

## Troubleshooting

| Symptom | Resolution |
|---|---|
| Metric is in the catalog but has no value | Check for the `catalog_only` status; fix errors in the compile preview. |
| Totals over time are wrong | Check the inferred additivity and `as_of_policy`; do not add snapshots across multiple days. |
| List filters do not affect the metric | Declare the filter-inheriting fields in the context. |
| Ratio gives an odd value | Check that the numerator and denominator have the same scope and the same date. |

## Next steps

- [Data mapping](mapping.md) for datasets and keys.
- [Explore objects](explore.md) to view metrics on records.
- [Ontology governance](governance.md) for release.
