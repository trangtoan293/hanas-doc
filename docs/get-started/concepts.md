---
title: Khái niệm chính
sidebar_label: Khái niệm chính
sidebar_position: 3
description: Định nghĩa ngắn các khái niệm cốt lõi xuyên suốt Hanas Data Platform, kèm liên kết tới trang chi tiết.
---

Trang này định nghĩa các khái niệm bạn gặp ở nhiều thành phần của Hanas Data Platform. Mỗi mục có liên kết tới trang chi tiết. Để tra cứu theo thứ tự chữ cái, xem [bảng thuật ngữ](../reference/glossary.md).

## Dữ liệu và truy vấn

**Source** là kết nối từ query engine tới một hệ thống dữ liệu bên ngoài, ví dụ cơ sở dữ liệu quan hệ hoặc object storage. Sau khi thêm source, bạn duyệt và truy vấn dữ liệu mà không sao chép. Xem [Nguồn dữ liệu truy vấn trực tiếp](../connect/data-sources.md).

**Physical dataset** là bảng hoặc tệp trong source đã được query engine nhận diện, có schema và định dạng truy cập. Physical dataset là dữ liệu gốc, không phải SQL đã lưu. Xem [Nguồn dữ liệu truy vấn trực tiếp](../connect/data-sources.md).

**View** (virtual dataset) là câu SQL được lưu và đặt tên để dùng lại; kết quả được tính khi truy vấn. Xem [Workspace, folder và view](../query/spaces-and-views.md).

**Workspace** (space) và **folder** là container logic để tổ chức view và dataset, đồng thời là đơn vị để cấp quyền. Xem [Workspace, folder và view](../query/spaces-and-views.md).

**Reflection** là cấu trúc dữ liệu được query engine lưu sẵn để tăng tốc truy vấn. Planner chỉ dùng Reflection khi thấy phù hợp, nên hiệu quả phụ thuộc truy vấn và trạng thái refresh. Xem [Tăng tốc truy vấn với Reflection](../query/acceleration.md).

**Job** là một lần thực thi SQL, có trạng thái, thời gian và profile để phân tích. Xem [Lịch sử job và profile truy vấn](../query/jobs.md).

**Engine** và **queue** là cơ chế phân bổ tài nguyên và điều phối tải cho truy vấn. Xem [Engine, queue và điều phối tải](../query/workload-management.md).

**Bảng Iceberg** là bảng lakehouse theo định dạng Apache Iceberg, hỗ trợ DDL, DML và time travel. Xem [Bảng Iceberg](../query/iceberg-tables.md).

## Nạp và xử lý dữ liệu

**Ingestion flow** là luồng nạp dữ liệu từ một nguồn vào bảng Iceberg, gồm connection, bảng nguồn, đích, lịch và checkpoint. Xem [Nạp dữ liệu vào lakehouse](../connect/ingestion.md) và [Lịch chạy, checkpoint và chạy lại](../connect/ingestion-schedules.md).

**dbt project** là tập hợp SQL model, test và cấu hình dbt được quản lý trong dbt Studio, thường gắn với kho Git. Xem [dbt Studio](../transform/dbt-studio.md) và [Chạy, kiểm thử và lập lịch dbt](../transform/dbt-runs.md).

**Pipeline** là workflow điều phối nhiều bước theo dependency, lịch và danh tính chạy. Xem [Pipeline](../transform/pipelines.md).

**Compute** là môi trường thực thi Spark, PySpark và notebook trên Kubernetes. Xem [Compute](../transform/compute.md).

## Quản trị metadata

**Catalog asset** là đối tượng metadata trong Hanas Catalog, ví dụ dataset, dashboard hay pipeline được thu thập từ nguồn. Xem [Tìm kiếm và khám phá tài sản dữ liệu](../govern/catalog.md).

**Glossary term** là thuật ngữ nghiệp vụ được định nghĩa tập trung và gắn lên asset. Cùng nhóm với **tag** và **owner**. Xem [Glossary, tag và ownership](../govern/glossary-and-tags.md).

**Lineage** là quan hệ upstream và downstream giữa các tài sản dữ liệu. Mức chi tiết phụ thuộc metadata được thu thập. Xem [Lineage](../govern/lineage.md).

**Metadata ingestion** là quá trình thu thập metadata từ nguồn vào Hanas Catalog, khác với Ingestion nạp dữ liệu. Xem [Thu thập metadata](../govern/metadata-ingestion.md).

## Ontology

**Object type** mô tả cấu trúc một loại đối tượng nghiệp vụ được phục vụ: dataset nguồn, khóa chính và property. Xem [Khái niệm Ontology](../ontology/concepts.md).

**Link type** khai báo quan hệ giữa hai object type cùng các cột join và cardinality. Xem [Khái niệm Ontology](../ontology/concepts.md).

**Metric** là định nghĩa chỉ số có tên, công thức và quy tắc thời gian, có thể tính trên object type. Xem [Metric](../ontology/metrics.md).

**Ontology Workspace** là nơi bạn thiết kế, ánh xạ, kiểm tra và publish ontology. Xem [Ontology Workspace](../ontology/workspace.md) và [Ánh xạ ontology vào dữ liệu](../ontology/mapping.md).

## AI và trình bày

**Kapas agent** là agent AI cấu hình sẵn với tool và skill riêng để hỗ trợ tìm dữ liệu, viết SQL hoặc tính metric. Xem [Agent, skill và tool](../kapas/agents.md) và [An toàn trong Kapas](../kapas/safety.md).

**Analytics** là khu vực nhúng Apache Superset để tạo dataset BI, chart và dashboard. Xem [Analytics với Superset](../bi/superset.md).

## Danh tính và truy cập

**Role** là nhóm quyền gán cho người dùng hoặc group; role Keycloak điều khiển truy cập dịch vụ, còn grant trên đối tượng dữ liệu do query engine kiểm tra. Xem [Quản lý người dùng, group và role](../operate/user-management.md) và [Phân quyền dữ liệu](../govern/access-control.md).

**PAT** (personal access token) là token cá nhân để SQL client hoặc script gọi API dưới danh nghĩa bạn. Bạn tạo PAT từ menu tài khoản, mục **Access Tokens**. Xem [Tổng quan tích hợp](../develop/index.md).

:::note Điều kiện

Một số khái niệm chỉ có hiệu lực khi thành phần tương ứng được triển khai, ví dụ Ingestion, Hanas Catalog, Ontology hoặc Kapas. Xem [kiến trúc nền tảng](architecture.md).

:::

## Tiếp theo

- [Kiến trúc nền tảng](architecture.md).
- [Làm quen Hanas Console](console-tour.md).
- [Quickstart](quickstart.md).
