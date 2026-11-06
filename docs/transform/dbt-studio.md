---
title: dbt Studio — project và IDE
sidebar_label: dbt Studio
sidebar_position: 1
description: Tạo project dbt, phát triển model trong IDE, kiểm tra SQL và quản lý thay đổi bằng Git trong Hanas Console.
---

dbt Studio trong Hanas Data Platform giúp bạn phát triển model SQL, kiểm thử dữ liệu và quản lý project ngay trong Hanas Console. Trang này hướng dẫn analytics engineer và data engineer chuẩn bị project trước khi chạy hoặc lập lịch dbt.

## Khái niệm

Một project chứa model SQL, tệp YAML, macro, package và cấu hình phục vụ dbt. Connection xác định hệ thống đích; target xác định bộ cấu hình dùng cho một môi trường thực thi.

IDE cung cấp cây tệp, trình soạn thảo, Source Control và các công cụ compile, preview, query, explain. Lineage của project được dựng từ manifest dbt và thể hiện dependency giữa các model.

| Thành phần | Mục đích |
|---|---|
| Model | Câu SQL định nghĩa dữ liệu đầu ra, có thể tham chiếu model khác. |
| Source | Khai báo bảng nguồn mà project sử dụng. |
| Test | Kiểm tra dữ liệu theo điều kiện đã khai báo. |
| Macro, package | Tái sử dụng logic và các thành phần của project. |
| Connection, target | Chọn đích kết nối và cấu hình môi trường chạy. |
| Git | Lưu lịch sử và trao đổi thay đổi với repository. |

## Điều kiện cần

:::note Điều kiện

dbt Studio cần chức năng phát triển được bật và dbt runner đang phục vụ. Bạn cần `dbt-editor` hoặc `dbt-admin` để tạo project, sửa tệp, thao tác Git và chạy dbt. `dbt-viewer` chỉ sử dụng các thao tác đọc được cho phép.

:::

Quản trị viên dbt chuẩn bị connection và gắn connection, target cho project. Quyền admin của query engine không tự cấp quyền `dbt-admin`.

:::caution Giới hạn hiện tại

Các project dbt dùng workspace chung: người có role dbt thấy project, tên connection, lịch và run trong workspace. Không dùng việc tạo project riêng làm ranh giới phân quyền giữa các nhóm.

:::

## Chuẩn bị project

1. Mở **dbt Studio** trong Hanas Console. Menu có ba mục con: **Projects**, **Explore** và **Orchestrate**. Trang đầu hiển thị Recent projects và Quick actions (Create project, Manage connections, Run history), cùng các nút **Open IDE**, **New project** và **User guide**.
2. Chọn **New project**, hoặc thao tác **Import** hay **Clone**, phù hợp với nguồn mã hiện có.
3. Nhập tên project có ý nghĩa và thống nhất với quy ước đặt tên của nhóm phát triển.
4. Chọn template nếu bạn khởi tạo từ mẫu, hoặc cung cấp repository khi clone mã đã có.
5. Nhờ quản trị viên dbt gắn connection và target dùng cho môi trường phát triển của project.
6. Mở project để kiểm tra cấu trúc tệp, package và khai báo nguồn trước khi chỉnh sửa model.

Project có thể được tạo từ template Data Vault. Bạn vẫn cần rà soát business key, schema nguồn và quy tắc lịch sử của mẫu trước khi dùng.

## Phát triển model đầu tiên

Ví dụ dưới đây giả định bảng bronze đã tồn tại và được khai báo làm source trong project. Các tên trong ví dụ là tên minh họa; bạn thay bằng source và bảng thực tế của mình.

Khai báo source trong tệp YAML của project:

```yaml
version: 2

sources:
  - name: bronze_retail
    database: Lakehouse
    schema: bronze_retail
    tables:
      - name: account
```

Tạo model có tên `stg_retail_account.sql` trong project:

```sql
select
    account_id,
    customer_id,
    account_status
from {{ source('bronze_retail', 'account') }}
```

