# Kubernetes

## Vai trò

Kubernetes là lớp điều phối container cho Hanas. Kubernetes chịu trách nhiệm đặt Pod lên node, duy trì replica, cấp phát resource, cung cấp service discovery và thực hiện rollout/rollback; Kubernetes không thay thế cơ chế backup dữ liệu hoặc catalog.

## Kiến trúc tham chiếu

| Thành phần | Vai trò | Khuyến nghị production |
|---|---|---|
| Control plane | API Server, Scheduler, Controller, etcd | Tách biệt, HA, backup etcd theo quy trình của distribution |
| General worker pool | Airflow, DataHub, Dremio, UI, services stateless | Tối thiểu 3 node hoặc theo capacity |
| Data/compute pool | Kafka, NiFi, Spark executor, storage client | Gắn label/taint, scale theo workload |
| Storage pool | MinIO và stateful dependencies | Node/disk/network đồng nhất, failure domain rõ |
| GPU pool | vLLM hoặc AI inference | GPU resource, driver/runtime và scheduling policy riêng |

## Namespace tham chiếu

| Namespace | Thành phần |
|---|---|
| `hanas-platform` | Common config, ingress và platform services nếu dùng namespace hợp nhất |
| `ingestion` | NiFi, Kafka/Connect/AKHQ hoặc profile tương ứng |
| `storage` | MinIO, catalog và storage integration |
| `processing` | Spark Operator, SparkApplication và job artifacts |
| `orchestration` | Airflow và metadata DB nếu được quản lý trong cluster |
| `governance` | DataHub |
| `serving` | Dremio, Superset |
| `security` | Ranger, Vault, certificate/auth components |
| `observability` | OpenObserve và collector |
| `velero` | Velero server, BackupStorageLocation và schedules |

Tên namespace có thể khác theo manifest. Không cấp quyền `cluster-admin` cho service account của ứng dụng nếu không có lý do được phê duyệt.

## Tài liệu liên quan

- [Chuẩn bị và thiết lập cluster](cluster-setup.md)
- [Best practices](best-practices.md)
- [Sơ đồ triển khai](../deployment-diagram.md)
- [Baseline triển khai](../../00-overview/platform-baseline.md)
