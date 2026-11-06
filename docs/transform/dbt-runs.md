---
title: Chạy, kiểm thử và lập lịch dbt
sidebar_label: Chạy và lập lịch dbt
sidebar_position: 2
description: Chạy command dbt với target và selector, đọc log và artifacts, kiểm thử dữ liệu và cấu hình lịch chạy.
---

Hanas Data Platform lưu trạng thái, log và artifacts cho các lần thực thi dbt trong Hanas Console. Trang này hướng dẫn bạn chọn command, kiểm tra kết quả và đưa công việc đã xác nhận vào lịch chạy.

## Khái niệm

Run là một lần thực thi command trên project với target và phạm vi model được chọn. Selector giới hạn tài nguyên dbt cần xử lý; target quyết định cấu hình kết nối được sử dụng.

| Command | Mục đích |
|---|---|
| `dbt compile` | Biên dịch model thành SQL để kiểm tra logic và dependency. |
| `dbt run` | Xây dựng các model thuộc phạm vi lựa chọn. |
| `dbt build` | Thực thi tài nguyên và test theo dependency của dbt. |
| `dbt test` | Chạy các kiểm thử đã khai báo trong project. |
| `dbt seed` | Nạp dữ liệu seed của project. |
| `dbt snapshot` | Chạy các định nghĩa snapshot được project cung cấp. |
| `dbt source freshness` | Kiểm tra độ mới theo cấu hình freshness của source. |
| `dbt deps` | Cài dependency khai báo cho project. |
| `dbt docs generate` | Sinh artifacts phục vụ tài liệu và thu thập metadata. |

Command thành công không tự xác nhận dữ liệu đạt mọi yêu cầu nghiệp vụ. Bạn cần khai báo test, điều kiện freshness và phép đối soát tương ứng với mô hình đang xây dựng.

## Điều kiện cần

:::note Điều kiện

Bạn cần `dbt-editor` hoặc `dbt-admin` để chạy, hủy và lập lịch dbt. Viewer được xem lịch sử, log và các công cụ đọc được cho phép. Connection, target và quyền dữ liệu phải được chuẩn bị trước khi chạy.

:::

Lịch không có người thao tác tại thời điểm kích hoạt. Đường chạy query engine theo lịch cần credential ngoại tuyến của người tạo lịch; thiếu hoặc hết hiệu lực sẽ làm công việc lỗi.

## Chạy thủ công

1. Mở project trong **dbt Studio** để kiểm tra nội dung model đã lưu.
2. Chọn **Target** tương ứng với môi trường cần chạy, tránh ghi nhầm dữ liệu sang vùng phục vụ báo cáo.
3. Chọn command như **Build**, **Run** hoặc **Test** theo mục tiêu của lần thực thi.
4. Nhập selector khi bạn muốn giới hạn một model hoặc một nhóm dependency cụ thể.
5. Bắt đầu chạy và mở log để theo dõi tiến độ, cảnh báo và thông báo lỗi đầu tiên.
6. Mở chi tiết run để đối chiếu trạng thái cùng kết quả từng tài nguyên dbt sau khi hoàn tất.

Ví dụ command tương đương dưới đây dùng target `dev` và model giao dịch đã có trong project:

```bash
dbt compile --target dev --select fct_transaction
dbt build --target dev --select +fct_transaction
dbt test --target dev --select fct_transaction
```

Dấu cộng trước tên model chọn thêm các dependency upstream theo cú pháp selector của dbt. Kiểm tra phạm vi lựa chọn trước khi chạy trên các model có thao tác ghi dữ liệu.

## Bổ sung kiểm thử dữ liệu

Ví dụ YAML sau minh họa kiểm tra khóa giao dịch không null và không trùng. Chỉ dùng test `unique` khi grain đã xác định đúng một dòng cho mỗi `transaction_id`.

```yaml
version: 2

models:
  - name: fct_transaction
    description: Mỗi dòng là một giao dịch đã chuẩn hóa.
    columns:
      - name: transaction_id
        tests:
          - not_null
          - unique
      - name: account_id
        tests:
          - not_null
```

