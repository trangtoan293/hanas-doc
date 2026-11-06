---
title: Glossary
sidebar_label: Glossary
sidebar_position: 1
description: Glossary of Hanas Data Platform terms in alphabetical order, each with a short definition and a link to the related page.
---

This table explains terms commonly found in the Hanas Data Platform documentation, in alphabetical order. For core concepts, see also [Core concepts](../get-started/concepts.md).

## A

**Action**: an operation on an object type, governed by the Ontology submit and approval policy. See [Actions and change requests](../ontology/actions.md).

**Agent** (Kapas): an AI entity with its own prompt, skills, and tools. See [Agents, skills, and tools](../kapas/agents.md).

**Analytics**: the Console area that embeds Apache Superset for building charts and dashboards. See [Analytics with Superset](../bi/superset.md).

**Apache Arrow Flight**: a high-performance data transfer protocol that SQL clients use to fetch results. See [JDBC, ODBC, and Arrow Flight](../develop/sql-clients.md).

**Asset** (catalog asset): a metadata object in Hanas Catalog. See [Search and discover data assets](../govern/catalog.md).

## B

**Bronze, Silver, Gold**: the layers of the medallion architecture, from raw data to analysis-ready data. See [Modeling standards](../transform/modeling-standards.md).

## C

**Cardinality**: the number of relationships between two object types (one-to-one, one-to-many, many-to-many). See [Ontology concepts](../ontology/concepts.md).

**Catalog**: see Hanas Catalog and Iceberg catalog.

**Checkpoint**: a marker of the progress of an Ingestion flow, used to resume or rerun. See [Schedules, checkpoints, and reruns](../connect/ingestion-schedules.md).

**Compute**: the environment that runs Spark, PySpark, and notebooks on Kubernetes. See [Compute](../transform/compute.md).

**Concept**: a business concept in the Ontology model. See [Ontology concepts](../ontology/concepts.md).

**Connector**: a component that connects to a specific type of data source. See [Directly queryable data sources](../connect/data-sources.md).

## D

**Dashboard**: a collection of charts in Analytics. See [Analytics with Superset](../bi/superset.md).

**Data Hub**: the Console area to view and add sources and browse data. See [Hanas Console tour](../get-started/console-tour.md).

**Data Vault**: a modeling method that uses hubs, links, and satellites. See [Modeling standards](../transform/modeling-standards.md).

**dbt**: a tool that transforms data with SQL models. See [dbt Studio](../transform/dbt-studio.md).

**dbt project**: a collection of dbt models, tests, and configuration. See [dbt Studio](../transform/dbt-studio.md).

**Dimension**: an attribute used to group data during aggregation. See [Metrics](../ontology/metrics.md).

## E

**Engine**: a group of resources that executes queries in the query engine. See [Engines, queues, and workload orchestration](../query/workload-management.md).

**External BI**: a BI tool outside Console that connects to the query engine. See [Connect external BI tools](../bi/external-bi.md).

## F

**Folder**: a directory that holds views and datasets in a workspace. See [Workspaces, folders, and views](../query/spaces-and-views.md).

## G

**Glossary term**: a business term defined in Hanas Catalog. See [Glossary, tags, and ownership](../govern/glossary-and-tags.md).

**Grant**: a permission given to a user or role on a data object. See [Data access control](../govern/access-control.md).

**Group**: a collection of users in Keycloak. See [Manage users, groups, and roles](../operate/user-management.md).

## H

**Hanas Catalog**: the metadata store that supports search, glossary, tags, ownership, and lineage. See [Catalog and data governance](../govern/index.md).

**Hanas Console**: the platform's shared web UI. See [Hanas Console tour](../get-started/console-tour.md).

**helmfile**: a tool that declares the deployment of multiple Helm releases to Kubernetes. See [Install with helmfile](../operate/install.md).

## I

**Iceberg catalog**: a lookup service for Iceberg tables; different from Hanas Catalog. See [Iceberg tables](../query/iceberg-tables.md).

**Iceberg table**: a lakehouse table in Apache Iceberg format. See [Iceberg tables](../query/iceberg-tables.md).

**Ingestion**: the service that loads data from sources into Iceberg tables. See [Load data into the lakehouse](../connect/ingestion.md).

**Ingestion flow**: a load flow made up of a source, a destination, a schedule, and checkpoints. See [Load data into the lakehouse](../connect/ingestion.md).

**Interface** (Ontology): a shared contract that multiple object types can implement. See [Ontology concepts](../ontology/concepts.md).

## J

**JDBC, ODBC**: driver standards for applications and BI tools to query through SQL. See [JDBC, ODBC, and Arrow Flight](../develop/sql-clients.md).

**Job**: one SQL execution in the query engine. See [Job history and query profiles](../query/jobs.md).

## K

