---
title: Nguồn dữ liệu truy vấn trực tiếp
sidebar_label: Nguồn dữ liệu
sidebar_position: 1
description: Thêm nguồn trong Connections để truy vấn trực tiếp object storage, catalog và các hệ thống khác bằng SQL, kèm tuỳ chọn metadata refresh và format file.
---

Trang này hướng dẫn bạn thêm một nguồn vào **Hanas Console** để query engine truy vấn dữ liệu tại chỗ, không sao chép. Nếu cần lưu bản sao trong lakehouse, xem [Nạp dữ liệu vào lakehouse](./ingestion.md).

## Khái niệm

- **Nguồn (source)**: kết nối tới một hệ thống bên ngoài. Sau khi thêm, bạn duyệt được folder và bảng của nguồn trong cây dữ liệu.
- **Physical dataset**: tệp hoặc bảng của nguồn đã được nhận diện định dạng để truy vấn bằng SQL.
- **View**: câu SQL đã lưu, tạo trên physical dataset; xem [Workspace, folder và view](../query/spaces-and-views.md).

## Danh sách connector

Hộp thoại **Add Source** cung cấp các loại nguồn sau, nhóm theo ba mục.

| Nhóm | Connector |
|---|---|
| Lakehouse Catalogs | Apache Polaris (Incubating), AWS Glue Data Catalog, Hive 2.x, Hive 3.x, Iceberg REST Catalog, Nessie, Snowflake Open Catalog, Unity Catalog |
| Object Storage | Amazon S3, Azure Storage, Google Cloud Storage, HDFS, NAS / Local Path |
| Databases | Amazon OpenSearch Service, Amazon Redshift, Druid, Elasticsearch, Google BigQuery, IBM Db2, Microsoft Azure Data Explorer, Microsoft Azure Synapse Analytics, Microsoft SQL Server, MongoDB, MySQL, Oracle, PostgreSQL, SAP HANA, Snowflake, Teradata, Vertica |

Danh sách Databases còn có một mục để kết nối tới một instance query engine khác (another query engine instance).

:::note Điều kiện

Một số loại nguồn phụ thuộc gói triển khai và phương thức xác thực của môi trường bạn. Nếu cần dữ liệu từ một hệ thống theo cách ổn định và lặp lại, dùng [Ingestion](./ingestion.md).

:::

## Điều kiện cần

- Quyền tạo nguồn trong query engine (thường là quản trị viên).
- Thông tin kết nối: endpoint, thông tin xác thực, bucket hoặc đường dẫn gốc.
- Mạng từ query engine tới hệ thống nguồn đã được mở.

## Thêm một nguồn

1. Mở **Connections** (hoặc cây dữ liệu trong SQL Editor, menu **Workspaces**), chọn **New Source**. Hộp thoại **Add Source** mở ra với hai tab **Manual Setup** và **Import File**.
2. Ở tab **Manual Setup**, chọn loại nguồn trong danh sách. Danh sách được nhóm theo Lakehouse Catalogs, Object Storage và Databases.
3. Điền thông tin kết nối và xác thực. Các trường thay đổi theo loại nguồn.
4. Mở các tab tuỳ chọn nếu muốn đổi chính sách **Metadata** hoặc **Reflection Refresh** (xem bên dưới).
5. Chọn lưu để tạo nguồn. Nguồn xuất hiện trong cây dữ liệu.
6. Duyệt folder và bảng của nguồn. Với nguồn dạng tệp, định dạng tệp thành physical dataset (xem bên dưới), rồi mở trong SQL Editor hoặc tạo view.

Tab **Import File** của **Add Source** cho phép nhập cấu hình nguồn từ tệp JSON, dành cho trường hợp bạn cần tạo nhiều nguồn cùng lúc.

## Tuỳ chọn metadata refresh

Query engine lưu metadata của nguồn (danh sách tên, định nghĩa dataset) để truy vấn nhanh. Tab **Metadata** quyết định mức độ cập nhật.

| Tuỳ chọn | Ý nghĩa | Giá trị mặc định trong form |
|---|---|---|
| Tần suất làm mới danh sách tên | Bao lâu kiểm tra tên folder, bảng mới | 1 giờ |
| Làm mới định nghĩa dataset sau | Bao lâu đọc lại schema của dataset | 1 giờ |
| Hết hạn định nghĩa dataset sau | Sau bao lâu metadata bị coi là cũ | 3 giờ |

Console kiểm tra giá trị tối thiểu và yêu cầu thời gian hết hạn không nhỏ hơn thời gian làm mới. Tab **Reflection Refresh** cấu hình chu kỳ hoặc lịch làm mới và thời hạn của [Reflection](../query/acceleration.md) tạo trên dataset của nguồn.

## Format tệp thành physical dataset

Với nguồn dạng tệp, query engine cần biết định dạng trước khi truy vấn.

1. Trong cây dữ liệu, mở nguồn và chọn tệp hoặc folder.
2. Chọn thao tác định dạng (**Format**) và chọn kiểu: văn bản có phân tách, JSON, Parquet, Excel và các định dạng bảng khác mà hộp thoại cung cấp.
3. Điều chỉnh tuỳ chọn (dấu phân tách, dòng tiêu đề...) và xem trước dữ liệu.
4. Lưu. Tệp hoặc folder trở thành physical dataset; bạn truy vấn bằng SQL hoặc tạo view.

Để huỷ, chọn xoá format. Tệp trở về trạng thái chưa định dạng; dữ liệu gốc không bị xoá.

## Giới hạn

:::caution Giới hạn hiện tại

- Federation đọc trực tiếp từ nguồn, nên hiệu năng phụ thuộc vào hệ thống nguồn và mạng. Dùng Reflection hoặc Ingestion cho truy vấn lặp lại.
- Một số plugin nội bộ của query engine không dành cho người dùng tự thêm và không xuất hiện trong danh sách.

:::

## Tiếp theo

- [Tải tệp lên](./file-upload.md) nếu bạn chỉ có vài tệp rời.
- [SQL Editor](../query/sql-studio.md) để truy vấn dataset.
- [Reflection](../query/acceleration.md) để tăng tốc truy vấn trên nguồn ngoài.
