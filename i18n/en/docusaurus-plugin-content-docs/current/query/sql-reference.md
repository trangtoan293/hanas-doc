---
title: SQL reference
sidebar_label: SQL reference
sidebar_position: 7
description: Overview of the query engine's SQL command groups, function groups, and data types, with common examples.
---

This page summarizes what you can write in the SQL Editor (opened from the **Workspaces** menu) and through SQL clients. It is an overview and does not list every function; use autocomplete in the [SQL Editor](sql-studio.md) to see the full list of functions.

## Command groups

| Group | Representative commands | Notes |
|---|---|---|
| Query | `SELECT`, `WITH`, `JOIN`, `GROUP BY`, window functions | Read data from tables, views, and connected sources. |
| Table DDL | `CREATE TABLE`, `CREATE TABLE AS`, `ALTER TABLE`, `DROP TABLE`, `TRUNCATE` | Details in [Iceberg tables](iceberg-tables.md). |
| DML | `INSERT`, `UPDATE`, `DELETE`, `MERGE` | On Iceberg tables; requires write permission. |
| Maintenance | `OPTIMIZE TABLE`, `VACUUM TABLE`, `ROLLBACK TABLE` | File and snapshot cleanup. |
| Views | `CREATE VIEW`, `CREATE OR REPLACE VIEW`, `DROP VIEW` | See [Workspaces and views](spaces-and-views.md). |
| User-defined functions | `CREATE FUNCTION`, `DROP FUNCTION`, `DESCRIBE FUNCTION` | SQL UDFs; check permissions when using them. |
| Discovery | `SHOW TABLES`, `SHOW VIEWS`, `DESCRIBE` | List objects and columns. |
| Statistics | `ANALYZE TABLE ... COMPUTE STATISTICS` | Provides statistics to the query planner. |
| Plan analysis | `EXPLAIN PLAN FOR` | View the execution plan. |

To query a table in a different state, use `AT SNAPSHOT` or `AT TIMESTAMP`; see [Iceberg tables](iceberg-tables.md).

## Function groups

| Group | Examples |
|---|---|
| String | `CONCAT`, `SUBSTR`, `UPPER`, `TRIM`, `REGEXP_REPLACE` |
| Numeric and math | `ROUND`, `ABS`, `MOD`, `CEIL`, `FLOOR` |
| Date and time | `CURRENT_DATE`, `DATE_ADD`, `DATE_TRUNC`, `TO_DATE` |
| Type conversion | `CAST`, `TO_CHAR`, `TO_NUMBER` |
| Complex data | `ARRAY_CONTAINS`, `FLATTEN`, functions on `MAP` and `STRUCT` |
| Context | `QUERY_USER()` returns the user running the query |
| Data masking | Mask functions that transform displayed values |

Mask functions only transform data within an expression. To apply a per-user masking policy, see [Data access control](../govern/access-control.md).

## Data types

| Group | Common types |
|---|---|
| Integer | `INT`, `BIGINT` |
| Decimal | `DECIMAL(p, s)`, `FLOAT`, `DOUBLE` |
| String | `VARCHAR`, `VARBINARY` |
| Logical | `BOOLEAN` |
| Time | `DATE`, `TIME`, `TIMESTAMP`, `INTERVAL` |
| Complex | `LIST`, `STRUCT`, `MAP` |

The exact type mapping depends on the source; directly connected sources may support only part of it.

## Examples

Total transactions by day and account status:

```sql
SELECT DATE_TRUNC('DAY', t.txn_time) AS txn_day,
       a.account_status,
       SUM(t.amount) AS total_amount
FROM Lakehouse.silver_retail.transaction AS t
JOIN Lakehouse.silver_retail.account AS a
  ON t.account_id = a.account_id
GROUP BY DATE_TRUNC('DAY', t.txn_time), a.account_status
ORDER BY txn_day;
```

View the execution plan:

```sql
EXPLAIN PLAN FOR
SELECT account_id FROM Lakehouse.silver_retail.account WHERE account_status = 'ACTIVE';
```

## Limitations

:::caution Current limitations

This documentation does not claim full compatibility with the ANSI SQL standard or with every function of other database systems. User-defined functions are currently SQL UDFs; do not assume support for UDFs written in other languages.

:::

## Next steps

- [SQL Editor](sql-studio.md).
- [Iceberg tables](iceberg-tables.md).
- [JDBC, ODBC, and Arrow Flight](../develop/sql-clients.md).
