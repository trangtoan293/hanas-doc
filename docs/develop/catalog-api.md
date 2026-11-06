---
title: Hanas Catalog API
sidebar_label: Catalog API
sidebar_position: 6
description: Các nhóm endpoint của Hanas Catalog API gồm tìm kiếm, chi tiết entity, lineage, glossary, tag và thu thập metadata.
---

Hanas Catalog API là REST API của dịch vụ Hanas Catalog. Bạn dùng nó để tìm kiếm tài sản dữ liệu, đọc schema và lineage, quản lý glossary, tag và ownership, cũng như cấu hình việc thu thập metadata. Hanas Console dùng chính các endpoint này.

## Khái niệm

Mọi endpoint nằm dưới `/api/v1`, và dịch vụ phục vụ dưới tiền tố `/catalog-api`. Qua gateway, URL có dạng `https://<host>/catalog-api/api/v1/...`; dịch vụ lắng nghe ở cổng 8091 trong cụm.

- Entity được định danh bằng `urn`. Dữ liệu JSON dùng camelCase; thời gian là epoch milliseconds.
- Đọc dữ liệu catalog ở mức người xem: tài khoản đăng nhập nào cũng tìm được, nhưng kết quả chỉ gồm tài sản mà tài khoản được phép xem ở query engine.
- Tài liệu OpenAPI tương tác nằm tại `/catalog-api/docs`; kiểm tra sức khỏe tại `/catalog-api/health` (không cần token).

## Xác thực và quyền

| Yêu cầu | Chi tiết |
|---|---|
| Access token Keycloak | Header `Authorization: Bearer <access_token>` cho mọi endpoint, trừ health. |
| Phiên query engine | Header phiên query engine (xem ví dụ bên dưới) khi đọc hoặc sửa tài sản của query engine; thiếu hoặc hết hạn trả 401. |
| Role | Suy ra từ role Keycloak `data-governance-*`: `viewer` (mặc định, không cần role), `editor`, `admin`. |

Endpoint thu thập metadata và secret yêu cầu mức `admin`; endpoint ghi mô tả, tag, glossary, owner và lineage yêu cầu từ mức `editor`. Xem [Phân quyền dữ liệu](../govern/access-control.md) và [Xác thực và SSO](../operate/identity.md).

Bạn có thể xác nhận role hiện tại bằng `GET /api/v1/me`, trả về `username`, `displayName`, `role` và hai cờ `canManageIngestion`, `canManageSecrets`.

## Tìm kiếm và duyệt

| Endpoint | Chức năng |
|---|---|
| `POST /catalog/search` | Tìm kiếm full-text kèm filter, sắp xếp, phân trang và facets. |
| `POST /catalog/browse` | Duyệt cây theo từng cấp (source, space, container). |
| `GET /catalog/display-name` | Tên hiển thị từ `urn`. |
| `GET /catalog/tags` | Tag đang có trong kho. |

```bash
curl -s -X POST "https://<host>/catalog-api/api/v1/catalog/search" \
  -H "Authorization: Bearer <access_token>" \
  -H "X-Dremio-Token: <session_token>" \
  -H "Content-Type: application/json" \
  -d '{"query": "transactions", "start": 0, "count": 10,
       "filters": [{"field": "_entityType", "values": ["DATASET"]}]}'
```

Request `query` rỗng hoặc `*` trả toàn bộ; nhiều từ khoá ghép bằng AND và khớp tiền tố trên tên, đường dẫn, mô tả và tên cột. Đặt `count` bằng 0 nếu chỉ cần tổng số và facets. Các `filters` hỗ trợ trường như loại entity, nền tảng, tag, owner, container cha và mô tả. Phản hồi gồm `total`, danh sách `entities` và `facets`.

## Chi tiết entity và lineage

| Endpoint | Chức năng |
|---|---|
| `GET /catalog/entity?urn=...` | Chi tiết: schema, mô tả, owner, tag, term, định nghĩa view, profile. |
| `POST /catalog/entities` | Lấy nhiều entity cùng lúc. |
| `POST /catalog/lineage` | Đọc đồ thị lineage upstream và downstream. |
| `GET /catalog/entity/assertions`, `GET /catalog/entity/runs` | Kết quả kiểm tra chất lượng và lịch sử chạy, khi connector mang về dữ liệu này. |
| `GET /lineage/edges` | Các cạnh lineage do API ghi. |

