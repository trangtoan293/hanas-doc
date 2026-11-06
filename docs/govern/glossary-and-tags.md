---
title: Glossary, tag và ownership
sidebar_label: Glossary, tag và ownership
sidebar_position: 3
description: Xây dựng glossary, quản lý tag và chỉ định người sở hữu cho tài sản dữ liệu trong Hanas Catalog.
---

Glossary, tag và ownership giúp mọi người dùng chung một ngôn ngữ về dữ liệu và biết ai chịu trách nhiệm. Trang này dành cho data steward và người sở hữu dữ liệu.

## Khái niệm

| Thành phần | Mục đích |
|---|---|
| Term | Một thuật ngữ nghiệp vụ có định nghĩa, ví dụ "Khách hàng cá nhân". |
| Nhóm thuật ngữ (term group) | Thư mục để tổ chức term theo cây phân cấp. |
| Related terms | Quan hệ giữa các term, giúp người đọc đi từ khái niệm này sang khái niệm liên quan. |
| Tag | Nhãn nhẹ để phân loại, ví dụ mức nhạy cảm hoặc miền dữ liệu. Mỗi tag có màu. |
| Owner | Người hoặc nhóm chịu trách nhiệm về tài sản. |

Term mô tả nghĩa nghiệp vụ; tag dùng để lọc và phân loại nhanh. Nếu cùng một khái niệm vừa cần định nghĩa vừa cần lọc, dùng term và để tag cho phân loại kỹ thuật.

## Điều kiện cần

:::note Điều kiện

Mức viewer chỉ đọc. Gắn và gỡ tag, term, owner, sửa mô tả, tạo và sửa định nghĩa tag, quản lý glossary cần mức editor. Xem [Phân quyền dữ liệu](access-control.md).

:::

## Xây dựng glossary

1. Mở **Data Governance** trong Hanas Console, chọn **Glossary**.
2. Tạo một nhóm thuật ngữ cho miền nghiệp vụ, ví dụ "Khách hàng" hoặc "Tài khoản".
3. Trong nhóm, tạo term, nhập tên và định nghĩa.
4. Dùng thao tác thêm **Related terms** để liên kết các term liên quan.
5. Thêm tài liệu hoặc liên kết giải thích nếu cần.
6. Gắn term vào các tài sản dữ liệu liên quan.

Bạn có thể đổi tên, di chuyển term giữa các nhóm hoặc xóa chúng.

## Quản lý tag

1. Mở **Data Governance**, chọn **Tags**.
2. Tạo tag mới: nhập tên, mô tả, chọn màu và người sở hữu tag.
3. Sửa hoặc xóa tag khi cần.

:::caution Lưu ý khi xóa tag

Xóa định nghĩa tag sẽ gỡ tag khỏi mọi tài sản đang gắn, kể cả tài sản mà bạn không có quyền xem. Hãy kiểm tra phạm vi trước khi xóa.

:::

## Gắn lên tài sản

Bạn gắn tag, term và owner ở nhiều nơi:

- Trang chi tiết dataset: cho cả dataset và từng cột.
- Danh sách kết quả tìm kiếm: gắn nhanh tag hoặc term.
- Trang chi tiết term hoặc tag: thêm nhiều tài sản cùng lúc.

Sau khi gắn, bạn có thể lọc kết quả tìm kiếm theo tag, term hoặc owner. Xem [Catalog](catalog.md).

## Ví dụ tổ chức

Một nhóm dữ liệu ngân hàng bán lẻ có thể dùng:

| Loại | Giá trị |
|---|---|
| Nhóm term | Khách hàng, Tài khoản, Giao dịch |
| Term | Khách hàng cá nhân, Số dư khả dụng |
| Tag | `pii`, `gold`, `deprecated` |
| Owner | Nhóm dữ liệu khách hàng |

## Giới hạn

- Thuộc tính tùy chỉnh thêm từ giao diện chưa được xác nhận là lưu lên máy chủ; không dùng để lưu thông tin quan trọng.
- Màn hình Domains không còn là trang riêng và được chuyển về tìm kiếm.

## Tiếp theo

- [Tìm kiếm và khám phá tài sản dữ liệu](catalog.md)
- [Lineage](lineage.md)
- [Phân quyền dữ liệu](access-control.md)
