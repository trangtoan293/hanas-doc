---
title: Thành phần và phiên bản
sidebar_label: Thành phần và phiên bản
sidebar_position: 3
description: Danh sách thành phần của Hanas Data Platform, image và tag được ghim trong bộ cài, cùng cách ghi nhận phiên bản khi vận hành.
---

Trang này liệt kê các thành phần của Hanas Data Platform và image mà bộ cài đang ghim. Bạn dùng nó để biết môi trường đang chạy phiên bản nào, và để đối chiếu khi nâng cấp hoặc liên hệ [hỗ trợ](support.md).

:::note Phạm vi

Số liệu lấy từ file khai báo image của bộ cài ngày 05/11/2026. Image thực tế đang chạy có thể khác nếu đơn vị bạn đã đổi tag; hãy xem `helmfile diff` hoặc `kubectl get pod -o wide` để biết trạng thái hiện tại.

:::

## Thành phần và vai trò

| Thành phần | Vai trò | Release Helm |
|---|---|---|
| Hanas Console | Giao diện web và reverse proxy tới các API | `console` |
| User API | API người dùng, group, role và đồng bộ với query engine | `console` |
| Query engine | SQL, Reflection, catalog, Arrow Flight, JDBC/ODBC | `dremio` |
| Keycloak | Danh tính, SSO, OIDC | `keycloak` |
| Ontology (API và graph worker) | Lớp ontology | `ontology` |
| Kapas | Trợ lý AI | `kapas` |
| dbt Studio runner | dbt Studio và Compute | `dbtRunner` |
| Hanas Catalog | Catalog metadata, lineage, glossary | `hanasCatalog` |
| Ingestion service | Nạp dữ liệu vào Iceberg | `ingestion` |
| Apache Superset | Dashboard và BI | `superset` |
| Job hook khởi tạo | Seed, bootstrap và tạo PAT ban đầu | Job trong bộ cài |

Ngoài ra bộ cài triển khai các thành phần hạ tầng: MinIO (S3), PostgreSQL và Redis riêng cho từng ứng dụng, ZooKeeper cho query engine, APISIX làm gateway, và Spark operator cho Compute. Phiên bản của các thành phần này được khai báo trong values của từng chart.

## Image và tag được ghim

Tag có hậu tố `@sha256:...` được ghim theo digest, vì tag trong registry có thể bị ghi đè. Bảng dưới đây chỉ ghi phần tag; digest nằm trong file khai báo image.

| Khoá image | Repository | Tag |
|---|---|---|
| `consoleUi` | `katalysthub/dremio-ee-ui` | `20261105-e706ad90` (digest) |
| `consoleUserApi` | `silver13072002/dremio-user-api` | `08_10` |
| `dremio` | `nghnhhquang/dremio-kt` | `26.1.6` |
| `zookeeper` | `katalyst147/bitnami_zookeeper` | `3.9.5-UBI9-r1` |
| `dremioInitBase` | `katalyst147/base` | `UBI9.3-r1` |
| `keycloak` | `katalyst147/keycloak-dataplatform` | `26.3.3-2.1` |
| `dpHooks` | `katalyst147/dp-hooks` | `1.3` |
| `ontologyApi` | `katalysthub/ontology-api` | `20261029-1bf7dd85` (digest) |
| `ontologyGraphWorker` | `katalysthub/ontology-graph-worker` | `20261029-1bf7dd85` (digest) |
| `superset` | `tranphat2911/superset-kt` | `6.1.0-authlib` |
| `kapas` | `katalysthub/qwenpaw-kapas` | `20261029-0a45f100` (digest) |
| `dbtRunner` | `katalysthub/dbt-studio-runner` | `20261105-e706ad90` (digest) |
| `computeSpark` | `katalysthub/spark-compute` | `20261105-e706ad90` (digest) |
| `hanasCatalog` | `katalysthub/hanas-catalog` | `20261102-4ee4410f` (digest) |
| `ingestionService` | `katalysthub/ingestion-service` | `20261102-4ee4410f` (digest) |

Quy ước tag của image do đội phát triển build là `<YYYYMMDD>-<mã commit 8 ký tự>`. Ngày là ngày build, mã commit trỏ về đúng revision nguồn.

## Phiên bản thành phần mã nguồn mở

| Thành phần | Phiên bản trong bộ cài |
|---|---|
| Query engine | 26.1.6 |
| Keycloak | 26.3.3 |
| Apache Superset | 6.1.0 |
| Apache Spark (image Compute) | 4.1.3 |
| ZooKeeper | 3.9.5 |
| Ingestion (engine nạp dữ liệu) | OLake v1.1.0 |

## Ghi nhận phiên bản khi vận hành

Trước và sau mỗi lần nâng cấp, bạn nên lưu lại:

1. Nội dung file khai báo image và tag hoặc digest của từng release.
2. Kết quả `helmfile diff` đã được phê duyệt.
3. Feature flags đang bật, vì chúng quyết định release nào tồn tại.

Quy trình thay tag, xử lý migration và rollback nằm ở [Nâng cấp và rollback](../operate/upgrade.md). Khi gửi yêu cầu hỗ trợ, hãy đính kèm danh sách tag hoặc digest này.

## Tiếp theo

- [Nâng cấp và rollback](../operate/upgrade.md).
- [Cổng và endpoint](ports-and-endpoints.md).
- [Hỗ trợ và bảo trì](support.md).