**Kapas**: the Hanas AI layer with conversations, agents, and tools. See [Kapas AI](../kapas/index.md).

**Keycloak**: the identity and SSO service. See [Authentication and SSO with Keycloak](../operate/identity.md).

## L

**Lakehouse**: a storage architecture that combines the flexibility of a data lake with the query capability of a data warehouse. See [Platform architecture](../get-started/architecture.md).

**Lineage**: the upstream and downstream relationships between data assets. See [Lineage](../govern/lineage.md).

**Link type**: a relationship between two object types in the Ontology. See [Ontology concepts](../ontology/concepts.md).

## M

**Mapping**: the mapping of object types, properties, and relationships to datasets. See [Map the ontology to data](../ontology/mapping.md).

**Masking**: hiding or transforming column values according to a policy attached to the column, applied when querying through the query engine. See [Data access control](../govern/access-control.md).

**Medallion**: a multi-layer architecture of Bronze, Silver, and Gold. See [Modeling standards](../transform/modeling-standards.md).

**Metadata ingestion**: collecting metadata from sources into Hanas Catalog. See [Metadata ingestion](../govern/metadata-ingestion.md).

**Metric**: an indicator with a name, a formula, and time rules in the Ontology. See [Metrics](../ontology/metrics.md).

## O

**Object type**: describes a type of business object tied to a dataset. See [Ontology concepts](../ontology/concepts.md).

**Ontology**: the semantic layer that connects the business model with data. See [Ontology](../ontology/index.md).

**Ontology Workspace**: where you design, map, and publish an ontology. See [Ontology Workspace](../ontology/workspace.md).

**Owner**: the person or team responsible for a data asset. See [Glossary, tags, and ownership](../govern/glossary-and-tags.md).

## P

**PAT** (personal access token): a personal token for clients and scripts to call APIs. See [Integration overview](../develop/index.md).

**Physical dataset**: a table or file in a source that the query engine has recognized. See [Directly queryable data sources](../connect/data-sources.md).

**Pipeline**: a workflow that orchestrates multiple steps. See [Pipelines](../transform/pipelines.md).

**Preflight**: a configuration check step before running an Ingestion flow. See [Load data into the lakehouse](../connect/ingestion.md).

**Profile** (query profile): the execution details of a job. See [Job history and query profiles](../query/jobs.md).

**Property**: an attribute of an object type. See [Ontology concepts](../ontology/concepts.md).

**Publish**: the step that releases an ontology version to serve users. See [Ontology Workspace](../ontology/workspace.md).

## Q

**Query engine**: the component that executes SQL and manages views, jobs, and Reflections. See [Query engine](../query/index.md).

**Queue**: a queue that routes queries to an engine. See [Engines, queues, and workload orchestration](../query/workload-management.md).

## R

**Record**: a specific object read from a mapped dataset. See [Ontology concepts](../ontology/concepts.md).

**Reflection**: a precomputed data structure that speeds up queries. See [Accelerate queries with Reflections](../query/acceleration.md).

**Role**: a set of permissions assigned to a user or group. See [Manage users, groups, and roles](../operate/user-management.md).

**Row access policy**: a policy that filters rows based on who is querying, applied when querying through the query engine. See [Data access control](../govern/access-control.md).

## S

**Skill** (Kapas): a package of guidance and tools that helps an agent perform a type of task. See [Agents, skills, and tools](../kapas/agents.md).

**Snapshot**: the state of an Iceberg table at a point in time, used for time travel. See [Iceberg tables](../query/iceberg-tables.md).

**Source**: a connection from the query engine to an external data system. See [Directly queryable data sources](../connect/data-sources.md).

**Spark**: the distributed processing engine used in Compute. See [Compute](../transform/compute.md).

**SQL Studio**: the Console area to write and run SQL. See [SQL Studio](../query/sql-studio.md).

**SSE** (server-sent events): a mechanism for receiving streamed responses from the Kapas API. See [Kapas API and SSE](../develop/kapas-api.md).

**Superset**: the open-source BI tool used in Analytics. See [Analytics with Superset](../bi/superset.md).

## T

**Tag**: a classification label attached to a data asset. See [Glossary, tags, and ownership](../govern/glossary-and-tags.md).

**Time travel**: querying an Iceberg table at an earlier snapshot or point in time. See [Iceberg tables](../query/iceberg-tables.md).

**Token exchange**: exchanging a Keycloak token for a token for the target service (RFC 8693). See [Platform architecture](../get-started/architecture.md).

## V

**View**: a saved, named SQL statement for reuse. See [Workspaces, folders, and views](../query/spaces-and-views.md).

## W

**Workspace** (space): a logical container that holds folders and views, and also the unit for granting permissions. See [Workspaces, folders, and views](../query/spaces-and-views.md).
