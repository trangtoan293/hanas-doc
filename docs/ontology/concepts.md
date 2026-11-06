---
title: Khái niệm Ontology
sidebar_label: Khái niệm
sidebar_position: 1
description: Giải thích object type, property, link type, interface, metric, action và vòng đời định nghĩa Ontology.
---

Ontology của Hanas Data Platform kết nối mô hình nghiệp vụ với dữ liệu có thể truy vấn. Trang này giải thích những khái niệm bạn gặp khi thiết kế, phát hành và sử dụng ontology.

## Concept, object type và record

**Concept** diễn đạt một khái niệm nghiệp vụ trong mô hình canonical. Concept có thể là `EntityType`, chẳng hạn khách hàng, hoặc `ValueType`, chẳng hạn một kiểu mã hay giá trị nghiệp vụ.

Concept chưa nhất thiết có dữ liệu để đọc. Bạn có thể giữ nó làm vocabulary, hoặc bổ sung mapping để cung cấp một object type trong runtime.

**Object type** mô tả cấu trúc record được phục vụ: dataset nguồn, primary key, các property và cấu hình truy vấn. Tên API dùng cho request có thể khác tên hiển thị trên giao diện.

**Record** là một đối tượng cụ thể được đọc từ dataset đã ánh xạ. Identity của record gồm object type và primary key; với snapshot, bạn cần hiểu thêm grain và ngữ cảnh ngày.

Ví dụ, khách hàng có mã `C001` là một record của object type khách hàng. Một snapshot số dư tài khoản cùng ngày có identity và ý nghĩa khác snapshot của ngày tiếp theo.

:::note Điều kiện

Việc tạo concept chưa làm xuất hiện danh sách record. Concept cần mapping runtime hợp lệ, khóa và deployment đang phục vụ trước khi người dùng truy vấn dữ liệu.

:::

## Property và shared property type

**Property** là thuộc tính của một object type, ví dụ mã khách hàng, tên hoặc ngày mở tài khoản. Property khai báo kiểu dữ liệu và các capability độc lập.

| Capability | Ý nghĩa |
|---|---|
| `required` | Thuộc tính được khai báo là bắt buộc trong mô hình. |
| `searchable` | Có thể tham gia tìm kiếm record theo tiền tố. |
| `filterable` | Có thể dùng trong điều kiện lọc của Query DSL. |
| `sortable` | Có thể dùng để sắp xếp danh sách record. |
| `aggregatable` | Có thể tham gia nhóm hoặc tính tổng hợp theo operation phù hợp. |
| `hidden` | Điều khiển trình bày; không phải chính sách bảo mật cột. |

Các kiểu runtime gồm `string`, `integer`, `long`, `double`, `decimal`, `boolean`, `date`, `timestamp` và `array_string`. Kiểu `array_string` hiện được hiển thị nhưng không hỗ trợ search, filter, sort hoặc aggregate.

`aggregation_role` phân biệt `none`, `dimension` và `measurement`. Dimension thường dùng để phân nhóm; measurement biểu diễn giá trị cần đo, nhưng operation vẫn phải phù hợp kiểu dữ liệu.

**Shared property type** định nghĩa một thuộc tính ngữ nghĩa dùng chung cho nhiều object type. Ví dụ, hai loại tài khoản có thể cùng sử dụng định nghĩa mã khách hàng hoặc ngày nghiệp vụ.

Mỗi property cục bộ ánh xạ tới shared property tương ứng. Cơ chế này thống nhất ý nghĩa và schema; nó không tự join hoặc hợp nhất record từ các nguồn.

## Link type

**Link type** khai báo quan hệ giữa hai object type cùng các cặp cột dùng để join. Quan hệ có nhãn theo chiều thuận, nhãn theo chiều ngược và cardinality.

