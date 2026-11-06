---
title: Ánh xạ ontology vào dữ liệu
sidebar_label: Ánh xạ dữ liệu
sidebar_position: 3
description: Ánh xạ object type, property và link type vào dataset, khóa và điều kiện join; dùng automap và Mapping Copilot để tăng tốc.
---

Mapping nối mô hình nghiệp vụ với bảng hoặc view trong query engine. Trang này dành cho tác giả ontology cần biến một concept thành object type có thể truy vấn, kèm property và quan hệ.

Mapping nằm ở giai đoạn **Mapping** của [Ontology Workspace](workspace.md). Nó gồm bốn phần: nguồn dữ liệu, property và khóa, relationship, và trải nghiệm record.

## Khái niệm

| Thành phần | Mô tả |
|---|---|
| Dataset binding | Đường dẫn của bảng hoặc view mà object type đọc record. |
| Primary key | Một hoặc nhiều cột xác định duy nhất một record. |
| Property mapping | Cột nguồn tương ứng với từng property, kèm kiểu và capability. |
| Link mapping | Một hoặc nhiều cặp cột `source_field` và `target_field` dùng để join hai object type. |
| Grain và date policy | Cách dataset biểu diễn thời gian: không có ngày, snapshot theo ngày hoặc khoảng hiệu lực. |

Dataset binding phải là đường dẫn hợp lệ trong query engine. Với khóa gồm nhiều cột, ontology lưu khóa composite và mã hóa giá trị khi cần dùng trong API, nên bạn không tự ghép chuỗi khóa trong ứng dụng.

## Điều kiện cần

- Role `ontology-editor` hoặc `ontology-admin` trong workspace.
- Dataset đã tồn tại trong query engine và bạn có quyền đọc để kiểm tra schema.
- Concept đã được chọn là cần runtime. Concept chỉ làm từ vựng không cần mapping.

:::note Điều kiện

Một entity cần runtime nhưng thiếu dataset hoặc primary key sẽ chặn phát hành. Release validation báo mã lỗi và vị trí để bạn xử lý.

:::

## Các bước

### 1. Chọn nguồn dữ liệu

1. Từ thẻ project trong **Ontology** > **Explore**, chọn **Open Build** (hoặc mở **Ontology** > **Workbench**), rồi chuyển sang **Mapping**.
2. Chọn concept cần ánh xạ.
3. Chọn dataset từ danh sách source, schema, table hoặc view, hoặc dùng đề xuất nguồn của hệ thống.
4. Kiểm tra schema và mẫu dữ liệu của dataset.

Đề xuất nguồn chỉ là gợi ý dựa trên metadata. Hãy xác nhận grain: một dòng là một khách hàng, hay một khách hàng trong một ngày.

### 2. Ánh xạ property và khóa

1. Gán từng property với một cột nguồn và kiểm tra kiểu dữ liệu.
2. Chọn primary key. Nếu một cột chưa đủ duy nhất, chọn khóa composite.
3. Đặt title property để Explore hiển thị tên dễ đọc cho record.
4. Bật `searchable`, `filterable`, `sortable`, `aggregatable` chỉ khi dữ liệu và nhu cầu sử dụng đáp ứng.
5. Đánh dấu cột bỏ qua nếu bạn không muốn đưa vào object type.

Capability quyết định operation nào được phép trong [Query DSL](../develop/ontology-query-dsl.md). Planner từ chối request dùng property chưa bật capability tương ứng.

### 3. Khai báo relationship

1. Chọn quan hệ ngữ nghĩa giữa hai concept, ví dụ khách hàng sở hữu tài khoản.
2. Chọn cặp cột join. Thêm nhiều cặp nếu khóa gồm nhiều cột, chẳng hạn mã khách hàng và mã đơn vị.
3. Chọn cardinality và nhập nhãn thuận, nhãn ngược.
4. Chọn chiều hiển thị trong graph nếu mô hình cho phép.

Hệ thống không đoán join tùy ý. Join mơ hồ hoặc không hợp lệ được báo trong mapping preview. Cardinality chỉ là khai báo; nó không sửa dữ liệu trùng khóa ở nguồn.

### 4. Đặt chính sách ngày

Với dataset snapshot, đặt cột thời gian và chọn `daily_snapshot` làm grain. Date policy có ba giá trị: `none`, `snapshot` và `effective_range`.

| Date policy | Hành vi |
|---|---|
| `none` | Không lọc theo ngày. |
| `snapshot` | Lọc theo ngày được chọn; có thể dùng ngày mới nhất khi không chọn. |
| `effective_range` | Chọn record có khoảng hiệu lực chứa ngày được chọn. |

### 5. Xem trước và kiểm tra

1. Chạy **mapping preview** để xem chẩn đoán compile.
2. Xem trước danh sách record, một record cụ thể và graph theo draft.
3. Chạy **mapping analysis** để biết mức phủ và các đề xuất còn lại.
4. Mở **Release** để validate toàn bộ draft.

Preview đọc dữ liệu bằng danh tính của bạn. Một người dùng khác có thể thấy kết quả khác nếu có row access hoặc masking khác tại query engine.

## Automap và Mapping Copilot

Hai công cụ này giúp tăng tốc mapping nhưng không thay thế validation.

- **Automap** tự đề xuất và gắn nguồn, cột, khóa và quan hệ dựa trên metadata của dataset. Bạn chạy trên một draft rồi xem lại kết quả.
- **Mapping Copilot** xử lý các blocker còn lại sau automap. Mỗi đề xuất được lưu thành candidate riêng, chưa sửa draft. Bạn có thể validate candidate, profile khóa và join trong một ngân sách giới hạn, rồi áp dụng hoặc bỏ qua.

:::note Điều kiện

Mapping Copilot cần dịch vụ AI và cấu hình tương ứng, xem [Ontology Workspace](workspace.md). Khi chưa cấu hình, bạn vẫn mapping thủ công hoặc dùng automap.

:::

Khi áp dụng một candidate, hệ thống ghi lựa chọn vào draft trong một transaction. Hãy chạy lại validation sau đó.

## Giới hạn

:::caution Giới hạn hiện tại

- Kiểu `array_string` được hiển thị nhưng không hỗ trợ search, filter, sort hoặc aggregate.
- Cờ `hidden` chỉ điều khiển trình bày. Để chặn cột, dùng masking và grant tại query engine.
- Concept, business group hoặc shared property type không tự tạo dataset binding, link hay metric.

:::

## Xử lý sự cố

| Hiện tượng | Cách xử lý |
|---|---|
| Publish báo thiếu dataset hoặc key | Hoàn tất binding và primary key cho entity cần runtime, hoặc chuyển concept về vocabulary. |
| Số record bị nhân lên sau khi bật link | Kiểm tra cặp cột join có duy nhất ở phía đích không; thêm cột vào khóa join. |
| Preview không có record | Kiểm tra quyền đọc, bộ lọc ngày và đường dẫn dataset. |
| Property không dùng được để lọc | Bật `filterable` rồi validate lại draft. |

## Tiếp theo

- Thêm chỉ số tại [Metric](metrics.md).
- Kiểm tra kết quả bằng [Khám phá đối tượng](explore.md).
- Phát hành theo [Quản trị ontology](governance.md).
