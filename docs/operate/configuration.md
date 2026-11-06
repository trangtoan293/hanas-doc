---
title: Tham chiếu cấu hình
sidebar_label: Cấu hình
sidebar_position: 4
description: Feature flag, tham số vận hành chính và danh sách tên khoá secret của bộ cài Hanas Data Platform.
---

Trang này là tham chiếu cho các khoá cấu hình mà người vận hành thường chỉnh. Giá trị là cấu hình mẫu của bộ cài, không phải khuyến nghị production. Trang chỉ liệt kê tên khoá secret, không có giá trị.

## Nguồn cấu hình

Helmfile nạp ba file theo thứ tự: `images.yaml` (image và digest), file cấu hình môi trường, rồi `secrets.yaml`. URL nội bộ và public được suy ra từ `hosts`, `scheme` và tên release; chỉ ghi đè qua `urls.*` khi cần.

## Feature flag

| Khoá | Mẫu | Tác động và điều kiện |
|---|---|---|
| `superset` | `true` | Bật Apache Superset và Job cấp PAT. Cần secret Superset và client secret tương ứng. |
| `kapas` | `true` | Bật Kapas. Ontology nhận URL chat nội bộ. Cần PostgreSQL, Redis, JWT và các credential được bộ kiểm tra yêu cầu. |
| `dbtRunner` | `true` | Bật dbt runner. Console nhận URL dbt; Hanas Catalog nhận URL dbt nếu bật. |
| `minio` | `true` | Tạo MinIO trong cluster. Khi tắt, bạn phải trỏ `externalS3` tới object storage ngoài. |
| `hanasCatalog` | `false` | Bật API, runner và PostgreSQL của Hanas Catalog. Cần image, khoá mã hoá và mật khẩu database. |
| `ingestion` | `false` | Bật Ingestion, PostgreSQL và thư mục làm việc bền vững. Cần image, khoá mã hoá và mật khẩu database. |
| `compute` | `false` | Cần `dbtRunner`. Bật RBAC, quota, admission policy và Spark Operator; cần image Spark. |

Tắt feature là thay đổi vòng đời release: lần apply sau có thể gỡ release. Đây không phải thao tác ẩn menu. Kiểm tra diff, chính sách giữ PVC và backup trước khi tắt.

## Tham số vận hành chính

| Nhóm | Mẫu | Ý nghĩa |
|---|---|---|
| `scheme`, `hosts.*`, `gatewayIP` | HTTP, host theo môi trường | Issuer public, redirect, URL cho trình duyệt và hostAliases của pod. |
| `realm` | `data-platform` | Một realm Keycloak dùng chung cho cả nền tảng. |
| `clients.*` | Xem [Xác thực và SSO](identity.md) | Client ID cho từng ứng dụng. Client của Kapas phân biệt hoa thường. |
| `urls.*` | Rỗng | Dùng URL suy ra. Không đặt DNS nội bộ của Service vào URL dành cho trình duyệt. |
| `storageClass` | `longhorn` | Phải tồn tại trước khi cài. |
| `externalS3.*` | MinIO trong cluster | Endpoint, bucket và path của object storage cho query engine. Phải đồng bộ với dữ liệu hiện có. |
| `minio.size` | `10Gi` | Dung lượng nhỏ để kiểm bộ cài; tăng khi dùng dữ liệu thật. |
| `keycloakSeed.enabled` | `true` | Tắt khi cài mới sẽ làm mất bước seed realm mà query engine cần. |
| `keycloakSeed.groupsClaim` | `true` | Thêm mapper claim `groups` (đường dẫn đầy đủ); Ingestion dùng làm team. |
| `keycloakSeed.translations.enabled` | `true` | Import bản dịch vi/en vào realm; khoá có trong file sẽ ghi đè chỉnh tay mỗi lần Job chạy lại. |
| `keycloakSeed.compositeAdmin.skipClients` | rỗng | Mặc định gom mọi client role vào realm role `admin`; đây không phải thiết lập least privilege. |
| `dbtRunner.maxConcurrentRuns` | `10` | Giới hạn số run dbt đồng thời. |
| `hanasCatalog.maxConcurrentRuns` | `4` | Số run đồng thời của runner Hanas Catalog. |
| `hanasCatalog.dbtStudioClientId` | rỗng | Cần khi Hanas Catalog chạy nguồn dbt theo lịch. |
| `ingestion.workerThreads` | `2` | Số worker trong pod Ingestion. |
| `ontology.allowDestructiveMigrations` | `false` | Chỉ áp dụng cho migration được ứng dụng đánh dấu; không bảo đảm chặn mọi lệnh xoá. |
| Ontology `api.workers` | `4` | Ảnh hưởng số kết nối database và bộ nhớ. |
| Kapas web | 1 replica, PVC RWO | Có shared state; không tăng replica tuỳ ý. |
| Kapas mode, cookie secure, xác nhận TLS | `development`, `false`, `false` | Phải đổi đồng bộ khi chuyển sang HTTPS production. |