Model này giữ nguyên grain một dòng cho một bản ghi nguồn. Nếu nguồn lưu nhiều phiên bản hoặc CDC, bạn cần bổ sung logic chọn phiên bản và xử lý xóa phù hợp.

1. Chọn tệp model trong cây tệp để mở trình soạn thảo SQL của project.
2. Lưu nội dung đã chỉnh sửa trước khi dùng các thao tác kiểm tra hoặc chạy model.
3. Chọn **Compile** để xem SQL được sinh sau khi dbt xử lý cấu hình và tham chiếu.
4. Chọn **Preview** để xem dữ liệu thử và kiểm tra tên cột, kiểu dữ liệu, giá trị null.
5. Chọn **Explain** khi cần xem kế hoạch truy vấn của SQL đã biên dịch.
6. Bổ sung mô tả và test trong YAML trước khi chuyển model sang bước chạy chính thức.

Preview giúp phát hiện lỗi truy vấn và cấu trúc dữ liệu; bạn vẫn cần chạy test và đối soát kết quả. Viewer chỉ được gửi SQL đọc thuộc nhóm `SELECT` hoặc `WITH` qua các công cụ đọc được cho phép.

## Làm việc với Git

Source Control hỗ trợ xem diff, stage, unstage, commit, branch, fetch, pull và push. Các thao tác hợp nhất nhánh, xử lý conflict và stash hỗ trợ quy trình phát triển từ repository dùng chung.

1. Mở **Source Control** để kiểm tra các tệp thay đổi và diff trước khi đưa vào commit.
2. Stage các tệp thuộc cùng một thay đổi để lịch sử commit có phạm vi rõ ràng.
3. Nhập thông điệp mô tả thay đổi nghiệp vụ hoặc kỹ thuật rồi chọn **Commit**.
4. Đồng bộ nhánh từ remote trước khi push nếu repository đã có commit mới của thành viên khác.
5. Xử lý từng conflict trong tệp, stage bản đã giải quyết rồi hoàn tất thao tác hợp nhất.
6. Chọn **Push** để gửi commit lên remote bằng credential Git của chính bạn.

Credential Git được quản lý theo từng người dùng. Việc khởi tạo Git hoặc thêm, đổi remote thuộc quyền admin dbt; các thao tác Git phát triển thông thường thuộc editor trở lên.

Khi project đang có người sửa, cơ chế phiên chỉnh sửa điều phối quyền ghi trên project. Bạn nên trao đổi với người đang chỉnh sửa trước khi thay đổi cùng model hoặc chuyển nhánh dùng chung.

## Giới hạn

Lineage trong IDE hiện có ở cấp model từ manifest; lineage cột của runner chưa được cung cấp. Bạn xem lineage cột trong Hanas Catalog khi connector đã thu thập đủ schema và thông tin biến đổi.

Python chạy cục bộ trong runner là chức năng có điều kiện và mặc định tắt. Với PySpark hoặc notebook trên cluster, hãy dùng Compute và các quyền tương ứng.

## Xử lý sự cố

| Hiện tượng | Cách kiểm tra |
|---|---|
| Không thấy menu dbt | Kiểm tra chức năng phát triển và role dbt, sau đó đăng nhập lại. |
| IDE chỉ đọc | Kiểm tra role viewer và trạng thái phiên chỉnh sửa của project. |
| Không chọn được connection hoặc target | Nhờ admin dbt kiểm tra cấu hình gắn với project. |
| Compile lỗi ở source hoặc ref | Kiểm tra tên khai báo, dependency và package đã cài. |
| Git từ chối chuyển nhánh | Commit, stash hoặc xử lý thay đổi chưa lưu trước khi checkout. |

## Tiếp theo

- [Chạy, kiểm thử và lập lịch dbt](dbt-runs.md).
- [Chuẩn mô hình hóa](modeling-standards.md).
- [Lineage trong Hanas Catalog](../govern/lineage.md).
