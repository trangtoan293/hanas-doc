---
title: Get to Know Hanas Console
sidebar_label: Console tour
sidebar_position: 4
description: The menu areas of Hanas Console, who uses them, and the conditions for them to appear.
---

Hanas Console is the shared web interface of Hanas Data Platform. This page helps you identify which area serves your work and why a menu might not appear for your account.

## Menu display conditions

Menus in Console depend on three factors: whether the component is deployed and enabled, your role, and the environment's feature configuration. A hidden menu does not replace permission checks in the backend; conversely, seeing a menu does not mean you are allowed to act on every object.

## Main areas

| Menu | What you do | Typical users |
|---|---|---|
| Home | View recent activity and go to tools | All users |
| Data Hub | View sources by group, add sources, browse folders, tables, and views | Analysts, data engineers |
| SQL Studio | Write and run SQL in multiple tabs, view results and jobs, save views, manage workspaces and folders in the data tree | Analysts, data engineers |
| Data Governance | Search data assets, view schema, ownership, glossary, tags, lineage; manage metadata collection | Data stewards, analysts; Catalog administrators |
| Ingestion | Create and monitor ingestion flows, manage sources and destinations | Data engineers |
| dbt | Manage dbt projects, develop models in the IDE, run and schedule dbt, explore data | Data engineers, analytics engineers |
| Pipeline | Design on the canvas, view the Pipeline list, schedules, and results of each step | Data engineers |
| Compute | Manage PySpark projects and notebooks, run them, and view logs | Data engineers, data scientists |
| Ontology | Explore objects, track change requests, design and administer ontologies | Business users, modeling specialists |
| AI Agent (Kapas) | Converse with agents to ask about data and create reports | All users granted an agent |
| Analytics | Open Apache Superset to build charts and dashboards | Analysts, BI team |
| Engine | Monitor nodes, manage engines, queues, routing rules, and Reflections | Query engine administrators |
| Settings | Manage users, roles, and permissions; BI applications, external token providers, AI and query configuration | Administrators |
| Account Settings | Manage account information and PATs | All users |

## Details of each area

### Home and Data Hub

Home is the landing page and collects recent activity. Data Hub lists sources and lets you add new ones; from here you open a table or view to query it or view its lineage. See [Direct-query data sources](../connect/data-sources.md).

### SQL Studio

SQL Studio is the main place to work with the query engine: multiple tabs and scripts, context selection, **Run** and **Preview**, and result and job views. When several statements run together, the sequence stops if one statement fails or is canceled. You save a query as a view with **Save as View**. See [SQL Studio](../query/sql-studio.md) and [Workspaces, folders, and views](../query/spaces-and-views.md).

### Data Governance

This area uses Hanas Catalog. You search for assets, open a dataset detail page, and manage glossary terms and tags. The metadata collection part (Sources, Run History, Secrets) is only for Data Governance administrators. See [Search and discover data assets](../govern/catalog.md) and [Metadata ingestion](../govern/metadata-ingestion.md).

### Ingestion, dbt, Pipeline, Compute

These four areas serve data engineers. Ingestion loads data into Iceberg ([Ingestion](../connect/ingestion.md)). dbt includes a home page, a project list, an IDE, an exploration area, and run schedules ([dbt Studio](../transform/dbt-studio.md)). Pipeline orchestrates multiple steps ([Pipelines](../transform/pipelines.md)). Compute runs Spark ([Compute](../transform/compute.md)).

### Ontology, AI Agent, and Analytics

Ontology has sections for exploration, requests, design (Workbench), administration, and settings ([Ontology](../ontology/index.md)). AI Agent opens Kapas ([Kapas AI](../kapas/index.md)). Analytics embeds Superset ([Analytics with Superset](../bi/superset.md)).

### Engine and Settings

Engine is for query workload administrators: monitoring, engines, queues, and Reflections ([Engines, queues, and workload management](../query/workload-management.md)). Settings includes users, roles, permissions, and system configuration ([Manage users, groups, and roles](../operate/user-management.md)).

### Account Settings and PAT

In Account Settings, you list PATs, create a new PAT with a label and an expiration, copy the token you just created, and revoke tokens you no longer use. A token is shown only when it is created, so store it in a safe place. See [Integration overview](../develop/index.md).

:::note Requirements

- dbt must be enabled for the environment, and you need the corresponding dbt role.
- Data Governance, Ingestion, Compute, Ontology, AI Agent, and Analytics are available only when the component is deployed and configured.
- Engine and Settings are for administrator accounts.
- The PAT feature requires the deployed query engine to support token issuance.

:::

:::caution Current limitations

Some menus might be hidden depending on the Console version, for example the separate view management area and standalone Jobs; you access these actions through SQL Studio. Some screens in Engine depend on the deployed query engine version.

:::

## Next

- [Quickstart](quickstart.md).
- [Key concepts](concepts.md).
- [SQL Studio](../query/sql-studio.md).
