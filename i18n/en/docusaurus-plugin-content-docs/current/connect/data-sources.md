---
title: Query data sources in place
sidebar_label: Data sources
sidebar_position: 1
description: Add sources in Data Hub to query object storage, catalogs, and other systems directly with SQL, including metadata refresh options and file formats.
---

This page shows you how to add a source to **Hanas Console** so the query engine queries data in place, without copying it. If you need to store a copy in the lakehouse, see [Ingest data into the lakehouse](./ingestion.md).

## Concepts

- **Source**: a connection to an external system. After you add it, you can browse the source's folders and tables in the data tree.
- **Physical dataset**: a file or table in a source whose format has been recognized so you can query it with SQL.
- **View**: a saved SQL statement created on a physical dataset; see [Workspaces, folders, and views](../query/spaces-and-views.md).

## Connector groups

The table below lists the connector groups that the query engine implements as plugins.

| Group | Connectors |
|---|---|
| Object storage | Amazon S3 (and S3-compatible storage through endpoint configuration), Azure Storage, Google Cloud Storage |
| File system | HDFS, NAS (local or shared directory) |
| Lakehouse catalog | AWS Glue Data Catalog, Nessie (versioned catalog), Iceberg REST Catalog, Hive Metastore |
| Search and NoSQL | Elasticsearch (including Amazon Elasticsearch), MongoDB |

:::note Requirements

The actual list shown in **New Source** is returned by the backend of your release. Some groups, such as Iceberg REST Catalog, MongoDB, and Hive, depend on the deployment package and the authentication method. Relational databases (PostgreSQL, MySQL, Oracle, SQL Server) may appear in the list; check your environment before promising them to users. If you need stable data from these systems, use [Ingestion](./ingestion.md).

:::

## Prerequisites

- Permission to create sources in the query engine (usually an administrator).
- Connection details: endpoint, credentials, bucket or root path.
- Network access from the query engine to the source system.

## Add a source

1. Open **Data Hub** or the data tree in SQL Studio, and select **New Source**.
2. Select the source type from the list. The list is grouped by lakehouse, object storage, and database.
3. Enter the connection and authentication details. The fields vary by source type.
4. Open the optional tabs if you want to change the **Metadata** or **Reflection Refresh** policy (see below).
5. Select save to create the source. The source appears in the data tree.
6. Browse the source's folders and tables. For file-based sources, format the file as a physical dataset (see below), then open it in SQL Studio or create a view.

The **New Source** screen also has a tab for importing source configuration from a JSON file, for when you need to create many sources at once.

## Metadata refresh options

The query engine stores source metadata (name lists, dataset definitions) to speed up queries. The **Metadata** tab controls how fresh that metadata is.

| Option | Meaning | Default value in the form |
|---|---|---|
| Name list refresh frequency | How often to check for new folder and table names | 1 hour |
| Refresh dataset definitions after | How often to re-read dataset schemas | 1 hour |
| Expire dataset definitions after | How long until metadata is considered stale | 3 hours |

The console checks minimum values and requires the expiration time to be no less than the refresh time. The **Reflection Refresh** tab configures the refresh period or schedule and the expiration of [Reflections](../query/acceleration.md) created on the source's datasets.

## Format files as physical datasets

For file-based sources, the query engine needs to know the format before you can query.

1. In the data tree, open the source and select the file or folder.
2. Select the format action (**Format**) and choose a type: delimited text, JSON, Parquet, Excel, and other tabular formats that the dialog offers.
3. Adjust the options (delimiter, header row, and so on) and preview the data.
4. Save. The file or folder becomes a physical dataset; you query it with SQL or create a view.

To undo, select remove format. The file returns to the unformatted state; the original data is not deleted.

## Limitations

:::caution Current limitations

- Federation reads directly from the source, so performance depends on the source system and the network. Use Reflections or Ingestion for repeated queries.
- Some internal query engine plugins are not meant for users to add and do not appear in the list.

:::

## Next steps

- [Upload files](./file-upload.md) if you only have a few loose files.
- [SQL Studio](../query/sql-studio.md) to query datasets.
- [Reflections](../query/acceleration.md) to speed up queries on external sources.
