---
title: Ontology API
sidebar_label: Ontology API
sidebar_position: 4
description: Tham chiếu Ontology API cho tích hợp ứng dụng, gồm xác thực, base path và các nhóm endpoint kèm ví dụ cURL.
---

Ontology API cho phép ứng dụng đọc định nghĩa ontology, truy vấn record, tính metric, quản lý draft và deployment, nhập xuất định nghĩa và gửi action request. Trang này dành cho nhà phát triển tích hợp và liệt kê các endpoint nghiệp vụ; cú pháp truy vấn nằm ở [Ontology Query DSL](ontology-query-dsl.md).

## Xác thực

Mọi request gửi header `Authorization: Bearer <JWT>` với token do Keycloak cấp. Xem [Tổng quan tích hợp](index.md) cho cách lấy token. Tenant và người dùng lấy từ token, không gửi trong body.

| Yếu tố | Cách dùng |
|---|---|
| Token | Header `Authorization: Bearer <JWT>`; token hết hạn trả 401. |
| Role | `ontology-viewer`, `ontology-editor`, `ontology-admin`; thiếu quyền trả 403. |
| Workspace | Tham số `?workspace=<slug>` cho endpoint runtime khi có nhiều workspace đã phát hành. |
| Dữ liệu | Truy vấn chạy dưới danh nghĩa người gọi; row access và masking của query engine vẫn áp dụng. |

Khi có nhiều workspace đã phát hành mà request không chỉ rõ workspace, API có thể từ chối thay vì chọn ngầm.

## Base path

Các endpoint dùng tiền tố chung sau, đặt sau tên miền gateway của bản triển khai.

| Nhóm | Tiền tố |
|---|---|
| Định nghĩa, truy vấn, authoring | `/api/v1/ontology` |
| Metric runtime | `/api/v1/runtime` |
| Quản trị hệ thống (workspace, template) | `/api/v1/system` |

Trong bảng dưới, `{type_name}` là tên API của object type, `{pk}` là primary key, `{workspace}` là slug, `{link_name}` là tên link type. Đường dẫn trong bảng tính từ tiền tố `/api/v1/ontology` trừ khi ghi khác.

## Ví dụ cURL

```bash
curl -s "https://<HANAS_HOST>/api/v1/ontology/object-types" \
  -H "Authorization: Bearer $TOKEN"
```

```bash
curl -s -X POST \
  "https://<HANAS_HOST>/api/v1/ontology/query/objects/Customer/list?workspace=banking" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"filters":[{"property":"branch_code","op":"eq","value":"001"}],"page_size":20,"direction":"first"}'
```

Lỗi trả về luôn có `detail`, `code`, `message` và `request_id`; header `X-Request-ID` có cùng giá trị. Xem mục lỗi trong [Query DSL](ontology-query-dsl.md).

## Definition

Đọc định nghĩa đã phát hành.

| Method | Đường dẫn | Mục đích |
|---|---|---|
| GET | `/object-types` | Catalog object type và property. |
| GET | `/object-types/{type_id}` | Một object type theo UUID. |
| GET | `/links` | Link type; có thể lọc theo object type. |
| GET | `/shared-property-types` | Shared property type. |
| GET | `/interfaces` | Interface và các object type implement. |
| GET | `/action-types` | Định nghĩa action. |
| GET | `/metrics` | Catalog metric. |
| GET | `/audit-log` | Audit log của tenant (admin). |
| POST | `/inspect-dataset` | Cột của dataset, tùy chọn mẫu dữ liệu và profile khóa có giới hạn. |
| GET | `/metadata/datasets` | Danh sách dataset. |
| GET | `/metadata/sources`, `/metadata/schemas`, `/metadata/tables`, `/metadata/views` | Duyệt source, schema, bảng, view. |

Response định nghĩa có ETag và `Cache-Control: private, no-cache`.

## Query

Tiền tố `/query`. Body và ví dụ của các endpoint này nằm trong [Query DSL](ontology-query-dsl.md).

