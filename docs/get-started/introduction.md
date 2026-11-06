---
title: Hanas Data Platform là gì
sidebar_label: Giới thiệu nền tảng
sidebar_position: 1
description: Tổng quan vai trò, thành phần và mô hình triển khai Hanas Data Platform trên Kubernetes.
---

Hanas Data Platform là nền tảng dữ liệu doanh nghiệp kết hợp lưu trữ lakehouse, truy vấn, biến đổi và khai thác dữ liệu. Nền tảng phục vụ analyst, data engineer, người dùng nghiệp vụ và đội ngũ quản trị trên các công cụ có vai trò riêng.

Bạn sử dụng Hanas Console làm điểm vào chung cho phần lớn công việc với dữ liệu. Các dịch vụ phía sau thực hiện truy vấn, nạp dữ liệu, quản lý metadata, mô hình nghiệp vụ và hỗ trợ AI.

## Hanas giải quyết công việc nào

Doanh nghiệp thường cần phân tích dữ liệu từ nhiều hệ thống với cách tổ chức và tốc độ cập nhật khác nhau. Hanas cung cấp hai hướng tiếp cận: truy vấn nguồn đã kết nối hoặc nạp dữ liệu vào bảng lakehouse để xử lý tiếp.

Trên dữ liệu đó, đội ngũ kỹ thuật có thể tạo view, phát triển dbt model và thực thi Spark. Hanas Catalog bổ sung mô tả, ownership và lineage để người sử dụng tìm hiểu tài sản dữ liệu. Ontology diễn đạt đối tượng và quan hệ nghiệp vụ, còn Kapas hỗ trợ tương tác qua ngôn ngữ tự nhiên.

Ví dụ, dữ liệu khách hàng, tài khoản và giao dịch có thể được chuẩn hóa thành các dataset phân tích. Analyst dùng view để tổng hợp giao dịch; người dùng nghiệp vụ khám phá đối tượng đã ánh xạ trong Ontology. Việc có dataset chưa tự tạo ra object type hoặc metric; đội ngũ phụ trách cần cấu hình các lớp tương ứng.

## Các thành phần

### Truy cập và truy vấn

**Hanas Console** tập hợp các khu vực kết nối dữ liệu, SQL Editor, phát triển, quản trị và phân tích. Menu phụ thuộc quyền và tính năng được bật; mỗi backend vẫn kiểm tra quyền khi nhận yêu cầu.

**Query Engine** thực thi SQL trên nguồn được hỗ trợ và bảng lakehouse. Thành phần này quản lý dataset, view, job, profile và Reflection, đồng thời cung cấp REST API và giao diện SQL client.

Một **view** lưu định nghĩa SQL để tái sử dụng, thay vì lưu riêng toàn bộ kết quả. **Reflection** tạo cấu trúc dữ liệu phục vụ tăng tốc khi planner tìm được phương án phù hợp. Hiệu quả phụ thuộc truy vấn, dữ liệu, trạng thái refresh và cấu hình triển khai.

### Nạp và xử lý dữ liệu

**Ingestion** quản lý connection, khám phá bảng nguồn, kiểm tra cấu hình và nạp dữ liệu vào Iceberg. Luồng nạp có lịch chạy, log và checkpoint; chế độ đồng bộ phụ thuộc connector và engine được chọn.

**dbt Studio** cung cấp project và IDE để phát triển SQL model, quản lý Git, chạy lệnh và kiểm thử dbt. Kết quả thực thi và artifacts hỗ trợ kiểm tra lỗi, dependency và lịch sử chạy.

**Pipeline** điều phối nhiều bước theo dependency, chẳng hạn chạy SQL rồi chạy dbt. Engine điều phối và loại bước hỗ trợ phụ thuộc môi trường; cần kiểm tra cấu hình trước khi thiết kế workflow.

**Compute** cung cấp project PySpark và notebook, thực thi Spark trên Kubernetes. Đây là lựa chọn cho xử lý bằng Spark; vòng đời chạy và quyền truy cập dữ liệu khác truy vấn SQL tương tác.