| Cardinality | Cách hiểu |
|---|---|
| `one_to_one` | Một record nguồn liên quan một record đích theo mô hình khai báo. |
| `one_to_many` | Một record nguồn có thể liên quan nhiều record đích. |
| `many_to_many` | Nhiều record ở hai phía có thể liên quan nhau. |

Một khách hàng có nhiều tài khoản là ví dụ quan hệ một–nhiều. Mapping có thể cần nhiều cặp cột nếu khóa còn bao gồm đơn vị hoặc ngữ cảnh khác.

Khai báo cardinality không tự sửa các khóa trùng hoặc dữ liệu sai ở nguồn. Bạn cần kiểm tra join thực tế để tránh nhân bản record và làm lệch kết quả tổng hợp.

## Interface

**Interface** mô tả một tập shared properties mà nhiều object type cùng implement. Ứng dụng có thể đọc các thuộc tính chung qua một truy vấn xuyên các loại đó.

Ví dụ, tài khoản tiền gửi và tài khoản vay có thể cùng implement một interface tài khoản. Kết quả có trường `__type` để phân biệt object type của từng record.

:::caution Giới hạn hiện tại

Truy vấn interface hiện là danh sách có giới hạn, dùng flat filters trên shared properties. Chưa áp dụng đầy đủ cursor, sort, filter expression hoặc `page_size` như truy vấn object type.

:::

## Metric và action

**Metric** là định nghĩa chỉ số có tên, mô tả, đơn vị và cấu hình thực thi. Một metric có thể dùng aggregate đơn giản, tỷ số hoặc biểu thức dẫn xuất từ các thành phần khác.

Metric trong catalog có thể mang trạng thái `catalog_only`. Chỉ trạng thái `executable` cùng cấu hình phù hợp mới cho phép runtime tính giá trị; vị trí hiển thị được quản lý riêng bằng placement.

**Action** mô tả một thao tác đề xuất trên đối tượng, gồm parameters, thay đổi dự kiến và chính sách xét duyệt. Luồng request phân biệt người gửi, người duyệt và bộ xử lý bên ngoài.

:::caution Giới hạn hiện tại

Action không cung cấp writeback trực tiếp đang hoạt động. Endpoint invoke kiểu cũ bị chặn; action canonical sử dụng request workflow và chờ bộ xử lý bên ngoài sau phê duyệt.

:::

## Business group và workspace

**Business group** tổ chức concept theo miền nghiệp vụ để thuận tiện duyệt và thiết kế. Group có tên hiển thị, thứ tự và được version cùng revision.

Business group không phải nhóm phân quyền. Nó cũng không tự tạo dataset binding, link hoặc metric cho các concept được xếp chung.

**Workspace** là phạm vi dự án chứa định nghĩa, draft, revision và deployment. Khi có nhiều workspace đã publish, ứng dụng cần chỉ rõ workspace để tránh truy vấn thiếu ngữ cảnh.

## Vòng đời draft → review → publish

| Giai đoạn | Ý nghĩa |
|---|---|
| Draft | Tài liệu canonical và manifest đang được soạn; chưa đổi runtime đang phục vụ. |
| Review | Xem mapping, lỗi và tác động; có thể gửi sang trạng thái `pending_approval`. |
| Publish | Kiểm tra checksum, compile và phê duyệt revision để phát hành. |
| Deployment | Bản projection được chuẩn bị và kích hoạt cho runtime đọc. |

Draft chờ phê duyệt bị khóa sửa. Người gửi hoặc admin có thể rút submission; admin có thể từ chối kèm lý do để tác giả sửa tiếp.

Admin có thể publish trực tiếp một draft hợp lệ theo release gate. Vì vậy, thao tác submit không phải bước bắt buộc trước mọi lần publish của admin.

## Tiếp theo

- Tạo và phát hành định nghĩa tại [Ontology Workspace](workspace.md).
- Thiết lập dữ liệu runtime theo [Hướng dẫn mapping](mapping.md).
- Kiểm soát vòng đời bằng [Quản trị ontology](governance.md).