| Method | Đường dẫn | Mục đích |
|---|---|---|
| POST | `/query/objects/{type_name}/list` | Liệt kê, lọc, sắp xếp, phân trang. |
| POST | `/query/objects/{type_name}/search` | Tìm theo tiền tố trên property `searchable`. |
| POST | `/query/objects/{type_name}/aggregate` | Histogram hoặc aggregate nhiều metric theo nhóm. |
| GET | `/query/objects/{type_name}/{pk}` | Đọc một record. |
| GET | `/query/objects/{type_name}/{pk}/latest-date` | Ngày mới nhất liên quan record. |
| POST | `/query/objects/{type_name}/{pk}/links/{link_name}/query` | Duyệt một bước link. |
| POST | `/query/objects/{type_name}/links/{link_name}/list` | Danh sách record kèm dataset liên kết. |
| POST | `/query/objects/{type_name}/{pk}/links/{link_name}/aggregate` | Aggregate tập đích sau một bước. |
| POST | `/query/objects/{type_name}/links/{link_name}/aggregate` | Aggregate join ở cấp object type. |
| POST | `/query/objects/{type_name}/{pk}/links/{link1}/{link2}/query` | Duyệt hai bước link. |
| POST | `/query/objects/{type_name}/{pk}/links/{link1}/{link2}/aggregate` | Aggregate sau hai bước. |
| POST | `/query/interfaces/{interface_name}/list` | Danh sách xuyên các object type implement interface. |

Có thêm các endpoint GET đọc nhanh link một và hai bước, và endpoint ngữ cảnh ngày cho đồ thị record (`graph/date-context`, `graph/resolve-snapshot`).

:::note Điều kiện

Endpoint mở rộng đồ thị `graph/expand` cần bật tính năng graph tương ứng ở bản triển khai.

:::

### Object set

| Method | Đường dẫn | Mục đích |
|---|---|---|
| GET, POST | `/object-sets` | Liệt kê hoặc lưu object set. |
| GET, PUT, DELETE | `/object-sets/{set_id}` | Mở, sửa hoặc xóa theo quyền sở hữu. |

## Metrics

| Method | Đường dẫn | Mục đích |
|---|---|---|
| GET | `/api/v1/runtime/object-types/{type_name}/metric-placements` | Vị trí hiển thị metric cho danh sách và chi tiết. |
| POST | `/api/v1/runtime/object-types/{type_name}/metrics/aggregate` | Tính một metric theo filter và ngữ cảnh. |
| POST | `/api/v1/runtime/object-types/{type_name}/{pk}/metrics` | Tính các metric cho một record và ngày chọn. |

## Workspace authoring

Tiền tố `/workspaces/{workspace}`. Yêu cầu `ontology-editor`, trừ khi ghi chú khác.

| Method | Đường dẫn | Mục đích |
|---|---|---|
| GET | `/workspace` | Trạng thái authoring và con trỏ revision. |
| GET | `/workflow` | Tóm tắt draft, readiness và runtime. |
| GET | `/revisions`, `/revisions/{revision_id}` | Danh sách và nội dung revision. |
| POST | `/drafts` | Lưu draft với kiểm soát revision và checksum. |
| POST | `/drafts/blank`, `/drafts/import` | Tạo draft rỗng hoặc import YAML, JSON. |
| POST | `/templates/{template_id}/instantiate` | Tạo draft từ template. |
| POST | `/revisions/{revision_id}/draft` | Tạo draft thay đổi từ revision. |
| DELETE | `/drafts/{draft_id}` | Bỏ draft đang mở. |
| POST | `/drafts/{draft_id}/mapping` | Lưu tài liệu và manifest mapping. |
| POST | `/drafts/{draft_id}/automap` | Tự đề xuất nguồn, cột, khóa, quan hệ. |
| POST | `/drafts/{draft_id}/source-proposals`, `/mapping-analysis`, `/mapping-preview` | Đề xuất nguồn, phân tích và xem trước mapping. |
| POST | `/validate-preview`, `/drafts/{draft_id}/validate` | Validate nội dung chưa lưu hoặc draft. |
| POST | `/drafts/{draft_id}/preview/{concept}/records` | Xem trước danh sách record theo draft. |
| PUT, DELETE | `/metrics/{name}` | Tạo, sửa hoặc xóa metric trong draft. |
| POST | `/metrics/{name}/validate`, `/metrics/{name}/compile-preview` | Validate và compile preview metric. |
| POST | `/drafts/{draft_id}/preview-publish` | Kiểm tra release và tác động. |
| POST | `/drafts/{draft_id}/submit` | Gửi draft chờ phê duyệt. |
| POST | `/drafts/{draft_id}/withdraw` | Rút draft đã gửi. |
| POST | `/drafts/{draft_id}/reject` | Từ chối draft (admin). |
| POST | `/drafts/{draft_id}/publish` | Phê duyệt và kích hoạt (admin). |
| POST | `/revisions/{revision_id}/rollback` | Rollback qua cổng phát hành (admin). |

