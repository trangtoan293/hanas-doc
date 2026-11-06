---
title: "Quickstart: từ nguồn dữ liệu đến câu trả lời"
sidebar_label: Quickstart
sidebar_position: 5
description: Hướng dẫn đi từ đăng nhập, thêm nguồn, truy vấn, lưu view và tăng tốc đến xem kết quả trong Analytics hoặc hỏi Kapas.
---

Quickstart này dẫn bạn qua một tình huống ngân hàng bán lẻ: tổng hợp giao dịch theo khách hàng, lưu thành view và dùng lại cho phân tích. Bạn sẽ hoàn thành khoảng sáu bước trong Hanas Console.

## Điều kiện cần

- Tài khoản Hanas và quyền đăng nhập Console.
- Quyền thêm source, hoặc một source đã được quản trị viên tạo sẵn.
- Một nguồn dữ liệu chứa ba bảng mẫu: `customers`, `accounts` và `transactions`.
- Quyền tạo view trong một workspace hoặc folder của bạn.
- Tuỳ chọn: Analytics hoặc Kapas đã được triển khai.

Các tên source, workspace và bảng trong ví dụ là giả định; hãy thay bằng tên trong môi trường của bạn.

## Các bước

### 1. Đăng nhập

1. Mở địa chỉ Hanas Console do quản trị viên cung cấp.
2. Đăng nhập bằng tài khoản SSO của tổ chức.
3. Sau khi vào **Home**, kiểm tra menu bạn thấy; xem [Làm quen Hanas Console](console-tour.md) nếu thiếu khu vực cần dùng.

### 2. Thêm nguồn dữ liệu

1. Mở **Connections**, chọn **New Source**.
2. Chọn loại nguồn, ví dụ cơ sở dữ liệu quan hệ chứa dữ liệu ngân hàng bán lẻ.
3. Nhập endpoint và thông tin xác thực. Dùng tài khoản chỉ đọc; không dán secret thật vào tài liệu hay chat.
4. Tạo source, rồi duyệt folder và table để xác nhận thấy ba bảng mẫu.

Danh sách loại nguồn phụ thuộc bản query engine triển khai. Xem [Nguồn dữ liệu truy vấn trực tiếp](../connect/data-sources.md).

### 3. Truy vấn trong SQL Editor

1. Mở **SQL Editor** (menu **Workspaces**) và tạo tab mới.
2. Chạy câu truy vấn tổng hợp giao dịch theo khách hàng:

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

3. Chọn **Run** để thực thi hoặc **Preview** để xem nhanh. Kiểm tra kết quả và trạng thái job.

Xem [SQL Editor](../query/sql-studio.md).

### 4. Lưu thành view

1. Trong SQL Editor, chọn **Save as View**.
2. Chọn workspace và folder đích, đặt tên, ví dụ `customer_txn_summary`.
3. Lưu và mở lại view từ cây dữ liệu để kiểm tra.

View lưu định nghĩa SQL, không lưu riêng kết quả. Xem [Workspace, folder và view](../query/spaces-and-views.md).

### 5. Tạo Reflection (tuỳ chọn)

Nếu view chạy chậm trên dữ liệu lớn, bạn có thể tạo Reflection cho nó.

1. Mở view và vào cấu hình tăng tốc của dataset.
2. Chọn loại Reflection phù hợp: RAW hoặc AGGREGATION.
3. Bật Reflection và theo dõi trạng thái refresh.

Planner chỉ dùng Reflection khi tìm được phương án phù hợp, nên hãy so sánh profile job trước và sau. Xem [Tăng tốc truy vấn với Reflection](../query/acceleration.md).

### 6. Xem trong Analytics hoặc hỏi Kapas

- **Analytics**: mở **Analytics**, tạo dataset BI trỏ tới view và dựng chart. Lưu view chưa tự tạo dashboard. Xem [Analytics với Superset](../bi/superset.md).
- **Kapas**: mở **AI Agent** và đặt câu hỏi như "Khách hàng nào có tổng giá trị giao dịch cao nhất?". Kapas chạy SQL dưới danh nghĩa bạn, nên chỉ thấy dữ liệu bạn được phép đọc. Hãy đối chiếu kết quả với view. Xem [Hỏi đáp dữ liệu với Kapas](../kapas/chat-with-data.md).

:::note Điều kiện

Analytics và Kapas chỉ dùng được khi quản trị viên đã triển khai và cấu hình thành phần đó; Kapas cần thêm model AI hợp lệ.

:::

## Xử lý sự cố

| Hiện tượng | Hướng kiểm tra |
|---|---|
| Không thấy **New Source** | Tài khoản có thể thiếu quyền; liên hệ quản trị viên |
| Không duyệt được table | Kiểm tra quyền của tài khoản kết nối ở nguồn và quyền trên source |
| Truy vấn báo lỗi không tìm thấy bảng | Kiểm tra tên source, schema và context trong SQL Editor |
| Không lưu được view | Kiểm tra quyền ghi vào workspace hoặc folder đích |

Xem thêm [Lịch sử job và profile truy vấn](../query/jobs.md) để đọc chi tiết lỗi.

## Tiếp theo

- [Khái niệm chính](concepts.md).
- [Nạp dữ liệu vào lakehouse](../connect/ingestion.md).
- [Khám phá đối tượng](../ontology/explore.md).
- [Hỏi đáp dữ liệu với Kapas](../kapas/chat-with-data.md).
