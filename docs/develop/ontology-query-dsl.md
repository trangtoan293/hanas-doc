---
title: Ontology Query DSL
sidebar_label: Ontology Query DSL
sidebar_position: 5
description: Cú pháp Query DSL để liệt kê, lọc, tìm kiếm, tổng hợp và duyệt link giữa các object type, kèm ví dụ request và response JSON.
---

Query DSL là định dạng JSON để truy vấn record theo ontology mà không viết SQL. Trang này dành cho nhà phát triển ứng dụng; endpoint và xác thực nằm ở [Ontology API](ontology-api.md).

Planner đối chiếu mỗi request với property và capability đã khai báo, rồi mới sinh truy vấn. Request không thể gửi SQL tự do. Tên property phải dùng đúng tên API trong định nghĩa đã phát hành; các ví dụ dưới giả định object type `Customer` với các property nêu trong ví dụ.

## Quy ước chung

Base path là `/api/v1/ontology/query`. Gửi `Authorization: Bearer <JWT>` và `?workspace=<slug>` khi có nhiều workspace đã phát hành. Truy vấn chạy dưới danh nghĩa người gọi.

| Thành phần | Quy định |
|---|---|
| Filter phẳng | `[{"property":"branch_code","op":"eq","value":"001"}]`, kết hợp bằng AND. |
| Toán tử | `eq`, `neq`, `gt`, `gte`, `lt`, `lte`, `in`, `contains`, `is_null`, `not_null`. |
| Cây điều kiện | `node_type` là `group` hoặc `clause`; group có `combinator` (`and`, `or`), `negated`, `children`. |
| Toán tử trong cây | Thêm `between` (hai giá trị); `in` cần `values` không rỗng; toán tử null không nhận giá trị. |
| Giới hạn cây | Sâu tối đa 6, tối đa 100 node. |
| Nguồn field | `source` là `base` hoặc `linked`; `linked` chỉ hợp lệ khi thao tác có join. |
| Sắp xếp | `[{"property":"name","dir":"asc","source":"base"}]`; hệ thống tự thêm primary key để giữ thứ tự ổn định. |
| Ngày | `as_of_date` theo date policy của object type; không áp dụng cho search. |

Property phải bật capability tương ứng: `filterable` cho filter, `sortable` cho sort, `searchable` cho search, `aggregatable` cho nhóm và tổng hợp.

Toán tử `contains` khớp chuỗi con, không phân biệt hoa thường, mỗi từ khóa một điều kiện và kết hợp AND. Nó khác với search theo tiền tố.

## List và keyset pagination

```http
POST /api/v1/ontology/query/objects/Customer/list?workspace=banking
Authorization: Bearer <JWT>
Content-Type: application/json
```

```json
{
  "filters": [{"property": "branch_code", "op": "eq", "value": "001"}],
  "sort": [{"property": "customer_id", "dir": "asc"}],
  "page_size": 20,
  "direction": "first",
  "include_linked_columns": true
}
```

Response:

```json
{
  "items": [{"customer_id": "C001", "name": "Khách hàng A", "branch_code": "001"}],
  "next_cursor": null,
  "previous_cursor": null,
  "has_next": false,
  "has_previous": false
}
```

| Tham số | Mô tả |
|---|---|
| `page_size` | Mặc định 20; có trần cấu hình, mặc định 200. |
| `direction` | `first`, `next`, `previous` hoặc `last`. |
| `cursor` | Chuỗi opaque lấy từ `next_cursor` hoặc `previous_cursor` của response trước. |

Để sang trang tiếp, gửi lại cùng filter và sort, cùng `direction: "next"` và `cursor` nhận được. Không tự dựng cursor hoặc OFFSET. Đổi filter hoặc sort thì quay lại `direction: "first"`.

Đọc một record theo khóa: `GET /objects/Customer/C001`. Response là object của record, không có phong bì phân trang.

## Filter nâng cao

Dùng `filter_expression` thay cho `filters` khi cần OR, NOT hoặc lồng nhau.

```json
{
  "filter_expression": {
    "node_type": "group", "combinator": "and", "negated": false,
    "children": [
      {"node_type": "clause", "property": "branch_code", "operator": "in", "values": ["001", "002"]},
      {"node_type": "group", "combinator": "or", "children": [
        {"node_type": "clause", "property": "age", "operator": "between", "values": [30, 50]},
        {"node_type": "clause", "property": "segment", "operator": "eq", "value": "VIP"}
      ]}
    ]
  },
  "page_size": 20
}
```

## Search

Search tìm theo tiền tố trên các property `searchable`.

```http
POST /api/v1/ontology/query/objects/Customer/search
```

```json
{"q": "Ng", "page_size": 20}
```

