---
title: Tài liệu Hanas Data Platform
sidebar_label: Trang chủ tài liệu
sidebar_position: 0
description: Hướng dẫn sử dụng, quản trị, vận hành và tích hợp Hanas Data Platform theo vai trò và thành phần sản phẩm.
slug: /
---

Hanas Data Platform là nền tảng dữ liệu doanh nghiệp kết hợp lakehouse, truy vấn SQL, biến đổi, quản trị metadata, Ontology và AI. Hanas Console cung cấp giao diện chung để kết nối dữ liệu, phát triển mô hình và sử dụng kết quả phân tích. Nền tảng được triển khai trên Kubernetes trong hạ tầng on-premise hoặc private cloud của tổ chức.

Tài liệu này giúp bạn sử dụng từng thành phần, hiểu luồng dữ liệu và xác định điều kiện triển khai tương ứng. Nếu mới tiếp cận Hanas, hãy đọc [giới thiệu nền tảng](get-started/introduction.md), sau đó thực hiện [quickstart](get-started/quickstart.md).

## Bắt đầu theo vai trò

### Người dùng nghiệp vụ và analyst

Bạn tìm dữ liệu, kiểm tra ý nghĩa chỉ số và phân tích thông qua SQL, đối tượng nghiệp vụ hoặc hội thoại.

- [Làm quen Hanas Console](get-started/console-tour.md): xác định khu vực làm việc và công cụ phù hợp.
- [Quickstart](get-started/quickstart.md): truy vấn nguồn dữ liệu và lưu view dùng lại.
- [Khám phá đối tượng](ontology/explore.md): xem record, thuộc tính và quan hệ trong Ontology.
- [Hỏi đáp dữ liệu với Kapas](kapas/chat-with-data.md): đặt câu hỏi với phạm vi và ngữ cảnh dữ liệu rõ ràng.

### Data engineer

Bạn kết nối nguồn, nạp dữ liệu vào Iceberg, phát triển model và điều phối các bước xử lý.

- [Kết nối dữ liệu](connect/index.md): chọn truy vấn trực tiếp, tải tệp hoặc Ingestion.
- [Nạp dữ liệu vào lakehouse](connect/ingestion.md): cấu hình nguồn, đích và chế độ đồng bộ.
- [dbt Studio](transform/dbt-studio.md): quản lý project, SQL model và quy trình phát triển.
- [Pipeline](transform/pipelines.md): tổ chức các bước xử lý theo quan hệ phụ thuộc.

### Quản trị và vận hành

Bạn chuẩn bị hạ tầng, quản lý danh tính và duy trì các dịch vụ theo cấu hình triển khai.

- [Kiến trúc triển khai](operate/deployment-architecture.md): xem các dịch vụ và phụ thuộc hạ tầng.
- [Cài đặt bằng helmfile](operate/install.md): triển khai thành phần đã chọn trên Kubernetes.
- [Xác thực và SSO](operate/identity.md): cấu hình Keycloak và kết nối danh tính giữa ứng dụng.
- [Sao lưu và khôi phục](operate/backup-recovery.md): xác định dữ liệu trạng thái và thứ tự khôi phục.

### Nhà phát triển tích hợp

Bạn sử dụng API hoặc SQL client để đưa dữ liệu và khả năng phân tích vào ứng dụng khác.

- [Tổng quan tích hợp](develop/index.md): lựa chọn giao diện và phương thức xác thực.
- [JDBC, ODBC và Arrow Flight](develop/sql-clients.md): kết nối ứng dụng truy vấn dữ liệu.
- [REST API của query engine](develop/query-engine-api.md): gửi SQL, theo dõi job và lấy kết quả.
- [Kapas API và SSE](develop/kapas-api.md): tích hợp hội thoại và nhận phản hồi theo luồng.

## Các thành phần sản phẩm

| Thành phần | Vai trò | Tài liệu |
|---|---|---|
| Hanas Console | Giao diện chung cho dữ liệu, phát triển, phân tích và quản trị | [Làm quen Console](get-started/console-tour.md) |
| Query Engine | Truy vấn SQL, view, job và Reflection | [Query Engine](query/index.md) |
| Ingestion | Nạp dữ liệu từ nguồn vào bảng Iceberg, theo dõi lịch và checkpoint | [Ingestion](connect/ingestion.md) |
| dbt Studio | Phát triển model, quản lý Git, chạy và kiểm thử dbt | [dbt Studio](transform/dbt-studio.md) |
| Pipeline | Điều phối các bước xử lý theo dependency, lịch và danh tính chạy | [Pipeline](transform/pipelines.md) |
| Compute | Thực thi Spark, PySpark và notebook trên Kubernetes | [Compute](transform/compute.md) |
| Hanas Catalog | Tìm kiếm metadata, ownership, glossary, tag và lineage | [Catalog](govern/catalog.md) |
| Ontology | Mô hình đối tượng, quan hệ và metric gắn với dữ liệu | [Ontology](ontology/index.md) |
| Kapas AI | Hội thoại, agent và tool hỗ trợ khai thác dữ liệu | [Kapas AI](kapas/index.md) |
| Analytics / Apache Superset | Tạo và sử dụng dataset BI, chart, dashboard | [Analytics](bi/superset.md) |
| Keycloak | Danh tính, SSO, group và role cho các ứng dụng | [Xác thực và SSO](operate/identity.md) |
| Apache Iceberg và object storage | Lưu bảng lakehouse, metadata bảng và snapshot; có thể dùng MinIO | [Bảng Iceberg](query/iceberg-tables.md) |

:::note Điều kiện

Thành phần được bật, menu hiển thị và thao tác được phép phụ thuộc cấu hình môi trường và quyền của bạn. Có quyền truy cập Console chưa đồng nghĩa được sử dụng mọi dịch vụ hoặc đọc mọi dataset.

:::

## Đọc tài liệu theo mục đích

Để hiểu các lớp và luồng danh tính, xem [kiến trúc nền tảng](get-started/architecture.md). Để phân biệt source, view, object type và metric, xem [khái niệm chính](get-started/concepts.md). Khi cần tra cứu nhanh một thuật ngữ, sử dụng [bảng thuật ngữ](reference/glossary.md).
