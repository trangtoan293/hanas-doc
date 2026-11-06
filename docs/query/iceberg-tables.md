---
title: Bảng Iceberg — DDL, DML, time travel
sidebar_label: Bảng Iceberg
sidebar_position: 3
description: Tạo và thay đổi bảng Apache Iceberg bằng SQL, bảo trì file và snapshot, truy vấn lịch sử bằng time travel.
---

Bảng Apache Iceberg là định dạng bảng chính của lakehouse trong Hanas Data Platform. Trang này hướng dẫn data engineer tạo bảng, ghi dữ liệu, bảo trì và truy vấn lịch sử bằng SQL của query engine. Tên đối tượng trong ví dụ là minh họa.

:::note Điều kiện

Khả năng ghi phụ thuộc source hoặc catalog chứa bảng, định dạng bảng và quyền của bạn. DML chỉ hỗ trợ trên bảng Iceberg, không áp dụng cho mọi nguồn kết nối trực tiếp.

:::

## Tạo bảng

```sql
CREATE TABLE Lakehouse.silver_retail.transaction (
    transaction_id BIGINT,
    account_id     VARCHAR,
    amount         DECIMAL(18, 2),
    txn_time       TIMESTAMP
)
PARTITION BY (DAY(txn_time));
```

`PARTITION BY` nhận các transform như `YEAR`, `MONTH`, `DAY`, `HOUR`, `TRUNCATE` và `IDENTITY`. Bạn cũng tạo bảng từ truy vấn:

```sql
CREATE TABLE Lakehouse.silver_retail.account AS
SELECT account_id, customer_id, account_status
FROM Lakehouse.bronze_retail.account;
```

## Ghi và sửa dữ liệu

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

`MERGE` phù hợp khi bạn upsert từ bảng staging:

```sql
MERGE INTO Lakehouse.silver_retail.account AS t
USING Lakehouse.bronze_retail.account_delta AS s
ON t.account_id = s.account_id
WHEN MATCHED THEN UPDATE SET account_status = s.account_status
WHEN NOT MATCHED THEN INSERT (account_id, customer_id, account_status)
    VALUES (s.account_id, s.customer_id, s.account_status);
```

`TRUNCATE TABLE` xóa toàn bộ dòng của bảng.

## Thay đổi schema

```sql
ALTER TABLE Lakehouse.silver_retail.account ADD COLUMNS (opened_date DATE);
ALTER TABLE Lakehouse.silver_retail.account DROP COLUMN opened_date;
ALTER TABLE Lakehouse.silver_retail.account
    ALTER COLUMN account_status SET MASKING POLICY mask_status (account_status);
```

`ALTER TABLE` còn hỗ trợ đổi tên hoặc kiểu cột (`CHANGE`, `ALTER`, `MODIFY COLUMN`) và thêm hoặc bỏ partition field. Với masking policy, xem [Phân quyền dữ liệu](../govern/access-control.md).

## Bảo trì bảng

Mỗi lần ghi tạo thêm file dữ liệu và snapshot. Bảo trì định kỳ giúp giữ truy vấn nhanh và dung lượng gọn. Đây là việc dọn file và snapshot, khác với [Reflection](acceleration.md).

```sql
-- Gộp file nhỏ
OPTIMIZE TABLE Lakehouse.silver_retail.transaction
    REWRITE DATA USING BIN_PACK (target_file_size_mb = 256);

-- Gộp manifest
OPTIMIZE TABLE Lakehouse.silver_retail.transaction REWRITE MANIFESTS;

-- Xóa snapshot cũ
VACUUM TABLE Lakehouse.silver_retail.transaction
    EXPIRE SNAPSHOTS older_than = '2026-10-01 00:00:00' retain_last = 5;

-- Xóa file mồ côi
VACUUM TABLE Lakehouse.silver_retail.transaction
    REMOVE ORPHAN FILES older_than = '2026-10-01 00:00:00';
```

Các tuỳ chọn của `OPTIMIZE` gồm `min_input_files`, `target_file_size_mb`, `min_file_size_mb`, `max_file_size_mb`. Bạn giới hạn phạm vi bằng `FOR PARTITIONS` kèm điều kiện.

:::caution Giới hạn hiện tại

`VACUUM ... EXPIRE SNAPSHOTS` xóa snapshot cũ nên làm mất khả năng time travel và rollback về các phiên bản đó. Chọn `older_than` và `retain_last` theo nhu cầu truy vết của bạn.

:::

## Time travel

Bạn đọc bảng tại một snapshot hoặc một thời điểm trong quá khứ:

```sql
SELECT * FROM Lakehouse.silver_retail.account AT SNAPSHOT '1234567890123456789';

SELECT * FROM Lakehouse.silver_retail.account AT TIMESTAMP '2026-10-01 00:00:00';
```

Để tìm snapshot, dùng các hàm metadata:

```sql
SELECT * FROM TABLE(table_history('Lakehouse.silver_retail.account'));
SELECT * FROM TABLE(table_snapshot('Lakehouse.silver_retail.account'));
```

Muốn đưa bảng về một phiên bản cũ:

```sql
ROLLBACK TABLE Lakehouse.silver_retail.account TO SNAPSHOT '1234567890123456789';
```

Time travel chỉ dùng được với snapshot còn được giữ và source hỗ trợ.

## Xử lý sự cố

| Hiện tượng | Cách kiểm tra |
|---|---|
| DML bị từ chối | Kiểm tra bảng là Iceberg, source cho phép ghi và bạn có quyền ghi. |
| `AT SNAPSHOT` không tìm thấy | Snapshot có thể đã bị `VACUUM`; liệt kê lại bằng `table_history`. |
| Truy vấn chậm dần sau nhiều lần ghi | Chạy `OPTIMIZE TABLE` để gộp file nhỏ. |

## Tiếp theo

- [Tham chiếu SQL](sql-reference.md).
- [Tăng tốc với Reflection](acceleration.md).
- [Nạp dữ liệu vào lakehouse](../connect/ingestion.md).
