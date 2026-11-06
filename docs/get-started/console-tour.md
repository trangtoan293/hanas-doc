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

Thanh menu bên trái liệt kê các khu vực dưới đây theo thứ tự từ trên xuống. Dấu `›` ghi các mục con hiện ra khi bạn rê chuột vào menu.

| Menu | Bạn làm gì | Ai thường dùng |
|---|---|---|
| **Home** | Xem các thẻ lối tắt (New Connection, New Object Type, SQL Editor, Analytics, New Project, My Jobs) và hoạt động gần đây theo tab All, Jobs, Projects | Mọi người dùng |
| **Overview** | Giám sát nền tảng: thống kê schema, phân bố node, quản lý connection, Action Center (cảnh báo) và job gần đây | Quản trị viên, data engineer |
| **Connections** | Xem nguồn theo nhóm Data Lakehouse, Object Storage, Databases; lọc theo trạng thái; thêm source bằng **New Source** | Analyst, data engineer |
| **Data Governance** › Glossary, Tags, Data Sources | Tìm kiếm tài sản dữ liệu, quản lý glossary và tag; **Data Sources** thu thập metadata | Data steward, analyst; quản trị Catalog |
| **Ingestion Flows** › Ingestion Flows, Sources, Destinations, Access Control | Tạo và theo dõi luồng nạp dữ liệu, quản lý nguồn, đích và quyền truy cập | Data engineer |
| **Data Pipeline** | Xem danh sách **Pipelines** và **Runs**, tạo pipeline, quản lý service account | Data engineer |
| **Ontology** › Explore, My requests, Workbench, Governance, Settings | Khám phá đối tượng theo project, theo dõi yêu cầu thay đổi, thiết kế và quản trị ontology | Người dùng nghiệp vụ, chuyên gia mô hình hóa |
| **Workspaces** | Mở **SQL Editor**: viết và chạy SQL, xem kết quả và lịch sử, lưu view, quản lý workspace và folder | Analyst, data engineer |
| **dbt Studio** › Projects, Explore, Orchestrate | Quản lý dbt project, phát triển model trong IDE, chạy và lập lịch dbt | Data engineer, analytics engineer |
| **Compute Engine** | Quản lý project PySpark và notebook qua các tab **Projects**, **Runs**, **Streaming jobs**, **Sessions** | Data engineer, data scientist |
| **AI Agent** | Hội thoại với Kapas để hỏi dữ liệu và tạo báo cáo | Mọi người dùng được cấp agent |
| **Analytics** | Mở Apache Superset (Dashboards, Charts, Template, Report, Datasets, SQL) | Analyst, đội BI |
| **Engine** › Monitor, Nodes, Engines, Queues, Routing, Reflections | Giám sát, quản lý engine, queue, quy tắc định tuyến và Reflection | Quản trị query engine |
| **Settings** › User Administration, Integrations, System, Custom | Quản lý user, role, quyền; ứng dụng BI, token bên ngoài, cấu hình AI; tuỳ chọn hệ thống và cấu hình truy vấn | Quản trị viên |

Ở góc dưới bên trái, menu tài khoản (nhấp vào avatar) gồm **Access Tokens**, **Language** (English hoặc Vietnamese) và **Sign out**.

## Chi tiết từng khu vực

### Home và Overview

Home là trang vào: các thẻ lối tắt và danh sách hoạt động gần đây. Overview là trang giám sát nền tảng, gồm thống kê schema, phân bố node, khối **Connection Management** (nút **New Connection**, **Manage All**), **Action Center** hiển thị cảnh báo như lỗi làm mới Reflection hoặc lỗi kết nối source, và danh sách job gần đây.

### Connections

Connections liệt kê source theo nhóm Data Lakehouse, Object Storage và Databases, có bộ lọc trạng thái All, Healthy, Warning, Error. Nút **New Source** mở hộp thoại **Add Source**; từ đây bạn mở một table hoặc view để truy vấn hoặc xem lineage. Xem [Nguồn dữ liệu truy vấn trực tiếp](../connect/data-sources.md).

### Workspaces và SQL Editor

Menu **Workspaces** mở SQL Editor, nơi làm việc chính với query engine. Panel trái có các tab DATA, SCRIPTS, FUNCTIONS; bạn chọn **Context**, chạy truy vấn bằng nút **Run** (Ctrl/Cmd+Enter), xem kết quả ở tab **Results** và lịch sử ở tab **History**. Khi nhiều câu lệnh được chạy cùng lúc, chuỗi dừng nếu một câu lỗi hoặc bị hủy. Bạn lưu truy vấn thành view bằng **Save as View**. Xem [SQL Editor](../query/sql-studio.md) và [Workspace, folder và view](../query/spaces-and-views.md).

