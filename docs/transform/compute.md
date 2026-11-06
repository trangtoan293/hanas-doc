---
title: Compute — Spark và notebook
sidebar_label: Compute
sidebar_position: 4
description: Phát triển và chạy project PySpark, notebook, pipeline khai báo và streaming job trên Spark, xem log và kết quả trong Hanas Console.
---

Compute (menu **Compute Engine**) là môi trường chạy Apache Spark trên Kubernetes trong Hanas Data Platform. Bạn viết Python hoặc PySpark ngay trong Hanas Console, chạy và đọc log mà không phải tự quản lý cụm. Trang này dành cho data engineer xử lý khối lượng lớn hoặc logic không biểu diễn được bằng SQL.

## Điều kiện cần

:::note Điều kiện

Compute tắt theo mặc định. Quản trị viên cần bật Compute, cung cấp Spark Operator, image Spark và cấu hình lakehouse catalog. Bạn cần role `compute-user` hoặc `compute-admin`, cùng quyền theo project: view, run, edit hoặc manage.

:::

Mỗi lần chạy tạo ứng dụng Spark riêng gồm driver và executor trên Kubernetes. Code của bạn không chạy trong container runner dùng chung. Tài nguyên được chọn khi chạy (Small, Medium, Large hoặc Custom) trong giới hạn do admin đặt.

## Khái niệm

| Thành phần | Mô tả |
|---|---|
| Project Compute | Tập file Python/SQL, cấu hình Spark, thư viện và biến, có quản lý Git. |
| Notebook | File `.ipynb` chạy qua Spark Connect, có thể tái sử dụng session khi phát triển. |
| Pipeline khai báo | Các dataset và flow Spark Declarative Pipelines, hiển thị thành đồ thị dataset. |
| Streaming job | Job Python hoặc SQL chạy liên tục, có checkpoint và vòng đời riêng. |

Khác với Python run trong dbt Studio chạy ngay trong container runner với giới hạn thời gian ngắn, Compute dành cho job Spark phân tán và có timeout dài hơn.

## Tạo project và chạy

1. Mở **Compute Engine** trong Hanas Console. Trang này có các tab **Projects**, **Runs**, **Streaming jobs** và **Sessions**.
2. Trong tab **Projects**, chọn **New project**.
3. Tạo file Python, SQL hoặc notebook trong cây file.
4. Chọn catalog trong khung Catalog để duyệt bảng lakehouse.
5. Chọn **Run**, chọn kích thước tài nguyên rồi xác nhận.
6. Mở tab **Output** để đọc log theo thời gian thực. Chọn Driver hoặc Executor để xem log từng thành phần, hoặc tải về.
7. Sau khi chạy xong, mở chi tiết Run để xem người chạy, cấu hình, tham số, lỗi và nơi chạy.

Ví dụ script PySpark đọc bảng Iceberg và ghi kết quả:

```python
from pyspark.sql import SparkSession, functions as F

spark = SparkSession.builder.getOrCreate()

df = spark.table("lakehouse.silver.transaction")
daily = (
    df.groupBy(F.to_date("transaction_ts").alias("txn_date"))
      .agg(F.sum("amount").alias("total_amount"))
)
daily.writeTo("lakehouse.gold.daily_transaction").createOrReplace()
```

Tên catalog và namespace phụ thuộc cấu hình lakehouse của bản triển khai.

## Pipeline khai báo

Pipeline khai báo mô tả dataset và quan hệ giữa chúng; Spark tự xác định thứ tự. Bạn có thể chạy cập nhật hoặc chạy thử (dry-run), làm mới toàn bộ, và truyền tham số riêng cho lần chạy. Mỗi project chỉ chạy một pipeline tại một thời điểm.

Trong `expectations.yml`, quy tắc chất lượng với `on_fail: drop` loại dòng vi phạm trước khi ghi và giữ chúng ở bảng quarantine `<dataset>__dropped`. Quy tắc này áp dụng cho dataset viết bằng Python; `unique` không loại dòng được mà chỉ cảnh báo.

## Streaming job

Streaming job chạy liên tục, lưu checkpoint và có thể được khởi động lại tự động. Job lỗi liên tiếp nhiều lần trong thời gian ngắn sẽ dừng hẳn và ghi lý do. Bạn xem metrics, sự kiện và cảnh báo của job trong giao diện. Đặt lại checkpoint làm nguồn được đọc lại từ đầu, nên bảng đích có thể nhận dữ liệu hai lần.

## Log và thông báo

Log driver được lưu đầy đủ; log executor được sao chép trước khi pod bị xóa. Bảng log lọc theo mức và nguồn, gồm log nền tảng, Spark và output của bạn. Mức log Spark mặc định là WARN; tăng khi gỡ lỗi rồi đặt lại. Thời gian giữ log do admin cấu hình.

Webhook thông báo lỗi cấu hình theo project, mặc định áp dụng cho run không có người theo dõi như lịch hoặc chạy liên tục. Chưa có thông báo qua email.

## Giới hạn

:::caution Giới hạn hiện tại

- Run dùng danh tính lakehouse của nền tảng, không phải danh tính từng người. Row access và masking của query engine không áp dụng khi Spark đọc file trực tiếp; hãy kiểm soát quyền project và vùng dữ liệu.
- Gói project nén tối đa 8 MB.
- Notebook chưa hỗ trợ cùng sửa theo ký tự; file văn bản thì có.
- Không có terminal vào pod.
- Chi phí hiển thị là ước tính theo cách tính của nền tảng, không phải hóa đơn.
- Step Spark trong Pipeline engine mới chưa được hỗ trợ chính thức; xem [Pipeline](pipelines.md).

:::

## Xử lý sự cố

| Hiện tượng | Cách xử lý |
|---|---|
| Không thấy menu Compute Engine | Compute chưa bật hoặc bạn thiếu role Compute. |
| Run ở trạng thái chờ lâu rồi lỗi | Cụm thiếu tài nguyên hoặc lỗi image; Run lỗi sau khi pod Pending quá lâu. |
| Lỗi cài thư viện | Xem log `pip install` ở khung Môi trường. |
| Run bị hủy giữa chừng | Kiểm tra lại dữ liệu đã ghi trước khi chạy lại. |

## Tiếp theo

- [Điều phối bằng Pipeline](pipelines.md).
- [Chuẩn mô hình hóa](modeling-standards.md).
- [Hiểu các miền phân quyền](../govern/access-control.md).
