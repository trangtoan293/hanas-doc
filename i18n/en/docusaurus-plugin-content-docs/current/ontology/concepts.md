---
title: Ontology concepts
sidebar_label: Concepts
sidebar_position: 1
description: Explains object types, properties, link types, interfaces, metrics, actions, and the Ontology definition lifecycle.
---

The Ontology in Hanas Data Platform connects the business model to queryable data. This page explains the concepts you encounter when you design, publish, and use an ontology.

## Concepts, object types, and records

A **concept** expresses a business idea in the canonical model. A concept can be an `EntityType`, such as a customer, or a `ValueType`, such as a type of code or business value.

A concept does not necessarily have data to read. You can keep it as vocabulary, or add a mapping to provide an object type at runtime.

An **object type** describes the structure of the records it serves: the source dataset, primary key, properties, and query configuration. The API name used in requests can differ from the display name in the UI.

A **record** is a specific object read from a mapped dataset. A record's identity consists of the object type and primary key; for snapshots, you also need to understand the grain and date context.

For example, the customer with ID `C001` is a record of the customer object type. An account balance snapshot for one day has a different identity and meaning from the snapshot for the next day.

:::note Requirements

Creating a concept does not make a record list appear. A concept needs a valid runtime mapping, a key, and an active deployment before users can query data.

:::

## Properties and shared property types

A **property** is an attribute of an object type, such as customer ID, name, or account opening date. A property declares a data type and independent capabilities.

| Capability | Meaning |
|---|---|
| `required` | The attribute is declared as required in the model. |
| `searchable` | Can take part in prefix search over records. |
| `filterable` | Can be used in Query DSL filter conditions. |
| `sortable` | Can be used to sort record lists. |
| `aggregatable` | Can take part in grouping or aggregation using suitable operations. |
| `hidden` | Controls presentation; it is not a column security policy. |

Runtime types are `string`, `integer`, `long`, `double`, `decimal`, `boolean`, `date`, `timestamp`, and `array_string`. The `array_string` type is currently displayed but does not support search, filter, sort, or aggregate.

`aggregation_role` distinguishes `none`, `dimension`, and `measurement`. A dimension is typically used for grouping; a measurement represents a value to measure, but the operation must still match the data type.

A **shared property type** defines a semantic attribute shared across multiple object types. For example, two account types can use the same definition of customer ID or business date.

Each local property maps to its corresponding shared property. This mechanism unifies meaning and schema; it does not automatically join or merge records from different sources.

## Link types

A **link type** declares a relationship between two object types, together with the column pairs used to join them. A relationship has a forward label, a reverse label, and a cardinality.

| Cardinality | Meaning |
|---|---|
| `one_to_one` | One source record relates to one target record in the declared model. |
| `one_to_many` | One source record can relate to many target records. |
| `many_to_many` | Many records on both sides can relate to each other. |

A customer with many accounts is an example of a one-to-many relationship. A mapping may need multiple column pairs if the key also includes a unit or other context.

Declaring a cardinality does not fix duplicate keys or bad data in the source. You need to check the actual join to avoid duplicating records and skewing aggregate results.

## Interfaces

An **interface** describes a set of shared properties that multiple object types implement. Applications can read the common attributes through one query across those types.

For example, deposit accounts and loan accounts can both implement an account interface. The result includes a `__type` field to distinguish the object type of each record.

:::caution Current limitations

Interface queries are currently a bounded list that uses flat filters on shared properties. Cursor, sort, filter expressions, and `page_size` are not yet fully applied as they are for object type queries.

:::

## Metrics and actions

A **metric** is an indicator definition with a name, description, unit, and execution configuration. A metric can use a simple aggregate, a ratio, or an expression derived from other components.

A metric in the catalog can have the `catalog_only` status. Only the `executable` status with a suitable configuration lets the runtime compute values; display positions are managed separately through placement.

An **action** describes a proposed operation on an object, including parameters, the expected change, and an approval policy. The request flow distinguishes the submitter, the approver, and an external processor.

:::caution Current limitations

Actions do not provide active direct writeback. The legacy invoke endpoint is blocked; canonical actions use the request workflow and wait for an external processor after approval.

:::

## Business groups and workspaces

A **business group** organizes concepts by business domain to make browsing and design easier. A group has a display name and an order, and is versioned with revisions.

A business group is not a permission group. It also does not automatically create dataset bindings, links, or metrics for the concepts placed together.

A **workspace** is a project scope that holds definitions, drafts, revisions, and deployments. When multiple workspaces are published, applications must specify the workspace to avoid queries that lack context.

## Draft, review, and publish lifecycle

| Stage | Meaning |
|---|---|
| Draft | The canonical document and manifest are being authored; the serving runtime is unchanged. |
| Review | View mappings, errors, and impact; can be moved to the `pending_approval` status. |
| Publish | Verify the checksum, compile, and approve the revision for release. |
| Deployment | A projection is prepared and activated for the runtime to read. |

A draft pending approval is locked for editing. The submitter or an admin can withdraw the submission; an admin can reject it with a reason so the author can continue editing.

An admin can publish a valid draft directly according to the release gate. Submitting is therefore not a mandatory step before every admin publish.

## Next steps

- Create and release definitions in [Ontology Workspace](workspace.md).
- Set up runtime data following the [mapping guide](mapping.md).
- Control the lifecycle with [Ontology governance](governance.md).
