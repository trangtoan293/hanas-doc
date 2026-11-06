---
title: Lineage
sidebar_label: Lineage
sidebar_position: 4
description: Xem quan hệ upstream và downstream giữa các tài sản dữ liệu, các nguồn tạo lineage và giới hạn hiện tại.
---

Lineage cho biết dữ liệu của một dataset đến từ đâu và đang được dùng ở đâu. Bạn dùng nó để đánh giá tác động trước khi đổi schema và để truy vết sai lệch về nguồn.

## Khái niệm

- Upstream: các tài sản mà dataset phụ thuộc.
- Downstream: các tài sản dùng dataset này, như view, model dbt hoặc dashboard.
- Lineage cấp bảng nối các dataset với nhau. Lineage cấp cột nối từng cột đầu ra với cột nguồn, khi có đủ dữ liệu.

## Xem lineage

1. Tìm và mở dataset trong Hanas Catalog. Xem [Catalog](catalog.md).
2. Mở tab **Lineage**; bản tóm tắt cũng xuất hiện trong phần Summary.
3. Chọn một node để xem chi tiết và mở rộng đồ thị theo từng bước.
4. Dùng bộ lọc để thu hẹp các tài sản liên quan khi phân tích tác động.

Với lineage cấp cột, mở một cột trong tab Schema để xem cột nguồn khi có dữ liệu.

## Lineage đến từ đâu

| Nguồn | Nội dung |
|---|---|
| Metadata ingestion | Các connector mang theo quan hệ giữa dataset, job và dashboard khi nguồn cung cấp. Xem [Thu thập metadata](metadata-ingestion.md). |
| dbt | Quan hệ giữa các model và source, dựng từ manifest dbt của project. |
| SQL của view và job | Hanas Catalog có thể suy ra lineage cấp bảng và cột từ câu SQL. |
| Khai báo thủ công | Editor có thể thêm lineage qua API của catalog. Xem [Hanas Catalog API](../develop/catalog-api.md). |

## Giới hạn hiện tại

:::caution Giới hạn hiện tại

- Lineage chỉ phản ánh những gì đã được thu thập hoặc khai báo. Dataset chưa có trong catalog không có node lineage.
- Trong dbt Studio, lineage của project được dựng từ manifest và chỉ ở cấp bảng. Phần lineage cấp cột do dbt runner trả về hiện để trống. Lineage cấp cột trong Hanas Catalog là một luồng riêng và chỉ có khi metadata ingestion hoặc SQL cung cấp đủ dữ liệu.
- Chưa xác nhận việc nạp dữ liệu bằng Ingestion tự động sinh lineage đầu cuối trong Hanas Catalog. Hãy coi lineage của luồng nạp là có khi một source thu thập metadata đã bao phủ nó.
- Lineage của dataset trong một số màn hình của query engine dùng nguồn riêng, nên có thể khác với đồ thị trong Hanas Catalog.

:::

## Xử lý sự cố

| Hiện tượng | Cách xử lý |
|---|---|
| Tab Lineage trống | Chạy metadata ingestion cho source liên quan, gồm cả dbt nếu bạn dùng. |
| Thiếu lineage cột | Kiểm tra source có mang thông tin cấp cột; nhớ giới hạn của dbt runner ở trên. |
| Node bị ẩn | Bạn không có quyền xem tài sản đó trên nguồn của nó. |

## Tiếp theo

- [Thu thập metadata](metadata-ingestion.md)
- [Chạy, kiểm thử và lập lịch dbt](../transform/dbt-runs.md)
- [Hanas Catalog API](../develop/catalog-api.md)
