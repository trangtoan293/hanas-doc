# Quy Trình Bảo Trì Và Bảo Dưỡng

## 1. Mục tiêu

Bảo trì chủ động nhằm duy trì tính sẵn sàng, hiệu năng, an toàn và khả năng khôi phục của Data Platform. Công việc được lập lịch hoặc mở theo yêu cầu, luôn có change record, người thực hiện, người phê duyệt và bằng chứng sau thực hiện.

## 2. Chu kỳ bảo trì tham chiếu

| Chu kỳ | Nội dung chính | Giao phẩm |
|---|---|---|
| Hàng ngày | Kiểm tra service health, pipeline failed, consumer lag, storage capacity, alert và backup gần nhất | Daily operations log |
| Hàng tuần | Kiểm tra queue/retry, Iceberg small files/snapshot, Kafka retention/lag, Airflow backlog, log ingestion | Weekly health summary |
| Hàng tháng | Health check toàn platform, dung lượng/tăng trưởng, performance trend, quyền truy cập, certificate/secret expiry và test restore mẫu | Monthly health-check report |
| Hàng quý | DR exercise theo phạm vi, review capacity, policy/RBAC, data quality và dependency version | Biên bản DR/capacity/security review |
| 6 tháng | Rà quét lỗ hổng, rà soát hardening, access recertification và kế hoạch vá lỗi | Security assessment/remediation report |
| Theo yêu cầu | Tuning, thay đổi nghiệp vụ, nâng version, mở rộng nguồn hoặc xử lý cảnh báo | Change record + acceptance |

Tần suất chính thức phải được điều chỉnh theo SLA, retention, tốc độ tăng dữ liệu và lịch vận hành của khách hàng.

## 3. Checklist theo lớp

### 3.1 Hạ tầng và Kubernetes

- Node ready, capacity/allocatable, CPU/memory pressure và filesystem.
- Pod restart, pending/evicted, PDB, anti-affinity, probe và resource quota.
- PV/StorageClass, inode, snapshot, object storage capacity và network latency.
- Certificate, DNS, ingress, registry image và clock synchronization.

### 3.2 Ingestion và processing

- NiFi flow/queue/backpressure/provenance và error relationship.
- Kafka broker health, ISR, disk, topic retention, connector/task state và consumer lag.
- Airflow scheduler/worker/DAG import error, failed task, retry/backfill và metadata DB.
- Spark application success, executor OOM, shuffle, skew, checkpoint và event log.

### 3.3 Storage, catalog và data model

- MinIO cluster/drive health, erasure coding, bucket policy, replication lag và quota.
- Iceberg snapshot age, small files, orphan files, compaction và schema evolution.
- Catalog health, namespace/table visibility và consistency giữa catalog với object data.
- dbt build/test freshness, model dependency, reconciliation và lineage.

### 3.4 Governance, security, serving và AI

- DataHub ingestion, asset freshness, owner/domain/glossary, lineage và quality result.
- Ranger policy changes/audit, user/group recertification, masking/row filter và export.
- Vault seal/HA/audit, lease expiry, rotation và quyền truy cập theo path.
- Dremio query latency/memory/reflection; Superset dashboard/query error.
- Dify workflow failure, vLLM model/latency/GPU/queue và Langfuse trace/token/cost.

## 4. Quy trình thực hiện

1. **Lập kế hoạch:** xác định phạm vi, rủi ro, cửa sổ, người thực hiện, người phê duyệt và tiêu chí thành công.
2. **Chuẩn bị:** kiểm tra backup/restore point, quyền truy cập, manifest hiện tại, dependency và kế hoạch rollback.
3. **Thông báo:** gửi lịch, phạm vi ảnh hưởng và kênh liên hệ cho các bên liên quan.
4. **Thực hiện:** chạy checklist, ghi timestamp, command/query quan trọng và kết quả; không ghi secret value.
5. **Kiểm tra:** health/readiness, pipeline mẫu, query, dữ liệu đối soát, alert và log.
6. **Đóng:** cập nhật change record, báo cáo, action item, owner/deadline và tài liệu bị ảnh hưởng.

## 5. Quy tắc thao tác dữ liệu

- Không xóa object, snapshot hoặc bảng production nếu chưa có backup, phê duyệt và kế hoạch phục hồi.
- `expire_snapshots`, `remove_orphan_files`, compaction và retention phải chạy theo policy đã chốt.
- Mọi dữ liệu test phải được đánh dấu và dọn dẹp theo thời hạn; không dùng dữ liệu cá nhân thật trong lab.
- Sau khi thay đổi schema hoặc logic KPI, phải chạy data quality, reconciliation và cập nhật DataHub/glossary.

## 6. Nội dung báo cáo bảo trì

| Phần | Nội dung |
|---|---|
| Tóm tắt | Kỳ bảo trì, phạm vi, tình trạng chung |
| Chỉ số | Uptime, pipeline success, lag, capacity, query latency, backup/replication |
| Phát hiện | Lỗi, rủi ro, xu hướng và mức độ |
| Hành động | Đã thực hiện, kết quả, người thực hiện |
| Khuyến nghị | Ưu tiên, effort, ảnh hưởng, thời hạn |
| Bằng chứng | Dashboard/export/log đã che thông tin nhạy cảm |
| Xác nhận | Người lập, người kiểm tra, đại diện khách hàng |

Ghi kết quả vào hệ thống ITSM hoặc kho tài liệu được khách hàng phê duyệt; không lưu report duy nhất trên máy cá nhân.
