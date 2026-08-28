# OpenObserve — Cấu hình

## Nguyên tắc

Cấu hình được quản lý theo môi trường, version-control phần không nhạy cảm và lấy secret từ Vault/Kubernetes Secret. Không commit password, access key, token, private key hoặc DSN có credential.

## Chế độ và storage

| Tham số | Giá trị tham chiếu | Production guidance |
|---|---|---|
| `ZO_LOCAL_MODE` | `true` mặc định | `false` cho cluster/HA |
| `ZO_LOCAL_MODE_STORAGE` | `disk` | Chỉ local mode; dùng S3-compatible nếu cần |
| `ZO_META_STORE` | SQLite ở local mode | PostgreSQL (khuyến nghị) hoặc MySQL ở cluster mode |
| `ZO_S3_SERVER_URL` | Rỗng với AWS S3 | Bắt buộc với MinIO/S3-compatible |
| `ZO_S3_PROVIDER` | `s3` | Chọn provider phù hợp, ví dụ `minio` |
| `ZO_S3_BUCKET_NAME` | `<CẦN ĐIỀN>` | Bucket riêng, policy tối thiểu |
| `ZO_S3_BUCKET_PREFIX` | `<CẦN ĐIỀN>` | Prefix riêng cho OpenObserve |

Stream data có thể ở object storage; metadata của cluster phải dùng DB được backup. Không coi PVC của một pod là bản backup duy nhất.

## Network và UI

| Tham số | Giá trị tham chiếu | Lưu ý |
|---|---|---|
| `ZO_HTTP_PORT` | `5080` | Chỉ expose qua Service/Ingress cần thiết |
| `ZO_WEB_URL` | `<PUBLIC_OR_INTERNAL_URL>` | Dùng cho redirect/alert link |
| `ZO_BASE_URI` | Rỗng hoặc `<SUBPATH>` | Cần khi chạy sau reverse proxy dưới subpath |
| `ZO_HTTP_TLS_ENABLED` | Theo topology | Ưu tiên TLS tại ingress; mTLS nội bộ nếu yêu cầu |
| `ZO_HTTP_TLS_MIN_VERSION` | `1.2` hoặc `1.3` | Theo chuẩn ATTT khách hàng |
| `ZO_PROMETHEUS_ENABLED` | Theo monitoring | Chỉ expose endpoint metrics trong mạng được phép |

Ingress phải giới hạn method/size/timeout phù hợp với payload và không ghi header `Authorization` vào access log.

## Mẫu values tham chiếu

```yaml
config:
  ZO_LOCAL_MODE: "false"
  ZO_HTTP_PORT: "5080"
  ZO_META_STORE: "postgres"
  ZO_S3_SERVER_URL: <MINIO_OR_S3_ENDPOINT>
  ZO_S3_PROVIDER: "minio"
  ZO_S3_BUCKET_NAME: <O2_BUCKET>
  ZO_S3_BUCKET_PREFIX: <O2_PREFIX>
  ZO_PROMETHEUS_ENABLED: "true"

auth:
  ZO_ROOT_USER_EMAIL: <FROM_SECRET_MANAGER>
  ZO_ROOT_USER_PASSWORD: <FROM_SECRET_MANAGER>
  ZO_META_POSTGRES_DSN: <FROM_SECRET_MANAGER>
  ZO_S3_ACCESS_KEY: <FROM_SECRET_MANAGER>
  ZO_S3_SECRET_KEY: <FROM_SECRET_MANAGER>
```

Tên key có thể thay đổi theo chart/version; luôn so sánh với `values.yaml` và [environment variables reference](https://openobserve.ai/docs/administration/configuration/environment-variables/) trước khi upgrade.

## Stream, retention và dữ liệu

- Đặt convention cho organization, stream và field; không gửi tất cả log vào một stream không có owner.
- Tách `logs`, `metrics`, `traces` và domain/service có retention khác nhau khi cần.
- Chốt retention theo loại dữ liệu tại baseline; kiểm tra tác động đến object storage, compaction và query.
- Chuẩn hóa timestamp (`_timestamp` hoặc `@timestamp`) và timezone; tránh dùng giờ local không có timezone.
- Cấu hình giới hạn payload/field theo capacity; payload quá lớn phải được chunk/batch ở collector.
- Mask/redact PII trước khi ingest nếu OpenObserve không phải vùng được phép lưu dữ liệu đó.

## Authentication, RBAC và audit

- Bật SSO/RBAC theo [tài liệu xác thực](../../09-security/authentication.md) và [phân quyền](../../09-security/authorization.md) nếu edition/topology hỗ trợ.
- Root user chỉ dùng cho bootstrap; tạo user/group/service account riêng với scope tối thiểu.
- TLS certificate, root credential, metadata DSN và S3 key lấy từ Secret/Vault; định kỳ rotate.
- Bật audit và giám sát các thao tác login, policy, export, delete stream, thay đổi retention.
- Không dùng endpoint admin hoặc Swagger công khai ngoài network quản trị.

## Checklist thay đổi cấu hình

1. Tạo change ticket nêu mục tiêu, owner, version và rollback.
2. Đánh giá ảnh hưởng ingestion/query/retention/storage.
3. Cập nhật values/Secret bằng kênh được phê duyệt; review tối thiểu hai người với production.
4. Rollout từng bước, kiểm tra pod/log/metric và smoke test ingest/query.
5. Cập nhật baseline, changelog và evidence; revoke credential tạm thời.
