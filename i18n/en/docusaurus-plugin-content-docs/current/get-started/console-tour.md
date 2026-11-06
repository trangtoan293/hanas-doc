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

The left sidebar lists the areas below from top to bottom. The `›` sign marks sub-items that appear in a flyout when you hover over the menu.

| Menu | What you do | Typical users |
|---|---|---|
| **Home** | View shortcut cards (New Connection, New Object Type, SQL Editor, Analytics, New Project, My Jobs) and recent activity on the All, Jobs, and Projects tabs | All users |
| **Overview** | Monitor the platform: schema statistics, node distribution, connection management, Action Center (alerts), and recent jobs | Administrators, data engineers |
| **Connections** | View sources by group (Data Lakehouse, Object Storage, Databases), filter by status, and add a source with **New Source** | Analysts, data engineers |
| **Data Governance** › Glossary, Tags, Data Sources | Search data assets, manage glossary terms and tags; **Data Sources** collects metadata | Data stewards, analysts; Catalog administrators |
| **Ingestion Flows** › Ingestion Flows, Sources, Destinations, Access Control | Create and monitor ingestion flows, manage sources, destinations, and access control | Data engineers |
| **Data Pipeline** | View the **Pipelines** list and **Runs**, create a pipeline, manage service accounts | Data engineers |
| **Ontology** › Explore, My requests, Workbench, Governance, Settings | Explore objects by project, track change requests, design and administer ontologies | Business users, modeling specialists |
| **Workspaces** | Open **SQL Editor**: write and run SQL, view results and history, save views, manage workspaces and folders | Analysts, data engineers |
| **dbt Studio** › Projects, Explore, Orchestrate | Manage dbt projects, develop models in the IDE, run and schedule dbt | Data engineers, analytics engineers |
| **Compute Engine** | Manage PySpark projects and notebooks on the **Projects**, **Runs**, **Streaming jobs**, and **Sessions** tabs | Data engineers, data scientists |
| **AI Agent** | Converse with Kapas to ask about data and create reports | All users granted an agent |
| **Analytics** | Open Apache Superset (Dashboards, Charts, Template, Report, Datasets, SQL) | Analysts, BI team |
| **Engine** › Monitor, Nodes, Engines, Queues, Routing, Reflections | Monitor, manage engines, queues, routing rules, and Reflections | Query engine administrators |
| **Settings** › User Administration, Integrations, System, Custom | Manage users, roles, and permissions; BI applications, external tokens, AI configuration; system preferences and query configuration | Administrators |

At the bottom left, the account menu (select your avatar) contains **Access Tokens**, **Language** (English or Vietnamese), and **Sign out**.

## Details of each area

### Home and Overview

Home is the landing page: shortcut cards and a list of recent activity. Overview is the platform monitoring page. It shows schema statistics, node distribution, a **Connection Management** block (**New Connection** and **Manage All** buttons), an **Action Center** with alerts such as a Reflection refresh failure or a source connection error, and a list of recent jobs.

### Connections

Connections lists sources by group (Data Lakehouse, Object Storage, and Databases) with the status filters All, Healthy, Warning, and Error. The **New Source** button opens the **Add Source** dialog; from the list you open a table or view to query it or view its lineage. See [Direct-query data sources](../connect/data-sources.md).

### Workspaces and SQL Editor

The **Workspaces** menu opens SQL Editor, the main place to work with the query engine. The left panel has the DATA, SCRIPTS, and FUNCTIONS tabs; you select a **Context**, run a query with **Run** (Ctrl/Cmd+Enter), and see results on the **Results** tab and history on the **History** tab. When several statements run together, the sequence stops if one statement fails or is canceled. You save a query as a view with **Save as View**. See [SQL Editor](../query/sql-studio.md) and [Workspaces, folders, and views](../query/spaces-and-views.md).

### Data Governance

This area uses Hanas Catalog. The landing page is a metadata search with filters such as Type, Platform, Environment, Owner, and Tag. You open a dataset detail page and manage glossary terms and tags. The **Data Sources** item (tabs **Sources**, **Run History**, **Secrets**, and the **Create Source** button) handles metadata collection and is only for Data Governance administrators. See [Search and discover data assets](../govern/catalog.md) and [Metadata ingestion](../govern/metadata-ingestion.md).

### Ingestion Flows, Data Pipeline, dbt Studio, Compute Engine

These four areas serve data engineers. **Ingestion Flows** loads data into Iceberg; the flow list filters by mode (All, Batch, Stream) and status (All, Active, Error, Paused) ([Ingestion](../connect/ingestion.md)). **Data Pipeline** has the **Pipelines** and **Runs** tabs, plus the **Create pipeline** and **Service accounts** buttons ([Pipelines](../transform/pipelines.md)). **dbt Studio** includes Projects, Explore, Orchestrate, and an **Open IDE** button ([dbt Studio](../transform/dbt-studio.md)). **Compute Engine** runs Spark; the **New project** button creates a project ([Compute](../transform/compute.md)).

### Ontology, AI Agent, and Analytics

Ontology organizes work in projects; its menu has Explore, My requests, Workbench, Governance, and Settings ([Ontology](../ontology/index.md)). **AI Agent** opens Kapas with **New chat** and a chat history ([Kapas AI](../kapas/index.md)). **Analytics** embeds Superset ([Analytics with Superset](../bi/superset.md)).

### Engine and Settings

**Engine** is for query workload administrators: Monitor (tabs **Catalog usage**, **Jobs**, **Resources**), Nodes, Engines, Queues, Routing, and Reflections ([Engines, queues, and workload management](../query/workload-management.md)). **Settings** includes:

- **User Administration**: the Users, Roles, and Permissions tabs (**New User** button).
- **Integrations**: BI Applications (Power BI, Tableau), External Tokens, AI Config.
- **System**: Preferences, Support, Compute.
- **Custom**: SQL Query Config.

See [Manage users, groups, and roles](../operate/user-management.md).

### Job history

Console has no standalone Jobs menu. You reach job history from the **My Jobs** card on Home, the **View all jobs** link on Overview, the **History** tab in SQL Editor, or Engine › Monitor › the **Jobs** tab.

### Account menu and PATs

Open the account menu (the avatar at the bottom left) and select **Access Tokens** to open the **Personal Access Tokens** dialog. The dialog lists your PATs (Token ID, Label, Creation, Expiration), lets you create a new PAT with **Generate Token** using a label and an expiration, copy the token you just created, and delete tokens you no longer use (**Delete All** removes them all). A token is shown only when it is created, so store it in a safe place. See [Integration overview](../develop/index.md).

:::note Requirements

- dbt must be enabled for the environment, and you need the corresponding dbt role.
- Data Governance, Ingestion Flows, Compute Engine, Ontology, AI Agent, and Analytics are available only when the component is deployed and configured.
- Engine and Settings are for administrator accounts.
- The PAT feature requires the deployed query engine to support token issuance.

:::

:::caution Current limitations

Some menus might be hidden depending on the Console version, for example the separate view management area; you access this action through SQL Editor. Some screens in Engine depend on the deployed query engine version.

:::

## Next

- [Quickstart](quickstart.md).
- [Key concepts](concepts.md).
- [SQL Editor](../query/sql-studio.md).