Request search chỉ có `q`, `page_size`, `cursor`, `direction`; không có filter hay ngày. Response có cùng dạng với list.

## Aggregate

Aggregate nhóm record và tính chỉ số.

```http
POST /api/v1/ontology/query/objects/Customer/aggregate?workspace=banking
```

```json
{
  "group_by": [{"property": "branch_code", "bucket": "exact"}],
  "metrics": [{"op": "count"}],
  "max_buckets": 100
}
```

```json
{
  "group_by": ["branch_code"],
  "metrics": ["count"],
  "buckets": [{"key": {"branch_code": "001"}, "metrics": {"count": 42}}]
}
```

| Thành phần | Giá trị |
|---|---|
| `bucket` | `exact`, `by_day`, `by_week`, `by_month`, `by_quarter`, `by_year`, `by_ranges`. |
| Metric inline | `op` là `count`, `sum`, `avg`, `min`, `max` hoặc `cardinality`, kèm `property` và `source`. |
| Metric đặt tên | `{"metric": "total_balance"}`; không kết hợp với `op` hoặc `property`. |
| Giới hạn | `max_buckets` mặc định 100. |

Khóa metric trong response do hệ thống sinh theo `op` và property; với count là `count`. Metric đặt tên chỉ dùng được khi metric đã `executable` và phù hợp thao tác, xem [Metric](../ontology/metrics.md).

Dạng histogram đơn giản:

```json
{"property": "branch_code", "top_k": 20}
```

```json
{"property": "branch_code", "buckets": [{"value": "001", "cnt": 42}]}
```

## Duyệt link

Một bước, từ một record, có filter, sort và cursor:

```http
POST /api/v1/ontology/query/objects/Customer/C001/links/customer_accounts/query
```

```json
{"q": "SAV", "page_size": 20, "direction": "first"}
```

Hai bước dùng `mid_filters` để lọc trung gian; filter, sort, group và metric áp cho đích:

```http
POST /api/v1/ontology/query/objects/Customer/C001/links/customer_accounts/account_transactions/query
```

```json
{"mid_filters": [{"property": "status", "op": "eq", "value": "ACTIVE"}], "page_size": 20}
```

Danh sách ở cấp object type kèm dataset liên kết dùng `/objects/Customer/links/customer_accounts/list`, trong đó filter và sort có thể đặt `source` là `linked`. Aggregate sau link dùng các endpoint `.../aggregate` tương ứng, xem [Ontology API](ontology-api.md).

## Interface

```http
POST /api/v1/ontology/query/interfaces/Account/list
```

Kết quả gồm các cột shared property và trường `__type` cho biết object type của từng record.

:::caution Giới hạn hiện tại

Truy vấn interface là danh sách có giới hạn, chỉ dùng filter phẳng trên shared property. Cursor, sort, `filter_expression` và `page_size` của request chưa được áp dụng như truy vấn object type.

:::

## Lỗi

Lỗi trả về giữ `detail` và bổ sung `code`, `message`, `request_id`; header `X-Request-ID` cùng giá trị.

```json
{
  "detail": "Property 'age' is not filterable",
  "code": "validation_error",
  "message": "Property 'age' is not filterable",
  "request_id": "<request-id>"
}
```

| Mã | Nguyên nhân thường gặp |
|---|---|
| 401 | Thiếu hoặc hết hạn token. |
| 403 | Thiếu role. |
| 404 | Object type, record hoặc link không tồn tại trong workspace. |
| 409 | Xung đột trạng thái. |
| 422 | DSL sai: property không có capability, toán tử không hợp lệ, cây quá sâu hoặc quá lớn. |
| 429 | Hết ngân sách request. |
| 502, 503, 504 | Query engine hoặc dịch vụ lỗi hoặc quá thời gian; thử lại theo `Retry-After` nếu có. |

Giá trị `code` và nội dung `message` trong ví dụ chỉ minh họa; dùng mã HTTP để xử lý.

## Xử lý sự cố

| Hiện tượng | Cách xử lý |
|---|---|
| 422 với property hợp lệ | Kiểm tra capability của property trong definition. |
| Cursor bị từ chối | Dùng lại filter và sort giống request tạo ra cursor. |
| Kết quả trống ở dataset snapshot | Truyền `as_of_date` hoặc kiểm tra ngày mới nhất. |
| Nhiều workspace, lỗi thiếu scope | Thêm `?workspace=<slug>`. |

## Tiếp theo

- [Ontology API](ontology-api.md) cho danh sách endpoint.
- [Khám phá đối tượng](../ontology/explore.md) cho trải nghiệm giao diện.
- [Metric](../ontology/metrics.md) cho metric đặt tên.
