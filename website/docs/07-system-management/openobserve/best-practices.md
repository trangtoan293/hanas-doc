# OpenObserve — Best Practices

## Kiến trúc và capacity

- Dùng local/single node cho dev/demo; dùng cluster mode với PostgreSQL/MySQL metadata và MinIO/S3-compatible cho production.
- Tách workload ingest, query, compaction hoặc node role khi volume/query concurrency yêu cầu; đặt requests/limits và anti-affinity theo topology.
- Tính storage theo bytes/day × retention × overhead/compaction × growth; theo dõi actual thay vì dùng sizing cố định.
- Pin image/chart bằng version hoặc digest; không dùng `latest`.
- Đồng bộ NTP giữa Kubernetes nodes, collectors và nguồn dữ liệu để timestamp/trace chính xác.

## Ingestion và schema

- Chuẩn hóa field bắt buộc: timestamp, service, environment, severity, correlation/trace ID.
- Tách stream theo loại dữ liệu và retention; kiểm soát field cardinality cao (request ID, user ID, URL động).
- Batch hợp lý, retry có backoff và dead-letter path ở collector; tránh retry vô hạn tạo duplicate.
- Redact PII/secret trước khi rời nguồn; không ingest payload request/response đầy đủ nếu không có nhu cầu và phê duyệt.
- Đặt dashboard/alert dựa trên field có schema ổn định; version-control parser/transform.

## Query và dashboard

- Luôn giới hạn time range và dùng filter có chọn lọc trước khi aggregate.
- Dùng query mẫu có owner; review query nặng, scheduled report và alert background.
- Không để dashboard production gọi hàng trăm query không giới hạn cùng lúc.
- Gắn business meaning, unit, timezone và data freshness vào dashboard.

## Bảo mật

- HTTPS ở mọi endpoint; giới hạn network bằng Ingress allowlist, NetworkPolicy và firewall.
- SSO/MFA cho người dùng; service account riêng, token scope tối thiểu và rotation.
- Lưu credential trong Vault/Secret manager, không trong values commit, image, command history hoặc log.
- Áp dụng RBAC theo organization/stream/role; audit login, policy, delete, retention, export.
- Bật `ZO_COOKIE_SECURE_ONLY` khi topology dùng HTTPS và kiểm tra reverse-proxy header.
- Tách OpenObserve khỏi vùng dữ liệu nghiệp vụ nếu chỉ cần lưu log kỹ thuật; xác định classification và retention.

## Vận hành và DR

- Cảnh báo health, pod restart, ingest failure, query error/latency, storage usage, compaction backlog, metadata DB và object storage.
- Backup metadata và cấu hình; object data phải có lifecycle/replication theo [DC-DR runbook](../../08-infrastructure/dc-dr/README.md).
- Test restore định kỳ trên môi trường cô lập; backup `Completed` không đồng nghĩa restore đã được kiểm chứng.
- Thực hiện upgrade theo canary/rolling, đọc release note, kiểm tra schema/config compatibility và có rollback.
- Mỗi thay đổi phải có ticket, owner, thời điểm, evidence và cập nhật [Baseline triển khai](../../00-overview/platform-baseline.md).

## Checklist trước go-live

- [ ] Image/chart/version và checksum đã được phê duyệt.
- [ ] HA, metadata DB, object storage, PVC/backup và retention đã test.
- [ ] HTTPS, SSO/MFA, RBAC, service account và secret rotation đã test.
- [ ] Collector cho logs/metrics/traces có retry, backpressure và owner.
- [ ] Dashboard/alert/runbook và kênh escalation đã test.
- [ ] Query, ingest, restart, failover/restore có evidence.
- [ ] Không còn credential mặc định hoặc hardcoded secret.
