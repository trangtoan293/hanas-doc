---
title: SQL Editor
sidebar_label: SQL Editor
sidebar_position: 1
description: Soạn và chạy SQL trong Hanas Console bằng SQL Editor, dùng cây dữ liệu, script, context, Run, nhiều statement, AI Agent và lưu truy vấn thành view.
---

SQL Editor là trình soạn thảo SQL trong Hanas Console, mở từ menu **Workspaces** (thẻ **SQL Editor** trên **Home** cũng dẫn tới đây). Bạn dùng nó để khám phá dữ liệu, thử truy vấn và lưu kết quả thành view cho người khác dùng lại. Mỗi lần chạy tạo một job của query engine, nên bạn xem lại được ở tab **History** của trình soạn thảo hoặc trong [Lịch sử job](jobs.md).

## Bố cục

| Thành phần | Ý nghĩa |
|---|---|
| Panel bên trái | Ba tab **DATA**, **SCRIPTS** và **FUNCTIONS**. DATA là cây dữ liệu; SCRIPTS chứa SQL đã lưu có tên; FUNCTIONS liệt kê các hàm có thể dùng. |
| Cây dữ liệu | Hai nhóm: **Workspaces** (workspace cá nhân dạng `@user`) và **Spaces**. Chỉ hiển thị đối tượng bạn có quyền xem. |
| Trình soạn thảo | Vùng nhập SQL, có nút **Run**, **Save as View** và bộ chọn **Context**. |
| Context | Đường dẫn mặc định (source, schema hoặc space) để viết tên bảng ngắn gọn. |
| Tab kết quả | **Results** hiển thị dữ liệu trả về; **History** liệt kê các lần chạy trước. |
| **AI Agent** | Panel nhúng bên cạnh trình soạn thảo để hỏi và nhờ hỗ trợ viết SQL. |

Chọn một đối tượng trong cây dữ liệu để chèn đường dẫn vào SQL hoặc xem thông tin tóm tắt.

## Chạy một truy vấn

1. Mở **Workspaces** từ menu của Hanas Console để vào SQL Editor.
2. Chọn **Context** nếu bạn muốn viết tên bảng ngắn, ví dụ `account` thay cho `Lakehouse.silver_retail.account`.
3. Nhập SQL vào trình soạn thảo.
4. Chọn **Run** hoặc nhấn `Ctrl/Cmd + Enter` để thực thi.
5. Xem kết quả ở tab **Results**; các lần chạy trước nằm ở tab **History**.

Nếu bạn bôi đen một đoạn SQL, Run chỉ thực thi đoạn được chọn. Khi không chọn gì, trình soạn thảo chạy toàn bộ nội dung.

## Nhiều statement

Bạn có thể viết nhiều statement ngăn cách bằng dấu chấm phẩy rồi chạy một lần. SQL Editor theo dõi từng statement với trạng thái riêng.

```sql
CREATE TABLE Lakehouse.silver_retail.account_stage AS
SELECT account_id, customer_id, account_status
FROM Lakehouse.bronze_retail.account;

SELECT account_status, COUNT(*) AS total
FROM Lakehouse.silver_retail.account_stage
GROUP BY account_status;
```

Các statement chạy tuần tự. Nếu một statement lỗi hoặc bị hủy, các statement sau không chạy và được đánh dấu **not run**.

## Autocomplete và kết quả

Trình soạn thảo gợi ý tên đối tượng và hàm khi bạn gõ, đồng thời đánh dấu lỗi cú pháp. Bảng kết quả ở tab **Results** hỗ trợ thao tác trên cột như sắp xếp và ẩn hiện cột.

Kết quả hiển thị trong trình duyệt chỉ là một phần dữ liệu. Với tập dữ liệu lớn, hãy ghi kết quả vào bảng bằng `CREATE TABLE AS` thay vì kéo toàn bộ về client.

## Lưu truy vấn thành view

1. Chạy truy vấn và kiểm tra kết quả đúng như mong muốn.
2. Chọn **Save as View**.
3. Chọn space và folder đích; bạn có thể tạo folder mới ngay trong hộp thoại.
4. Đặt tên view rồi xác nhận.

View lưu cả câu SQL và context tại thời điểm lưu. Xem thêm cách đặt view vào lớp bronze, silver, gold ở [Workspace, folder và view](spaces-and-views.md).

## Giới hạn

:::caution Giới hạn hiện tại

Một số thao tác ghi (`INSERT`, `UPDATE`, `DELETE`, `MERGE`) chỉ hỗ trợ trên bảng Iceberg và cần quyền ghi trên đối tượng đích. Xem [Bảng Iceberg](iceberg-tables.md).

:::

## Xử lý sự cố

| Hiện tượng | Cách kiểm tra |
|---|---|
| Lỗi "table not found" | Kiểm tra context và viết đường dẫn đầy đủ, đặt tên có ký tự đặc biệt trong dấu nháy kép. |
| Statement sau không chạy | Statement trước đã lỗi hoặc bị hủy; xem lỗi ở tab **History** hoặc trong [Lịch sử job](jobs.md). |
| Không lưu được view | Kiểm tra quyền ghi trên space đích và tên view chưa bị trùng. |

## Tiếp theo

- [Workspace, folder và view](spaces-and-views.md).
- [Bảng Iceberg: DDL, DML, time travel](iceberg-tables.md).
- [Tham chiếu SQL](sql-reference.md).
