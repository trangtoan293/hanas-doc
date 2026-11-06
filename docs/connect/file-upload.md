---
title: Tải tệp lên
sidebar_label: Tải tệp lên
sidebar_position: 2
description: Tải tệp CSV, JSON, Parquet hoặc Excel lên workspace từ cây DATA của SQL Editor và chọn định dạng trước khi lưu thành dataset.
---

Trang này hướng dẫn bạn tải một tệp cục bộ lên workspace của mình để truy vấn ngay bằng SQL. Cách này phù hợp với dữ liệu tham chiếu nhỏ hoặc tệp dùng một lần; với dữ liệu thường xuyên cập nhật, hãy dùng [nguồn dữ liệu](./data-sources.md) hoặc [Ingestion](./ingestion.md).

## Các bước

1. Mở [SQL Editor](../query/sql-studio.md) (menu **Workspaces**) và tìm **DATA** trong cây dữ liệu.
2. Chọn workspace cá nhân (home) hoặc một folder bên trong, rồi chọn thao tác **Upload**.
3. Chọn tệp bằng nút duyệt hoặc kéo thả vào hộp thoại. Đặt tên dataset nếu cần.
4. Ở bước tiếp theo, chọn **Format** phù hợp và chỉnh tuỳ chọn. Bản xem trước cập nhật theo thiết lập của bạn.
5. Nếu bản xem trước báo lỗi (ví dụ CSV sai dấu phân tách), đổi tuỳ chọn rồi xem lại.
6. Lưu. Tệp trở thành physical dataset trong folder đã chọn; mở trong SQL Editor hoặc tạo view.

## Định dạng hỗ trợ

| Định dạng | Tuỳ chọn chính |
|---|---|
| Văn bản có phân tách (CSV, TSV) | Dấu phân tách cột (phẩy, tab, gạch đứng), dấu trích dẫn, dấu thoát, dấu phân tách dòng, ký tự chú thích, lấy dòng đầu làm tiêu đề, bỏ qua dòng đầu, cắt khoảng trắng tiêu đề |
| JSON | Không có tuỳ chọn |
| Parquet | Tuỳ chọn riêng của Parquet trong hộp thoại |
| Excel, XLS | Tên sheet, lấy dòng đầu làm tiêu đề, mở rộng ô gộp |

Hộp thoại còn liệt kê các định dạng bảng Iceberg và Delta Lake. Đây là định dạng áp dụng cho dữ liệu dạng folder; với một tệp đơn lẻ, hãy chọn các định dạng ở trên.

## Giới hạn

:::caution Giới hạn hiện tại

Giao diện không đặt giới hạn dung lượng rõ ràng; giới hạn thực tế phụ thuộc cấu hình query engine và gateway của môi trường (kích thước request, vùng lưu trữ tạm). Với tệp lớn, đưa tệp vào object storage rồi thêm làm [nguồn dữ liệu](./data-sources.md). Tệp tải lên nằm trong workspace của bạn và theo quyền của workspace đó.

:::

## Xử lý sự cố

| Hiện tượng | Cách xử lý |
|---|---|
| Xem trước lỗi parse | Kiểm tra dấu phân tách, dấu trích dẫn và dòng tiêu đề. |
| Cột bị gộp thành một | Chọn lại dấu phân tách cột. |
| Tải lên thất bại với tệp lớn | Dùng object storage và thêm làm nguồn. |

## Tiếp theo

- [SQL Editor](../query/sql-studio.md)
- [Workspace, folder và view](../query/spaces-and-views.md)
- [Nguồn dữ liệu truy vấn trực tiếp](./data-sources.md)
