---
title: Modeling standards
sidebar_label: Modeling standards
sidebar_position: 5
description: Recommended standards for organizing data into bronze, silver, and gold on Iceberg and dbt, with Data Vault 2.0, SCD, surrogate keys, and audit columns.
---

This page gives recommended standards for organizing data on the Hanas Data Platform lakehouse. This is design guidance, not a constraint enforced by the platform. You can apply part of it, as long as you are consistent within the same data domain.

## Medallion: bronze, silver, gold

| Layer | Role | Example |
|---|---|---|
| Bronze | Data ingested from sources, keeping the original structure, with audit columns added. | Tables written by [Ingestion](../connect/ingestion.md). |
| Silver | Cleaned data with standardized types, deduplicated, and integrated across sources. | dbt models that reference bronze. |
| Gold | Models for business and BI use: fact, dimension, mart. | Views or tables for dashboards. |

Each layer is a namespace in the Iceberg catalog. dbt models in [dbt Studio](dbt-studio.md) read the layer below and write the layer above; the ordered execution flow is orchestrated with [Pipeline](pipelines.md) or a [dbt schedule](dbt-runs.md).

General principles:

- Write to a layer only from the layer directly below it; avoid gold reading bronze directly.
- Declare the grain and business key for each table before writing the model.
- Bronze contains no business logic; silver contains no metrics specific to a single report.
- Each model has minimum tests for keys (`not_null`, `unique`) and relationships.

## Data Vault 2.0

Data Vault 2.0 fits when many sources change frequently and you need full history traceability. You can use it in place of silver, or skip it if there are few sources and a direct dimensional model is enough. Data passes through three layers:

```mermaid
flowchart LR
    L["Bronze / landing"] --> R["Raw vault: hub, link, satellite"]
    R --> B["Business vault: bridge, PIT, business satellite"]
    B --> M["Information mart: fact, dimension, wide table"]
```

### Raw vault

The raw vault stores standardized source data, with no business logic applied, and is insert-only.

| Component | Content |
|---|---|
| Hub | The unique business key of an entity, for example customer or account. |
| Link | A relationship between hubs, for example a customer owns an account. |
| Satellite | The attributes and change history of a hub. |
| Link satellite | The attributes and history of a link. |

A satellite adds a new row only when the record's `hash_diff` changes compared with the latest one. You can create a view that returns the current record (suffix `_der`) or a snapshot table (`_snp`) for fast queries.

### Business vault

The business vault holds shared business logic, computed from the raw vault.

| Component | Purpose |
|---|---|
| Bridge | Pre-joins multiple hubs and links to shorten queries. |
| PIT (point-in-time) | For each snapshot time, points to the satellite record in effect. |
| Business satellite | Computed attributes, for example customer ranking. |

### Information mart

The information mart is the BI serving layer, equivalent to gold: star schemas made of fact and dimension tables, wide tables for quick exploration, and analytical views. Data is loaded from the business vault or directly from the raw vault.

## Surrogate keys and hash keys

Use stable surrogate keys that do not depend on the source's display values.

- In Data Vault, the hub key is a hash of the business key (`hkey_hub`). Standardize the business key before hashing: trim whitespace, use a consistent letter case, and join multiple columns with a fixed delimiter.
- The link key is a hash of the participating hub keys; `hash_diff` is a hash of the attribute columns used to detect changes.
- In a dimension, use a `*_key` column as the surrogate key; facts reference it through `dim_*_key`.
- Keep the original business key in the table for reconciliation.

Example of creating a hash key in a dbt model, using the hash function of the engine you are running:

```sql
select
    lower(to_hex(sha256(cast(upper(trim(customer_id)) as varbinary)))) as hkey_hub,
    customer_id,
    current_timestamp as dv_ldt
from bronze.customer
```

The specific hash function may differ by dialect; test it on the target before applying it, and use a single algorithm across the whole vault.

## Slowly changing dimension (SCD)

| Type | Behavior | When to use |
|---|---|---|
| Type 1 | Overwrites the old value. | Fixing data errors, attributes that do not need history. |
| Type 2 | Adds a new row and closes the old row with `effective_date`, `expiry_date`, `is_current`. | Attributes that must be tracked over time, for example customer ranking. |

With Type 2, each business key has only one row with `is_current = true`, and the effective periods do not overlap. Add dbt tests that check these two conditions. You can use dbt snapshots or build it from satellites in Data Vault.

## Audit columns

Every bronze and vault table should have the following technical columns, named according to the [naming conventions](naming-conventions.md).

| Column | Meaning |
|---|---|
| `dv_ldt` | The time the record was loaded into the current layer. |
| `dv_src_ldt` | The time the record originated at the source. |
| `dv_src_rec` | The name of the source table or system. |
| `dv_cdc_ops` | The CDC operation type: `INIT`, `INSERT`, `UPDATE`, `DELETE`. |

If the source has a log sequence such as SCN or RBA, keep it as well to order records with the same timestamp. For CDC streams, handle `DELETE` as a delete-marker record instead of a physical delete, and agree on how ingestion represents delete operations before you design the model.

## Limitations

:::caution Current limitations

The platform does not check compliance with medallion or Data Vault. That relies on model review, dbt tests, and reconciliation. If you want to enforce the conventions, put them into the project's review and test process.

:::

## Next steps

- [Naming conventions](naming-conventions.md).
- [Develop models in dbt Studio](dbt-studio.md).
- [Speed up queries with Reflections](../query/acceleration.md).
