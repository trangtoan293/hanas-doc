---
title: Thu thập metadata
sidebar_label: Thu thập metadata
sidebar_position: 2
description: Tạo source và recipe, kiểm tra kết nối, chạy theo lịch, theo dõi Run History và quản lý Secrets trong Hanas Catalog.
---

import Diagram from '@site/src/components/Diagram';

Metadata ingestion đưa metadata từ các hệ thống nguồn vào Hanas Catalog. Trang này dành cho quản trị viên catalog. Đừng nhầm với [Ingestion](../connect/ingestion.md), tính năng nạp dữ liệu vào lakehouse.

<Diagram name="05-catalog-ingestion" alt="Hanas Catalog thu thập metadata" />

## Khái niệm

| Thành phần | Mô tả |
|---|---|
| Source | Một cấu hình thu thập metadata từ một hệ thống nguồn. |
| Recipe | Phần cấu hình kết nối và phạm vi thu thập của source. |
| Execution (run) | Một lần chạy của source, thủ công hoặc theo lịch. |
| Secret | Giá trị nhạy cảm như mật khẩu hoặc token, tách khỏi recipe. |

Hanas Catalog tạo run trong cơ sở dữ liệu, một runner nhận run, chạy connector và ghi kết quả. Khi run hoàn tất, metadata được lập chỉ mục và lineage được cập nhật; Console đọc kết quả qua màn hình tìm kiếm và chi tiết.

## Điều kiện cần

:::note Điều kiện

Mọi thao tác trong mục **Data Sources** của Data Governance, kể cả xem, cần role admin Data Governance. Admin của query engine tự động là admin Data Governance. Xem [Phân quyền dữ liệu](access-control.md).

:::

## Connector được hỗ trợ

| Loại source | Ghi chú |
|---|---|
| Query engine | Thu thập metadata dataset của query engine. |
| Hanas | Dùng cấu hình kết nối query engine của nền tảng và cho phép chọn container cần thu thập. |
| Oracle | Thu thập metadata từ cơ sở dữ liệu Oracle. |
| dbt | Lấy artifact từ project dbt Studio hoặc từ cấu hình riêng. |
| Superset | Thu thập metadata dashboard và chart theo cấu hình và quyền. |

Triển khai có thể bật thêm loại source khác nếu image catalog được dựng với dependency tương ứng. Liên hệ quản trị viên triển khai.

:::caution Giới hạn hiện tại

Connector metadata cho Iceberg và dbt Cloud bị chặn trong Hanas Catalog. Điều này không ảnh hưởng đến việc query engine và Ingestion làm việc với bảng Iceberg.

:::

## Tạo source

1. Mở **Data Governance**, chọn **Data Sources**. Trang có tiêu đề **Manage Data Sources** với các tab **Sources**, **Run History** và **Secrets**. Mở tab **Sources**.
2. Chọn **Create Source** và chọn loại source.
3. Điền thông tin kết nối trong form recipe. Với giá trị nhạy cảm, tham chiếu một Secret thay vì nhập trực tiếp.
4. Chọn **Test connection** để kiểm tra kết nối trước khi lưu.
5. Đặt lịch chạy: nhập biểu thức cron và chọn múi giờ, hoặc để chạy thủ công.
6. Lưu source.

Ví dụ dưới đây minh họa cấu trúc một recipe. Khóa cấu hình thực tế phụ thuộc loại source.

```yaml
source:
  type: oracle
  config:
    host_port: "<host>:1521"
    database: "<service_name>"
    username: "<user>"
    password: "${ORACLE_PASSWORD}"
```

Trong đó `ORACLE_PASSWORD` là tên một Secret bạn đã tạo.

## Chạy, hủy và rollback

| Thao tác | Mô tả |
|---|---|
| Run | Chạy source ngay, không đợi lịch. |
| Cancel | Dừng một run đang chạy. |
| Rollback | Hoàn tác thay đổi metadata của một run đã hoàn tất, thực hiện từ Run History. |
| Xóa dữ liệu source | Xóa metadata đã thu thập của source, có bản xem trước phạm vi. |

Chạy theo lịch dùng biểu thức cron. Với source loại Hanas, lần chạy theo lịch dùng thông tin xác thực dịch vụ do quản trị viên triển khai cấu hình.

## Run History

Tab **Run History** liệt kê các lần chạy kèm trạng thái, thời gian và báo cáo chi tiết. Mở một run để xem log và số lượng thực thể đã thu thập; đây là nơi đầu tiên cần kiểm tra khi source báo lỗi.

## Secrets

Tab **Secrets** quản lý các giá trị nhạy cảm dùng trong recipe. Bạn tạo, cập nhật và xóa secret ở đây.

:::caution Lưu ý

Không dán mật khẩu trực tiếp vào recipe. Dùng Secret để giá trị không hiện trong cấu hình và log.

:::

## Xử lý sự cố

| Hiện tượng | Cách xử lý |
|---|---|
| Test connection thất bại | Kiểm tra host, thông tin đăng nhập và quyền mạng từ nơi catalog chạy. |
| Run kẹt ở trạng thái đang chạy | Dùng Cancel, rồi xem Run History. |
| Không thấy mục Data Sources | Bạn chưa có role admin Data Governance. |
| Dataset mới chưa xuất hiện | Chạy lại source hoặc kiểm tra phạm vi container trong recipe. |

## Tiếp theo

- [Tìm kiếm và khám phá tài sản dữ liệu](catalog.md)
- [Lineage](lineage.md)
- [Phân quyền dữ liệu](access-control.md)
