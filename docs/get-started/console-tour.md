---
title: Làm quen Hanas Console
sidebar_label: Làm quen Console
sidebar_position: 4
description: Các khu vực menu của Hanas Console, đối tượng sử dụng và điều kiện hiển thị.
---

Hanas Console là giao diện web chung của Hanas Data Platform. Trang này giúp bạn xác định khu vực nào phục vụ công việc của mình và vì sao một menu có thể không xuất hiện với tài khoản của bạn.

## Điều kiện hiển thị menu

Menu trên Console phụ thuộc ba yếu tố: thành phần có được triển khai và bật hay không, role của bạn và cấu hình tính năng của môi trường. Menu bị ẩn không thay thế kiểm tra quyền ở backend; ngược lại, thấy menu chưa chắc bạn được phép thao tác trên mọi đối tượng.

## Các khu vực chính

| Menu | Bạn làm gì | Ai thường dùng |
|---|---|---|
| Home | Xem hoạt động gần đây và đi tới các công cụ | Mọi người dùng |
| Data Hub | Xem nguồn theo nhóm, thêm source, duyệt folder, table và view | Analyst, data engineer |
| SQL Studio | Viết và chạy SQL nhiều tab, xem kết quả và job, lưu view, quản lý workspace và folder trong cây dữ liệu | Analyst, data engineer |
| Data Governance | Tìm kiếm tài sản dữ liệu, xem schema, ownership, glossary, tag, lineage; quản lý thu thập metadata | Data steward, analyst; quản trị Catalog |
| Ingestion | Tạo và theo dõi luồng nạp dữ liệu, quản lý nguồn và đích | Data engineer |
| dbt | Quản lý dbt project, phát triển model trong IDE, chạy và lập lịch dbt, khám phá dữ liệu | Data engineer, analytics engineer |
| Pipeline | Thiết kế canvas, xem danh sách Pipeline, lịch và kết quả từng bước | Data engineer |
| Compute | Quản lý project PySpark và notebook, chạy và xem log | Data engineer, data scientist |
| Ontology | Khám phá đối tượng, theo dõi yêu cầu thay đổi, thiết kế và quản trị ontology | Người dùng nghiệp vụ, chuyên gia mô hình hóa |
| AI Agent (Kapas) | Hội thoại với agent để hỏi dữ liệu và tạo báo cáo | Mọi người dùng được cấp agent |
| Analytics | Mở Apache Superset để dựng chart và dashboard | Analyst, đội BI |
| Engine | Giám sát node, quản lý engine, queue, quy tắc định tuyến và Reflection | Quản trị query engine |
| Settings | Quản lý user, role, quyền; ứng dụng BI, token provider bên ngoài, cấu hình AI và truy vấn | Quản trị viên |
| Account Settings | Quản lý thông tin tài khoản và PAT | Mọi người dùng |

## Chi tiết từng khu vực

### Home và Data Hub

Home là trang vào, tập hợp hoạt động gần đây. Data Hub liệt kê các source và cho phép thêm source mới; từ đây bạn mở một table hoặc view để truy vấn hoặc xem lineage. Xem [Nguồn dữ liệu truy vấn trực tiếp](../connect/data-sources.md).

### SQL Studio

SQL Studio là nơi làm việc chính với query engine: nhiều tab và script, chọn context, **Run** và **Preview**, xem kết quả và job. Khi nhiều câu lệnh được chạy cùng lúc, chuỗi dừng nếu một câu lỗi hoặc bị hủy. Bạn lưu truy vấn thành view bằng **Save as View**. Xem [SQL Studio](../query/sql-studio.md) và [Workspace, folder và view](../query/spaces-and-views.md).

### Data Governance

Khu vực này dùng Hanas Catalog. Bạn tìm tài sản, mở trang chi tiết dataset và quản lý glossary, tag. Phần thu thập metadata (Sources, Run History, Secrets) chỉ dành cho người quản trị Data Governance. Xem [Tìm kiếm và khám phá tài sản dữ liệu](../govern/catalog.md) và [Thu thập metadata](../govern/metadata-ingestion.md).

### Ingestion, dbt, Pipeline, Compute

Bốn khu vực này phục vụ data engineer. Ingestion nạp dữ liệu vào Iceberg ([Ingestion](../connect/ingestion.md)). dbt gồm trang chủ, danh sách project, IDE, khu vực khám phá và lịch chạy ([dbt Studio](../transform/dbt-studio.md)). Pipeline điều phối nhiều bước ([Pipeline](../transform/pipelines.md)). Compute chạy Spark ([Compute](../transform/compute.md)).

### Ontology, AI Agent và Analytics

Ontology có các phần khám phá, yêu cầu, thiết kế (Workbench), quản trị và cài đặt ([Ontology](../ontology/index.md)). AI Agent mở Kapas ([Kapas AI](../kapas/index.md)). Analytics nhúng Superset ([Analytics với Superset](../bi/superset.md)).

### Engine và Settings

Engine dành cho người quản trị tải truy vấn: giám sát, engine, queue và Reflection ([Engine, queue và điều phối tải](../query/workload-management.md)). Settings gồm user, role, quyền và các cấu hình hệ thống ([Quản lý người dùng, group và role](../operate/user-management.md)).

### Account Settings và PAT

Trong Account Settings, bạn liệt kê PAT, tạo PAT mới với nhãn và hạn dùng, sao chép token vừa tạo và thu hồi token không còn dùng. Token chỉ hiển thị khi tạo, nên hãy lưu ở nơi an toàn. Xem [Tổng quan tích hợp](../develop/index.md).

:::note Điều kiện

- dbt cần được bật cho môi trường và bạn cần role dbt tương ứng.
- Data Governance, Ingestion, Compute, Ontology, AI Agent và Analytics chỉ dùng được khi thành phần đã được triển khai và cấu hình.
- Engine và Settings dành cho tài khoản quản trị.
- Chức năng PAT cần query engine được triển khai hỗ trợ cấp token.

:::

:::caution Giới hạn hiện tại

Một số menu có thể bị ẩn tuỳ phiên bản Console, ví dụ khu vực quản lý view riêng và Jobs độc lập; các thao tác này được truy cập qua SQL Studio. Một số màn hình trong Engine phụ thuộc bản query engine được triển khai.

:::

## Tiếp theo

- [Quickstart](quickstart.md).
- [Khái niệm chính](concepts.md).
- [SQL Studio](../query/sql-studio.md).
