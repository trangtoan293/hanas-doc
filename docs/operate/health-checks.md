---
title: Kiểm tra sức khỏe và giám sát
sidebar_label: Kiểm tra sức khỏe
sidebar_position: 11
description: Cách dùng smoke test, các kiểm tra chức năng bổ sung và tín hiệu giám sát hằng ngày cho Hanas Data Platform.
---

Trang này giúp bạn xác nhận nền tảng hoạt động sau cài đặt hoặc nâng cấp, và theo dõi trạng thái hằng ngày. Smoke test đi kèm bộ cài bao phủ kết nối cơ bản; luồng nghiệp vụ cần kiểm tra bổ sung.

## Smoke test

Chạy từ thư mục gốc của bộ cài, vì script đọc cấu hình bằng đường dẫn tương đối:

```bash
python3 tests/smoke.py
SKIP_PUBLIC=1 python3 tests/smoke.py
```

Biến môi trường hỗ trợ: `HELMFILE` (đường dẫn lệnh), `CURL_IMAGE` (image pod curl tạm) và `SKIP_PUBLIC=1` (bỏ lớp 3 khi chưa tạo route gateway). Script thoát với mã `0` khi mọi kiểm tra đạt, `1` khi có lỗi.

Script cần quyền tạo, xoá và attach pod tạm trong các namespace, cùng khả năng pull image curl. Script xử lý manifest và Secret trong bộ nhớ; hãy giới hạn quyền truy cập log của lần chạy.

| Lớp | Kiểm tra | Giới hạn |
|---|---|---|
| 0. Release và workload | Release ở trạng thái deployed; Deployment, StatefulSet đủ replica Ready; Job hoàn tất. | Job đã bị dọn được coi là đã xong, không phân biệt được với Job bị xoá sau khi lỗi. |
| 1. URL nội bộ | Gọi từng URL Service trong manifest từ namespace bên gọi. Đạt khi nhận được phản hồi HTTP. | Mã `401`, `403`, `404`, `500` vẫn được coi là có phản hồi. Không kiểm TCP của PostgreSQL và Redis. |
| 2. Xác thực và dữ liệu | Issuer public khớp; client secret khớp Keycloak; query engine trả trạng thái `OK`; pod đến Keycloak public qua gateway; query engine ghi được vào object storage; Secret PAT của Superset có dữ liệu. | Không chứng minh token exchange dùng được; PAT chỉ được kiểm là có dữ liệu, không kiểm hiệu lực hay quyền. |
| 3. Public | Host public qua gateway có route; Ontology trả `200` ở endpoint readiness; issuer public khớp. | Chỉ loại các mã `000`, `404`, `502`, `503`, `504`. Không đi hết luồng đăng nhập. |

## Kiểm tra chức năng bổ sung

Các ca sau bù cho phần smoke test không bao phủ. Hãy đưa vào bước nghiệm thu của bạn.

1. Đăng nhập và đăng xuất Hanas Console, Superset và Kapas bằng người dùng thường và quản trị viên; kiểm tra callback, cookie, issuer và phiên đúng người.
2. Chạy truy vấn qua Console, dbt và Superset bằng người dùng bị giới hạn quyền; xác nhận không thừa quyền do proxy hoặc local admin.
3. Gọi Ontology, trò chuyện với Kapas và tool gọi ngược hai chiều; kiểm tra role `ontology-*` và token exchange.
4. Tạo và chạy một project dbt; kiểm tra quyền thư mục storage, workspace, Git SSH và concurrency.
5. Nếu bật Hanas Catalog: kiểm tra endpoint health, thu thập một nguồn thử, chạy theo lịch và giải mã credential sau khi restart.
6. Nếu bật Ingestion: kiểm tra endpoint health, chạy một run ghi vào đích thử, kiểm tra trạng thái, log và checkpoint.
7. Nếu bật Compute: tạo một SparkApplication thử, kiểm tra driver, executor, quota, admission policy và log.
8. Khôi phục một bản backup vào môi trường riêng và lặp lại các ca trên. Thấy file dump chưa đủ để coi backup đạt.

Probe của dbt chủ yếu là TCP, nên trạng thái Ready chưa chứng minh các dependency nghiệp vụ hoạt động.

## Giám sát hằng ngày

Theo dõi các tín hiệu sau bằng công cụ của đơn vị:

| Tín hiệu | Lệnh hoặc nguồn |
|---|---|
| Pod Ready, restart, `OOMKilled` | `kubectl get pods -A`, `kubectl describe pod` |
| Dung lượng PVC | Số liệu của StorageClass hoặc `kubectl get pvc -A` |
| Kết nối và lock PostgreSQL | Công cụ giám sát database |
| Run lỗi và thời gian chạy | Màn hình lịch sử trong Hanas Console |
| Lỗi object storage | Log query engine và MinIO |
| Hạn của PAT | Theo dõi hạn của PAT cấp cho Superset và các dịch vụ |
| Lỗi xác thực, exchange | Log Keycloak và ứng dụng |

Khi xuất log để báo lỗi, không đưa nội dung Secret vào báo cáo.

:::caution Giới hạn hiện tại

Bộ cài chưa có hệ thống monitoring và alerting tập trung. Metrics của query engine và Spark Operator đang tắt, và chưa có dashboard hay rule cảnh báo đi kèm. Bạn cần triển khai công cụ giám sát riêng.

:::

## Tiếp theo

- [Xử lý sự cố](troubleshooting.md).
- [Sao lưu và khôi phục](backup-recovery.md).
- [Cài đặt bằng helmfile](install.md).