## Deployment

Tiền tố `/workspaces/{workspace}/deployments`. Yêu cầu `ontology-admin`.

| Method | Đường dẫn | Mục đích |
|---|---|---|
| POST | `/prepare` | Chuẩn bị deployment từ revision đã phê duyệt; cần header `Idempotency-Key`. |
| POST | `/{deployment_id}/health-check` | Kiểm tra trạng thái. |
| GET | `/{deployment_id}/preview-activate` | Xem tác động kích hoạt. |
| POST | `/{deployment_id}/activate` | Kích hoạt, có kiểm tra generation. |

## Portability

| Method | Đường dẫn | Mục đích |
|---|---|---|
| POST | `/workspaces/{workspace}/exports/{package_type}` | Xuất gói `ossie`, `mapping` hoặc `bundle`. |
| POST | `/workspaces/{workspace}/imports` | Tải gói lên và tạo import session. |
| GET | `/workspaces/{workspace}/imports/{session_id}` | Xem session và quyết định đối chiếu. |
| PATCH | `/workspaces/{workspace}/imports/{session_id}/decisions/{decision_id}` | Chọn cách xử lý một tài nguyên. |
| POST | `/workspaces/{workspace}/imports/{session_id}/decisions/bulk` | Áp quyết định hàng loạt. |
| POST | `/workspaces/{workspace}/imports/{session_id}/apply` | Áp import vào draft. |

Response export có header `X-Package-Checksum`. Xem quy trình tại [Quản trị ontology](../ontology/governance.md).

## Workspace và template hệ thống

Tiền tố `/api/v1/system`, yêu cầu `ontology-admin`.

| Method | Đường dẫn | Mục đích |
|---|---|---|
| GET, POST | `/workspaces` | Liệt kê hoặc tạo workspace. |
| GET, PATCH | `/workspaces/{workspace}` | Đọc hoặc sửa metadata. |
| POST | `/workspaces/{workspace}/archive`, `/workspaces/{workspace}/unarchive` | Lưu trữ hoặc khôi phục. |
| GET, POST | `/ossie-templates` | Liệt kê hoặc tạo template. |
| POST | `/ossie-templates/{template_id}/versions` | Tải lên version. |

## Action request

| Method | Đường dẫn | Mục đích |
|---|---|---|
| POST | `/query/objects/{type_name}/{pk}/actions/{action_name}/requests` | Gửi request cho một record. |
| GET | `/query/objects/{type_name}/{pk}/action-requests` | Request của một record. |
| GET | `/action-requests/mine` | Request của bạn. |
| GET | `/action-requests/approvals` | Hộp thư phê duyệt. |
| POST | `/action-requests/{request_id}/approve`, `/reject`, `/cancel` | Duyệt, từ chối, hủy. |
| GET | `/action-requests/external` | Request đã duyệt cho worker. |
| POST | `/action-requests/{request_id}/claim`, `/complete`, `/fail`, `/retry` | Vòng xử lý của worker. |

Endpoint thực thi action kiểu cũ bị chặn; xem [Action](../ontology/actions.md).

## Agent

Tập endpoint rút gọn cho trợ lý và agent. Chúng dùng cùng quyền như truy vấn thông thường.

| Method | Đường dẫn | Mục đích |
|---|---|---|
| GET | `/agent/catalog` | Catalog gọn, tìm và xếp hạng metadata. |
| POST | `/agent/query` | Liệt kê, lọc, sắp xếp. |
| POST | `/agent/search` | Tìm theo tiền tố. |
| POST | `/agent/aggregate` | Aggregate theo nhóm. |
| GET | `/agent/get/{type_name}/{pk}` | Đọc một record. |
| POST | `/agent/traverse` | Duyệt một bước link. |

## Mã lỗi

| Mã | Ý nghĩa |
|---|---|
| 401 | Thiếu hoặc hết hạn token. |
| 403 | Thiếu role. |
| 404 | Không có tài nguyên. |
| 409 | Xung đột trạng thái hoặc revision. |
| 422 | Request sai DSL hoặc validation. |
| 429 | Hết ngân sách request. |
| 502, 503, 504 | Lỗi dịch vụ hoặc quá thời gian; một số có `retryable` và `Retry-After`. |

## Tiếp theo

- [Ontology Query DSL](ontology-query-dsl.md).
- [Tổng quan tích hợp](index.md) cho cách lấy token.
- [Ontology Workspace](../ontology/workspace.md) cho luồng authoring.
