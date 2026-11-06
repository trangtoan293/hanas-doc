---
title: Map the ontology to data
sidebar_label: Data mapping
sidebar_position: 3
description: Map object types, properties, and link types to datasets, keys, and join conditions; use automap and Mapping Copilot to speed up the work.
---

Mapping connects the business model to tables or views in the query engine. This page is for ontology authors who need to turn a concept into a queryable object type, with properties and relationships.

Mapping happens in the **Mapping** stage of [Ontology Workspace](workspace.md). It has four parts: data source, properties and keys, relationships, and record experience.

## Concepts

| Component | Description |
|---|---|
| Dataset binding | The path of the table or view from which the object type reads records. |
| Primary key | One or more columns that uniquely identify a record. |
| Property mapping | The source column for each property, with its type and capabilities. |
| Link mapping | One or more `source_field` and `target_field` column pairs used to join two object types. |
| Grain and date policy | How the dataset represents time: no date, daily snapshot, or effective range. |

A dataset binding must be a valid path in the query engine. For a multi-column key, the ontology stores a composite key and encodes the value when needed in the API, so you do not concatenate key strings yourself in the application.

## Requirements

- The `ontology-editor` or `ontology-admin` role in the workspace.
- The dataset already exists in the query engine and you have read permission to check the schema.
- The concept is already selected as needing a runtime. A concept used only as vocabulary does not need a mapping.

:::note Requirements

An entity that needs a runtime but lacks a dataset or primary key blocks release. Release validation reports the error code and location so you can resolve it.

:::

## Steps

### 1. Select the data source

1. From the project card in **Ontology** > **Explore**, choose **Open Build** (or open **Ontology** > **Workbench**), then switch to **Mapping**.
2. Select the concept to map.
3. Select a dataset from the list of sources, schemas, tables, or views, or use the system's source suggestions.
4. Check the dataset's schema and data sample.

Source suggestions are only hints based on metadata. Confirm the grain: is a row one customer, or one customer on one day?

### 2. Map properties and keys

1. Assign each property to a source column and check the data type.
2. Choose the primary key. If one column is not unique enough, choose a composite key.
3. Set the title property so Explore shows a readable name for the record.
4. Enable `searchable`, `filterable`, `sortable`, and `aggregatable` only when the data and usage needs support them.
5. Mark a column as ignored if you do not want it in the object type.

Capabilities determine which operations are allowed in the [Query DSL](../develop/ontology-query-dsl.md). The planner rejects requests that use a property without the corresponding capability enabled.

### 3. Declare relationships

1. Choose the semantic relationship between two concepts, for example a customer owns accounts.
2. Choose the join column pair. Add multiple pairs if the key has multiple columns, such as customer ID and unit ID.
3. Choose the cardinality and enter the forward and reverse labels.
4. Choose the display direction in the graph if the model allows it.

The system does not guess joins arbitrarily. Ambiguous or invalid joins are reported in the mapping preview. Cardinality is only a declaration; it does not fix duplicate keys in the source.

### 4. Set the date policy

For a snapshot dataset, set the time column and choose `daily_snapshot` as the grain. The date policy has three values: `none`, `snapshot`, and `effective_range`.

| Date policy | Behavior |
|---|---|
| `none` | No date filtering. |
| `snapshot` | Filters by the selected date; can use the latest date when none is selected. |
| `effective_range` | Selects records whose effective range contains the selected date. |

### 5. Preview and validate

1. Run **mapping preview** to see compile diagnostics.
2. Preview the record list, a specific record, and the graph according to the draft.
3. Run **mapping analysis** to see coverage and the remaining suggestions.
4. Open **Release** to validate the entire draft.

Preview reads data with your identity. Another user may see different results if they have different row access or masking in the query engine.

## Automap and Mapping Copilot

These two tools speed up mapping but do not replace validation.

- **Automap** automatically suggests and attaches sources, columns, keys, and relationships based on dataset metadata. You run it on a draft and then review the results.
- **Mapping Copilot** handles the blockers that remain after automap. Each suggestion is saved as its own candidate and does not modify the draft. You can validate a candidate and profile keys and joins within a limited budget, then apply or dismiss it.

:::note Requirements

Mapping Copilot requires an AI service and the corresponding configuration; see [Ontology Workspace](workspace.md). When it is not configured, you can still map manually or use automap.

:::

When you apply a candidate, the system writes the selection to the draft in a single transaction. Run validation again afterward.

## Limitations

:::caution Current limitations

- The `array_string` type is displayed but does not support search, filter, sort, or aggregate.
- The `hidden` flag only controls presentation. To block a column, use masking and grants in the query engine.
- Concepts, business groups, and shared property types do not automatically create dataset bindings, links, or metrics.

:::

## Troubleshooting

| Symptom | Resolution |
|---|---|
| Publish reports a missing dataset or key | Complete the binding and primary key for entities that need a runtime, or change the concept back to vocabulary. |
| Record count multiplies after enabling a link | Check whether the join column pair is unique on the target side; add columns to the join key. |
| Preview shows no records | Check read permission, the date filter, and the dataset path. |
| Property cannot be used for filtering | Enable `filterable`, then validate the draft again. |

## Next steps

- Add indicators in [Metrics](metrics.md).
- Verify the results with [Explore objects](explore.md).
- Release following [Ontology governance](governance.md).
