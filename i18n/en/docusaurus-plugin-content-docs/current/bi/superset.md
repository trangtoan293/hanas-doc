---
title: Analytics with Superset in Console
sidebar_label: Superset
sidebar_position: 1
description: Use Apache Superset embedded in Hanas Console to create datasets, charts, and dashboards on query engine data.
---

The Analytics menu in Hanas Console embeds Apache Superset so you can create charts and dashboards on lakehouse data. This page is for analysts and BI developers; the configuration parts are for administrators.

## Concepts

| Component | Description |
|---|---|
| Database connection | The connection from Superset to the query engine, preconfigured by the platform. |
| Dataset | A query engine table or view, or a SQL statement, used as the source for charts. |
| Chart | A visualization on a dataset. |
| Dashboard | A set of charts with filters, shared with others. |

Superset sends queries to the query engine, so results are subject to the same permissions, Reflections, and load limits as queries from [SQL Studio](../query/sql-studio.md).

## Requirements

:::note Requirements

Superset is an optional component. When enabled, the platform runs Superset with its own PostgreSQL and Redis, and sign-in goes through Keycloak. An initialization task issues a personal access token (PAT) so Superset can connect to the query engine and stores it in a Kubernetes Secret. If you do not see the Analytics menu, ask an administrator to check this component.

:::

## Access and sign in

1. Open **Analytics** in Hanas Console.
2. Superset signs you in automatically with your Keycloak identity; you do not need a separate account.
3. The first time you sign in, Superset creates the corresponding user and assigns roles based on your Keycloak groups.

## Create datasets, charts, and dashboards

1. Open **Datasets** and choose to create a new dataset.
2. Choose the query engine database, the schema (namespace or space), and the table or view. You can also use SQL Lab to write a query and save it as a dataset.
3. Give it a clear name, and define calculated columns and shared metrics.
4. Open **Charts**, choose a dataset and a chart type, configure dimensions, metrics, and filters, then save.
5. Open **Dashboards**, create a dashboard, and add the charts.
6. Share the dashboard with the appropriate users or roles.

Build datasets on standardized gold views. Keeping business logic in views makes every chart consistent, and Reflections accelerate repeated queries.

## Permissions

| Layer | Mechanism |
|---|---|
| Superset roles | Preconfigured: `superset_admin` maps to the Admin role, `superset_user` maps to the Gamma role. Roles are synchronized on every sign-in. |
| Data permissions | Determined by the query engine, based on grants on sources, spaces, folders, tables, and views. |

Synchronizing roles from Keycloak does not automatically grant read permission on data in the query engine. A person who can view a dashboard can still see data according to the identity that Superset uses to query.

:::caution Current limitations

Superset connects to the query engine with a service PAT created by the initialization task. User impersonation depends on the integration configuration of each deployment; a PAT obtained from a user signed in through SSO cannot be used for this flow. Before you share a dashboard that contains sensitive data, confirm with an administrator which identity is actually used for queries, and verify with a restricted account. The expiration of the service PAT is set by the administrator; a rotation policy is required.

:::

## Troubleshooting

| Symptom | Resolution |
|---|---|
| You do not see Analytics | Superset is not enabled or not ready; finishing the deployment does not mean Superset is Ready. |
| The dataset does not list tables | Check the permissions of the query identity on that schema and table. |
| Authentication error when querying | Ask an administrator to check that the Superset PAT is still valid. |
| Slow chart | Build the dataset on a gold view and consider a Reflection. |

## Next

- [Accelerate queries with Reflections](../query/acceleration.md).
- [Connect external BI tools](external-bi.md).
- [Data access control](../govern/access-control.md).
