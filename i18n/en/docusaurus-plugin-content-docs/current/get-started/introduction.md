---
title: What is Hanas Data Platform
sidebar_label: Platform introduction
sidebar_position: 1
description: An overview of the role, components, and deployment model of Hanas Data Platform on Kubernetes.
---

Hanas Data Platform is an enterprise data platform that combines lakehouse storage, querying, transformation, and data exploration. The platform serves analysts, data engineers, business users, and administration teams with tools designed for each role.

You use Hanas Console as the common entry point for most data work. The services behind it run queries, load data, manage metadata, model the business, and provide AI support.

## What problems Hanas solves

Enterprises often need to analyze data from many systems that are organized differently and update at different speeds. Hanas offers two approaches: query connected sources directly, or load data into lakehouse tables for further processing.

On top of that data, technical teams can create views, develop dbt models, and run Spark. Hanas Catalog adds descriptions, ownership, and lineage so users can understand data assets. Ontology expresses business objects and relationships, and Kapas supports interaction in natural language.

For example, customer, account, and transaction data can be standardized into analytical datasets. Analysts use views to aggregate transactions; business users explore objects mapped in Ontology. Having a dataset does not automatically create an object type or a metric; the responsible team must configure those layers.

## Components

### Access and querying

**Hanas Console** brings together the areas for connecting data, SQL Studio, development, administration, and analytics. Menus depend on your permissions and the enabled features; each backend still checks permissions when it receives a request.

**Query Engine** runs SQL on supported sources and lakehouse tables. It manages datasets, views, jobs, profiles, and Reflections, and provides a REST API and SQL client interfaces.

A **view** stores a SQL definition for reuse instead of storing the full result separately. A **Reflection** creates data structures that accelerate queries when the planner finds a suitable plan. The benefit depends on the query, the data, the refresh state, and the deployment configuration.

### Loading and processing data

**Ingestion** manages connections, discovers source tables, validates configuration, and loads data into Iceberg. Ingestion runs have schedules, logs, and checkpoints; the sync mode depends on the selected connector and engine.

**dbt Studio** provides projects and an IDE to develop SQL models, manage Git, and run and test dbt commands. Run results and artifacts help you check errors, dependencies, and run history.

**Pipeline** orchestrates multiple steps by dependency, for example running SQL and then running dbt. The orchestration engine and the supported step types depend on the environment; check the configuration before you design a workflow.

**Compute** provides PySpark projects and notebooks and runs Spark on Kubernetes. It is the option for Spark-based processing; the run lifecycle and data access permissions differ from interactive SQL queries.

### Governance and business semantics

**Hanas Catalog** stores and serves metadata for searching, discovering, and governing data assets. Schema, descriptions, owners, glossary, tags, and lineage depend on the metadata sources that are collected.

**Ontology** defines concepts, object types, properties, link types, and metrics bound to datasets. You design in **Ontology Workspace**, validate the mapping, then publish and activate the version that serves users. PostgreSQL stores Ontology definitions and state; business records are queried through the query engine.

Catalog and Ontology serve different needs. Catalog describes data assets; Ontology organizes the business model with bindings and query rules. Attaching a glossary term to a table does not automatically create a binding for an object type.

### AI and presentation

**Kapas AI** provides conversations, agents, and tools that help find data, write SQL, and compute configured metrics. What it can do depends on the agent, the model, permissions, and the target service; verify analysis results against the source.

**Analytics**, which integrates **Apache Superset**, provides BI datasets, charts, and dashboards in Console. BI datasets reference data through configured connections; saving a view in the query engine does not automatically create a dashboard.

### Identity and storage

**Keycloak** provides identity and SSO for integrated applications. Groups and roles support per-service authorization, while permissions on sources, tables, or views are checked at the query engine.

**Apache Iceberg on object storage** is the lakehouse table storage layer, consisting of data files, metadata, and snapshots. Object storage can be MinIO or a compatible service, depending on the environment configuration. The Iceberg catalog manages table lookup; Hanas Catalog serves business and governance metadata.

## Deployment model

Hanas is deployed with Helm/helmfile on Kubernetes in on-premises or private cloud infrastructure. The installer configures application services, databases, volumes, and connections for the selected components.

Your organization needs to prepare the network, domain names, TLS, storage, and secrets that suit the operating environment. Stateful services such as PostgreSQL, object storage, and workspaces need their own backup plans. Node count and resources must be determined according to the workload and the specific deployment configuration.

:::note Requirements

Ingestion, Hanas Catalog, Compute, Analytics, and Kapas must be deployed and configured before you use them. Compute additionally needs Spark Operator, a Spark image, a catalog connection, and the corresponding permissions. Kapas needs an AI model and valid credentials for the enabled integrations.

:::

## Boundaries to understand

:::caution Current limitations

The list of visible connectors, Iceberg write capabilities, and administration APIs depend on the deployed query engine version. Query engine policies do not automatically apply to Spark or Ingestion when they access storage with their own credentials.

:::

Hanas provides tools for a connected data flow, but each layer must be configured and verified separately. Do not assume that every source already has lineage, that every metric is executable, or that every agent has the same permissions.

## Next

- [Platform architecture](architecture.md).
- [Key concepts](concepts.md).
- [Get to know Hanas Console](console-tour.md).
- [Quickstart](quickstart.md).
