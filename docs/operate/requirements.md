---
title: Yêu cầu hệ thống và sizing
sidebar_label: Yêu cầu hệ thống
sidebar_position: 2
description: Điều kiện Kubernetes, công cụ, storage và tài nguyên tham chiếu để định cỡ triển khai Hanas Data Platform.
---

Hanas Data Platform cần hạ tầng Kubernetes, storage bền vững và đường truy cập ứng dụng được chuẩn bị trước khi cài đặt. Trang này cung cấp cấu hình tài nguyên tham chiếu và hướng dẫn lập kế hoạch theo tải sử dụng.

## Điều kiện hạ tầng

| Hạng mục | Yêu cầu |
|---|---|
| Kubernetes | Từ 1.30 khi dùng Kapas trong bộ cài hiện tại; admission policies của Compute cũng cần API tương ứng. |
| Helm và Helmfile | README công bố Helm từ 3.14, Helmfile từ 1.0; bộ cài ghi nhận kiểm với Helmfile 1.8.2. |
| Công cụ | `kubectl`, kubeconfig, `curl`; Python 3 và PyYAML để chạy smoke test. |
| Diff | Helm phải có plugin hỗ trợ lệnh diff dùng bởi Helmfile. |
| Storage | StorageClass cấp PVC động; cấu hình mẫu sử dụng Longhorn. |
| Gateway | APISIX hoạt động, phân giải được Service DNS và truy cập được các upstream. |
| DNS và TLS | Tên miền ứng dụng truy cập được từ browser và các pod cần gọi public issuer. |
| Image | Node pull được image đã ghim, có credential registry nếu môi trường yêu cầu. |
| Quyền triển khai | Tạo namespace, release, PVC, Job và RBAC; Compute còn cần quyền đối với tài nguyên cấp cluster. |

Bộ cài không tự triển khai Longhorn hoặc APISIX. Bạn cần kiểm tra kiến trúc CPU của image trước khi chọn node; không mặc định image hỗ trợ mọi kiến trúc.

## Tài nguyên trong cấu hình mẫu

Bảng dưới kết hợp chart defaults với values của bộ cài, cho một instance mỗi hàng trừ khi có ghi chú. CPU được tính theo core hoặc millicore; RAM và PVC sử dụng đơn vị Kubernetes.

Dấu `—` trong cột CPU limit nghĩa bộ cài không khai báo limit CPU tường minh. LimitRange hoặc ResourceQuota của cluster vẫn có thể bổ sung giới hạn thực tế.

| Thành phần | CPU request / limit | RAM request / limit | PVC logic |
|---|---|---|---|
| Query engine master coordinator | `1 / 3` | `3Gi / 6Gi` | `8Gi` |
| Query engine coordinator | `1 / 3` | `3Gi / 6Gi` | `8Gi` |
| Query engine executor mặc định | `1 / 3` | `3Gi / 6Gi` | `8Gi` |
| ZooKeeper | `250m / 1` | `512Mi / 768Mi` | `4Gi` |
| Keycloak | `100m / —` | `512Mi / 1Gi` | Không |
| PostgreSQL Keycloak | `50m / —` | `256Mi / 512Mi` | `4Gi` |
| MinIO standalone | `250m / 375m` | `256Mi / 384Mi` | `10Gi` |
| Console UI | `100m / —` | `128Mi / 256Mi` | Không |
| Console User API | `250m / —` | `512Mi / 1Gi` | Không |
| Ontology API, 4 worker | `500m / —` | `512Mi / 2Gi` | Không |
| Ontology graph-worker | `250m / —` | `512Mi / 1Gi` | Không |
| PostgreSQL Ontology | `250m / —` | `512Mi / 2Gi` | `4Gi` |
| Redis Ontology | `50m / —` | `128Mi / 640Mi` | Không |
| Superset web | `250m / —` | `1Gi / 2Gi` | Không |
| Superset worker | `250m / —` | `1Gi / 2Gi` | Không |
| Superset Celery beat | `50m / —` | `256Mi / 512Mi` | Không |
| PostgreSQL Superset | `100m / —` | `256Mi / 512Mi` | `4Gi` |
| Redis Superset | `50m / —` | `64Mi / 256Mi` | Không |
| Kapas web | `500m / 2` | `1Gi / 4Gi` | Data `4Gi`, secrets `1Gi`, backups `4Gi` |
| PostgreSQL Kapas | `250m / 1` | `512Mi / 2Gi` | `4Gi` |
| Redis Kapas | `100m / 500m` | `128Mi / 512Mi` | `2Gi` |
| dbt runner | `250m / 2` | `1Gi / 2Gi` | Storage `4Gi`, workspace `4Gi` |
| PostgreSQL dbt | `100m / —` | `256Mi / 512Mi` | `2Gi` |
| Redis dbt | `50m / —` | `64Mi / 256Mi` | `2Gi` |
| Mỗi Job seed, bootstrap hoặc cấp PAT | `50m / —` | `64Mi / 256Mi` | Không |

