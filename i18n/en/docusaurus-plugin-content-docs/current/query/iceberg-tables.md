---
title: Iceberg tables - DDL, DML, time travel
sidebar_label: Iceberg tables
sidebar_position: 3
description: Create and alter Apache Iceberg tables with SQL, maintain files and snapshots, and query history with time travel.
---

Apache Iceberg tables are the primary table format of the lakehouse in Hanas Data Platform. This page shows data engineers how to create tables, write data, maintain tables, and query history with the query engine's SQL. Object names in the examples are illustrative.

:::note Requirements

Write capability depends on the source or catalog that holds the table, the table format, and your permissions. DML is supported only on Iceberg tables and does not apply to every directly connected source.

:::

## Create a table

```sql
CREATE TABLE Lakehouse.silver_retail.transaction (
    transaction_id BIGINT,
    account_id     VARCHAR,
    amount         DECIMAL(18, 2),
    txn_time       TIMESTAMP
)
PARTITION BY (DAY(txn_time));
```

`PARTITION BY` accepts transforms such as `YEAR`, `MONTH`, `DAY`, `HOUR`, `TRUNCATE`, and `IDENTITY`. You can also create a table from a query:

```sql
CREATE TABLE Lakehouse.silver_retail.account AS
SELECT account_id, customer_id, account_status
FROM Lakehouse.bronze_retail.account;
```

## Write and modify data

```sql
INSERT INTO Lakehouse.silver_retail.transaction
SELECT transaction_id, account_id, amount, txn_time
FROM Lakehouse.bronze_retail.transaction
WHERE txn_time >= TIMESTAMP '2026-01-01 00:00:00';

UPDATE Lakehouse.silver_retail.account
SET account_status = 'CLOSED'
WHERE account_id = 'A001';

DELETE FROM Lakehouse.silver_retail.transaction
WHERE txn_time < TIMESTAMP '2020-01-01 00:00:00';
```

`MERGE` suits upserting from a staging table:

```sql
MERGE INTO Lakehouse.silver_retail.account AS t
USING Lakehouse.bronze_retail.account_delta AS s
ON t.account_id = s.account_id
WHEN MATCHED THEN UPDATE SET account_status = s.account_status
WHEN NOT MATCHED THEN INSERT (account_id, customer_id, account_status)
    VALUES (s.account_id, s.customer_id, s.account_status);
```

`TRUNCATE TABLE` deletes all rows of the table.

## Change the schema

```sql
ALTER TABLE Lakehouse.silver_retail.account ADD COLUMNS (opened_date DATE);
ALTER TABLE Lakehouse.silver_retail.account DROP COLUMN opened_date;
ALTER TABLE Lakehouse.silver_retail.account
    ALTER COLUMN account_status SET MASKING POLICY mask_status (account_status);
```

`ALTER TABLE` also supports renaming or changing column types (`CHANGE`, `ALTER`, `MODIFY COLUMN`) and adding or dropping partition fields. For masking policies, see [Data access control](../govern/access-control.md).

## Maintain tables

Each write creates more data files and snapshots. Regular maintenance keeps queries fast and storage compact. This is file and snapshot cleanup, which is different from [Reflections](acceleration.md).

```sql
-- Compact small files
OPTIMIZE TABLE Lakehouse.silver_retail.transaction
    REWRITE DATA USING BIN_PACK (target_file_size_mb = 256);

-- Compact manifests
OPTIMIZE TABLE Lakehouse.silver_retail.transaction REWRITE MANIFESTS;

-- Expire old snapshots
VACUUM TABLE Lakehouse.silver_retail.transaction
    EXPIRE SNAPSHOTS older_than = '2026-10-01 00:00:00' retain_last = 5;

-- Remove orphan files
VACUUM TABLE Lakehouse.silver_retail.transaction
    REMOVE ORPHAN FILES older_than = '2026-10-01 00:00:00';
```

The `OPTIMIZE` options are `min_input_files`, `target_file_size_mb`, `min_file_size_mb`, and `max_file_size_mb`. You limit the scope with `FOR PARTITIONS` and a condition.

:::caution Current limitations

`VACUUM ... EXPIRE SNAPSHOTS` deletes old snapshots, so you lose the ability to time travel and roll back to those versions. Choose `older_than` and `retain_last` according to your audit-trail needs.

:::

## Time travel

You can read a table at a snapshot or at a point in the past:

```sql
SELECT * FROM Lakehouse.silver_retail.account AT SNAPSHOT '1234567890123456789';

SELECT * FROM Lakehouse.silver_retail.account AT TIMESTAMP '2026-10-01 00:00:00';
```

To find snapshots, use the metadata functions:

```sql
SELECT * FROM TABLE(table_history('Lakehouse.silver_retail.account'));
SELECT * FROM TABLE(table_snapshot('Lakehouse.silver_retail.account'));
```

To restore a table to an earlier version:

```sql
ROLLBACK TABLE Lakehouse.silver_retail.account TO SNAPSHOT '1234567890123456789';
```

Time travel works only with snapshots that are still retained and with sources that support it.

## Troubleshooting

| Symptom | What to check |
|---|---|
| DML is rejected | Check that the table is Iceberg, the source allows writes, and you have write permission. |
| `AT SNAPSHOT` not found | The snapshot may have been removed by `VACUUM`; list again with `table_history`. |
| Queries slow down after many writes | Run `OPTIMIZE TABLE` to compact small files. |

## Next steps

- [SQL reference](sql-reference.md).
- [Accelerate with Reflections](acceleration.md).
- [Ingest data into the lakehouse](../connect/ingestion.md).
