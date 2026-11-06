---
title: SQL Editor
sidebar_label: SQL Editor
sidebar_position: 1
description: Write and run SQL in Hanas Console with the SQL Editor, using the data tree, scripts, context, Run, multiple statements, the AI Agent panel, and saving queries as views.
---

The SQL Editor is the SQL editor in Hanas Console, opened from the **Workspaces** menu (the **SQL Editor** card on **Home** also leads here). You use it to explore data, try queries, and save results as views for others to reuse. Each run creates a query engine job, so you can review it later in the editor's **History** tab or in [Job history](jobs.md).

## Layout

| Component | Meaning |
|---|---|
| Left panel | Three tabs: **DATA**, **SCRIPTS**, and **FUNCTIONS**. DATA is the data tree; SCRIPTS holds named, saved SQL; FUNCTIONS lists the functions you can use. |
| Data tree | Two sections: **Workspaces** (your personal workspace, shown as `@user`) and **Spaces**. It shows only objects you have permission to view. |
| Editor | The SQL input area, with a **Run** button, **Save as View**, and a **Context** selector. |
| Context | The default path (source, schema, or space) so you can write short table names. |
| Result tabs | **Results** shows the returned data; **History** lists earlier runs. |
| **AI Agent** | An embedded panel next to the editor for asking questions and getting help writing SQL. |

Select an object in the data tree to insert its path into the SQL or to view summary information.

## Run a query

1. Open **Workspaces** from the Hanas Console menu to reach the SQL Editor.
2. Select a **Context** if you want to write short table names, for example `account` instead of `Lakehouse.silver_retail.account`.
3. Enter SQL in the editor.
4. Select **Run** or press `Ctrl/Cmd + Enter` to execute.
5. View the results in the **Results** tab; earlier runs are in the **History** tab.

If you highlight a piece of SQL, Run executes only the selected part. When nothing is selected, the editor runs the entire content.

## Multiple statements

You can write multiple statements separated by semicolons and run them at once. The SQL Editor tracks each statement with its own status.

```sql
CREATE TABLE Lakehouse.silver_retail.account_stage AS
SELECT account_id, customer_id, account_status
FROM Lakehouse.bronze_retail.account;

SELECT account_status, COUNT(*) AS total
FROM Lakehouse.silver_retail.account_stage
GROUP BY account_status;
```

Statements run sequentially. If a statement fails or is cancelled, the later statements do not run and are marked **not run**.

## Autocomplete and results

The editor suggests object and function names as you type and flags syntax errors. The results table in the **Results** tab supports column operations such as sorting and showing or hiding columns.

Results shown in the browser are only a portion of the data. For large datasets, write the results into a table with `CREATE TABLE AS` instead of pulling everything to the client.

## Save a query as a view

1. Run the query and check that the results are what you expect.
2. Select **Save as View**.
3. Select the destination space and folder; you can create a new folder right in the dialog.
4. Enter a view name and confirm.

A view stores both the SQL statement and the context at the time of saving. For how to place views in the bronze, silver, and gold layers, see [Workspaces, folders, and views](spaces-and-views.md).

## Limitations

:::caution Current limitations

Some write operations (`INSERT`, `UPDATE`, `DELETE`, `MERGE`) are supported only on Iceberg tables and require write permission on the target object. See [Iceberg tables](iceberg-tables.md).

:::

## Troubleshooting

| Symptom | What to check |
|---|---|
| "table not found" error | Check the context and write the full path; put names with special characters in double quotes. |
| Later statements do not run | An earlier statement failed or was cancelled; see the error in the **History** tab or in [Job history](jobs.md). |
| Cannot save a view | Check write permission on the destination space and that the view name is not already taken. |

## Next steps

- [Workspaces, folders, and views](spaces-and-views.md).
- [Iceberg tables: DDL, DML, time travel](iceberg-tables.md).
- [SQL reference](sql-reference.md).