### Quản trị và ngữ nghĩa nghiệp vụ

**Hanas Catalog** lưu và phục vụ metadata để tìm kiếm, khám phá và quản trị tài sản dữ liệu. Schema, mô tả, owner, glossary, tag và lineage phụ thuộc nguồn metadata được thu thập.

**Ontology** định nghĩa concept, object type, property, link type và metric gắn với dataset. Bạn thiết kế trong **Ontology Workspace**, kiểm tra mapping, rồi publish và activate phiên bản phục vụ người dùng. PostgreSQL lưu định nghĩa và trạng thái Ontology; record nghiệp vụ được truy vấn qua query engine.

Catalog và Ontology phục vụ những nhu cầu khác nhau. Catalog mô tả tài sản dữ liệu; Ontology tổ chức mô hình nghiệp vụ có binding và quy tắc truy vấn. Việc gắn glossary term lên một bảng chưa tự tạo binding cho object type.

### AI và trình bày

**Kapas AI** cung cấp hội thoại, agent và tool hỗ trợ tìm dữ liệu, viết SQL và tính metric đã cấu hình. Khả năng thực hiện phụ thuộc agent, model, quyền và dịch vụ đích; kết quả phân tích cần được đối chiếu với nguồn.

**Analytics**, tích hợp **Apache Superset**, cung cấp dataset BI, chart và dashboard trong Console. Dataset BI tham chiếu dữ liệu qua kết nối đã cấu hình; lưu view trong query engine chưa tự tạo dashboard.

### Danh tính và lưu trữ

**Keycloak** cung cấp danh tính và SSO cho các ứng dụng được tích hợp. Group và role hỗ trợ phân quyền theo dịch vụ, còn quyền trên source, table hoặc view được kiểm tra tại query engine.

**Apache Iceberg trên object storage** là lớp lưu bảng lakehouse, gồm data file, metadata và snapshot. Object storage có thể là MinIO hoặc dịch vụ tương thích theo cấu hình môi trường. Iceberg catalog quản lý việc tra cứu bảng; Hanas Catalog phục vụ metadata nghiệp vụ và quản trị.

## Mô hình triển khai

Hanas được triển khai bằng Helm/helmfile trên Kubernetes trong hạ tầng on-premise hoặc private cloud. Bộ cài cấu hình các dịch vụ ứng dụng, cơ sở dữ liệu, volume và kết nối theo thành phần được chọn.

Tổ chức cần chuẩn bị mạng, tên miền, TLS, storage và secret phù hợp với môi trường vận hành. Các dịch vụ có trạng thái như PostgreSQL, object storage và workspace cần có phương án sao lưu riêng. Số node và tài nguyên phải được xác định theo workload và cấu hình triển khai cụ thể.

:::note Điều kiện

Ingestion, Hanas Catalog, Compute, Analytics và Kapas cần được triển khai và cấu hình trước khi sử dụng. Compute cần thêm Spark Operator, image Spark, kết nối catalog và quyền tương ứng. Kapas cần model AI và credential hợp lệ cho các tích hợp được bật.

:::

## Ranh giới cần hiểu

:::caution Giới hạn hiện tại

Danh sách connector hiển thị, khả năng ghi Iceberg và các API quản trị phụ thuộc bản query engine được triển khai. Chính sách query engine không tự áp dụng cho Spark hoặc Ingestion khi truy cập storage bằng credential riêng.

:::

Hanas cung cấp các công cụ cho một luồng dữ liệu liên kết, nhưng từng lớp cần được cấu hình và kiểm tra riêng. Không mặc định mọi nguồn đã có lineage, mọi metric đã thực thi được hoặc mọi agent có cùng quyền.

## Tiếp theo

- [Kiến trúc nền tảng](architecture.md).
- [Khái niệm chính](concepts.md).
- [Làm quen Hanas Console](console-tour.md).
- [Quickstart](quickstart.md).