Bạn nên bổ sung kiểm tra quan hệ, trạng thái hợp lệ và tổng số tiền theo kỳ nếu mô hình cần đối soát. Freshness chỉ có ý nghĩa khi source có cấu hình thời gian và ngưỡng được nhóm dữ liệu thống nhất.

## Theo dõi và hủy run

Mở **dbt Studio** → **Orchestrate** rồi chọn **Runs** để xem lịch sử các run đã ghi nhận. Chi tiết run cung cấp command, target, thời gian, trạng thái và log phục vụ chẩn đoán.

Log trực tiếp được truyền từ runner; artifacts được lưu theo kết quả thực thi. Khi cần dừng công việc, chọn thao tác **Cancel** trên run đang hoạt động, rồi kiểm tra trạng thái cuối cùng.

Hủy hoặc lỗi giữa chừng không tự hoàn nguyên toàn bộ dữ liệu mà các model trước đó đã ghi. Trước khi chạy lại, hãy kiểm tra tính idempotent, materialization và phạm vi các model đã thành công.

## Tạo lịch dbt

1. Mở **dbt Studio** → **Orchestrate** rồi chọn **Schedules** để quản lý lịch của workspace.
2. Chọn thao tác tạo lịch và nhập tên mô tả rõ công việc cần thực thi.
3. Chọn project, command, target và selector giống cấu hình đã chạy thử thành công.
4. Nhập cron hoặc chọn mẫu lịch có sẵn để xác định các thời điểm kích hoạt.
5. Kiểm tra danh sách thời điểm chạy tiếp theo do backend tính trước khi lưu lịch.
6. Bật lịch và theo dõi run đầu tiên để kiểm tra credential, quyền dữ liệu và kết quả.

:::note Điều kiện

Lịch dbt hiện tính cron theo UTC. Ví dụ `0 2 * * *` tương ứng 02:00 UTC, tức 09:00 tại Việt Nam. Đối chiếu thời điểm hiển thị trong giao diện trước khi xác nhận lịch.

:::

| Trường | Ý nghĩa |
|---|---|
| Project | Project chứa tài nguyên dbt cần thực thi. |
| Command | Command được lịch kích hoạt. |
| Selector | Phạm vi model và dependency được lựa chọn. |
| Target | Cấu hình môi trường chạy do admin dbt chuẩn bị. |
| Cron | Biểu thức lịch; các lần chạy tiếp theo cần được kiểm tra. |
| Active | Bật hoặc tạm dừng các lần kích hoạt mới. |
| Webhook | Kênh nhận thông báo lỗi khi đã cấu hình và được phép truy cập. |

## Giới hạn

Runner có cơ chế bỏ qua một số node đã chứng minh không thay đổi. Với table, incremental và snapshot, quyết định còn dựa trên lịch sử snapshot Iceberg khi đọc được metadata cần thiết.

Nếu không chứng minh được trạng thái không đổi, runner vẫn xây dựng node. Có thể yêu cầu xây dựng lại bằng `--rebuild-unchanged`; `--full-refresh` cũng loại bỏ tối ưu này khi được sử dụng.

:::caution Giới hạn hiện tại

Trường `publish_schema` trong lịch dbt chưa thực hiện publish Iceberg. Không dùng trường này làm bước phát hành dữ liệu; hãy mô hình hóa bảng đích trong project và kiểm tra kết quả ghi.

:::

## Xử lý sự cố

| Hiện tượng | Cách xử lý |
|---|---|
| Run lỗi target | Kiểm tra target có thuộc project và connection còn dùng được. |
| Lịch không chạy đúng giờ | Kiểm cron UTC, trạng thái Active và thời điểm chạy tiếp theo. |
| Chạy tay được, lịch lỗi xác thực | Nhờ quản trị viên kiểm tra credential ngoại tuyến của người tạo lịch. |
| Test lỗi sau khi model đã ghi | Đọc tài nguyên lỗi và đối soát dữ liệu trước khi chạy lại. |
| Run chờ hoặc bị từ chối do tải | Kiểm tra các run đang hoạt động và giới hạn đồng thời của runner. |

## Tiếp theo

- [Điều phối nhiều bước bằng Pipeline](pipelines.md).
- [Thu thập metadata dbt](../govern/metadata-ingestion.md).
- [Chuẩn mô hình hóa](modeling-standards.md).
