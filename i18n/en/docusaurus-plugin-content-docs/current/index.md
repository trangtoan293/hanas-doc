---
title: Hanas Data Platform Documentation
sidebar_label: Documentation home
sidebar_position: 0
description: Guides for using, administering, operating, and integrating Hanas Data Platform, organized by role and product component.
slug: /
---

Hanas Data Platform is an enterprise data platform that combines a lakehouse, SQL querying, transformation, metadata governance, Ontology, and AI. Hanas Console provides a single interface for connecting data, developing models, and using analysis results. The platform runs on Kubernetes in your organization's on-premises or private cloud infrastructure.

This documentation helps you use each component, understand the data flow, and identify the requirements for your deployment. If you are new to Hanas, read the [platform introduction](get-started/introduction.md), then complete the [quickstart](get-started/quickstart.md).

## Get started by role

### Business users and analysts

You find data, check what metrics mean, and run analysis through SQL, business objects, or conversation.

- [Get to know Hanas Console](get-started/console-tour.md): identify the work areas and tools that fit your task.
- [Quickstart](get-started/quickstart.md): query a data source and save a reusable view.
- [Explore objects](ontology/explore.md): view records, properties, and relationships in Ontology.
- [Chat with your data using Kapas](kapas/chat-with-data.md): ask questions with a clear data scope and context.

### Data engineers

You connect sources, load data into Iceberg, develop models, and orchestrate processing steps.

- [Connect data](connect/index.md): choose between direct query, file upload, or Ingestion.
- [Load data into the lakehouse](connect/ingestion.md): configure the source, destination, and sync mode.
- [dbt Studio](transform/dbt-studio.md): manage projects, SQL models, and the development workflow.
- [Pipelines](transform/pipelines.md): organize processing steps by dependency.

### Administration and operations

You prepare infrastructure, manage identities, and keep services running according to the deployment configuration.

- [Deployment architecture](operate/deployment-architecture.md): review the services and infrastructure dependencies.
- [Install with helmfile](operate/install.md): deploy the selected components on Kubernetes.
- [Authentication and SSO](operate/identity.md): configure Keycloak and identity connections between applications.
- [Backup and recovery](operate/backup-recovery.md): identify stateful data and the recovery order.

### Integration developers

You use APIs or SQL clients to bring data and analytics into other applications.

- [Integration overview](develop/index.md): choose an interface and an authentication method.
- [JDBC, ODBC, and Arrow Flight](develop/sql-clients.md): connect applications to query data.
- [Query engine REST API](develop/query-engine-api.md): submit SQL, track jobs, and retrieve results.
- [Kapas API and SSE](develop/kapas-api.md): integrate conversations and receive streamed responses.

## Product components

| Component | Role | Documentation |
|---|---|---|
| Hanas Console | Shared interface for data, development, analysis, and administration | [Get to know Console](get-started/console-tour.md) |
| Query Engine | SQL queries, views, jobs, and Reflections | [Query Engine](query/index.md) |
| Ingestion | Loads data from sources into Iceberg tables; tracks schedules and checkpoints | [Ingestion](connect/ingestion.md) |
| dbt Studio | Model development, Git management, and dbt runs and tests | [dbt Studio](transform/dbt-studio.md) |
| Pipeline | Orchestrates processing steps by dependency, schedule, and run identity | [Pipelines](transform/pipelines.md) |
| Compute | Runs Spark, PySpark, and notebooks on Kubernetes | [Compute](transform/compute.md) |
| Hanas Catalog | Metadata search, ownership, glossary, tags, and lineage | [Catalog](govern/catalog.md) |
| Ontology | Object models, relationships, and metrics bound to data | [Ontology](ontology/index.md) |
| Kapas AI | Conversations, agents, and tools that support data exploration | [Kapas AI](kapas/index.md) |
| Analytics / Apache Superset | Create and use BI datasets, charts, and dashboards | [Analytics](bi/superset.md) |
| Keycloak | Identity, SSO, groups, and roles for applications | [Authentication and SSO](operate/identity.md) |
| Apache Iceberg and object storage | Stores lakehouse tables, table metadata, and snapshots; can use MinIO | [Iceberg tables](query/iceberg-tables.md) |

:::note Requirements

Which components are enabled, which menus appear, and which actions are allowed depend on your environment configuration and your permissions. Access to Console does not mean you can use every service or read every dataset.

:::

## Read the documentation by purpose

To understand the layers and identity flows, see the [platform architecture](get-started/architecture.md). To distinguish sources, views, object types, and metrics, see [key concepts](get-started/concepts.md). For a quick lookup of a term, use the [glossary](reference/glossary.md).
