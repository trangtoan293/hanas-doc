---
title: Thuật ngữ
sidebar_label: Thuật ngữ
sidebar_position: 1
description: Bảng thuật ngữ của Hanas Data Platform theo thứ tự chữ cái, mỗi thuật ngữ có định nghĩa ngắn và liên kết tới trang liên quan.
---

Bảng này giải thích các thuật ngữ thường gặp trong tài liệu Hanas Data Platform, xếp theo chữ cái. Với khái niệm cốt lõi, xem thêm [Khái niệm chính](../get-started/concepts.md).

## A

**Action**: thao tác trên object type theo chính sách submit và approval của Ontology. Xem [Action và yêu cầu thay đổi](../ontology/actions.md).

**Agent** (Kapas): thực thể AI có prompt, skill và tool riêng. Xem [Agent, skill và tool](../kapas/agents.md).

**Analytics**: khu vực Console nhúng Apache Superset để dựng chart và dashboard. Xem [Analytics với Superset](../bi/superset.md).

**Apache Arrow Flight**: giao thức truyền dữ liệu hiệu năng cao mà SQL client dùng để lấy kết quả. Xem [JDBC, ODBC và Arrow Flight](../develop/sql-clients.md).

**Asset** (catalog asset): đối tượng metadata trong Hanas Catalog. Xem [Tìm kiếm và khám phá tài sản dữ liệu](../govern/catalog.md).

## B

**Bảng Iceberg**: bảng lakehouse theo định dạng Apache Iceberg. Xem [Bảng Iceberg](../query/iceberg-tables.md).

**Bronze, Silver, Gold**: các tầng của kiến trúc medallion, từ dữ liệu thô đến dữ liệu sẵn sàng phân tích. Xem [Chuẩn mô hình hóa](../transform/modeling-standards.md).

## C

**Cardinality**: số lượng quan hệ giữa hai object type (một-một, một-nhiều, nhiều-nhiều). Xem [Khái niệm Ontology](../ontology/concepts.md).

**Catalog**: xem Hanas Catalog và Iceberg catalog.

**Checkpoint**: điểm đánh dấu tiến độ của một luồng Ingestion, dùng để chạy tiếp hoặc chạy lại. Xem [Lịch chạy, checkpoint và chạy lại](../connect/ingestion-schedules.md).

**Compute**: môi trường chạy Spark, PySpark và notebook trên Kubernetes; trong Console là menu **Compute Engine**. Xem [Compute](../transform/compute.md).

**Concept**: khái niệm nghiệp vụ trong mô hình Ontology. Xem [Khái niệm Ontology](../ontology/concepts.md).

**Connections**: menu Console để xem và thêm source, duyệt dữ liệu. Xem [Làm quen Hanas Console](../get-started/console-tour.md).

**Connector**: thành phần kết nối tới một loại nguồn dữ liệu cụ thể. Xem [Nguồn dữ liệu truy vấn trực tiếp](../connect/data-sources.md).

## D

**Dashboard**: tập hợp chart trong Analytics. Xem [Analytics với Superset](../bi/superset.md).

**Data Vault**: phương pháp mô hình hóa dùng hub, link và satellite. Xem [Chuẩn mô hình hóa](../transform/modeling-standards.md).

**dbt**: công cụ biến đổi dữ liệu bằng SQL model. Xem [dbt Studio](../transform/dbt-studio.md).

**dbt project**: tập hợp model, test và cấu hình dbt. Xem [dbt Studio](../transform/dbt-studio.md).

**Dimension**: thuộc tính dùng để phân nhóm khi tổng hợp. Xem [Metric](../ontology/metrics.md).

## E

**Engine**: nhóm tài nguyên thực thi truy vấn của query engine. Xem [Engine, queue và điều phối tải](../query/workload-management.md).

**External BI**: công cụ BI bên ngoài Console kết nối vào query engine. Xem [Kết nối công cụ BI bên ngoài](../bi/external-bi.md).

## F

**Folder**: thư mục chứa view và dataset trong một workspace. Xem [Workspace, folder và view](../query/spaces-and-views.md).

