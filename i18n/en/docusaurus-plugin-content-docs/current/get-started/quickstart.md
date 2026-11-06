---
title: "Quickstart: From Data Source to Answer"
sidebar_label: Quickstart
sidebar_position: 5
description: A walkthrough from signing in, adding a source, querying, saving a view, and accelerating, to viewing results in Analytics or asking Kapas.
---

This quickstart walks you through a retail banking scenario: aggregate transactions by customer, save the result as a view, and reuse it for analysis. You complete about six steps in Hanas Console.

## Requirements

- A Hanas account and permission to sign in to Console.
- Permission to add a source, or a source that an administrator has already created.
- A data source that contains three sample tables: `customers`, `accounts`, and `transactions`.
- Permission to create views in one of your workspaces or folders.
- Optional: Analytics or Kapas deployed.

The source, workspace, and table names in the example are assumptions; replace them with the names in your environment.

## Steps

### 1. Sign in

1. Open the Hanas Console address provided by your administrator.
2. Sign in with your organization's SSO account.
3. After you reach **Home**, check the menus you see; see [Get to know Hanas Console](console-tour.md) if an area you need is missing.

### 2. Add a data source

1. Open **Connections** and select **New Source**.
2. Choose the source type, for example a relational database that holds retail banking data.
3. Enter the endpoint and the credentials. Use a read-only account; do not paste real secrets into documents or chats.
4. Create the source, then browse the folders and tables to confirm you see the three sample tables.

The list of source types depends on the deployed query engine version. See [Direct-query data sources](../connect/data-sources.md).

### 3. Query in SQL Editor

1. Open **SQL Editor** (menu **Workspaces**) and create a new tab.
2. Run a query that aggregates transactions by customer:

```sql
SELECT c.customer_id,
       c.full_name,
       COUNT(t.transaction_id) AS txn_count,
       SUM(t.amount)           AS total_amount
FROM   retail_src.customers c
JOIN   retail_src.accounts a     ON a.customer_id = c.customer_id
JOIN   retail_src.transactions t ON t.account_id  = a.account_id
GROUP  BY c.customer_id, c.full_name
```

3. Select **Run** to execute or **Preview** for a quick look. Check the result and the job status.

See [SQL Editor](../query/sql-studio.md).

### 4. Save as a view

1. In SQL Editor, select **Save as View**.
2. Choose the destination workspace and folder, and enter a name, for example `customer_txn_summary`.
3. Save, then reopen the view from the data tree to verify it.

A view stores the SQL definition, not a separate copy of the result. See [Workspaces, folders, and views](../query/spaces-and-views.md).

### 5. Create a Reflection (optional)

If the view runs slowly on large data, you can create a Reflection for it.

1. Open the view and go to the dataset's acceleration settings.
2. Choose a suitable Reflection type: RAW or AGGREGATION.
3. Enable the Reflection and monitor the refresh status.

The planner uses a Reflection only when it finds a suitable plan, so compare the job profile before and after. See [Accelerate queries with Reflections](../query/acceleration.md).

### 6. View in Analytics or ask Kapas

- **Analytics**: open **Analytics**, create a BI dataset that points to the view, and build a chart. Saving a view does not automatically create a dashboard. See [Analytics with Superset](../bi/superset.md).
- **Kapas**: open **AI Agent** and ask a question such as "Which customers have the highest total transaction value?". Kapas runs SQL on your behalf, so it sees only the data you are allowed to read. Verify the results against the view. See [Chat with your data using Kapas](../kapas/chat-with-data.md).

:::note Requirements

Analytics and Kapas are available only when an administrator has deployed and configured the component; Kapas also needs a valid AI model.

:::

## Troubleshooting

| Symptom | What to check |
|---|---|
| You do not see **New Source** | Your account might lack permission; contact an administrator |
| You cannot browse tables | Check the permissions of the connecting account at the source and your permissions on the source |
| The query reports that a table is not found | Check the source name, schema, and context in SQL Editor |
| You cannot save the view | Check write permission on the destination workspace or folder |

See also [Job history and query profiles](../query/jobs.md) to read error details.

## Next

- [Key concepts](concepts.md).
- [Load data into the lakehouse](../connect/ingestion.md).
- [Explore objects](../ontology/explore.md).
- [Chat with your data using Kapas](../kapas/chat-with-data.md).
