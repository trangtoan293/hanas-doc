---
title: Cài đặt bằng helmfile
sidebar_label: Cài đặt
sidebar_position: 3
description: Các bước cài Hanas Data Platform trên Kubernetes bằng helmfile, từ chuẩn bị môi trường, secret, feature flag đến route gateway và kiểm tra sau cài.
---

Trang này hướng dẫn cài Hanas Data Platform lần đầu bằng bộ cài hợp nhất. Bạn cần quyền quản trị cluster và đã đọc [Kiến trúc triển khai](deployment-architecture.md) cùng [Yêu cầu hệ thống và sizing](requirements.md).

:::note Phạm vi

Các lệnh dưới đây là runbook để bạn thực hiện trên môi trường của mình. Host, IP và namespace trong ví dụ chỉ mang tính minh hoạ; hãy thay bằng giá trị của đơn vị bạn.

:::

## Điều kiện cần

- Kubernetes, Helm, helmfile và plugin diff đáp ứng [yêu cầu hệ thống](requirements.md).
- StorageClass cấp được PVC động (cấu hình mẫu dùng Longhorn).
- APISIX đã chạy, truy cập được Service trong cluster. Bộ cài không tự cài APISIX hoặc Longhorn.
- Tên miền (hoặc bản ghi hosts) cho Hanas Console, Keycloak và các ứng dụng bật theo feature, phân giải được từ trình duyệt.
- Credential pull image nếu registry yêu cầu.

## Các bước

### Bước 1. Kiểm tra môi trường

Làm việc từ thư mục gốc của bộ cài. Không áp chồng các đoạn cấu hình ghép tay từ bộ cũ lên bộ hợp nhất.

```bash
kubectl config current-context
kubectl version
helm version
helmfile --version
kubectl get nodes
kubectl get storageclass
```

Xác nhận đúng context và StorageClass dự định dùng đã tồn tại.

### Bước 2. Điền file cấu hình môi trường

File cấu hình môi trường nằm ở `environments/local.yaml`, nhưng environment của helmfile tên là `default`. Vì vậy bạn chạy `helmfile` không kèm `-e`.

Điền nhất quán các nhóm sau: `namespaces`, `releases`, `scheme`, `hosts`, `gatewayIP`, `realm`, `clients`, `storageClass`, `externalS3`. Ví dụ:

```yaml
scheme: http
hosts:
  console: console.hanas.example.com
  keycloak: auth.hanas.example.com
  superset: bi.hanas.example.com
  kapas: kapas.hanas.example.com
gatewayIP: "<GATEWAY_IP>"
realm: data-platform
storageClass: longhorn
```

Để trống các khoá `urls.*` nếu muốn bộ cài tự suy ra URL từ `hosts`; chỉ ghi đè khi endpoint thực tế khác. Xem thêm [Tham chiếu cấu hình](configuration.md).

:::caution Giới hạn hiện tại

Chuyển `scheme` sang `https` không chỉ là đổi một giá trị. Bạn còn cần TLS và forwarded headers ở gateway, chính sách cookie, URL nội bộ và các kiểm tra production của ứng dụng. Cấu hình mẫu chạy HTTP.

:::

### Bước 3. Chuẩn bị secret

Chỉ copy file mẫu khi cài mới. Không ghi đè file secret của môi trường đang vận hành.

```bash
cp environments/secrets.example.yaml environments/secrets.yaml
```

Điền giá trị bằng quy trình quản lý secret của đơn vị. File `secrets.yaml` bị loại khỏi Git, nhưng việc này không thay thế secret manager, backup hay phân quyền file. Danh sách tên khoá nằm ở [Tham chiếu cấu hình](configuration.md).

Lưu các khoá mã hoá (`appEncryptionKey` của Hanas Catalog, Ingestion, dbt) ngay từ đầu và giữ nguyên qua mọi lần deploy. Mất khoá thì dữ liệu đã mã hoá không giải mã được; xem [Sao lưu và khôi phục](backup-recovery.md).

### Bước 4. Chọn feature flag và image

Bật hoặc tắt thành phần tuỳ chọn trong khối `features` của file cấu hình:

```yaml
features:
  superset: true
  kapas: true
  dbtRunner: true
  minio: true
  hanasCatalog: false
  ingestion: false
  compute: false
```

Trước khi bật một feature, điền đủ secret và điều kiện của nó. `compute` bắt buộc `dbtRunner` bật, đồng thời cần image Spark và quyền tạo tài nguyên cấp cluster. Danh sách image nằm trong `environments/images.yaml`; xem [Nâng cấp và rollback](upgrade.md).

### Bước 5. Xem inventory và diff

```bash
helmfile list
helmfile diff
```

Helmfile nạp cấu hình theo thứ tự `images.yaml`, `local.yaml`, `secrets.yaml`. Output diff có thể chứa dữ liệu nhạy cảm, nên chỉ lưu ở kênh vận hành phù hợp.

### Bước 6. Apply và theo dõi bootstrap

```bash
helmfile apply
```

