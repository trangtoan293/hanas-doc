# Tài liệu Tổng hợp Logic Publish DataHub

Tài liệu này tóm tắt cơ chế tích hợp giữa Airflow, dbt, Iceberg và DataHub trong hệ thống hiện tại. Tài liệu nhằm mục đích làm tài liệu tham khảo cho đội ngũ kỹ sư khi reimplement hệ thống.

## 1. Tổng quan các thành phần

Hệ thống sử dụng các DAG trong `dags/raw_vault` để trigger pipeline. Metadata được publish lên DataHub thông qua các task group được định nghĩa trong `dags/raw_vault/taskgroups/publish_to_datahub_taskgroup.py`. Các logic xử lý chính nằm trong `dags/utils`.

### File & Thư mục quan trọng
*   `dags/utils/datahub_publisher.py`: Chứa logic chính để publish metadata.
*   `dags/utils/column_lineage_publisher.py`: Chứa logic phân tích SQL và tạo column lineage.
*   `dags/debug/`: Nơi lưu trữ artifacts (catalog, manifest, run_results) để debug.

## 2. Cấu trúc URN (DataHub Identity)

Một data asset (bảng) trong DataHub được định danh bằng URN (Uniform Resource Name). Hệ thống hiện tại tạo ra 2 entity song song cho cùng một bảng vật lý: một cho **Iceberg** (vật lý) và một cho **dbt** (logic).

### A. Iceberg Platform URN
Sử dụng cho các dataset thực tế lưu trữ trên S3/MinIO.

*   **Format:** `urn:li:dataset:(urn:li:dataPlatform:iceberg,<dataset_name>,<env>)`
*   **Dataset Name Logic:** `<iceberg_platform_instance>.<schema>.<table_name>`
*   **Ví dụ:** `urn:li:dataset:(urn:li:dataPlatform:iceberg,demo.integration.hub_gl,PROD)`
*   **Nguồn dữ liệu:**
    *   `iceberg_platform_instance`: Default là `demo` (lấy từ biến `ICEBERG_PLATFORM_INSTANCE`).
    *   `schema`, `table_name`: Parse từ file `catalog.json` hoặc dbt artifacts.

### B. dbt Platform URN
Sử dụng cho các logic model được quản lý bởi dbt.

*   **Format:** `urn:li:dataset:(urn:li:dataPlatform:dbt,<dataset_name>,<env>)`
*   **Dataset Name Logic:** `<dbt_platform_instance>.<schema>.<table_name>` (Lưu ý: **hiện tại có** prefix `dbt_platform_instance`).
*   **Ví dụ:** `urn:li:dataset:(urn:li:dataPlatform:dbt,demo.integration.hub_gl,PROD)`
*   **Nguồn dữ liệu:**
    *   `dbt_platform_instance`: Default là `demo` (lấy từ biến `DBT_PLATFORM_INSTANCE`).
    *   `schema`, `table_name`: Lấy từ `manifest.json` của dbt.

### C. Logic Combine (Sibling Aspects)
DataHub gộp 2 entity trên thành một trên giao diện UI thông qua cơ chế **Sibling**.
*   Khi publish dbt metadata (`publish_dbt_to_datahub`), tham số `target_platform` được set cứng là `iceberg` và `iceberg_platform_instance` được sử dụng.
*   DataHub Service nhận diện rằng dbt node này là "anh em" của iceberg node tương ứng và hiển thị chúng như một.
    *   **dbt Platform:** Cung cấp documentation, tags, owners, logic definition.
    *   **iceberg Platform:** Cung cấp schema kỹ thuật (column types), thống kê (row count), và các đặc tính vật lý.

## 3. Logic Lineage (Table & Column Level)

Hệ thống tạo ra 2 đồ thị lineage song song để đảm bảo tính nhất quán trên UI.

### Quy trình tạo Lineage:
1.  **Parse SQL:** Hàm `ColumnLineagePublisher._parse_sql_lineage` đọc `compiled_sql` từ `run_results.json`. Sử dụng `datahub.sql_parsing` để phân tích cú pháp.
2.  **Xây dựng Iceberg Lineage (Physical):**
    *   Parser xác định bảng nguồn và đích.
    *   Tên bảng được chuẩn hóa thành URN Iceberg (thêm prefix `demo.`).
    *   Tạo kết nối: `Iceberg Table A` -> `Iceberg Table B`.
3.  **Xây dựng dbt Lineage (Logical):**
    *   Hệ thống clone kết quả từ bước 2.
    *   Convert URN từ Iceberg sang dbt: Thay `dataPlatform:iceberg` bằng `dataPlatform:dbt` và xóa prefix `demo.`.
    *   Tạo kết nối: `dbt Model A` -> `dbt Model B`.
    *   **Mục đích:** Để khi xem lineage ở chế độ "Logical" (dbt), người dùng vẫn thấy đầy đủ kết nối column level.

## 4. Logic dbt Test Assertion

Các dbt test (schema tests như `unique`, `not_null`) được publish dưới dạng **Data Quality Assertions**.

### Liên kết Test với Dataset (Mapping Logic)
Làm sao biết test `T` thuộc về dataset `D`?
1.  **Đọc Run Results:** Lọc các node có `unique_id` bắt đầu bằng `test.`.
2.  **Đọc Manifest:**
    *   Tìm node definition của test trong `manifest.json`.
    *   Lấy danh sách `refs` hoặc `depends_on` của test node.
    *   Reference đầu tiên chính là Model (Dataset) mà test này đang kiểm tra.
