---
title: Naming conventions
sidebar_label: Naming conventions
sidebar_position: 6
description: Naming conventions for namespaces, tables, views, columns, and keys for medallion and Data Vault data on the lakehouse.
---

Consistent conventions help you recognize the table type, data layer, and purpose from the name alone. The conventions below are recommendations that accompany the [modeling standards](modeling-standards.md); the platform does not enforce them.

## General rules

- Use lowercase and underscores (`snake_case`), with no diacritics and no spaces.
- Use names that clearly describe the content; avoid uncommon abbreviations.
- Table name format: `<prefix>_<entity>[_<description>]`.
- Use the singular for entities (`customer`, not `customers`), unless the whole team has agreed otherwise.
- Keep names short. If a target system limits name length, check that limit before finalizing.

## Namespaces by layer

| Layer | Suggested namespace |
|---|---|
| Bronze / landing | `bronze` or `landing` |
| Raw vault | `raw_vault` |
| Business vault | `business_vault` |
| Silver | `silver` |
| Information mart / gold | `information_mart` or `gold` |
| Reference tables | `reference` |

## Table prefixes

### Raw vault

| Type | Prefix | Example |
|---|---|---|
| Hub | `hub_` | `hub_customer` |
| Link | `lnk_` | `lnk_customer_account` |
| Satellite | `sat_` | `sat_customer_detail` |
| Link satellite | `lsat_` | `lsat_customer_account` |
| Effectivity satellite | `lsate_` | `lsate_customer_account` |

### Business vault

| Type | Prefix | Example |
|---|---|---|
| Bridge | `brdg_` | `brdg_account_limit` |
| Point-in-time | `pit_` | `pit_customer` |
| Business satellite | `sat_biz_` | `sat_biz_customer_kpi` |

Satellite variants use suffixes: `_der` for the current-record view, `_snp` for the snapshot table. For example, `sat_customer_detail_der`.

### Information mart

| Type | Prefix | Example |
|---|---|---|
| Fact | `fct_` | `fct_transaction` |
| Dimension | `dim_` | `dim_customer` |
| Aggregate | `agg_` | `agg_daily_summary` |
| Wide table | `wide_` | `wide_customer_360` |
| Analytical view | `v_` | `v_daily_transaction_summary` |
| Reference table | `ref_` | `ref_product_type` |

### dbt models

In dbt, the model name is also the target table name, so apply the same prefixes. Use the `int_` prefix for intermediate models, `src_` for declared source tables, and `stg_` for cleansing models in silver if your team follows the standard dbt pattern. Choose one approach and use it consistently across the whole project.

## Column names

### Keys

| Column | Meaning |
|---|---|
| `hkey_hub` | Hub hash key. |
| `hkey_link` | Link hash key. |
| `hkey_sat`, `hkey_lsat` | Hash key of a satellite or link satellite. |
| `hash_diff` | Hash used to detect attribute changes. |
| `<entity>_key` | Dimension surrogate key. |
| `dim_<entity>_key` | Foreign key from a fact to a dimension. |
| `<entity>_id` | Original business key, for example `customer_id`. |

### Technical columns

| Column | Meaning |
|---|---|
| `dv_ldt` | Load time. |
| `dv_src_ldt` | Time the record originated at the source. |
| `dv_src_rec` | Source of the record. |
| `dv_cdc_ops` | CDC operation type. |
| `dv_ccd` | Key collision handling code. |
| `is_current` | Current-record flag (SCD Type 2). |
| `effective_date`, `expiry_date` | Effective period (SCD Type 2). |

Name boolean columns starting with `is_` or `has_`; end timestamp columns with `_ts` or `_date` depending on the data type; for amount columns, include the unit when it is unclear, for example `amount_vnd`.

## Example

```sql
create table raw_vault.hub_customer (
    hkey_hub    varchar not null,
    customer_id varchar not null,
    dv_cdc_ops  varchar,
    dv_src_ldt  timestamp,
    dv_src_rec  varchar,
    dv_ldt      timestamp
);

create table raw_vault.sat_customer_detail (
    hkey_hub      varchar not null,
    hash_diff     varchar not null,
    customer_name varchar,
    phone         varchar,
    dv_src_ldt    timestamp,
    dv_ldt        timestamp
);
```

Data types and table creation syntax depend on where you create the table: Iceberg tables through the [SQL Editor](../query/sql-studio.md) (**Workspaces** menu) or dbt materialization.

## Limitations

:::caution Current limitations

Constraint and index names following the `pk_`, `fk_`, `idx_` pattern apply only when the target system supports them. Iceberg tables do not enforce primary or foreign keys; check integrity with dbt tests.

:::

## Next steps

- [Modeling standards](modeling-standards.md).
- [Develop models in dbt Studio](dbt-studio.md).
- [Browse and find assets in Catalog](../govern/catalog.md).
