---
title: Tham chiếu SQL
sidebar_label: Tham chiếu SQL
sidebar_position: 7
description: Tổng quan nhóm lệnh SQL, nhóm hàm và kiểu dữ liệu của query engine, kèm ví dụ thường dùng.
---

Trang này tóm tắt những gì bạn viết được trong SQL Editor (mở từ menu **Workspaces**) và qua các client SQL. Đây là bản tổng quan, không liệt kê từng hàm; dùng autocomplete trong [SQL Editor](sql-studio.md) để xem danh sách hàm đầy đủ.

## Nhóm lệnh

| Nhóm | Lệnh tiêu biểu | Ghi chú |
|---|---|---|
| Truy vấn | `SELECT`, `WITH`, `JOIN`, `GROUP BY`, hàm window | Đọc dữ liệu từ bảng, view và nguồn kết nối. |
| DDL bảng | `CREATE TABLE`, `CREATE TABLE AS`, `ALTER TABLE`, `DROP TABLE`, `TRUNCATE` | Chi tiết ở [Bảng Iceberg](iceberg-tables.md). |
| DML | `INSERT`, `UPDATE`, `DELETE`, `MERGE` | Trên bảng Iceberg, cần quyền ghi. |
| Bảo trì | `OPTIMIZE TABLE`, `VACUUM TABLE`, `ROLLBACK TABLE` | Dọn file và snapshot. |
| View | `CREATE VIEW`, `CREATE OR REPLACE VIEW`, `DROP VIEW` | Xem [Workspace và view](spaces-and-views.md). |
| Hàm do người dùng | `CREATE FUNCTION`, `DROP FUNCTION`, `DESCRIBE FUNCTION` | SQL UDF; kiểm tra quyền khi dùng. |
| Khám phá | `SHOW TABLES`, `SHOW VIEWS`, `DESCRIBE` | Liệt kê đối tượng và cột. |
| Thống kê | `ANALYZE TABLE ... COMPUTE STATISTICS` | Cung cấp thống kê cho bộ lập kế hoạch. |
| Phân tích kế hoạch | `EXPLAIN PLAN FOR` | Xem kế hoạch thực thi. |

Truy vấn trên bảng ở trạng thái khác nhau dùng `AT SNAPSHOT` hoặc `AT TIMESTAMP`, xem [Bảng Iceberg](iceberg-tables.md).

## Nhóm hàm

| Nhóm | Ví dụ |
|---|---|
| Chuỗi | `CONCAT`, `SUBSTR`, `UPPER`, `TRIM`, `REGEXP_REPLACE` |
| Số và toán học | `ROUND`, `ABS`, `MOD`, `CEIL`, `FLOOR` |
| Ngày giờ | `CURRENT_DATE`, `DATE_ADD`, `DATE_TRUNC`, `TO_DATE` |
| Chuyển kiểu | `CAST`, `TO_CHAR`, `TO_NUMBER` |
| Dữ liệu phức hợp | `ARRAY_CONTAINS`, `FLATTEN`, hàm trên `MAP` và `STRUCT` |
| Ngữ cảnh | `QUERY_USER()` trả về người dùng đang chạy truy vấn |
| Che dữ liệu | Các hàm mask biến đổi giá trị hiển thị |

Các hàm mask chỉ biến đổi dữ liệu trong biểu thức. Để áp dụng chính sách che dữ liệu theo người dùng, xem [Phân quyền dữ liệu](../govern/access-control.md).

## Kiểu dữ liệu

| Nhóm | Kiểu thường gặp |
|---|---|
| Số nguyên | `INT`, `BIGINT` |
| Số thập phân | `DECIMAL(p, s)`, `FLOAT`, `DOUBLE` |
| Chuỗi | `VARCHAR`, `VARBINARY` |
| Logic | `BOOLEAN` |
| Thời gian | `DATE`, `TIME`, `TIMESTAMP`, `INTERVAL` |
| Phức hợp | `LIST`, `STRUCT`, `MAP` |

Ánh xạ kiểu cụ thể phụ thuộc source; nguồn kết nối trực tiếp có thể chỉ hỗ trợ một phần.

## Ví dụ

Tổng giao dịch theo ngày và trạng thái tài khoản:

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

Xem kế hoạch thực thi:

```sql
EXPLAIN PLAN FOR
SELECT account_id FROM Lakehouse.silver_retail.account WHERE account_status = 'ACTIVE';
```

## Giới hạn

:::caution Giới hạn hiện tại

Tài liệu này không cam kết tương thích đầy đủ với chuẩn ANSI SQL hay với mọi hàm của hệ quản trị khác. Hàm do người dùng hiện là SQL UDF; không giả định hỗ trợ UDF viết bằng ngôn ngữ khác.

:::

## Tiếp theo

- [SQL Editor](sql-studio.md).
- [Bảng Iceberg](iceberg-tables.md).
- [JDBC, ODBC và Arrow Flight](../develop/sql-clients.md).