Các role query engine dùng preset chart với request `1 CPU/3072Mi`, limit `3 CPU/6144Mi`. Preset còn đặt ephemeral-storage request `50Mi`, limit `2Gi`; không được bỏ qua dung lượng tạm khi tính tài nguyên node.

Ontology migration Job không khai báo requests và limits tường minh trong template. InitContainer và Job khác có thể tạo nhu cầu tài nguyên ngoài các container thường trực ở bảng trên.

### Thành phần tuỳ chọn

:::note Điều kiện

Các hàng sau chỉ phát sinh khi bật feature tương ứng. Spark driver và executor được tạo theo run, nên không có một sizing cố định cho mọi tác vụ Compute.

:::

| Thành phần | CPU request / limit | RAM request / limit | Storage |
|---|---|---|---|
| Hanas Catalog API | `100m / —` | `256Mi / 1Gi` | Không PVC riêng |
| Hanas Catalog runner | `250m / —` | `512Mi / 4Gi` | `emptyDir` tối đa `10Gi` |
| PostgreSQL Hanas Catalog | `100m / —` | `256Mi / 1Gi` | PVC `4Gi` |
| Ingestion API và worker | `500m / —` | `2Gi / 8Gi` | PVC `20Gi`, vùng dumps tạm `4Gi` |
| PostgreSQL Ingestion | `100m / —` | `256Mi / 1Gi` | PVC `4Gi` |
| Spark Operator controller | `100m / 1` | `512Mi / 1Gi` | Không PVC riêng |
| Spark driver và executor | Theo run | Theo run | Theo cấu hình run |

Compute khởi tạo quota requests `16 CPU`, `64Gi RAM`, tối đa `40` pod. LimitRange đặt trần mỗi container `4 CPU/18Gi`, defaultRequest `100m/256Mi`; quota không đồng nghĩa tài nguyên đã được dự trữ.

## Cách dùng số liệu để sizing

Tổng số học container thường trực đang bật xấp xỉ `7 CPU`, `18.25Gi RAM requests` và `77Gi PVC logic`. Tổng này chưa tính Kubernetes, CNI, APISIX, Longhorn, Jobs, image layers, rollout và dự phòng lỗi.

Mỗi pod vẫn cần một node đủ tài nguyên khả dụng để đáp ứng request riêng. Dung lượng PVC logic cũng khác dung lượng vật lý khi storage có replication hoặc snapshot.

:::caution Giới hạn hiện tại

Các giá trị trên phục vụ kiểm tra bộ cài, không phải cấu hình production tối thiểu hoặc cam kết năng lực. Chưa có benchmark capacity, ma trận HA hay số node tối thiểu đã được xác nhận cho mọi môi trường.

:::

## Khuyến nghị theo quy mô

Bảng sau là khuyến nghị lập kế hoạch, cần điều chỉnh bằng workload và phép đo thực tế. Không quy đổi số người dùng thành CPU/RAM khi chưa có thông tin về truy vấn và concurrency.

| Quy mô sử dụng | Khuyến nghị |
|---|---|
| Kiểm tra chức năng | Bắt đầu từ values mẫu, chừa tài nguyên cho Jobs và chạy tuần tự các ca nghiệm thu. |
| Nhóm sử dụng chung | Đo truy vấn, dbt concurrency và tăng trưởng metadata; điều chỉnh requests, limits và PVC theo từng thành phần. |
| Nhiều workload đồng thời | Lập ngân sách riêng cho query executor, Ingestion và Spark; kiểm tra queue, quota và ảnh hưởng lên datastore. |
| Môi trường cần phục hồi dịch vụ | Thiết kế storage, topology, backup ngoài cluster và diễn tập restore theo mục tiêu đã thống nhất. |

MinIO mẫu chỉ có `10Gi` và chạy standalone. Khi sử dụng dữ liệu thực, tính thêm thời gian lưu trữ, tăng trưởng object, dữ liệu tạm và chính sách backup.

Kapas và dbt đang sử dụng PVC RWO; tăng replica cần đánh giá shared state và cách truy cập volume. Với PostgreSQL ngoài cluster, xác nhận extension, quyền migration, TLS và khả năng khôi phục trước khi chuyển đổi.

## Tiếp theo

- [Cài đặt bằng helmfile](install.md).
- [Tham chiếu cấu hình](configuration.md).
- [Sao lưu và khôi phục](backup-recovery.md).