## G

**Glossary term**: thuật ngữ nghiệp vụ được định nghĩa trong Hanas Catalog. Xem [Glossary, tag và ownership](../govern/glossary-and-tags.md).

**Grant**: quyền được cấp cho user hoặc role trên đối tượng dữ liệu. Xem [Phân quyền dữ liệu](../govern/access-control.md).

**Group**: tập hợp người dùng trong Keycloak. Xem [Quản lý người dùng, group và role](../operate/user-management.md).

## H

**Hanas Catalog**: kho metadata phục vụ tìm kiếm, glossary, tag, ownership và lineage. Xem [Catalog và quản trị dữ liệu](../govern/index.md).

**Hanas Console**: giao diện web chung của nền tảng. Xem [Làm quen Hanas Console](../get-started/console-tour.md).

**helmfile**: công cụ khai báo triển khai nhiều Helm release lên Kubernetes. Xem [Cài đặt bằng helmfile](../operate/install.md).

## I

**Iceberg catalog**: dịch vụ tra cứu bảng Iceberg; khác với Hanas Catalog. Xem [Bảng Iceberg](../query/iceberg-tables.md).

**Ingestion**: dịch vụ nạp dữ liệu từ nguồn vào bảng Iceberg. Xem [Nạp dữ liệu vào lakehouse](../connect/ingestion.md).

**Ingestion flow**: một luồng nạp gồm nguồn, đích, lịch và checkpoint. Xem [Nạp dữ liệu vào lakehouse](../connect/ingestion.md).

**Interface** (Ontology): hợp đồng chung mà nhiều object type có thể triển khai. Xem [Khái niệm Ontology](../ontology/concepts.md).

## J

**JDBC, ODBC**: chuẩn driver để ứng dụng và công cụ BI truy vấn qua SQL. Xem [JDBC, ODBC và Arrow Flight](../develop/sql-clients.md).

**Job**: một lần thực thi SQL trong query engine. Xem [Lịch sử job và profile truy vấn](../query/jobs.md).

## K

**Kapas**: lớp AI của Hanas với hội thoại, agent và tool. Xem [Kapas AI](../kapas/index.md).

**Keycloak**: dịch vụ danh tính và SSO. Xem [Xác thực và SSO với Keycloak](../operate/identity.md).

## L

**Lakehouse**: kiến trúc lưu trữ kết hợp tính linh hoạt của data lake và khả năng truy vấn của data warehouse. Xem [Kiến trúc nền tảng](../get-started/architecture.md).

**Lineage**: quan hệ upstream và downstream giữa các tài sản dữ liệu. Xem [Lineage](../govern/lineage.md).

**Link type**: quan hệ giữa hai object type trong Ontology. Xem [Khái niệm Ontology](../ontology/concepts.md).

## M

**Mapping**: ánh xạ object type, property và quan hệ vào dataset. Xem [Ánh xạ ontology vào dữ liệu](../ontology/mapping.md).

**Masking**: che hoặc biến đổi giá trị cột theo chính sách gắn trên cột, áp dụng khi truy vấn qua query engine. Xem [Phân quyền dữ liệu](../govern/access-control.md).

**Medallion**: kiến trúc nhiều tầng Bronze, Silver, Gold. Xem [Chuẩn mô hình hóa](../transform/modeling-standards.md).

**Metadata ingestion**: thu thập metadata từ nguồn vào Hanas Catalog. Xem [Thu thập metadata](../govern/metadata-ingestion.md).

**Metric**: chỉ số có tên, công thức và quy tắc thời gian trong Ontology. Xem [Metric](../ontology/metrics.md).

## O

**Object type**: mô tả một loại đối tượng nghiệp vụ gắn với dataset. Xem [Khái niệm Ontology](../ontology/concepts.md).

**Ontology**: lớp semantic kết nối mô hình nghiệp vụ với dữ liệu. Xem [Ontology](../ontology/index.md).

**Ontology Workspace**: nơi thiết kế, ánh xạ và publish ontology. Xem [Ontology Workspace](../ontology/workspace.md).

