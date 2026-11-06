---
title: Workspaces, folders, and views (semantic layer)
sidebar_label: Workspaces and views
sidebar_position: 2
description: Organize workspaces, spaces, folders, and views into a semantic layer by bronze, silver, and gold, and manage their permissions.
---

The query engine organizes data into an object tree: sources and the lakehouse hold physical data, while workspaces and spaces hold the views that you define. This page helps data engineers and analytics engineers build a clear semantic layer that is easy to manage permissions for.

## Concepts

| Object | Role |
|---|---|
| Source, lakehouse | Where physical data lives; Iceberg tables and data from connected sources. |
| Workspace, space | Logical containers that hold folders and views. A space is usually tied to a group of users or a domain. |
| Folder | Groups views inside a space. |
| Physical dataset | Data that the query engine has recognized (tables, files, formatted directories). |
| View (virtual dataset) | A saved SQL statement; it does not copy data, and each time you query the view it re-runs the underlying SQL. |

A physical dataset is real data, while a view is only a definition. As a result, editing a view does not change the source data, and deleting a view does not delete data.

## Organize by bronze, silver, gold

Mirror the medallion model in your space structure. The full model is in [Modeling standards](../transform/modeling-standards.md).

| Layer | Contents | Suggested layout |
|---|---|---|
| Bronze | Raw data from ingestion. | `bronze_*` schemas in the lakehouse; do not put views here. |
| Silver | Cleaned, standardized data. | Iceberg tables created by dbt, or views in the `silver` space. |
| Gold | Business-ready data. | Views in the `gold` space, split into folders by domain (for example `retail`, `risk`). |

An example gold view for the retail banking domain:

```sql
CREATE OR REPLACE VIEW gold.retail.active_account AS
SELECT a.account_id, a.customer_id, c.segment
FROM Lakehouse.silver_retail.account AS a
JOIN Lakehouse.silver_retail.customer AS c
  ON a.customer_id = c.customer_id
WHERE a.account_status = 'ACTIVE';
```

Name objects according to the [Naming conventions](../transform/naming-conventions.md) so users can recognize the layer and domain from the path.

## Create spaces, folders, and views

1. In the data tree of **SQL Studio**, select the action to create a new workspace or space.
2. Create folders in the space to group views by domain.
3. Run a query, select **Save as View**, and then select the destination space and folder. See [SQL Studio](sql-studio.md).
4. Open the saved view to edit the SQL, view the columns, and check the summary information.

You can also create views directly with `CREATE VIEW` or `CREATE OR REPLACE VIEW`.

## Permissions

Permissions on views and folders are granted by role or user, separate from permissions on the source data. Common patterns:

| Goal | Approach |
|---|---|
| Let the analyst group read gold but not silver | Grant select permission on the `gold` space, and do not grant it on silver. |
| Mask sensitive data | Use row access and masking; see [Data access control](../govern/access-control.md). |
| Let owners edit views | Keep write permission on the folder for the data engineering group. |

:::note Requirements

A view reads the underlying sources with the permissions of the view owner or of the querying user, depending on configuration. Test with a trial account before publishing a view to a wide group.

:::

## Troubleshooting

| Symptom | What to check |
|---|---|
| A user cannot see a space | Check permissions on the space and the user's roles. |
| A view fails after the source table's schema changes | Open the view, check that the columns still exist, and save the corrected SQL. |
| Querying a view is slow | Look at the job profile and consider [Reflections](acceleration.md). |

## Next steps

- [Accelerate queries with Reflections](acceleration.md).
- [Modeling standards](../transform/modeling-standards.md).
- [Data access control](../govern/access-control.md).