Helmfile tự sắp xếp theo thứ tự phụ thuộc: Keycloak, Job seed realm, query engine, Job bootstrap danh tính, rồi các ứng dụng còn lại. Theo dõi trạng thái mà không in Secret:

```bash
kubectl -n keycloak-dp get pods,jobs
kubectl -n dataplatform get pods,jobs
kubectl -n superset-dp get pods,jobs
kubectl -n ontology get pods,jobs
kubectl -n dbt-studio get pods
kubectl -n kapas get pods
```

Hai điểm cần biết khi quan sát:

- Query engine bật OAuth ngay từ lần khởi động đầu. Job bootstrap dùng tài khoản SSO đã seed để tạo danh tính đầu tiên, sau đó tạo một local admin riêng và cấu hình Personal Access Token (PAT) cho Superset. Mặc định tên SSO admin và local admin khác nhau; không dùng cùng tên cho hai loại danh tính.
- Để chỉ áp dụng một release, dùng bộ chọn theo tên. Chỉ làm vậy khi các release phụ thuộc đã sẵn sàng:

```bash
helmfile -l name=ontology diff
helmfile -l name=ontology apply
```

Khi cài lần đầu, hãy dùng `helmfile apply` đầy đủ.

### Bước 7. Tạo upstream và route trên APISIX

APISIX nằm ngoài helmfile, vì vậy apply thành công chưa tạo đường truy cập public. Sau khi các Service tồn tại, tạo upstream và route qua Admin API của gateway. Chi tiết route, upstream và rewrite nằm ở [API gateway và tên miền](gateway.md). Ví dụ cho Hanas Console:

```bash
export APISIX_ADMIN='http://<APISIX_ADMIN_HOST>:9180/apisix/admin'
# Cấp biến APISIX_KEY bằng cơ chế quản lý secret của đơn vị.

curl -sS -X PUT "$APISIX_ADMIN/upstreams/console-ui" \
  -H "X-API-KEY: $APISIX_KEY" -H 'Content-Type: application/json' \
  -d '{"name":"console-ui","type":"roundrobin","scheme":"http","nodes":{"console-ui.dataplatform.svc.cluster.local:80":1}}'

curl -sS -X PUT "$APISIX_ADMIN/routes/console-ui" \
  -H "X-API-KEY: $APISIX_KEY" -H 'Content-Type: application/json' \
  -d '{"name":"console-ui","hosts":["console.hanas.example.com"],"uris":["/*"],"upstream_id":"console-ui","plugins":{"proxy-rewrite":{"headers":{"set":{"X-Forwarded-Proto":"http"}}}}}'
```

Lặp lại cho Keycloak, Superset và Kapas.

### Bước 8. Kiểm tra Keycloak client và role của dbt

Với bộ hợp nhất, Job seed tạo sẵn client `dbt` làm nơi chứa role (role holder) cùng các role `dbt-viewer`, `dbt-editor`, `dbt-admin`, `compute-user`, `compute-admin`, rồi gom vào composite realm role `admin`. Bạn không cần import file JSON client cho cài mới.

1. Đăng nhập Keycloak Admin Console, mở realm của nền tảng.
2. Mở **Clients** và xác nhận client `dbt` tồn tại, không bật luồng đăng nhập.
3. Gán role cho người dùng thông thường theo nhu cầu. Job seed chỉ cấp quyền cho app admin, không tự cấp cho mọi người dùng.

Nếu Hanas Catalog cần gọi dbt theo lịch, tạo một client riêng có service account và role `dbt-viewer`, rồi điền client ID và secret tương ứng vào cấu hình Hanas Catalog. Không bật service account trên client role holder chỉ để thuận tiện. Xem [Xác thực và SSO](identity.md).

### Bước 9. Kiểm tra sau cài

```bash
python3 tests/smoke.py
# Khi chưa tạo xong route public:
SKIP_PUBLIC=1 python3 tests/smoke.py
```

Chạy lệnh từ thư mục gốc của bộ cài, vì script đọc cấu hình bằng đường dẫn tương đối. Sau đó thực hiện các kiểm tra chức năng trong [Kiểm tra sức khỏe và giám sát](health-checks.md). Smoke test đạt chưa chứng minh mọi luồng SSO, truy vấn hay khôi phục hoạt động.

## Lưu ý khi tắt feature

Helmfile gỡ release khi feature bị tắt ở lần apply sau. Hãy xem `helmfile diff` và kiểm tra chính sách giữ PVC, reclaim policy của StorageClass cùng backup trước khi tắt.

## Xử lý sự cố

Các lỗi thường gặp khi cài (đăng nhập treo, pod không phân giải được Keycloak public, Superset không kết nối được database) có trong [Xử lý sự cố](troubleshooting.md).

## Tiếp theo

- [Tham chiếu cấu hình](configuration.md).
- [API gateway và tên miền](gateway.md).
- [Xác thực và SSO với Keycloak](identity.md).
- [Kiểm tra sức khỏe và giám sát](health-checks.md).