**Owner**: người hoặc nhóm chịu trách nhiệm về một tài sản dữ liệu. Xem [Glossary, tag và ownership](../govern/glossary-and-tags.md).

## P

**PAT** (personal access token): token cá nhân để client và script gọi API. Xem [Tổng quan tích hợp](../develop/index.md).

**Physical dataset**: bảng hoặc tệp trong source đã được query engine nhận diện. Xem [Nguồn dữ liệu truy vấn trực tiếp](../connect/data-sources.md).

**Pipeline**: workflow điều phối nhiều bước. Xem [Pipeline](../transform/pipelines.md).

**Preflight**: bước kiểm tra cấu hình trước khi chạy luồng Ingestion. Xem [Nạp dữ liệu vào lakehouse](../connect/ingestion.md).

**Profile** (query profile): chi tiết thực thi của một job. Xem [Lịch sử job và profile truy vấn](../query/jobs.md).

**Property**: thuộc tính của object type. Xem [Khái niệm Ontology](../ontology/concepts.md).

**Publish**: bước phát hành phiên bản ontology để phục vụ người dùng. Xem [Ontology Workspace](../ontology/workspace.md).

## Q

**Query engine**: thành phần thực thi SQL, quản lý view, job và Reflection. Xem [Query Engine](../query/index.md).

**Queue**: hàng đợi điều phối truy vấn tới engine. Xem [Engine, queue và điều phối tải](../query/workload-management.md).

## R

**Record**: một đối tượng cụ thể đọc từ dataset đã ánh xạ. Xem [Khái niệm Ontology](../ontology/concepts.md).

**Reflection**: cấu trúc dữ liệu lưu sẵn để tăng tốc truy vấn. Xem [Tăng tốc truy vấn với Reflection](../query/acceleration.md).

**Role**: nhóm quyền gán cho user hoặc group. Xem [Quản lý người dùng, group và role](../operate/user-management.md).

**Row access policy**: chính sách lọc dòng theo người truy vấn, áp dụng khi truy vấn qua query engine. Xem [Phân quyền dữ liệu](../govern/access-control.md).

## S

**Skill** (Kapas): gói hướng dẫn và công cụ giúp agent thực hiện một loại nhiệm vụ. Xem [Agent, skill và tool](../kapas/agents.md).

**Snapshot**: trạng thái của bảng Iceberg tại một thời điểm, dùng cho time travel. Xem [Bảng Iceberg](../query/iceberg-tables.md).

**Source**: kết nối từ query engine tới hệ thống dữ liệu ngoài. Xem [Nguồn dữ liệu truy vấn trực tiếp](../connect/data-sources.md).

**Spark**: engine xử lý phân tán dùng trong Compute. Xem [Compute](../transform/compute.md).

**SQL Editor**: khu vực Console để viết và chạy SQL, mở từ menu **Workspaces**. Xem [SQL Editor](../query/sql-studio.md).

**SSE** (server-sent events): cơ chế nhận phản hồi theo luồng từ Kapas API. Xem [Kapas API và SSE](../develop/kapas-api.md).

**Superset**: công cụ BI mã nguồn mở dùng trong Analytics. Xem [Analytics với Superset](../bi/superset.md).

## T

**Tag**: nhãn phân loại gắn lên tài sản dữ liệu. Xem [Glossary, tag và ownership](../govern/glossary-and-tags.md).

**Time travel**: truy vấn bảng Iceberg tại một snapshot hoặc thời điểm trước. Xem [Bảng Iceberg](../query/iceberg-tables.md).

**Token exchange**: đổi token Keycloak sang token cho dịch vụ đích (RFC 8693). Xem [Kiến trúc nền tảng](../get-started/architecture.md).

## V

**View**: câu SQL được lưu và đặt tên để dùng lại. Xem [Workspace, folder và view](../query/spaces-and-views.md).

## W

**Workspace** (space): container logic chứa folder và view, cũng là đơn vị cấp quyền. Xem [Workspace, folder và view](../query/spaces-and-views.md).
