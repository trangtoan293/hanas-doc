# Hanas Console — UI map verified on the live environment (2026-11-06)

UI language: English by default; account menu has **Language** (English / Vietnamese). Use the English labels below, bold, exactly as written.

## Left sidebar (top to bottom; `>` = flyout sub-items)

- **Home** — cards: New Connection, New Object Type, SQL Editor, Analytics, New Project, My Jobs; "Your Recent Activity" with tabs All / Jobs / Projects.
- **Overview** — platform monitoring: Schema Statistics, Node Distribution Metrics, Connection Management (button **New Connection**, **Manage All**), Action Center (alerts e.g. Reflection Refresh Failure, Source Connection Error), Recent Jobs with **View all jobs**.
- **Connections** (was wrongly "Data Hub" in docs) — page title "Connections"; groups Data Lakehouse / Object Storage / Databases; status filters All / Healthy / Warning / Error; button **New Source** opens dialog **Add Source** with tabs **Manual Setup** and **Import File**.
- **Data Governance** > Glossary, Tags, Data Sources. Landing page is metadata search with filters Type, Platform, Environment, Owner, Tag, Platform Instance, and Sort by; platform facets seen: Hanas, Superset, dbt.
  - **Data Sources** page heading "Manage Data Sources", tabs **Sources / Run History / Secrets**, button **Create Source**.
- **Ingestion Flows** > Ingestion Flows, Sources, Destinations, Access Control. Ingestion page filters by mode All / Batch / Stream and status All / Active / Error / Paused.
- **Data Pipeline** — page "Pipelines", tabs **Pipelines / Runs**, buttons **Create pipeline**, **Service accounts**.
- **Ontology** > Explore, My requests, Workbench, Governance, Settings. Explore page "Explore projects", button **Create project**; project cards show publication state (PUBLISHED vN / NOT PUBLISHED) and actions **Open Build**, **Explore**. (Ontology work is organised in *projects*.)
- **Workspaces** — this is the SQL editor (docs called it "SQL Studio"; the Home card calls it **SQL Editor**). Left panel tabs DATA / SCRIPTS / FUNCTIONS; tree sections Workspaces (personal home `@user`) and Spaces; editor has a Run button (Ctrl/Cmd+Enter), **Save as View**, **Context** selector; result tabs **Results / History**; embedded **AI Agent** side panel.
- **dbt Studio** > Projects, Explore, Orchestrate. Landing: Recent projects, Quick actions (Create project, Manage connections, Run history), **Open IDE**, **New project**, **User guide**.
- **Compute Engine** — tabs **Projects / Runs / Streaming jobs / Sessions**, button **New project**.
- **AI Agent** — Kapas chat: **New chat**, chat history list, "How can I help you today?".
- **Analytics** — embedded Superset (signs in via Keycloak); top tabs Dashboards, Charts, Template, Report, Datasets, SQL.
- **Engine** > Monitor, Nodes, Engines, Queues, Routing, Reflections. Monitor tabs **Catalog usage / Jobs / Resources**; also shows **Autonomous Reflections** with History log.
- **Settings** > 
  - **User Administration**: tabs Users / Roles / Permissions (button **New User**)
  - **Integrations**: BI Applications (Power BI, Tableau), External Tokens, AI Config
  - **System**: Preferences, Support, Compute
  - **Custom**: SQL Query Config
- There is NO standalone Jobs menu: job history is reached from Home (**My Jobs**), Overview (**View all jobs**) and the editor's **History** tab, and Engine > Monitor > Jobs.

## Account menu (avatar, bottom-left)

**Access Tokens** (opens dialog **Personal Access Tokens** with **Generate Token**, **Delete All**, columns Token ID / Label / Creation / Expiration), **Language**, **Sign out**. There is no "Account Settings" item.

## Add Source — source types actually offered

- Lakehouse Catalogs: Apache Polaris (Incubating), AWS Glue Data Catalog, Hive 2.x, Hive 3.x, Iceberg REST Catalog, Nessie, Snowflake Open Catalog, Unity Catalog
- Object Storage: Amazon S3, Azure Storage, Google Cloud Storage, HDFS, NAS / Local Path
- Databases: Amazon OpenSearch Service, Amazon Redshift, Druid, Elasticsearch, Google BigQuery, IBM Db2, Microsoft Azure Data Explorer, Microsoft Azure Synapse Analytics, Microsoft SQL Server, MongoDB, MySQL, Oracle, PostgreSQL, SAP HANA, Snowflake, Teradata, Vertica
  (The list also contains an entry for another instance of the query engine itself; describe it as "another query engine instance" and never by vendor name.)
