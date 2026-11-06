---
title: Metadata ingestion
sidebar_label: Metadata ingestion
sidebar_position: 2
description: Create sources and recipes, test connections, run on a schedule, monitor Run History, and manage Secrets in Hanas Catalog.
---

Metadata ingestion brings metadata from source systems into Hanas Catalog. This page is for catalog administrators. Do not confuse it with [Ingestion](../connect/ingestion.md), the feature that loads data into the lakehouse.

## Concepts

| Component | Description |
|---|---|
| Source | A configuration that collects metadata from one source system. |
| Recipe | The part of a source's configuration that defines the connection and collection scope. |
| Execution (run) | One run of a source, manual or scheduled. |
| Secret | A sensitive value such as a password or token, kept separate from the recipe. |

Hanas Catalog creates a run in the database, a runner picks up the run, runs the connector, and records the result. When the run completes, the metadata is indexed and lineage is updated; Console reads the results through the search and details screens.

## Requirements

:::note Requirements

Every action in the **Ingestion** section of Data Governance, including viewing, requires the Data Governance admin role. A query engine admin is automatically a Data Governance admin. See [Data access control](access-control.md).

:::

## Supported connectors

| Source type | Notes |
|---|---|
| Query engine | Collects dataset metadata from the query engine. |
| Hanas | Uses the platform's query engine connection configuration and lets you choose which containers to collect. |
| Oracle | Collects metadata from an Oracle database. |
| dbt | Gets artifacts from a dbt Studio project or from a separate configuration. |
| Superset | Collects dashboard and chart metadata according to configuration and permissions. |

A deployment can enable other source types if the catalog image is built with the corresponding dependencies. Contact your deployment administrator.

:::caution Current limitations

Metadata connectors for Iceberg and dbt Cloud are blocked in Hanas Catalog. This does not affect how the query engine and Ingestion work with Iceberg tables.

:::

## Create a source

1. Open **Data Governance**, choose **Ingestion**, then the **Sources** tab.
2. Choose the action to create a new source and select the source type.
3. Fill in the connection information in the recipe form. For sensitive values, reference a Secret instead of entering them directly.
4. Choose **Test connection** to check the connection before saving.
5. Set the run schedule: enter a cron expression and choose a time zone, or leave it to run manually.
6. Save the source.

The example below shows the structure of a recipe. The actual configuration keys depend on the source type.

```yaml
source:
  type: oracle
  config:
    host_port: "<host>:1521"
    database: "<service_name>"
    username: "<user>"
    password: "${ORACLE_PASSWORD}"
```

Here `ORACLE_PASSWORD` is the name of a Secret you have created.

## Run, cancel, and roll back

| Action | Description |
|---|---|
| Run | Run the source immediately, without waiting for the schedule. |
| Cancel | Stop a running run. |
| Rollback | Undo the metadata changes of a completed run, done from Run History. |
| Delete source data | Delete the metadata already collected for the source, with a preview of the scope. |

Scheduled runs use a cron expression. For a Hanas-type source, scheduled runs use the service credentials configured by the deployment administrator.

## Run History

The **Run History** tab lists runs with their status, time, and detailed report. Open a run to see the log and the number of entities collected; this is the first place to check when a source reports an error.

## Secrets

The **Secrets** tab manages the sensitive values used in recipes. You create, update, and delete secrets here.

:::caution Note

Do not paste passwords directly into a recipe. Use a Secret so the value does not appear in the configuration or logs.

:::

## Troubleshooting

| Symptom | Resolution |
|---|---|
| Test connection fails | Check the host, credentials, and network access from where the catalog runs. |
| A run is stuck in the running state | Use Cancel, then check Run History. |
| You do not see the Ingestion section | You do not have the Data Governance admin role. |
| A new dataset does not appear yet | Rerun the source or check the container scope in the recipe. |

## Next steps

- [Search and discover data assets](catalog.md)
- [Lineage](lineage.md)
- [Data access control](access-control.md)