Các khoá của Job bootstrap và Job cấp PAT được giữ nguyên tên định danh trong cấu hình:

```yaml
dremioBootstrap:
  localAdmin:
    username: admin      # local admin, khác danh tính SSO admin
  patMaxDays: 36525      # trần tuổi thọ PAT; query engine nhận 1 đến 36525
dremioPat:
  secretName: superset-dremio-pat   # Secret do Job ghi, Superset đọc
```

Tắt Job cấp PAT khi Superset đang bật thì không còn cơ chế cấp PAT cho Superset.

Các thông số Ontology (giới hạn truy vấn, graph, embedding) và Kapas (token budget, sandbox, NetworkPolicy) cũng nằm trong cấu hình môi trường. Các giá trị mẫu chưa được tinh chỉnh theo tải thực tế.

## Tên khoá secret

Khối dưới liệt kê tên khoá trong `secrets.example.yaml`. Không lưu giá trị vào Git hay tài liệu.

```yaml
# Client credentials
clientSecrets: [dremio, superset, bootstrap, ontology, kapas]
# Keycloak
keycloak: [masterAdminPassword, appAdminPassword, db.password, db.postgresPassword]
# Query engine và S3
dremio: [authPassword, s3AccessKeyID, s3AccessKeySecret, licenseKeyB64]
# Ontology
ontology: [postgresPassword, embeddingApiKey, graphWorkerSharedSecret, dremioPat]
# Superset
superset: [secretKey, guestTokenJwtSecret, postgresPassword, password]
# Kapas
kapas: [postgresPassword, redisPassword, jwtSecret, authPassword, hanasPassword, kpServiceToken, braveApiKey, vnstockApiKey]
# dbt
dbtRunner: [appEncryptionKey, postgresPassword, postgresAdminPassword, redisPassword]
# Hanas Catalog
hanasCatalog: [databasePassword, appEncryptionKey, dremioServicePat, dbtStudioClientSecret]
# Ingestion
ingestion: [databasePassword, appEncryptionKey, datahubToken]
```

Các nhóm trên tương ứng: client credentials, Keycloak, query engine và S3, Ontology, Superset, Kapas, dbt, Hanas Catalog, Ingestion.

Một số khoá chỉ cần khi bật tính năng liên quan, ví dụ PAT của Hanas Catalog cho nguồn chạy theo lịch. Ngược lại, helmfile kiểm tra `clientSecrets` cho mọi client đã khai, nên đừng xoá cả nhóm khi chưa kiểm tra.

Các ràng buộc cần nhớ:

- Mật khẩu PostgreSQL và Redis của Kapas và dbt chỉ được dùng ký tự `A-Za-z0-9._~-`, vì chúng nằm trong connection URL.
- Secret của Superset không được chứa chuỗi mở template kép (hai dấu ngoặc nhọn liên tiếp).
- Mật khẩu PostgreSQL phía server và phía ứng dụng của Superset đều lấy từ `superset.password`; mật khẩu admin là khoá khác.
- Các khoá mã hoá phải giữ nguyên theo database đã tạo.

## Tiếp theo

- [Cài đặt bằng helmfile](install.md).
- [API gateway và tên miền](gateway.md).
- [Xác thực và SSO với Keycloak](identity.md).
