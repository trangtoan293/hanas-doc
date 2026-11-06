---
title: Xác thực và SSO với Keycloak
sidebar_label: Xác thực và SSO
sidebar_position: 6
description: Realm, client, role, mapper, SSO giữa các thành phần, token exchange và cách phân biệt URL public với URL nội bộ trong Keycloak.
---

import Diagram from '@site/src/components/Diagram';

Hanas Data Platform dùng Keycloak làm nơi cấp danh tính chung. Trang này mô tả realm, client, role và cách các thành phần dùng token, để bạn cấu hình và chẩn đoán đăng nhập.

## Realm và tài khoản quản trị

Cả nền tảng dùng một realm ứng dụng, tên mẫu `data-platform`. Có hai loại quản trị khác nhau:

- Quản trị Keycloak: đăng nhập realm `master`, dùng cho Admin API và Admin Console.
- Quản trị ứng dụng: một người dùng trong realm ứng dụng, được Job seed gán role `admin`, `ontology-admin`, `ingest-admin` và quyền quản trị realm.

Keycloak chạy chế độ production, nhận `X-Forwarded-*` từ gateway và dùng hostname public. Job seed tạo realm trước khi query engine khởi động.

## Client

| Client ID | Loại | Vai trò |
|---|---|---|
| `odc` | Public SPA, PKCE | Đăng nhập Hanas Console; có mapper `groups`. |
| `hd` | Confidential | OAuth của query engine; callback về trang đăng nhập SSO của Console. |
| `superset` | Confidential | Đăng nhập Superset. |
| `bootstrap` | Direct access grant | Phục vụ Job bootstrap lần cài đầu. |
| `ontology-web` | Public SPA | Audience cho token mà tool gọi ngược về Ontology. |
| `ontology` | Confidential | Token exchange cho tích hợp Ontology. |
| `dbt` | Role holder, tắt đăng nhập | Chứa client role của dbt và Compute. |
| `data-governance` | Role holder, tắt đăng nhập | Chứa role của Hanas Catalog. |

Client của Kapas có ID phân biệt hoa thường và phải khớp chính xác với giá trị đã seed:

```yaml
clients:
  kapas: KaPaS
```

Đổi hoa thường làm Keycloak coi đó là client khác, và Kapas không đăng nhập được.

:::note Điều kiện

Một số client chỉ tồn tại khi feature tương ứng bật hoặc khi khai tên client trong cấu hình môi trường. Client role holder không được tạo nếu khoá tương ứng để trống.

:::

## Role và ánh xạ vào ứng dụng

Realm role: `admin`, `user`, `ontology-viewer`, `ontology-editor`, `ontology-admin`, `ingest-admin`, `ingest-viewer`. Job seed gom client role vào composite realm role `admin`.

| Thành phần | Role cần gán |
|---|---|
| Ontology | Realm role `ontology-viewer`, `ontology-editor`, `ontology-admin`. Chỉ có role `admin` chưa đảm bảo quyền ontology. |
| dbt | Client role `dbt-viewer`, `dbt-editor`, `dbt-admin` trên client `dbt`. |
| Compute | `compute-user`, `compute-admin` trên client `dbt`; cần thêm `dbt-editor` trở lên để chạy. |
| Hanas Catalog | `data-governance-viewer`, `data-governance-editor`, `data-governance-admin`. Người dùng không có role được xem như viewer. |
| Ingestion | `ingest-admin`, `ingest-viewer`; team lấy từ claim `groups`. |
| Superset | `superset_admin` ánh xạ sang vai trò Admin, `superset_user` sang Gamma; role được đồng bộ mỗi lần đăng nhập. |

Mapper `groups` thêm claim `groups` với đường dẫn đầy đủ (ví dụ `/crm`) vào access token, ID token và userinfo. Job seed không tự cấp quyền cho người dùng đã có.

:::caution Giới hạn hiện tại

Cấu hình `skipClients` mặc định rỗng, nên mọi client role được gom vào `admin`. Đây là thiết lập thuận tiện cho cài đặt ban đầu, chưa phải thiết kế least privilege. Hãy rà lại trước khi dùng cho môi trường nhiều người dùng.

:::

## SSO và token exchange

<Diagram name="03-dang-nhap-phan-quyen" alt="Một lần đăng nhập, quyền đi theo người dùng" />

1. Trình duyệt đăng nhập Keycloak qua client `odc`. Các ứng dụng dùng chung realm nhưng mỗi backend vẫn tự xác minh token và quyền.
2. Query engine tự đổi mã OIDC ở phía server và cấp session riêng. Hanas Console còn lấy token Keycloak để gọi các dịch vụ khác.
3. Ontology chấp nhận token có audience được cấu hình; khi token thiếu claim `tenant`, nó suy ra từ client phát hành token.
4. Khi Ontology gọi chat của Kapas hoặc Kapas gọi ngược tool, token được đổi (RFC 8693) sang audience tương ứng. Keycloak phải cho phép các lần đổi này; có client secret chưa đồng nghĩa có quyền exchange.
5. Superset đăng nhập qua OAuth, sau đó đổi token tới query engine, dùng PAT của local admin làm actor và người dùng hiện tại làm subject. Cấu hình mô tả luồng này dừng lại khi lỗi, không quay về quyền của tài khoản proxy.
6. Hanas Catalog kiểm quyền theo phiên query engine của người xem. Nguồn chạy theo lịch dùng service PAT hoặc service account riêng, khác danh tính người xem.

Chưa có bằng chứng kiểm chứng end-to-end về quyền token exchange và claims trong môi trường thực tế; hãy kiểm tra theo [Kiểm tra sức khỏe và giám sát](health-checks.md).

Về phía giao diện, token cho tích hợp bên ngoài được quản lý tại **Settings** > **Integrations** > **External Tokens**. Token cá nhân của bạn nằm ở menu tài khoản, mục **Access Tokens**.

## URL public và URL nội bộ

Nhầm hai loại URL là nguyên nhân phổ biến của lỗi đăng nhập.

| Luồng | URL dùng |
|---|---|
| Đăng nhập trình duyệt, iframe, redirect URI, issuer trong token | URL public với scheme và cổng đúng. |
| Query engine gọi Keycloak | URL nội bộ; URL xác thực mở trên trình duyệt là URL public. |
| Ontology, dbt, Ingestion xác minh JWT | So `iss` với issuer public, lấy JWKS qua URL nội bộ. |
| Kapas, Superset | Dùng issuer public; pod phải phân giải được tên miền public qua gateway. |
| Hanas Catalog | Kiểm chữ ký và hạn token qua JWKS nội bộ, không kiểm `iss`, theo mô tả trong chart. |
| Console đến query engine | Ghim vào master coordinator qua headless DNS để giữ node đã phát state OAuth. |

Console cấp URL public cho SPA và URL nội bộ cho User API. Nếu đặt DNS nội bộ của Service vào URL public, trình duyệt không phân giải được và đăng nhập không hoàn tất.

## Xử lý sự cố

Xem các lỗi `Invalid state`, `401` ở Ontology, và đăng nhập Kapas trong [Xử lý sự cố](troubleshooting.md).

## Tiếp theo

- [Quản lý người dùng, group và role](user-management.md).
- [API gateway và tên miền](gateway.md).
- [Tham chiếu cấu hình](configuration.md).
