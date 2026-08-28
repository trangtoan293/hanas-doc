# Hạ Tầng Và Triển Khai

## Tổng quan

Hạ tầng Hanas được thiết kế theo mô hình cloud-native: các service chạy trên Kubernetes, dữ liệu bền vững nằm trên object storage/table format, còn backup và khôi phục được kiểm soát bằng Velero và MinIO Site Replication. Mô hình tham chiếu không thay thế thiết kế hạ tầng đã được phê duyệt cho từng Data Center.

## Thành phần

| Nhóm | Thành phần | Trách nhiệm |
|---|---|---|
| Orchestration | Kubernetes | Scheduling, service discovery, rollout, isolation và resource quota |
| Storage | MinIO, PV/StorageClass | Object data, metadata và stateful service data |
| Data platform | NiFi, Kafka, Spark, Airflow, dbt, Dremio, DataHub | Ingestion, processing, modeling, governance và serving |
| Consumption/AI | Superset, Dify, vLLM, Langfuse | Dashboard, workflow, inference và observability |
| Security | Ingress/TLS, Ranger, Vault, IdP | Boundary, identity, authorization và secrets |
| Operations | OpenObserve, alerting | Logs, metrics, traces và cảnh báo |
| DR | Velero, MinIO Site Replication | Backup resource/PV, replicate object data và recovery |

## Tài liệu

- [Sơ đồ triển khai tham chiếu](deployment-diagram.md)
- [Kubernetes — kiến trúc và namespace](kubernetes/README.md)
- [Chuẩn bị cluster](kubernetes/cluster-setup.md)
- [Best practices Kubernetes](kubernetes/best-practices.md)
- [Giải pháp DC-DR](dc-dr/README.md)

## Phân tách môi trường

| Môi trường | Mục tiêu | Quy tắc |
|---|---|---|
| DEV | Phát triển và thử nghiệm | Có thể dùng catalog đơn giản; không dùng dữ liệu production |
| TEST/STAGING | Kiểm thử tích hợp, hiệu năng, restore và release | Cấu hình gần production, dữ liệu đã masking |
| PROD | Vận hành nghiệp vụ | SSO/RBAC, catalog production, backup/DR, change control bắt buộc |
| DR | Khôi phục khi site chính lỗi | Không ghi dữ liệu nghiệp vụ trước khi có quyết định chuyển site |

## Nguyên tắc triển khai

- Pin image bằng tag bất biến/digest; không dùng `latest` trong production.
- Stateful workload có PV, backup policy và restore test riêng.
- Tách node/pool cho storage, compute, platform services và GPU khi workload yêu cầu.
- Chỉ expose UI/API qua Ingress/TLS hoặc private network; không mở trực tiếp các port quản trị ra Internet.
- Mọi namespace có ResourceQuota, LimitRange, RBAC, NetworkPolicy và owner.
- Mỗi release phải có manifest/Helm values, release note, smoke test, rollback và biên bản.

## Thông tin bắt buộc trong hồ sơ bàn giao

Xem [Baseline triển khai](../00-overview/platform-baseline.md) để điền: Kubernetes distribution/version, topology node, StorageClass/PV, CNI/Ingress, DNS/TLS, registry, namespace, endpoint, capacity, backup/DR, owner và cửa sổ bảo trì.
