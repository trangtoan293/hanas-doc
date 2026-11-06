---
title: Lịch sử job và profile truy vấn
sidebar_label: Jobs
sidebar_position: 5
description: Xem lịch sử job của query engine, lọc theo trạng thái và người dùng, đọc chi tiết SQL, thời gian, profile và hủy job.
---

Mỗi truy vấn chạy qua query engine tạo ra một job. Hanas Console không có menu Jobs riêng; bạn mở danh sách job từ các điểm vào dưới đây để kiểm tra trạng thái, tìm truy vấn chậm hoặc lỗi và đọc profile thực thi.

| Điểm vào | Dùng khi |
|---|---|
| **Home** → **My Jobs** | Xem nhanh job của chính bạn. |
| **Overview** → **View all jobs** | Xem job gần đây trên toàn nền tảng từ phần Recent Jobs. |
| Tab **History** của SQL Editor | Xem lại các lần chạy trong phiên soạn SQL. |
| **Engine** → **Monitor** → **Jobs** | Theo dõi job cùng catalog usage và tài nguyên của engine. |

## Danh sách job

Danh sách job hiển thị bảng job với các thông tin như trạng thái, loại truy vấn, người chạy, queue, dataset và thời lượng. Bạn chọn cột hiển thị theo nhu cầu.

| Bộ lọc | Công dụng |
|---|---|
| Tìm kiếm | Tìm theo nội dung hoặc mã job. |
| Thời gian bắt đầu | Chọn khoảng thời gian có sẵn hoặc khoảng tuỳ chỉnh. |
| Trạng thái | Lọc theo job đang chạy, hoàn thành, lỗi hoặc đã hủy. |
| Loại | Lọc theo nguồn gửi truy vấn, ví dụ chạy từ giao diện hay từ client bên ngoài. |
| Người dùng | Lọc theo người gửi truy vấn. |
| Queue | Lọc theo queue mà job được định tuyến vào. |

Bộ lọc được giữ khi bạn mở chi tiết một job rồi quay lại danh sách.

## Chi tiết job

Chọn một job để mở trang chi tiết gồm các tab:

| Tab | Nội dung |
|---|---|
| **Overview** | Trạng thái, thời gian, người chạy, dataset liên quan, Reflection được dùng, thông báo lỗi nếu job thất bại. |
| **SQL** | Câu SQL đã gửi. |
| **Visual profile** | Đồ thị toán tử thực thi để tìm bước tốn thời gian. |
| **Raw profile** | Nội dung profile dạng thô, và tuỳ chọn tải profile về để chia sẻ khi cần hỗ trợ. |

Khi tìm nguyên nhân truy vấn chậm, bạn so sánh thời gian ở từng giai đoạn trong visual profile và kiểm tra truy vấn có dùng [Reflection](acceleration.md) hay không.

## Hủy job

Bạn hủy job đang chạy từ tab **History** của SQL Editor hoặc từ danh sách job ở **Engine** → **Monitor** → **Jobs**. Job bị hủy chuyển sang trạng thái đã hủy; trong chuỗi nhiều statement, các statement sau không được chạy.

:::note Điều kiện

Người dùng thường chỉ xem và hủy job của chính mình. Quản trị viên xem được job của mọi người dùng.

:::

## Xử lý sự cố

| Hiện tượng | Cách kiểm tra |
|---|---|
| Không thấy job của người khác | Bạn cần quyền quản trị để xem job của người dùng khác. |
| Job nằm lâu ở trạng thái chờ | Kiểm tra queue và giới hạn đồng thời ở [Engine, queue và điều phối tải](workload-management.md). |
| Job lỗi | Mở tab Overview đọc thông báo lỗi, sau đó đối chiếu SQL ở tab SQL. |

## Tiếp theo

- [SQL Editor](sql-studio.md).
- [Tăng tốc với Reflection](acceleration.md).
- [Engine, queue và điều phối tải](workload-management.md).
