# OpenObserve — Hướng dẫn sử dụng

## Truy cập

| Thông tin | Giá trị bàn giao |
|---|---|
| URL UI/API | `<CẦN ĐIỀN>` |
| Organization | `<CẦN ĐIỀN>` |
| SSO/local login | `<CẦN ĐIỀN>` |
| Nhóm quản trị | `<CẦN ĐIỀN>` |
| Kênh cảnh báo | `<CẦN ĐIỀN>` |
| Retention theo stream | `<CẦN ĐIỀN>` |

Người dùng phải truy cập qua HTTPS/Ingress được phê duyệt. Không chia sẻ root credential; nếu cần hỗ trợ, mở ticket và cấp quyền JIT.

## Luồng sử dụng chuẩn

1. Chọn organization và stream đúng domain/môi trường.
2. Xác nhận time range và timezone trước khi kết luận số liệu.
3. Dùng filter theo `service`, `namespace`, `pod`, `level`, `trace_id` hoặc field tương ứng.
4. Lưu query/dashboard với owner, mục đích và thời hạn review.
5. Khi export, kiểm tra classification và policy; không tải dữ liệu nhạy cảm về máy cá nhân.

## Ingest log qua HTTP API

OpenObserve hỗ trợ JSON ingestion tại `POST /api/{organization}/{stream}/_json`. Ví dụ dưới đây dùng dữ liệu không nhạy cảm:

```bash
export O2_HOST="https://<OPENOBSERVE_HOST>"
export O2_ORG="<ORG>"
export O2_USER="<SERVICE_USER>"
export O2_PASSWORD="<FROM_SECRET_MANAGER>"

curl -fsS -u "$O2_USER:$O2_PASSWORD" \
  -H 'Content-Type: application/json' \
  -X POST "$O2_HOST/api/$O2_ORG/platform_logs/_json" \
  --data '[
    {
      "_timestamp": "2026-01-01T00:00:00Z",
      "service": "example-service",
      "environment": "test",
      "level": "info",
      "message": "pipeline completed",
      "duration_ms": 120
    }
  ]'
```

Response phải có trạng thái thành công và số record thành công/thất bại. Dữ liệu JSON sâu sẽ được flatten theo cơ chế của OpenObserve; thống nhất schema trước khi dùng field trong dashboard.

## Query mẫu

```sql
-- Lỗi theo service trong khoảng thời gian đã chọn trên UI
SELECT service, count(*) AS error_count
FROM platform_logs
WHERE level = 'error'
GROUP BY service
ORDER BY error_count DESC;

-- Tìm request chậm
SELECT service, AVG(duration_ms) AS avg_duration_ms
FROM platform_logs
WHERE duration_ms > 1000
GROUP BY service
ORDER BY avg_duration_ms DESC;
```

Tên stream/field phải thay theo deployment; query mẫu không tạo quyền truy cập mới.

## Logs, metrics và traces

| Loại | Mục đích | Điểm cần kiểm tra |
|---|---|---|
| Logs | Điều tra lỗi và audit kỹ thuật | Timestamp, service, severity, correlation ID |
| Metrics | Theo dõi resource/throughput/latency | Unit, scrape interval, cardinality, missing data |
| Traces | Theo dõi request end-to-end | Trace ID, service name, sampling, clock sync |

Kubernetes logs/metrics và OpenTelemetry collector phải ghi rõ source, namespace, stream, credential và owner trong inventory.

## Dashboard và alert

- Dashboard production phải có owner, mục đích, query version và thời hạn review.
- Alert cần có condition, evaluation window, severity, deduplication, receiver, runbook và escalation.
- Mỗi alert phải được test bằng dữ liệu giả lập; không bắn notification thật khi chưa có cửa sổ kiểm tra.
- Theo dõi tối thiểu: ingest rate/error, query latency/error, storage usage, compaction, pod/node health, backup và replication.

## Troubleshooting

| Hiện tượng | Kiểm tra đầu tiên | Hướng xử lý |
|---|---|---|
| UI không truy cập được | DNS/TLS/Ingress/Service/pod | Kiểm tra network path và event; không tắt TLS để chữa cháy |
| `401/403` | User, org, group, token, policy | Kiểm tra SSO/RBAC/audit; cấp quyền theo ticket |
| Ingest trả lỗi | URL org/stream, auth, schema, payload size | Gửi batch nhỏ, xem response failed và collector log |
| Có ingest nhưng không thấy khi query | Time range/timezone/stream/timestamp | Query rộng hơn, kiểm tra `_timestamp`/`@timestamp` |
| Query chậm | Time range, filter, cardinality, object storage | Thu hẹp range, thêm filter, kiểm tra compaction/capacity |
| Mất dữ liệu sau restart | Local mode/PVC/permission/storage | Xác minh storage mode và backup; không xóa PVC |
| Alert không gửi | Rule, schedule, receiver, network | Chạy test notification và xem scheduler log |

Khi mở ticket, đính kèm thời điểm, org/stream, correlation ID, request ID, query đã redact, response code và ảnh hưởng; không đính kèm credential hoặc dữ liệu PII.
