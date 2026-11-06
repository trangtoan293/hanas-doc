---
title: Tăng tốc truy vấn với Reflection
sidebar_label: Reflection
sidebar_position: 4
description: Dùng Raw và Aggregation Reflection để tăng tốc truy vấn lặp lại, cấu hình refresh và theo dõi trạng thái.
---

Reflection là bản sao dữ liệu đã được tối ưu mà query engine tự dùng khi lập kế hoạch truy vấn. Người dùng vẫn truy vấn bảng hoặc view gốc; engine chọn Reflection phù hợp nếu có. Trang này dành cho data engineer và quản trị viên cần cải thiện hiệu năng các truy vấn lặp lại.

## Khái niệm

| Loại | Nội dung lưu | Khi nào dùng |
|---|---|---|
| Raw Reflection | Tập con cột của dataset, có thể sắp xếp và phân vùng lại. | Truy vấn chọn nhiều cột, lọc theo cột cụ thể, hoặc nguồn chậm. |
| Aggregation Reflection | Kết quả tổng hợp theo dimension và measure. | Dashboard và báo cáo lặp lại các phép `GROUP BY`, `SUM`, `COUNT`. |

Reflection có thể tạo trên bảng lẫn view. Reflection không thay thế việc bảo trì bảng Iceberg; xem [Bảng Iceberg](iceberg-tables.md).

## Điều kiện cần

:::note Điều kiện

Bạn cần quyền quản trị trên dataset để tạo hoặc sửa Reflection. Reflection tốn dung lượng lưu trữ và tài nguyên khi refresh, nên chỉ tạo cho truy vấn thực sự lặp lại.

:::

## Tạo Reflection

1. Mở dataset trong SQL Editor (menu **Workspaces**) hoặc cây dữ liệu và chọn mục cài đặt tăng tốc (Acceleration).
2. Chọn tab **Raw Reflections** hoặc **Aggregation Reflections**.
3. Với Raw, chọn các cột hiển thị và tuỳ chọn sắp xếp, phân vùng. Với Aggregation, chọn dimension và measure.
4. Bật Reflection rồi lưu.

Bạn cũng tạo bằng SQL:

```sql
ALTER TABLE gold.retail.active_account
    CREATE RAW REFLECTION active_account_raw
    USING DISPLAY (account_id, customer_id, segment);
```

Các khai báo `DIMENSIONS` và `MEASURES` dùng cho Aggregation Reflection.

## Refresh

Reflection được làm mới theo chính sách của dataset: theo lịch hoặc khi dữ liệu nguồn đổi, tuỳ cấu hình. Để làm mới thủ công:

```sql
ALTER TABLE gold.retail.active_account REFRESH REFLECTIONS;
```

Dữ liệu trong Reflection có thể cũ hơn nguồn cho đến lần refresh kế tiếp. Với báo cáo cần dữ liệu tức thời, hãy kiểm tra chính sách refresh trước khi dựa vào Reflection.

## Theo dõi

Bảng hệ thống `sys.reflections` liệt kê Reflection cùng trạng thái:

```sql
SELECT * FROM sys.reflections;
```

Trang **Reflections** trong menu **Engine** của Hanas Console hiển thị loại, dataset, trạng thái refresh, lỗi, dung lượng và mức sử dụng. Trong chi tiết một [job](jobs.md), phần Reflection cho biết truy vấn có dùng Reflection hay không.

Trong **Engine** → **Monitor**, Hanas Console còn có mục **Autonomous Reflections**, kèm nhật ký **History**. Bạn xem mục này cùng trang **Reflections** khi theo dõi tăng tốc.

:::caution Giới hạn hiện tại

Trang hiệu năng (Performance) có thể hiển thị dữ liệu mẫu khi chưa có dữ liệu thật. Đừng dùng số liệu ở đó làm bằng chứng hiệu năng; hãy đối chiếu với `sys.reflections` và job profile.

:::

## Xử lý sự cố

| Hiện tượng | Cách kiểm tra |
|---|---|
| Reflection ở trạng thái lỗi | Xem thông báo lỗi ở trang Reflection và job refresh tương ứng. |
| Truy vấn không dùng Reflection | Kiểm tra cột, dimension và measure có phủ truy vấn không, và Reflection đã bật. |
| Dữ liệu cũ | Kiểm tra thời điểm refresh gần nhất, chạy refresh thủ công nếu cần. |
| Dung lượng tăng nhanh | Xóa Reflection ít dùng, thu hẹp cột hoặc dimension. |

## Tiếp theo

- [Lịch sử job](jobs.md).
- [Engine, queue và điều phối tải](workload-management.md).
- [Workspace, folder và view](spaces-and-views.md).
