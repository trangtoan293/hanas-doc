---
title: Tìm kiếm và khám phá tài sản dữ liệu
sidebar_label: Catalog
sidebar_position: 1
description: Tìm kiếm, lọc tài sản dữ liệu và đọc trang chi tiết dataset trong Hanas Catalog.
---

Trang này hướng dẫn bạn tìm một dataset trong Hanas Catalog và đọc các thông tin đi kèm: schema, mô tả, người sở hữu, tag, term, lineage và kết quả kiểm tra chất lượng. Dữ liệu hiển thị phụ thuộc vào metadata đã được [thu thập](metadata-ingestion.md) hoặc khai báo.

## Điều kiện cần

:::note Điều kiện

Mọi người dùng đăng nhập đều xem được Hanas Catalog (mức viewer). Bạn chỉ thấy các tài sản mà query engine, dbt hoặc Superset cho phép bạn xem. Quyền chỉnh sửa metadata cần mức editor. Xem [Phân quyền dữ liệu](access-control.md).

:::

## Tìm kiếm và lọc

1. Mở mục **Data Governance** trong Hanas Console. Trang đầu là màn hình tìm kiếm metadata.
2. Nhập từ khóa vào ô tìm kiếm. Kết quả gồm tên, mô tả và metadata của tài sản.
3. Dùng bộ lọc **Type**, **Platform**, **Environment**, **Owner**, **Tag** và **Platform Instance** để thu hẹp kết quả. Dùng **Sort by** để đổi thứ tự sắp xếp.
4. Dùng thanh duyệt phía bên để đi theo cấu trúc nền tảng và container.
5. Chọn một kết quả để mở trang chi tiết. Bảng kết quả có thể thêm tag hoặc term trực tiếp nếu bạn là editor.

Nếu cần cập nhật mô tả cho nhiều tài sản, editor có thể nhập mô tả hàng loạt từ tệp CSV.

:::caution Giới hạn hiện tại

Tìm kiếm chỉ trả về tài sản đã có trong Hanas Catalog. Một bảng mới tạo trong query engine sẽ chưa xuất hiện cho tới khi một lần metadata ingestion thu thập nó.

:::

## Trang chi tiết dataset

Trang chi tiết gom thông tin của một dataset vào các tab. Tab hiển thị có thể khác nhau tùy loại tài sản và loại metadata mà nguồn mang về.

| Khu vực | Nội dung |
|---|---|
| Schema (Columns) | Danh sách cột, kiểu dữ liệu, mô tả, tag và term của từng cột. |
| Documentation | Mô tả dạng văn bản và các liên kết tài liệu liên quan. |
| Ownership, Tags, Terms | Người sở hữu, tag và glossary term gắn ở cấp dataset. |
| Lineage | Đồ thị upstream và downstream. Xem [Lineage](lineage.md). |
| Quality | Kết quả assertion và lịch sử run, khi nguồn mang về metadata này. |
| Properties | Thuộc tính của dataset do nguồn cung cấp. |

Với view, trang còn có phần định nghĩa view. Dataset do pipeline hoặc job tạo ra có thể có thêm lịch sử run.

### Chỉnh sửa metadata

Nếu có quyền editor, bạn có thể:

- Sửa phần mô tả của dataset và của từng cột.
- Gắn hoặc gỡ tag, term và người sở hữu. Xem [Glossary, tag và ownership](glossary-and-tags.md).
- Thêm hoặc gỡ liên kết tài liệu.

Admin có thêm thao tác xóa thực thể khỏi catalog. Hệ thống hiển thị bản xem trước phạm vi xóa trước khi bạn xác nhận.

### Assertion

Hanas Catalog hiển thị assertion và lịch sử run khi nguồn metadata mang chúng về, ví dụ kết quả test của dbt. Catalog không tự chạy các bài kiểm tra chất lượng. Nếu tab Quality trống, nguồn của dataset chưa cung cấp loại metadata này.

## Xử lý sự cố

| Hiện tượng | Nguyên nhân thường gặp | Cách xử lý |
|---|---|---|
| Không thấy một dataset | Bạn chưa có quyền xem trên query engine, hoặc chưa được thu thập | Kiểm tra quyền; nhờ admin chạy metadata ingestion |
| Nút chỉnh sửa bị ẩn | Bạn đang ở mức viewer | Nhờ quản trị viên cấp role editor |
| Lineage hoặc assertion trống | Nguồn không mang metadata đó về | Xem [Lineage](lineage.md) |

## Tiếp theo

- [Thu thập metadata](metadata-ingestion.md)
- [Glossary, tag và ownership](glossary-and-tags.md)
- [Lineage](lineage.md)
