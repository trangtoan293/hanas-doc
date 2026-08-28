# OpenObserve — Thông tin version

## Version triển khai

Repository hiện chỉ có tài liệu tham chiếu, chưa có manifest/image digest của một môi trường khách hàng. Vì vậy không được suy ra version production từ trang này; điền các giá trị sau từ Helm release, registry và biên bản nghiệm thu:

| Thông tin | Giá trị bàn giao |
|---|---|
| OpenObserve image tag/digest | `<CẦN CHỐT>` |
| Helm chart version | `<CẦN CHỐT>` |
| Ngày triển khai/nâng cấp | `<CẦN ĐIỀN>` |
| Môi trường | `<DEV/TEST/PROD>` |
| Deployment mode | `<LOCAL/CLUSTER>` |
| Metadata DB/version | `<CẦN ĐIỀN>` |
| MinIO/S3 endpoint/provider | `<CẦN ĐIỀN>` |
| Kubernetes version | `<CẦN ĐIỀN>` |
| Owner và change ticket | `<CẦN ĐIỀN>` |

## Cách xác minh phiên bản

```bash
helm -n observability list
helm -n observability get values openobserve -a
kubectl -n observability get pods -o wide
kubectl -n observability get deploy -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.template.spec.containers[*].image}{"\n"}{end}'
```

Nếu chart dùng label/release khác, điều chỉnh selector nhưng phải lưu output vào deployment register. Image digest là evidence đáng tin cậy hơn tag mutable.

## Compatibility matrix tham chiếu

| Thành phần | Yêu cầu kiểm tra |
|---|---|
| Kubernetes | API version, Ingress, StorageClass, RBAC và policy tương thích chart |
| Metadata | PostgreSQL/MySQL version, TLS, connection pool, backup/restore |
| Object storage | S3 API, path-style/TLS, bucket policy, quota và replication |
| Collector | OTLP/HTTP/agent version, retry, payload/schema và authentication |
| Ingress/proxy | Timeout, body size, websocket/UI, TLS và header forwarding |
| Backup/DR | Velero/PV strategy, object replication, restore order và RPO/RTO |

Mỗi lần upgrade phải chạy ingest log, query, alert, UI login, restart/rolling, backup và restore smoke test. Không nâng version metadata DB/object store chỉ vì nâng image nếu release note không yêu cầu.

## Changelog triển khai

| Ngày | Từ version | Đến version | Thay đổi | Ticket | Kết quả/rollback |
|---|---|---|---|---|---|
| `<CẦN ĐIỀN>` | `<...>` | `<...>` | `<...>` | `<...>` | `<...>` |

## Tham khảo chính thức

- [OpenObserve documentation](https://openobserve.ai/docs/)
- [Environment variables reference](https://openobserve.ai/docs/administration/configuration/environment-variables/)
- [Logs JSON ingestion API](https://openobserve.ai/docs/reference/api/ingestion/logs/json/)
- [High Availability deployment](https://openobserve.ai/docs/administration/deployment/ha-deployment/)
