---
title: Cổng và endpoint
sidebar_label: Cổng và endpoint
sidebar_position: 2
description: Bảng cổng và Service của các thành phần Hanas Data Platform trong cụm Kubernetes, cùng đường dẫn API qua gateway.
---

Trang này liệt kê các Service, cổng và đường dẫn mà Hanas Data Platform sử dụng. Bạn dùng nó khi cấu hình firewall, gateway, NetworkPolicy hoặc khi cần biết một client nên kết nối tới đâu.

:::note Phạm vi

Bảng được suy ra từ cấu hình bộ cài ngày 05/11/2026. Tên Service và cổng thực tế cần được xác nhận sau cài đặt bằng `kubectl get svc,endpoints` trong từng namespace.

:::

## Service trong cụm

Mọi Service ứng dụng là ClusterIP. Service headless (`clusterIP: None`) phục vụ DNS ổn định và liên lạc nội bộ giữa các pod.

| Namespace | Service | Cổng | Vai trò |
|---|---|---|---|
| `dataplatform` | `console-ui` | 80 (container 8080) | Điểm vào Hanas Console, nginx reverse proxy |
| `dataplatform` | `console-user-api` | 8081 | API người dùng và quyền |
| `dataplatform` | `dremio-26` | 9047, 31010, 32010 | Query engine: REST/web, SQL client, Arrow Flight |
| `dataplatform` | `dremio-26-headless` | 9047, 31010, 32010, 45678, 45679, 44349, 50000 | DNS ổn định và liên lạc nội bộ giữa các role |
| `dataplatform` | `dremio-26-zookeeper` | 2181 (2888, 3888 nội bộ) | Điều phối query engine |
| `keycloak-dp` | `keycloak` | 80 (container 8080) | Realm, OIDC và Admin API |
| `keycloak-dp` | `keycloak-postgresql` | 5432 | Cơ sở dữ liệu Keycloak |
| `hanas-minio` | `hanas-minio` | 9000 | S3 API (MinIO Console tắt) |
| `superset-dp` | `superset` | 8088 | Superset UI và API |
| `superset-dp` | `superset-superset-postgresql` | 5432 | Metadata Superset |
| `superset-dp` | `superset-superset-redis-master` | 6379 | Cache và Celery |
| `ontology` | `ontology-ontology-platform-api` | 8200 | Ontology REST, readiness `/readyz` |
| `ontology` | `ontology-ontology-platform-graph-worker` | 8210 | Xử lý đồ thị, nội bộ |
| `ontology` | `ontology-ontology-platform-postgres` | 5432 | Cơ sở dữ liệu Ontology |
| `ontology` | `ontology-ontology-platform-redis` | 6379 | Cache |
| `kapas` | `kapas-web` | 8088 | Giao diện và API Kapas, callback SSO |
| `kapas` | `kapas-postgres`, `kapas-redis` | 5432, 6379 | Datastore riêng của Kapas |
| `dbt-studio` | `dbt-dbt-runner` | 8080 | dbt Studio API |
| `dbt-studio` | `dbt-postgresql`, `dbt-redis-master` | 5432, 6379 | Metadata và Redis của dbt Studio |
| `hanas-catalog` | `hanas-catalog-api`, `hanas-catalog-postgres` | 8091, 5432 | Chỉ có khi bật Hanas Catalog; runner không có Service HTTP |
| `ingestion` | `ingestion-service`, `ingestion-service-postgres` | 8090, 5432 | Chỉ có khi bật Ingestion |
| `hanas-compute` | Service theo từng Spark run | Theo từng run | Sinh động khi chạy Compute |

Các Service Hanas Catalog, Ingestion và Compute chỉ xuất hiện khi bạn bật tính năng tương ứng trong [Tham chiếu cấu hình](../operate/configuration.md).

## Cổng của query engine

| Cổng | Giao thức | Người dùng |
|---:|---|---|
| 9047 | HTTP: web và REST API | Người dùng, [REST API](../develop/query-engine-api.md) |
| 31010 | JDBC và ODBC | [SQL client](../develop/sql-clients.md) |
| 32010 | Arrow Flight / Flight SQL | [SQL client](../develop/sql-clients.md) |
| 45678 | Giao tiếp giữa các node | Chỉ nội bộ cụm, không phải API người dùng |
| 2181 | ZooKeeper | Chỉ nội bộ cụm |

Cổng 31010 và 32010 là hai endpoint riêng biệt; không dùng cổng JDBC cho Arrow Flight.

## Đường dẫn qua Hanas Console

Nginx trong Hanas Console chuyển tiếp các tiền tố sau tới dịch vụ phía sau. Gateway production có thể đặt đường dẫn khác; hãy đối chiếu với cấu hình của bạn trong [API gateway và tên miền](../operate/gateway.md).

| Tiền tố | Dịch vụ | Tài liệu |
|---|---|---|
| `/ontology-api` | Ontology | [Ontology API](../develop/ontology-api.md) |
| `/api/chat` | Kapas | [Kapas API và SSE](../develop/kapas-api.md) |
| `/catalog-api` | Hanas Catalog | [Hanas Catalog API](../develop/catalog-api.md) |
| `/dbt-runner` | dbt Studio | [dbt Studio](../transform/dbt-studio.md) |
| `/ingest-api` | Ingestion | [Nạp dữ liệu](../connect/ingestion.md) |

## Lưu ý mạng

- Chỉ công bố ra ngoài cụm những cổng thật sự cần: cổng web của gateway, và 31010 hoặc 32010 nếu client SQL chạy ngoài cụm.
- Datastore (PostgreSQL, Redis) và cổng liên lạc nội bộ của query engine nên giữ trong cụm.
- Chi tiết thứ tự phụ thuộc và ranh giới mạng nằm ở [Kiến trúc triển khai](../operate/deployment-architecture.md).

## Tiếp theo

- [Thành phần và phiên bản](components-and-versions.md).
- [API gateway và tên miền](../operate/gateway.md).
- [Kiểm tra sức khỏe và giám sát](../operate/health-checks.md).
