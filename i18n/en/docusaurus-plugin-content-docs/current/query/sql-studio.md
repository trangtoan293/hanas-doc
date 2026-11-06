---
title: SQL Studio
sidebar_label: SQL Studio
sidebar_position: 1
description: Write and run SQL in Hanas Console, use tabs, context, Run, Preview, multiple statements, and save queries as views.
---

SQL Studio is the SQL editor in Hanas Console. You use it to explore data, try queries, and save results as views for others to reuse. Each run creates a query engine job, so you can review it later in [Job history](jobs.md).

## Concepts

| Component | Meaning |
|---|---|
| Tab | An independent SQL editing area. You open multiple tabs to work on several queries in parallel. |
| Script | Named, saved SQL that you can reopen later. |
| Context | The default path (source, schema, or space) so you can write short table names. |
| Run | Executes the SQL and records a full job. |
| Preview | A quick run that shows a sample of the results, suited to when you are refining a query. |

The data tree on the left shows the spaces, sources, and lakehouses that you have permission to view. Select an object to insert its path into the SQL or to view summary information such as owner, creation date, and the number of recent jobs.

## Run a query

1. Open **SQL Studio** from the Hanas Console menu.
2. Select a **context** if you want to write short table names, for example `account` instead of `Lakehouse.silver_retail.account`.
3. Enter SQL in the editor.
4. Select **Run** to execute, or **Preview** for a quick look.
5. View the results in the table below; the job status appears with the tab.

If you highlight a piece of SQL, Run and Preview execute only the selected part. When nothing is selected, the editor runs the entire content.

| Shortcut | Action |
|---|---|
| `Ctrl/Cmd + Shift + Enter` | Run |
| `Ctrl/Cmd + Enter` | Preview |
| `Ctrl/Cmd + S` | Save script |
| `Ctrl/Cmd + Shift + F` | Format SQL |

## Multiple statements

You can write multiple statements separated by semicolons and run them at once. SQL Studio tracks each statement with its own status.

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

The editor suggests object and function names as you type and flags syntax errors. The results table supports column operations such as sorting and showing or hiding columns.

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
| Later statements do not run | An earlier statement failed or was cancelled; see the error in [Job history](jobs.md). |
| Cannot save a view | Check write permission on the destination space and that the view name is not already taken. |

## Next steps

- [Workspaces, folders, and views](spaces-and-views.md).
- [Iceberg tables: DDL, DML, time travel](iceberg-tables.md).
- [SQL reference](sql-reference.md).
