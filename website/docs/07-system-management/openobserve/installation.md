# OpenObserve — Cài đặt và triển khai

Runbook này là mẫu tham chiếu cho OpenObserve trong lớp System Management. Image tag/digest, sizing, domain, storage và credential phải được ghi tại [Baseline triển khai](../../00-overview/platform-baseline.md) trước khi áp dụng.

## Chọn mô hình triển khai

| Mô hình | Dùng cho | Metadata | Stream data | Lưu ý |
|---|---|---|---|---|
| Local/single node | Dev, demo, smoke test | SQLite/local disk | Local disk hoặc S3-compatible | Không dùng làm profile production nếu chưa có thiết kế HA/backup |
| Cluster/HA | Test tải, production | PostgreSQL (khuyến nghị) hoặc MySQL | MinIO/S3-compatible | Cần topology, object storage, metadata DB và cơ chế discovery đã kiểm thử |

OpenObserve dùng HTTP port mặc định `5080`. Cluster mode được bật bằng `ZO_LOCAL_MODE=false`; local mode không được suy diễn thành HA.

## Yêu cầu hệ thống

Sizing phải tính theo ingestion rate, số field/record, retention, query concurrency, compaction và replication. Bảng dưới chỉ là mức khởi điểm để lập kế hoạch, không phải cam kết capacity:

| Môi trường | Compute khởi điểm tham khảo | Storage | Điều kiện |
|---|---:|---:|---|
| Dev/sandbox | 2 vCPU, 4 GiB RAM | 50 GiB | Local mode, dữ liệu mẫu |
| Test | 2–4 vCPU, 8 GiB RAM | Theo test volume | Có backup và test ingest/query |
| Production | `<CẦN ĐIỀN THEO SIZING>` | Object storage + retention | HA, monitoring, backup/restore test |

Checklist trước cài đặt:

- Kubernetes/namespace, StorageClass, Ingress/DNS/TLS và ResourceQuota đã sẵn sàng;
- MinIO/S3 bucket, PostgreSQL/MySQL và NATS/discovery (nếu cluster) đã được cấp phát;
- image được pin bằng tag/digest trong registry được phê duyệt;
- root credential và S3/metadata credential được tạo trong Vault/Secret manager;
- retention, dữ liệu nhạy cảm, người quản trị và kênh cảnh báo đã được chốt.

## Cài đặt trên Kubernetes

Helm command skeleton dưới đây cần đối chiếu với `values.yaml` của chart/version được phê duyệt. Không thay placeholder bằng credential trong shell history hoặc Git:

```bash
helm repo add openobserve https://charts.openobserve.ai
helm repo update
kubectl create namespace observability

helm upgrade --install openobserve openobserve/openobserve \
  --namespace observability \
  --set config.ZO_LOCAL_MODE=false \
  --set config.ZO_HTTP_PORT=5080 \
  --set config.ZO_META_STORE=postgres \
  --set-string auth.ZO_ROOT_USER_EMAIL=<O2_ADMIN_EMAIL> \
  --set-string auth.ZO_ROOT_USER_PASSWORD=<FROM_SECRET_MANAGER> \
  --set-string auth.ZO_META_POSTGRES_DSN=<FROM_SECRET_MANAGER> \
  --set-string auth.ZO_S3_SERVER_URL=<MINIO_OR_S3_ENDPOINT> \
  --set-string auth.ZO_S3_BUCKET_NAME=<O2_BUCKET> \
  --set-string auth.ZO_S3_ACCESS_KEY=<FROM_SECRET_MANAGER> \
  --set-string auth.ZO_S3_SECRET_KEY=<FROM_SECRET_MANAGER>
```

Sau khi cài:

1. Kiểm tra pod, PVC, Service, Ingress và event trong namespace.
2. Kiểm tra OpenObserve kết nối được metadata DB/object storage.
3. Tạo một stream test, ingest một payload không nhạy cảm và query lại.
4. Kiểm tra alert/audit và thử backup/restore theo [runbook DC-DR](../../08-infrastructure/dc-dr/README.md).

## Docker Compose cho Dev/Test

Chỉ dùng cho môi trường không chứa dữ liệu khách hàng:

```yaml
services:
  openobserve:
    image: <APPROVED_OPENOBSERVE_IMAGE>:<PINNED_TAG>
    ports:
      - "5080:5080"
    environment:
      ZO_LOCAL_MODE: "true"
      ZO_HTTP_PORT: "5080"
      ZO_ROOT_USER_EMAIL: <DEV_ADMIN_EMAIL>
      ZO_ROOT_USER_PASSWORD: <FROM_LOCAL_SECRET_STORE>
    volumes:
      - openobserve-data:/data

volumes:
  openobserve-data:
```

Không dùng `latest`, mật khẩu mẫu hoặc volume local cho production. Compose dev phải có `.env` ngoài Git và được xóa theo chính sách dữ liệu sau khi kết thúc thử nghiệm.

## Smoke test

```bash
export O2_HOST="https://<OPENOBSERVE_HOST>"
export O2_ORG="<ORG>"
export O2_USER="<USER>"
export O2_PASSWORD="<FROM_SECRET_MANAGER>"

curl -fsS "$O2_HOST/healthz"

curl -fsS -u "$O2_USER:$O2_PASSWORD" \
  -H 'Content-Type: application/json' \
  -X POST "$O2_HOST/api/$O2_ORG/platform_smoke/_json" \
  --data '[{"_timestamp":"2026-01-01T00:00:00Z","service":"smoke-test","level":"info","message":"ok"}]'
```

Kết quả nghiệm thu phải ghi endpoint, image digest, stream, thời gian ingest/query, log lỗi (nếu có), backup ID và người xác nhận.

## Tham khảo chính thức

- [OpenObserve HA deployment](https://openobserve.ai/docs/administration/deployment/ha-deployment/)
- [OpenObserve storage modes](https://openobserve.ai/docs/administration/maintenance/storage-management/storage/)
- [OpenObserve Helm chart](https://charts.openobserve.ai/)
