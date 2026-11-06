---
title: API gateway và tên miền
sidebar_label: API gateway
sidebar_position: 5
description: Cấu hình APISIX, tên miền, upstream, route và forwarded headers để truy cập Hanas Data Platform từ bên ngoài cluster.
---

APISIX là điểm vào từ bên ngoài cluster, và bộ cài không quản lý nó. Trang này liệt kê tên miền, upstream và route bạn cần tạo để người dùng truy cập Hanas Console và các ứng dụng đi kèm.

## Tên miền

Mỗi ứng dụng có giao diện riêng cần một tên miền phân giải được từ trình duyệt. Ví dụ:

| Ứng dụng | Tên miền ví dụ | Khi nào cần |
|---|---|---|
| Hanas Console | `console.hanas.example.com` | Luôn cần |
| Keycloak | `auth.hanas.example.com` | Luôn cần |
| Superset | `bi.hanas.example.com` | Khi bật Superset |
| Kapas | `kapas.hanas.example.com` | Khi bật Kapas |

Các tên miền này khai trong khối `hosts` của cấu hình môi trường. Trường `hosts` của route APISIX không kèm cổng; nếu gateway lắng nghe cổng khác 80/443, URL public và redirect URI của OIDC vẫn phải có cổng đó.

Pod của Superset và Kapas phải truy cập được tên miền public của Keycloak. Bộ cài thêm hostAliases theo `gatewayIP` cho việc này, nhưng DNS trên máy người dùng vẫn do bạn cấu hình.

## Upstream và route

| Host và path | Upstream (Service trong cluster) | Ghi chú |
|---|---|---|
| Console, `/*` | `console-ui.dataplatform.svc.cluster.local:80` | Giữ URI, đặt đúng forwarded scheme. |
| Keycloak, `/*` | `keycloak.keycloak-dp.svc.cluster.local:80` | Giữ URI. Keycloak chạy chế độ production sau proxy nên cần `X-Forwarded-*` đúng. |
| Superset, `/*` | `superset.superset-dp.svc.cluster.local:8088` | Khi bật Superset. |
| Kapas, `/*` | `kapas-web.kapas.svc.cluster.local:8088` | Khi bật Kapas. |

Console tự proxy các API nội bộ (ontology, dbt, Hanas Catalog, Ingestion, Kapas) qua nginx trong image, nên với phiên bản Console hiện tại bạn thường không cần route riêng cho các đường này. Nếu từng tạo route riêng cho bản Console cũ, hãy rà lại, vì route cụ thể có priority cao có thể ghi đè proxy của Console.

## Ví dụ tạo route

Đặt biến cho Admin API, cấp khoá bằng cơ chế quản lý secret của đơn vị:

```bash
export APISIX_ADMIN='http://<APISIX_ADMIN_HOST>:9180/apisix/admin'
# Cấp biến APISIX_KEY bằng cơ chế quản lý secret của đơn vị.
```

Tạo upstream và route cho Keycloak:

```bash
curl -sS -X PUT "$APISIX_ADMIN/upstreams/keycloak" \
  -H "X-API-KEY: $APISIX_KEY" -H 'Content-Type: application/json' \
  -d '{"name":"keycloak","type":"roundrobin","scheme":"http","nodes":{"keycloak.keycloak-dp.svc.cluster.local:80":1}}'

curl -sS -X PUT "$APISIX_ADMIN/routes/keycloak" \
  -H "X-API-KEY: $APISIX_KEY" -H 'Content-Type: application/json' \
  -d '{"name":"keycloak","hosts":["auth.hanas.example.com"],"uris":["/*"],"upstream_id":"keycloak","plugins":{"proxy-rewrite":{"headers":{"set":{"X-Forwarded-Proto":"http"}}}}}'
```

Dùng cùng mẫu cho Console, Superset và Kapas, thay host và upstream theo bảng trên. Khi dùng HTTPS, đặt `X-Forwarded-Proto` thành `https` và chấm dứt TLS ở gateway.

## Forwarded headers và HTTPS

Keycloak, Console và Superset dùng `X-Forwarded-*` để dựng URL public. Header sai làm redirect và issuer lệch với cấu hình. Đổi sang HTTPS cần đồng bộ cả TLS ở gateway, `scheme` trong cấu hình môi trường, cookie policy và các thiết lập production của từng ứng dụng.

:::caution Giới hạn hiện tại

Bộ cài chưa có cấu hình mẫu cho timeout, giới hạn kích thước body, WebSocket hoặc SSE trên gateway. Với các luồng dài như dbt hoặc chat Kapas, hãy kiểm tra các giới hạn này tại gateway của bạn.

:::

## Xử lý sự cố

- Mở Console trả `404` hoặc `502`: kiểm tra route và upstream tồn tại, Service đúng namespace.
- Đăng nhập lặp lại hoặc redirect sai host: kiểm tra `X-Forwarded-Proto`, host trong cấu hình môi trường và issuer của Keycloak.

Xem thêm [Xử lý sự cố](troubleshooting.md).

## Tiếp theo

- [Xác thực và SSO với Keycloak](identity.md).
- [Cài đặt bằng helmfile](install.md).
- [Kiểm tra sức khỏe và giám sát](health-checks.md).
