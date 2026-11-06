---
title: Xử lý sự cố
sidebar_label: Xử lý sự cố
sidebar_position: 12
description: Các sự cố đã biết khi cài đặt và vận hành Hanas Data Platform, trình bày theo triệu chứng, nguyên nhân và cách xử lý.
---

Trang này tổng hợp sự cố đã được ghi nhận trong quá trình xây dựng và triển khai bộ cài. Mỗi mục có triệu chứng, nguyên nhân và hướng xử lý. Một số mục đã được sửa trong cấu hình mẫu hiện tại; hãy kiểm tra cấu hình thực tế của bạn trước khi kết luận.

## Cách chẩn đoán chung

```bash
kubectl -n <NAMESPACE> get pods,jobs
kubectl -n <NAMESPACE> describe pod <POD>
kubectl -n <NAMESPACE> logs <POD> --previous
helm history <RELEASE> -n <NAMESPACE>
```

Xem Events trước khi kết luận image hỏng. Không đưa nội dung Secret vào báo cáo lỗi.

## Query engine và Console

| Triệu chứng | Nguyên nhân | Cách xử lý |
|---|---|---|
| ZooKeeper bị `OOMKilled`, query engine restart theo | Heap cũ lớn hơn giới hạn bộ nhớ của container. | Cấu hình hiện tại đã giảm heap và nâng giới hạn RAM. Kiểm tra values thực tế và áp lực bộ nhớ trên node. |
| Query engine bị restart trước khi khởi động xong | Liveness probe có độ trễ ban đầu quá ngắn. | Cấu hình hiện tại dùng độ trễ `180s` và timeout release `1800s`. Kiểm tra Events của probe. |
| Lỗi `Failed to load private key` sau restart trên PVC cũ | Đổi quyền đệ quy do fsGroup làm thư mục bảo mật sai quyền sở hữu. | Master coordinator đã đặt `fsGroupChangePolicy: OnRootMismatch`. Với PVC đã hỏng quyền, snapshot rồi sửa quyền cùng đội phụ trách query engine. |
| Đăng nhập SSO báo `400 Invalid state` ngẫu nhiên | Request OAuth đi qua coordinator khác node đã phát state. | Console và Job bootstrap phải dùng DNS headless ghim vào master coordinator. Không đổi thành Service round-robin. |
| Console trả `502` sau khi query engine restart | nginx giữ IP của pod cũ. | Console dùng dynamic DNS và resolver; kiểm tra FQDN, template đúng image và chu kỳ resolve. |
| Chart Console chặn nâng cấp tag | `templateForTag` khác với tag image. | Đồng bộ template nginx với image rồi cập nhật `templateForTag`. Không bỏ bước kiểm tra. |
| Các đường API Hanas Catalog hoặc Ingestion trả `502` | Feature tắt nên backend chưa được triển khai, nhưng nginx của Console vẫn chạy. | Bật đúng feature và prerequisite nếu bạn cần dùng. Đây không phải lỗi của toàn bộ Console. |
| Các đường API Ontology hoặc dbt trả `404` ở Console bản cũ | Console bản cũ không tự proxy các đường này. | Tạo route APISIX riêng cho bản cũ. Với bản hiện tại, kiểm tra không có route cũ ghi đè. Xem [API gateway và tên miền](gateway.md). |

## Đăng nhập và SSO

| Triệu chứng | Nguyên nhân | Cách xử lý |
|---|---|---|
| Đăng nhập treo hoặc trình duyệt cố truy cập địa chỉ nội bộ của Service | Nhầm URL public và URL nội bộ, sai cổng hoặc redirect. | Đối chiếu `hosts`, `urls.*`, issuer của realm và forwarded headers. Xem [Xác thực và SSO](identity.md). |
| Pod không phân giải được Keycloak public | DNS, hostAliases hoặc `gatewayIP` sai. | Kiểm tra `gatewayIP`, hostname khai trong hostAliases không kèm cổng, và kết nối từ pod đến gateway. DNS của máy người dùng là việc riêng. |
| Kapas báo `sign-in link expired`, log có `cookie_present=False` | Cookie secure được đặt trên kết nối HTTP. | Môi trường HTTP phải giữ mode `development`, cookie secure `false`. Với production cần TLS và đổi đồng bộ cả bộ thiết lập. |
| SSO của Kapas không đăng nhập | Sai chữ hoa thường của client ID. | Giữ client ID đúng như đã seed (phân biệt hoa thường) và secret tương ứng. |
| Ontology tool hoặc chat trả `401` | Thiếu audience, thiếu tenant fallback hoặc client chưa được phép token exchange. | Kiểm tra audience, ánh xạ tenant, và quyền exchange của client `ontology` sang hai audience cần dùng. |
| Người dùng Ontology bị `403` dù có role `admin` | Ứng dụng dựa vào role `ontology-*`. | Gán role `ontology-*` tương ứng. |
| Superset đổi token sang query engine bị `401` | Actor PAT lấy từ người dùng SSO, hoặc PAT không hợp lệ. | Dùng PAT của local admin do Job bootstrap tạo; kiểm tra Secret đích. Không in PAT ra terminal. |
| Lỗi sau khi chuyển `scheme` sang `https` | Các kiểm tra production đòi HTTPS và exchange, trong khi URL nội bộ vẫn HTTP. | Rà toàn bộ URL nội bộ, chế độ xác thực và thiết lập production, không chỉ đổi `scheme`. |

