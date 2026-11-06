---
title: Key Concepts
sidebar_label: Key concepts
sidebar_position: 3
description: Short definitions of the core concepts used throughout Hanas Data Platform, with links to detailed pages.
---

This page defines concepts you encounter across many components of Hanas Data Platform. Each entry links to a detailed page. For an alphabetical lookup, see the [glossary](../reference/glossary.md).

## Data and queries

A **source** is a connection from the query engine to an external data system, such as a relational database or object storage. After you add a source, you browse and query the data without copying it. See [Direct-query data sources](../connect/data-sources.md).

A **physical dataset** is a table or file in a source that the query engine has recognized, with a schema and an access format. A physical dataset is the original data, not saved SQL. See [Direct-query data sources](../connect/data-sources.md).

A **view** (virtual dataset) is a SQL statement that is saved and named for reuse; the result is computed when queried. See [Workspaces, folders, and views](../query/spaces-and-views.md).

A **workspace** (space) and a **folder** are logical containers for organizing views and datasets, and they are also the unit for granting permissions. See [Workspaces, folders, and views](../query/spaces-and-views.md).

A **Reflection** is a data structure the query engine precomputes and stores to accelerate queries. The planner uses a Reflection only when it finds it suitable, so the benefit depends on the query and the refresh state. See [Accelerate queries with Reflections](../query/acceleration.md).

A **job** is one execution of SQL, with a status, timing, and a profile for analysis. See [Job history and query profiles](../query/jobs.md).

An **engine** and a **queue** are the mechanisms for allocating resources and balancing load for queries. See [Engines, queues, and workload management](../query/workload-management.md).

An **Iceberg table** is a lakehouse table in Apache Iceberg format that supports DDL, DML, and time travel. See [Iceberg tables](../query/iceberg-tables.md).

## Loading and processing data

An **ingestion flow** is a flow that loads data from one source into an Iceberg table. It consists of a connection, source tables, a destination, a schedule, and checkpoints. See [Load data into the lakehouse](../connect/ingestion.md) and [Schedules, checkpoints, and reruns](../connect/ingestion-schedules.md).

A **dbt project** is a set of SQL models, tests, and dbt configuration managed in dbt Studio, usually tied to a Git repository. See [dbt Studio](../transform/dbt-studio.md) and [Run, test, and schedule dbt](../transform/dbt-runs.md).

A **Pipeline** is a workflow that orchestrates multiple steps by dependency, schedule, and run identity. See [Pipelines](../transform/pipelines.md).

**Compute** is the execution environment for Spark, PySpark, and notebooks on Kubernetes. See [Compute](../transform/compute.md).

## Metadata governance

A **catalog asset** is a metadata object in Hanas Catalog, such as a dataset, dashboard, or pipeline collected from a source. See [Search and discover data assets](../govern/catalog.md).

A **glossary term** is a business term defined centrally and attached to assets. It belongs to the same group as **tags** and **owners**. See [Glossary, tags, and ownership](../govern/glossary-and-tags.md).

**Lineage** is the upstream and downstream relationship between data assets. The level of detail depends on the metadata collected. See [Lineage](../govern/lineage.md).

**Metadata ingestion** is the process of collecting metadata from sources into Hanas Catalog; it is different from Ingestion, which loads data. See [Metadata ingestion](../govern/metadata-ingestion.md).

## Ontology

An **object type** describes the structure of a business object type that is served: its source dataset, primary key, and properties. See [Ontology concepts](../ontology/concepts.md).

A **link type** declares the relationship between two object types, along with the join columns and cardinality. See [Ontology concepts](../ontology/concepts.md).

A **metric** is a named indicator definition with a formula and time rules, and it can be computed on an object type. See [Metrics](../ontology/metrics.md).

**Ontology Workspace** is where you design, map, validate, and publish an ontology. See [Ontology Workspace](../ontology/workspace.md) and [Map an ontology to data](../ontology/mapping.md).

## AI and presentation

A **Kapas agent** is a preconfigured AI agent with its own tools and skills that helps find data, write SQL, or compute metrics. See [Agents, skills, and tools](../kapas/agents.md) and [Safety in Kapas](../kapas/safety.md).

**Analytics** is the area that embeds Apache Superset to create BI datasets, charts, and dashboards. See [Analytics with Superset](../bi/superset.md).

## Identity and access

A **role** is a set of permissions assigned to a user or group; Keycloak roles control access to services, while grants on data objects are checked by the query engine. See [Manage users, groups, and roles](../operate/user-management.md) and [Data access control](../govern/access-control.md).

A **PAT** (personal access token) is a personal token that SQL clients or scripts use to call APIs on your behalf. You create a PAT in Account Settings. See [Integration overview](../develop/index.md).

:::note Requirements

Some concepts take effect only when the corresponding component is deployed, for example Ingestion, Hanas Catalog, Ontology, or Kapas. See the [platform architecture](architecture.md).

:::

## Next

- [Platform architecture](architecture.md).
- [Get to know Hanas Console](console-tour.md).
- [Quickstart](quickstart.md).
