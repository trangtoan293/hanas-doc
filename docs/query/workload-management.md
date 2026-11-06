---
title: Engine, queue và điều phối tải
sidebar_label: Workload management
sidebar_position: 6
description: Quản lý engine, queue và quy tắc định tuyến truy vấn, kèm màn hình giám sát hoạt động của node.
---

Workload management giúp quản trị viên chia tài nguyên tính toán giữa các nhóm người dùng và loại truy vấn: engine cung cấp tài nguyên, queue giới hạn tải, còn quy tắc định tuyến quyết định truy vấn nào vào queue nào.

:::note Điều kiện

Các màn hình này nằm trong phần quản trị của Hanas Console, cần quyền quản trị. Khả năng dùng thực tế phụ thuộc bản triển khai query engine của bạn có bật quản lý engine và workload hay không. Nếu menu hiện nhưng thao tác báo lỗi, hãy liên hệ nhóm vận hành. Hãy xem đây là chức năng **(Preview)** cho đến khi bạn xác nhận trên môi trường của mình.

:::

## Khái niệm

| Thành phần | Vai trò |
|---|---|
| Engine | Nhóm tài nguyên thực thi truy vấn, có kích thước và trạng thái. |
| Queue | Hàng đợi với giới hạn: ưu tiên CPU, số truy vấn đồng thời, bộ nhớ của queue và của mỗi job. |
| Quy tắc định tuyến | Điều kiện đánh giá theo thứ tự để chọn queue cho từng truy vấn. |
| Quy tắc mặc định | Áp dụng cho mọi truy vấn không khớp quy tắc nào. |

```mermaid
flowchart LR
    Q["Truy vấn"] --> R{"Quy tắc định tuyến"}
    R -->|Khớp| A["Queue theo quy tắc"]
    R -->|Không khớp| D["Queue mặc định"]
    A --> E["Engine"]
    D --> E
```

## Quản lý engine

Trang **Engines** liệt kê engine kèm trạng thái và kích thước; bạn lọc theo hai tiêu chí này. Từ đây bạn tạo engine mới hoặc điều chỉnh số lượng tài nguyên của engine hiện có.

## Quản lý queue

1. Mở trang **Queues** trong phần quản trị.
2. Chọn thêm queue và đặt tên.
3. Đặt ưu tiên CPU, giới hạn đồng thời, giới hạn bộ nhớ của queue và của mỗi job.
4. Lưu; queue xuất hiện trong danh sách để dùng trong quy tắc định tuyến.

## Quy tắc định tuyến

1. Mở trang **Engine Routing**.
2. Thêm quy tắc, đặt tên, nhập điều kiện và chọn queue đích. Bạn cũng chọn từ chối truy vấn khớp quy tắc.
3. Kéo thả để sắp xếp thứ tự; quy tắc ở trên được đánh giá trước.
4. Chỉnh quy tắc mặc định cho các truy vấn còn lại.

Ví dụ ý tưởng: truy vấn của nhóm dashboard vào queue giới hạn đồng thời thấp, truy vấn của nhóm ETL vào queue bộ nhớ lớn.

## Giám sát

Màn hình monitor và **Node Activity** cho thấy hoạt động của job và node. Dùng chúng kết hợp với [Lịch sử job](jobs.md) để xác định queue hoặc node quá tải.

## Xử lý sự cố

| Hiện tượng | Cách kiểm tra |
|---|---|
| Không lưu được queue hoặc quy tắc | Kiểm tra quyền quản trị và bản triển khai có hỗ trợ workload management. |
| Truy vấn không vào queue mong đợi | Kiểm tra thứ tự quy tắc; quy tắc phía trên khớp trước. |
| Job chờ lâu | Tăng giới hạn đồng thời hoặc chuyển tải sang queue khác. |

## Tiếp theo

- [Lịch sử job](jobs.md).
- [Tăng tốc với Reflection](acceleration.md).
- [Kiểm tra sức khỏe và giám sát](../operate/health-checks.md).