## Kapas

| Triệu chứng | Nguyên nhân | Cách xử lý |
|---|---|---|
| Không khởi động, đường dẫn runtime không ghi được | Quyền sở hữu PVC với UID 10001. | Bật volumePermissions trong values; kiểm tra mount và owner. |
| Lỗi DNS database hoặc Redis, hoặc lỗi nội suy Alembic | Mật khẩu có ký tự phá connection URL. | Dùng mật khẩu chỉ gồm `A-Za-z0-9._~-`, đồng bộ phía server và ứng dụng. |
| `502` khi bật NetworkPolicy | Policy mặc định chọn namespace ingress khác với gateway thực tế. | Khai đúng namespace và nhãn của gateway. Không tắt toàn bộ policy để thay cho thiết kế truy cập. |

## Superset

| Triệu chứng | Nguyên nhân | Cách xử lý |
|---|---|---|
| `SQLAlchemyError`, không kết nối được database | Mật khẩu PostgreSQL phía server khác phía ứng dụng. | Cả hai lấy từ `superset.password`; kiểm tra Secret cũ và database đã khởi tạo. |
| Init bị deadlock, pod chờ Secret | Migration và web cùng giữ lock, hoặc chờ Ready làm hook không chạy. | Giữ cấu hình không chờ Ready; kiểm tra Secret `superset-migrated` và log init. Trạng thái `CreateContainerConfigError` khi chờ gate ban đầu chưa chắc là sai mật khẩu. |
| Gate không xuất hiện đúng tên | Đổi tên release hoặc ghi đè fullname. | Tên release phải chứa `superset`, không dùng `nameOverride` và `fullnameOverride`. |
| PostgreSQL crash-loop trên PVC cũ | Binary PostgreSQL 14 gặp dữ liệu PostgreSQL 18. | Dừng nâng cấp; chuyển đổi hoặc khôi phục dữ liệu theo major version. Helm rollback không hạ cấp dữ liệu. |
| Alerts và reports không chạy theo lịch | Thiếu Celery beat. | Cấu hình hiện bật beat; kiểm tra beat Ready và log scheduler. |

## Ontology, dbt và các thành phần khác

| Triệu chứng | Nguyên nhân | Cách xử lý |
|---|---|---|
| Ontology nâng cấp báo `MigrationIntegrityError` | Lịch sử migration cũ không khớp với schema đã gộp. | Backup, rồi thống nhất cách xử lý ledger và dữ liệu với đội ứng dụng. Không tự sửa checksum. |
| Ontology bị restart khi database lỗi | Cùng một endpoint readiness được dùng cho cả liveness và readiness. | Nhận diện hành vi này khi chẩn đoán; khôi phục database trước. |
| dbt mới không khởi động, thiếu bảng hoặc cột | Script khởi tạo chỉ chạy với database mới; database cũ chưa nâng schema. | Bước `db-upgrade` xử lý khi dùng PostgreSQL đi kèm. Với database ngoài, chạy nâng schema đầy đủ. Xem [Nâng cấp và rollback](upgrade.md). |
| dbt Git SSH lỗi ghi file | Thư mục known_hosts không ghi được. | Đặt `GIT_SSH_DIR=/data/storage/git-ssh`, `fsGroup` 10001, kiểm tra PVC. |
| MinIO Console `ImagePullBackOff` | Image Console cũ của MinIO không còn trong registry. | Cấu hình tắt MinIO Console; API object trên cổng 9000 vẫn hoạt động. |
| Bật Compute báo tài nguyên đã tồn tại không thuộc Helm | Namespace được tạo tay trước đó. | Xác minh quyền sở hữu và adopt có kiểm soát. Không xoá namespace đang có dữ liệu. |

## Khi cần hỗ trợ

Thu thập phiên bản image, kết quả `helmfile diff`, Events và log liên quan (đã loại Secret), rồi liên hệ kênh hỗ trợ của bạn. Xem [Kiểm tra sức khỏe và giám sát](health-checks.md) để biết các tín hiệu nên có sẵn.

## Tiếp theo

- [Kiểm tra sức khỏe và giám sát](health-checks.md).
- [Xác thực và SSO với Keycloak](identity.md).
- [Nâng cấp và rollback](upgrade.md).