Lineage ghi qua API có hai dạng.

| Endpoint | Chức năng |
|---|---|
| `POST /lineage` | Thêm hoặc xoá cạnh lineage theo kiểu patch, tối đa 1000 cạnh mỗi lần; hỗ trợ `dryRun`. |
| `POST /lineage/sql` | Gửi câu SQL đã chạy để server phân tích ra lineage bảng và cột. |

Lineage ghi bằng API không bị lần thu thập metadata sau ghi đè. Cạnh sinh tự động (ví dụ từ định nghĩa view) không gỡ được bằng `edgesToRemove`. Xem thêm [Lineage](../govern/lineage.md).

## Glossary, tag và ownership

| Nhóm | Endpoint |
|---|---|
| Tag | `GET/POST/PUT/DELETE /tags`, `GET /tags/detail`, `GET /tags/applied`, `PUT /tags/color` |
| Glossary | `GET /glossary/nodes`, `GET /glossary/children`, `GET /glossary/entity`, `GET /glossary/terms`, `POST/DELETE /glossary`, `PUT /glossary/name`, `PUT /glossary/parent`, `POST /glossary/related` |
| Gắn lên entity | `PUT /entity/description`, `POST /entity/tags`, `POST /entity/terms`, `POST /entity/owners`, `POST /entity/links` |
| Mô tả hàng loạt | `POST /entity/descriptions` |

Việc gắn tag, term và owner nhận danh sách entity trong một request và có tuỳ chọn `remove` để gỡ. Xem [Glossary, tag và ownership](../govern/glossary-and-tags.md).

## Thu thập metadata (ingestion)

| Endpoint | Chức năng |
|---|---|
| `GET /ingestion/source-types` | Các loại connector khả dụng. |
| `GET/POST /ingestion/sources`, `GET/PUT/DELETE /ingestion/sources/{id}` | Quản lý nguồn và recipe, kèm lịch cron. |
| `POST /ingestion/test-connection` | Kiểm tra kết nối bằng recipe, trả `id` để theo dõi. |
| `POST /ingestion/sources/{id}/executions` | Chạy thủ công. |
| `GET /ingestion/executions`, `GET /ingestion/executions/{id}` | Danh sách và chi tiết lần chạy, trạng thái, báo cáo. |
| `POST /ingestion/executions/{id}/cancel`, `.../rollback` | Huỷ hoặc hoàn tác một lần chạy. |
| `POST /ingestion/sources/{id}/delete-data-preview`, `.../delete-data` | Xem trước và xoá dữ liệu do nguồn đã ghi. |
| `GET/POST/PUT/DELETE /secrets` | Quản lý secret dùng trong recipe; không bao giờ trả giá trị. |

API không trực tiếp chạy connector: yêu cầu tạo một execution, runner nhận execution và xử lý nền. Bạn theo dõi bằng cách lấy lại execution cho đến khi `status` là một trạng thái kết thúc như `SUCCESS`, `FAILURE`, `CANCELLED` hoặc `TIMEOUT`. Xem [Thu thập metadata](../govern/metadata-ingestion.md).

:::caution Giới hạn hiện tại

Xoá dữ liệu của một nguồn trả 409 khi nguồn đang chạy hoặc đang rollback. Việc xoá yêu cầu quyền `admin` và có thể bị từ chối nếu có tài sản chưa được tài khoản xem được.

:::

## Quy ước lỗi

```json
{ "status": 409, "message": "...", "detail": "..." }
```

401 khi thiếu hoặc hết hạn token, 403 khi dưới mức quyền yêu cầu, 404 khi không có entity (hoặc bạn không có quyền xem), 409 khi trùng tên hoặc tác vụ khác đang ghi. Thao tác lặp lại cạnh lineage đã có hoặc gỡ cạnh không tồn tại được bỏ qua, nên bạn gửi lại cả request một cách an toàn.

## Tiếp theo

- [Tìm kiếm và khám phá tài sản dữ liệu](../govern/catalog.md).
- [Tổng quan tích hợp và xác thực](index.md).
- [Cổng và endpoint](../reference/ports-and-endpoints.md).
