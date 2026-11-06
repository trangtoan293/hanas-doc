---
title: Khám phá đối tượng
sidebar_label: Khám phá đối tượng
sidebar_position: 5
description: Tìm object type, lọc và tìm kiếm record, vẽ biểu đồ nhanh, xem chi tiết, quan hệ và đồ thị của record.
---

**Explore** là nơi người dùng nghiệp vụ đọc dữ liệu đã phát hành theo ontology, không cần viết SQL. Trang này hướng dẫn tìm đối tượng, lọc danh sách, xem chi tiết và đi theo quan hệ giữa các record.

## Điều kiện cần

- Role `ontology-viewer` trở lên và quyền đọc dữ liệu tại query engine.
- Workspace có deployment đang phục vụ; các object type đã được ánh xạ.
- Khi nhiều workspace đã phát hành, chọn đúng workspace trước khi duyệt.

Explore chạy truy vấn bằng danh tính của bạn. Row access và masking của query engine vẫn áp dụng.

## Catalog

Mở **Ontology** > **Explore**. Trang **Explore projects** liệt kê các project; mỗi thẻ cho biết trạng thái **PUBLISHED** (kèm phiên bản) hoặc **NOT PUBLISHED**. Chọn **Explore** trên thẻ project đã phát hành để xem catalog các đối tượng. Nếu bạn là tác giả, chọn **Open Build** để vào môi trường authoring; nếu cần project mới, chọn **Create project**.

- Tìm theo tên, mô tả, field hoặc metric. Đây là lọc metadata, không phải tìm kiếm toàn văn trên record.
- Lọc theo nhóm **All**, **Object** hoặc **Snapshot**.
- Xem thẻ của từng object type, kèm panel giải thích field, quan hệ và metric.
- Mở object type để vào danh sách record. Đồ thị ontology ở mức type cho biết các object type liên kết với nhau thế nào; đây không phải đồ thị record.

## Danh sách record

1. Chọn một object type để mở bảng record.
2. Nhập từ khóa để tìm trên các property `searchable`.
3. Thêm filter đơn giản hoặc dựng cây điều kiện AND, OR, NOT.
4. Chọn cột sắp xếp và kích thước trang.
5. Dùng nút trang đầu, trước, sau và cuối để duyệt.

Phân trang dùng keyset cursor, nên kết quả ổn định khi bạn chuyển trang liên tục. Khi chọn một relationship, bảng hiển thị thêm cột từ record liên kết và cho phép lọc hoặc sắp xếp theo dữ liệu của phía đó.

:::note Điều kiện

Object type bật `require_filter` không mở danh sách khi chưa có điều kiện hợp lệ, nhằm tránh quét toàn bộ dataset.

:::

### Facet

Panel facet liệt kê các giá trị của property dimension cùng số lượng. Chọn một giá trị để thêm nó làm filter. Chế độ tìm kiếm có giới hạn khi kết hợp với facet, biểu đồ và filter; nếu một tổ hợp không khả dụng, giao diện sẽ không cho chạy đồng thời.

### Saved object set

Bạn có thể lưu truy vấn và trạng thái hiển thị thành object set, riêng tư hoặc chia sẻ trong tenant. Khi mở lại, truy vấn chạy lại theo danh tính của người đọc và cursor về trang đầu. Nếu định nghĩa ontology đổi khiến truy vấn không còn hợp lệ, set được đánh dấu `broken` thay vì giữ dữ liệu cũ.

## Biểu đồ nhanh

Hộp thoại **Quick chart** cung cấp các mẫu sau, được chọn tùy theo kiểu và capability của property.

| Biểu đồ | Dùng cho |
|---|---|
| Pie, bar | Phân bố theo một nhóm. |
| Trend (area) | Xu hướng theo ngày, tuần, tháng, quý hoặc năm. |
| Histogram | Phân bố số theo khoảng. |
| Stacked | Phân bố theo hai nhóm. |
| Scatter | Quan hệ giữa hai giá trị đo. |

Biểu đồ dạng aggregate dùng filter hiện tại và có thể dùng dataset liên kết đã chọn. Scatter và khoảng của histogram được suy ra từ các dòng mẫu của trang hiện tại, nên không phản ánh toàn bộ dữ liệu. Chọn một cột của biểu đồ có thể thêm filter tương ứng.

## Chi tiết record

Mở một dòng để xem trang chi tiết: tiêu đề và identity, tóm tắt property, subtype badge, và các metric được [đặt](metrics.md) cho trang chi tiết. Khu vực action hiển thị khi object type có action; xem [Action](actions.md).

Với dữ liệu snapshot, chọn ngày để xem record và metric theo ngày đó. Hệ thống gợi ý ngày mới nhất có dữ liệu.

## Quan hệ và linked records

Phần **Quan hệ 360** liệt kê các link type của record, kèm nhãn thuận và nhãn ngược. Self-link có hai hướng riêng.

1. Mở một quan hệ để xem các record liên kết.
2. Lọc, tìm kiếm, sắp xếp và phân trang danh sách đó, hoặc xem aggregate.
3. Mở rộng tiếp một quan hệ thứ hai từ record liên kết để đi tối đa hai bước.

Không thấy record liên kết có thể do ontology chưa khai báo quan hệ, hoặc do mapping chưa phủ dữ liệu. Nó không chứng minh về mặt nghiệp vụ là không có quan hệ.

## Đồ thị record

Mở **Graph** từ trang chi tiết để xem đồ thị lấy record làm tâm, các cổng quan hệ và record lân cận.

- Chỉ hiện các link mà chính sách graph cho phép.
- Nhấp để mở rộng dần; hệ thống tránh lặp cùng một record.
- Chọn hướng thuận hoặc ngược, kiểm tra một record, chuyển tâm đồ thị và quay lại record trước.
- Chọn ngày hoặc snapshot khi dữ liệu có ngữ cảnh ngày.

Giao diện hiện lấy tối đa 8 record lân cận cho mỗi lần mở rộng và 20 record cho mỗi trang danh sách liên quan.

## Giới hạn

:::caution Giới hạn hiện tại

Catalog search chỉ lọc metadata. Scatter và histogram dựa trên dòng mẫu của trang. Giao diện hiện không có chức năng tìm đường ngắn nhất trên đồ thị record.

:::

## Xử lý sự cố

| Hiện tượng | Cách xử lý |
|---|---|
| Không thấy object type | Kiểm tra đúng workspace và deployment đang phục vụ. |
| Danh sách yêu cầu filter | Object type bật `require_filter`; thêm một điều kiện. |
| Danh sách trống | Kiểm tra quyền đọc dữ liệu, filter và ngày snapshot. |
| Object set báo `broken` | Mở lại và sửa truy vấn theo định nghĩa mới. |

## Tiếp theo

- [Metric](metrics.md) để hiểu số liệu trên record.
- [Action và yêu cầu thay đổi](actions.md).
- [Ontology Query DSL](../develop/ontology-query-dsl.md) để tái tạo cùng truy vấn bằng API.