### Data Governance

Khu vực này dùng Hanas Catalog. Trang đầu là tìm kiếm metadata với các bộ lọc như Type, Platform, Environment, Owner, Tag. Bạn mở trang chi tiết dataset và quản lý glossary, tag. Mục **Data Sources** (tab **Sources**, **Run History**, **Secrets**, nút **Create Source**) phục vụ thu thập metadata và chỉ dành cho người quản trị Data Governance. Xem [Tìm kiếm và khám phá tài sản dữ liệu](../govern/catalog.md) và [Thu thập metadata](../govern/metadata-ingestion.md).

### Ingestion Flows, Data Pipeline, dbt Studio, Compute Engine

Bốn khu vực này phục vụ data engineer. **Ingestion Flows** nạp dữ liệu vào Iceberg; trang luồng nạp lọc theo chế độ All, Batch, Stream và trạng thái All, Active, Error, Paused ([Ingestion](../connect/ingestion.md)). **Data Pipeline** có hai tab **Pipelines** và **Runs**, nút **Create pipeline** và **Service accounts** ([Pipeline](../transform/pipelines.md)). **dbt Studio** gồm Projects, Explore, Orchestrate và nút **Open IDE** ([dbt Studio](../transform/dbt-studio.md)). **Compute Engine** chạy Spark; nút **New project** tạo project mới ([Compute](../transform/compute.md)).

### Ontology, AI Agent và Analytics

Ontology tổ chức công việc theo project; menu có các mục Explore, My requests, Workbench, Governance và Settings ([Ontology](../ontology/index.md)). **AI Agent** mở Kapas với **New chat** và lịch sử hội thoại ([Kapas AI](../kapas/index.md)). **Analytics** nhúng Superset ([Analytics với Superset](../bi/superset.md)).

### Engine và Settings

**Engine** dành cho người quản trị tải truy vấn: Monitor (tab **Catalog usage**, **Jobs**, **Resources**), Nodes, Engines, Queues, Routing và Reflections ([Engine, queue và điều phối tải](../query/workload-management.md)). **Settings** gồm:

- **User Administration**: tab Users, Roles, Permissions (nút **New User**).
- **Integrations**: BI Applications (Power BI, Tableau), External Tokens, AI Config.
- **System**: Preferences, Support, Compute.
- **Custom**: SQL Query Config.

Xem [Quản lý người dùng, group và role](../operate/user-management.md).

### Lịch sử job

Console không có menu Jobs riêng. Bạn xem lịch sử job từ thẻ **My Jobs** trên Home, liên kết **View all jobs** trên Overview, tab **History** trong SQL Editor, hoặc Engine › Monitor › tab **Jobs**.

### Menu tài khoản và PAT

Mở menu tài khoản (avatar ở góc dưới bên trái) và chọn **Access Tokens** để mở hộp thoại **Personal Access Tokens**. Hộp thoại liệt kê PAT (Token ID, Label, Creation, Expiration), cho phép tạo PAT mới bằng **Generate Token** với nhãn và hạn dùng, sao chép token vừa tạo và xoá token không còn dùng (**Delete All** xoá toàn bộ). Token chỉ hiển thị khi tạo, nên hãy lưu ở nơi an toàn. Xem [Tổng quan tích hợp](../develop/index.md).

:::note Điều kiện

- dbt cần được bật cho môi trường và bạn cần role dbt tương ứng.
- Data Governance, Ingestion Flows, Compute Engine, Ontology, AI Agent và Analytics chỉ dùng được khi thành phần đã được triển khai và cấu hình.
- Engine và Settings dành cho tài khoản quản trị.
- Chức năng PAT cần query engine được triển khai hỗ trợ cấp token.

:::

:::caution Giới hạn hiện tại

Một số menu có thể bị ẩn tuỳ phiên bản Console, ví dụ khu vực quản lý view riêng; thao tác này được truy cập qua SQL Editor. Một số màn hình trong Engine phụ thuộc bản query engine được triển khai.

:::

## Tiếp theo

- [Quickstart](quickstart.md).
- [Khái niệm chính](concepts.md).
- [SQL Editor](../query/sql-studio.md).