3.  **Xác định URN của Dataset:**
    *   Từ model name tìm được ở bước 2, tra cứu ngược lại `schema` trong manifest.
    *   Tạo **Iceberg URN** (`demo.schema.table`) để log kết quả chạy (Run Event).
    *   Tạo **dbt URN** (`schema.table`) để hiển thị thông tin test (Assertion Info) trên UI.

### Quy trình Publish:
*   **Bước 1: Tạo Assertion Entity** (`AssertionInfo`)
    *   URN: `urn:li:assertion:<md5_hash_of_test_id>`
    *   Metadata: Tên test, mô tả (ví dụ: "Column CIF_NO values are not null").
    *   Liên kết: Gắn với **dbt URN** của dataset.
*   **Bước 2: Tạo Run Event** (`AssertionRunEvent`)
    *   Thời gian: `completed_at` từ `run_results.json`.
    *   Kết quả: `SUCCESS` hoặc `FAILURE`.
    *   Liên kết: Gắn với **Iceberg URN** của dataset (vì thực tế test chạy trên dữ liệu vật lý).

## 5. Các biến cấu hình mặc định (Hardcoded)

Các giá trị sau được set mặc định trong code (`publish_to_datahub_taskgroup.py`) nếu không có Variable override trong Airflow:

| Biến môi trường / Variable | Giá trị Mặc định (Hardcoded) | Ý nghĩa |
| :--- | :--- | :--- |
| `DBT_ARTIFACTS_BUCKET` | `data` | Tên bucket S3 chứa artifacts |
| `AWS_ENDPOINT_URL` | `http://192.168.1.151` | Địa chỉ nội bộ của MinIO/S3 |
| `DATAHUB_GMS_HOST` | `http://192.168.1.173:8080` | Địa chỉ DataHub GMS Service |
| `DATAHUB_ENV` | `PROD` | Môi trường logic trên DataHub |
| `ICEBERG_PLATFORM_INSTANCE`| `demo` | Định danh instance của Iceberg (Prefix cho Iceberg URN) |
| `DBT_PLATFORM_INSTANCE`| `demo` | Định danh instance của dbt (Prefix cho dbt URN) |
| `DATAHUB_INCLUDE_DATABASE_IN_NAME` | `false` | Cấu hình định dạng tên dataset (Xem chi tiết mục 6) |
| `DATAHUB_EMIT_BOTH_NAME_VARIANTS`| `false` | Có emit thêm tên dạng ngắn không (Xem chi tiết mục 6) |

## 6. Giải thích chi tiết về Variable định dạng tên

Hai biến `DATAHUB_INCLUDE_DATABASE_IN_NAME` và `DATAHUB_EMIT_BOTH_NAME_VARIANTS` kiểm soát cách tạo ra `dataset_name` trong **Iceberg URN**.

### Biến 1: `DATAHUB_INCLUDE_DATABASE_IN_NAME`
*   **Mặc định:** `false`
*   **Mục đích:** Quyết định xem tên dataset có bao gồm phần database (catalog) hay không.
*   **Tác động:**
    *   Nếu `true`: Tên dataset sẽ là `platform_instance.database.schema.table`. (Ví dụ: `demo.spark_catalog.integration.hub_gl`)
    *   Nếu `false`: Tên dataset sẽ là `platform_instance.schema.table`. (Ví dụ: `demo.integration.hub_gl`)
*   **Tại sao cần?** Một số query engine (như Trino/Dremio) yêu cầu full path gồm catalog, trong khi một số khác (như Hive cũ) chỉ quan tâm schema. Cấu hình này giúp URN khớp với cách người dùng query.

### Biến 2: `DATAHUB_EMIT_BOTH_NAME_VARIANTS`
*   **Mặc định:** `false`
*   **Mục đích:** Cho phép publish metadata cho **CẢ HAI** dạng tên (có và không có database) cùng lúc.
*   **Tác động:**
    *   Nếu `true`: Hệ thống sẽ loop qua và gửi schema metadata cho cả 2 URN:
        1.  `urn:li:dataset:iceberg:demo.spark_catalog.integration.hub_gl`
        2.  `urn:li:dataset:iceberg:demo.integration.hub_gl`
*   **Khi nào dùng?** Khi bạn đang trong quá trình migration hoặc có nhiều công cụ query khác nhau trỏ vào cùng một bảng nhưng dùng convention gọi tên khác nhau. Bật option này đảm bảo lineage không bị đứt gãy dù query dùng dạng tên nào.


### Lưu ý quan trọng cho Re-implementation:
1.  **Platform Instance:** Đây là thành phần quan trọng nhất để map giữa physical layer (Iceberg) và logical layer (dbt). Hệ thống sử dụng 2 biến riêng biệt: `ICEBERG_PLATFORM_INSTANCE` và `DBT_PLATFORM_INSTANCE`. Cả hai đều có default là `demo`. Nếu đổi giá trị, cần cập nhật đồng bộ cho cả 2.
2.  **URN Format (mới):** Cả Iceberg và dbt URN đều có cùng format `{platform_instance}.{schema}.{table}`. Điều này đảm bảo tính nhất quán khi chuyển đổi URN giữa 2 platform.
3.  **S3 Prefix Sharing:** Các task `validate`, `publish_dbt`, `publish_iceberg` đều dùng chung một `prefix` S3. DAG phải đảm bảo artifacts đã được upload lên đúng prefix đó trước khi gọi task group này.
4.  **Test Artifacts:** Logic publish test tách biệt (`publish_test_to_datahub_taskgroup`) và thường đọc từ thư mục artifact riêng (ví dụ `/test` thay vì `/run`). Task này **bỏ qua** bước publish column lineage để tối ưu hiệu năng.
