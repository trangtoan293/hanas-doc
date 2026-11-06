---
title: Phân quyền dữ liệu
sidebar_label: Phân quyền dữ liệu
sidebar_position: 5
description: Các miền quyền trong Hanas Data Platform, nơi cấu hình từng loại quyền, grant trên query engine, row access policy và column masking.
---

Quyền trong Hanas Data Platform không nằm ở một nơi. Mỗi thành phần có cơ chế riêng, và việc cấp quyền ở một miền không tự cấp quyền ở miền khác. Trang này giúp quản trị viên biết cần cấu hình gì, ở đâu.

## Các miền quyền

| Miền | Quyết định điều gì | Cơ chế |
|---|---|---|
| Danh tính | Ai là người dùng, thuộc group và role nào | Keycloak, quản lý trong **Settings** > **User Administration** của Hanas Console |
| Query engine | Ai đọc, ghi, sửa từng source, folder, bảng, view, function | Object grant theo user hoặc role |
| Row và column | Ai thấy hàng nào, giá trị cột nào | Row access policy, column masking |
| Hanas Catalog | Ai chỉnh sửa metadata, quản lý ingestion | Role `data-governance-viewer`, `editor`, `admin` |
| dbt | Ai xem, sửa, chạy dbt | Role `dbt-viewer`, `dbt-editor`, `dbt-admin` |
| Compute | Ai chạy Spark | Role `compute-user`, `compute-admin` và ACL theo project |
| Ingestion | Ai quản lý connection và job nạp dữ liệu | Team theo group Keycloak; `ingest-viewer`, `ingest-admin` |
| Analytics | Ai dùng dashboard, dataset BI | Role Superset ánh xạ từ Keycloak |
| Ontology | Ai xem và sửa ontology | Role `ontology-viewer`, `ontology-editor`, `ontology-admin` |

:::caution Giới hạn hiện tại

Đồng bộ role giữa Keycloak và query engine chỉ đồng bộ membership. Nó không tự cấp object grant, quyền Superset hay quyền lưu trữ. Ẩn menu trên giao diện cũng không thay thế việc kiểm tra quyền ở backend.

:::

## Cấu hình ở đâu

| Việc cần làm | Nơi thực hiện |
|---|---|
| Tạo user, group, role; gán role | **Settings** > **User Administration**, các tab **Users**, **Roles** và **Permissions**. Xem [Quản lý người dùng, group và role](../operate/user-management.md) |
| Cấp quyền trên bảng, view, folder | Tab quyền của đối tượng trong Console, hoặc câu lệnh SQL `GRANT` |
| Gắn row access policy, column masking | **SQL Editor** (menu **Workspaces**), bằng câu lệnh `ALTER TABLE` hoặc `ALTER VIEW` |
| Gán role Data Governance | Role của user trên client `data-governance` trong Keycloak |
| Gán role dbt và Compute | Role của user trong Keycloak; ACL Compute trong cấu hình project |
| Ánh xạ role Superset | Cấu hình ánh xạ group, role Keycloak sang role Superset khi triển khai |

Quản lý người dùng nằm ở [Quản lý người dùng, group và role](../operate/user-management.md); đăng nhập một lần nằm ở [Xác thực và SSO với Keycloak](../operate/identity.md).

## Hanas Catalog

Hanas Catalog có ba mức, mức trên bao gồm mức dưới. Khi người dùng có nhiều role, hệ thống lấy mức cao nhất. Không có role nào được xem như viewer.

| Chức năng | Viewer | Editor | Admin |
|---|:-:|:-:|:-:|
| Tìm kiếm, duyệt, xem chi tiết, lineage, tag, glossary, assertion | Có | Có | Có |
| Gắn, gỡ tag, term, owner, link; sửa mô tả; related terms | Không | Có | Có |
| Thêm lineage thủ công | Không | Có | Có |
| Tạo, sửa, xóa định nghĩa tag; quản lý glossary | Không | Có | Có |
| Xóa thực thể khỏi catalog | Không | Không | Có |
| Metadata ingestion và Secrets, kể cả xem | Không | Không | Có |

