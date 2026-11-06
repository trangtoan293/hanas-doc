---
title: Workspace, folder và view (semantic layer)
sidebar_label: Workspace và view
sidebar_position: 2
description: Tổ chức workspace, space, folder và view thành semantic layer theo bronze, silver, gold, cùng cách phân quyền.
---

Query engine tổ chức dữ liệu thành cây đối tượng: source và lakehouse chứa dữ liệu vật lý, còn workspace và space chứa view do bạn định nghĩa. Trang này giúp data engineer và analytics engineer dựng semantic layer rõ ràng và dễ phân quyền.

## Khái niệm

| Đối tượng | Vai trò |
|---|---|
| Source, lakehouse | Nơi dữ liệu vật lý nằm; bảng Iceberg và dữ liệu từ nguồn kết nối. |
| Workspace, space | Container logic chứa folder và view. Space thường gắn với một nhóm người dùng hoặc một lĩnh vực. |
| Folder | Nhóm view bên trong space. |
| Physical dataset | Dữ liệu đã được query engine nhận diện (bảng, tệp, thư mục đã định dạng). |
| View (virtual dataset) | Câu SQL đã lưu; không sao chép dữ liệu, mỗi lần truy vấn view chạy lại SQL gốc. |

Physical dataset là dữ liệu có thật, còn view chỉ là định nghĩa. Vì vậy sửa view không làm đổi dữ liệu nguồn, và xóa view không xóa dữ liệu.

## Tổ chức theo bronze, silver, gold

Bạn nên phản chiếu mô hình medallion trong cấu trúc space. Mô hình đầy đủ nằm ở [Chuẩn mô hình hóa](../transform/modeling-standards.md).

| Lớp | Nội dung | Gợi ý bố trí |
|---|---|---|
| Bronze | Dữ liệu thô từ ingestion. | Schema `bronze_*` trong lakehouse; không đặt view ở đây. |
| Silver | Dữ liệu đã làm sạch, chuẩn hóa. | Bảng Iceberg do dbt tạo, hoặc view trong space `silver`. |
| Gold | Dữ liệu sẵn sàng cho nghiệp vụ. | View trong space `gold`, chia folder theo domain (ví dụ `retail`, `risk`). |

Ví dụ một view gold cho miền ngân hàng bán lẻ:

```sql
CREATE OR REPLACE VIEW gold.retail.active_account AS
SELECT a.account_id, a.customer_id, c.segment
FROM Lakehouse.silver_retail.account AS a
JOIN Lakehouse.silver_retail.customer AS c
  ON a.customer_id = c.customer_id
WHERE a.account_status = 'ACTIVE';
```

Hãy đặt tên theo [Quy ước đặt tên](../transform/naming-conventions.md) để người dùng nhận ra lớp và domain ngay từ đường dẫn.

## Tạo space, folder và view

1. Mở **Workspaces** để vào SQL Editor. Trong cây dữ liệu (nhóm **Workspaces** và **Spaces**), chọn thao tác tạo workspace hoặc space mới.
2. Tạo folder trong space để nhóm view theo domain.
3. Chạy truy vấn, chọn **Save as View**, rồi chọn space và folder đích. Xem [SQL Editor](sql-studio.md).
4. Mở view đã lưu để chỉnh SQL, xem cột và kiểm tra thông tin tóm tắt.

Bạn cũng tạo view trực tiếp bằng `CREATE VIEW` hoặc `CREATE OR REPLACE VIEW`.

## Phân quyền

Quyền trên view và folder được cấp theo role hoặc user, tách khỏi quyền trên dữ liệu nguồn. Mẫu thường dùng:

| Mục tiêu | Cách làm |
|---|---|
| Cho nhóm analyst đọc gold nhưng không đọc silver | Cấp quyền chọn (select) trên space `gold`, không cấp trên silver. |
| Che dữ liệu nhạy cảm | Dùng row access và masking, xem [Phân quyền dữ liệu](../govern/access-control.md). |
| Người sở hữu chỉnh sửa view | Giữ quyền ghi trên folder cho nhóm data engineer. |

:::note Điều kiện

Một view đọc được nguồn bên dưới theo quyền của chủ sở hữu view hoặc của người truy vấn tùy cấu hình. Hãy kiểm tra bằng một tài khoản thử trước khi công bố view cho nhóm rộng.

:::

## Xử lý sự cố

| Hiện tượng | Cách kiểm tra |
|---|---|
| Người dùng không thấy space | Kiểm tra quyền trên space và role của người dùng. |
| View lỗi sau khi bảng nguồn đổi schema | Mở view, kiểm tra cột còn tồn tại và lưu lại SQL đã sửa. |
| Truy vấn view chậm | Xem job profile và cân nhắc [Reflection](acceleration.md). |

## Tiếp theo

- [Tăng tốc với Reflection](acceleration.md).
- [Chuẩn mô hình hóa](../transform/modeling-standards.md).
- [Phân quyền dữ liệu](../govern/access-control.md).