Admin của query engine tự động là admin Data Governance. Role chỉ quyết định bạn làm được gì; bạn thấy dataset nào vẫn do query engine quyết định, và admin cũng không thấy dataset mà query engine không cho xem. Role mới có hiệu lực sau khi người dùng đăng nhập lại.

## Object grant trên query engine

Bạn cấp quyền cho role thay vì từng user để dễ quản lý. Quyền áp dụng cho source, folder, bảng, view và function.

```sql
GRANT SELECT ON TABLE "lakehouse"."gold_retail"."customer" TO ROLE data_reader;
```

Các quyền thường dùng gồm `SELECT`, `ALTER`, `MODIFY`, `INSERT`, `DELETE`, `UPDATE`, `DROP`, `EXECUTE`, `MANAGE_GRANTS`. Tên source, schema và bảng trong ví dụ là minh họa.

## Row access policy và column masking

Hai cơ chế này lọc hàng hoặc che giá trị cột dựa trên một function (UDF) bạn định nghĩa. Function phải trả đúng kiểu của cột.

:::info

Row access policy và column masking được query engine áp dụng cho mọi truy vấn đi qua nó, bao gồm SQL Editor, BI, JDBC/ODBC và Arrow Flight. Console không có màn hình riêng để quản lý các policy này; bạn thao tác bằng SQL.

:::

Ví dụ che số điện thoại, chỉ cho một người được duyệt xem giá trị thật. Tên schema, function và role là minh họa.

```sql
CREATE FUNCTION security.mask_phone (v VARCHAR)
RETURNS VARCHAR
RETURN SELECT CASE
  WHEN query_user() = '<approved_user>' THEN v
  ELSE '***'
END;

ALTER TABLE "lakehouse"."gold_retail"."customer"
  MODIFY COLUMN phone_number
  SET MASKING POLICY security.mask_phone (phone_number);

GRANT SELECT ON TABLE "lakehouse"."gold_retail"."customer" TO ROLE data_reader;
GRANT EXECUTE ON FUNCTION security.mask_phone TO ROLE data_reader;
```

Gắn row access policy, rồi gỡ policy:

```sql
ALTER TABLE "lakehouse"."gold_retail"."account"
  ADD ROW ACCESS POLICY security.branch_filter (branch_code);

ALTER TABLE "lakehouse"."gold_retail"."customer"
  MODIFY COLUMN phone_number UNSET MASKING POLICY security.mask_phone;
```

Một số lưu ý khi áp dụng:

- Cấp `EXECUTE` trên function policy cùng với `SELECT`.
- Schema chứa function và các role phải tồn tại trước khi gắn policy.
- Nếu gắn policy trên view, hãy kiểm tra người bị che không có đường đọc trực tiếp bảng gốc.
- Không hard-code danh sách user trong function khi có nhiều người được xem; dùng role hoặc bảng ánh xạ đã kiểm chứng.
- Admin không mặc định được xem giá trị gốc; xác định rõ ai được unmask.

:::caution Giới hạn hiện tại

Policy của query engine chỉ áp dụng cho truy vấn đi qua query engine. Compute (Spark) hiện đọc dữ liệu bằng định danh chung của lakehouse, nên người có role `compute-user` có thể đọc dữ liệu thô, bỏ qua masking. Hãy cấp `compute-user` có chọn lọc với dữ liệu nhạy cảm.

:::

## dbt, Analytics và Ontology

- dbt: `dbt-viewer`, `dbt-editor`, `dbt-admin`. Admin của query engine không tự là `dbt-admin`. Viewer chỉ chạy được SQL đọc. Workspace dbt dùng chung nên mọi người có role dbt đều thấy các project và connection.
- Analytics: truy vấn từ Superset xuống query engine chạy bằng danh tính của chính người dùng, nên object grant và policy vẫn áp dụng. Role Superset được ánh xạ từ group, role Keycloak khi đăng nhập.
- Ontology: người không có role Ontology không thấy menu và bị chặn route trên giao diện.

## Tiếp theo

- [Quản lý người dùng, group và role](../operate/user-management.md)
- [Xác thực và SSO với Keycloak](../operate/identity.md)
- [Tăng tốc truy vấn với Reflection](../query/acceleration.md)
- [Thu thập metadata](metadata-ingestion.md)
