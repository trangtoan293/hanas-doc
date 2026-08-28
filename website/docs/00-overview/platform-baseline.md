# Baseline Triển Khai Và Bàn Giao

## Mục đích

Trang này là biểu mẫu kiểm soát thông tin trước khi bàn giao Hanas Data Platform cho khách hàng. Nội dung kiến trúc và runbook trong site là tham chiếu; các giá trị trong bảng dưới đây mới là căn cứ để vận hành một môi trường cụ thể.

> **Trạng thái:** Các ô `<CẦN ĐIỀN>` và `<CẦN CHỐT>` phải được điền từ manifest, biên bản nghiệm thu hoặc hợp đồng trước khi phát hành bản bàn giao chính thức. Không gửi trang này khi còn placeholder.

## 1. Phạm vi hệ thống

| Hạng mục | Giá trị bàn giao |
|---|---|
| Tên môi trường | `<DEV / TEST / STAGING / PROD>` |
| Tên khách hàng/đơn vị | `<CẦN ĐIỀN>` |
| Data Center chính | `<CẦN ĐIỀN>` |
| Site DR | `<CẦN ĐIỀN / KHÔNG ÁP DỤNG>` |
| Mục đích sử dụng | `<Báo cáo / phân tích / CDC / AI / khác>` |
| Ngày nghiệm thu | `<YYYY-MM-DD>` |
| Phiên bản tài liệu | `1.0.0` |
| Người phê duyệt | `<CẦN ĐIỀN>` |

## 2. Danh mục thành phần

| Năng lực | Thành phần | Vai trò | Namespace/endpoint thực tế | Owner |
|---|---|---|---|---|
| Ingestion | Apache NiFi | Batch, file/API/JDBC và routing | `<CẦN ĐIỀN>` | `<CẦN ĐIỀN>` |
| Ingestion | Apache Kafka/Confluent | Streaming, CDC và event replay | `<CẦN ĐIỀN>` | `<CẦN ĐIỀN>` |
| Ingestion (tùy dự án) | Oracle GoldenGate for Big Data / ODI | Oracle CDC, replication hoặc integration adapter | `<CẦN ĐIỀN / KHÔNG ÁP DỤNG>` | `<CẦN ĐIỀN>` |
| Storage | MinIO | Object Storage S3-compatible | `<CẦN ĐIỀN>` | `<CẦN ĐIỀN>` |
| Storage | Apache Iceberg | Table format, snapshot, schema/partition evolution | `<CẦN ĐIỀN>` | `<CẦN ĐIỀN>` |
| Catalog | Hive Metastore hoặc Apache Polaris | Catalog cho Iceberg | `<CẦN ĐIỀN>` | `<CẦN ĐIỀN>` |
| Processing | Apache Spark | Batch/stream distributed compute | `<CẦN ĐIỀN>` | `<CẦN ĐIỀN>` |
| Orchestration | Apache Airflow | Lập lịch và điều phối pipeline | `<CẦN ĐIỀN>` | `<CẦN ĐIỀN>` |
| Modeling | dbt + Data Vault 2.0 | Raw Vault, Business Vault, Information Mart | `<CẦN ĐIỀN>` | `<CẦN ĐIỀN>` |
| Governance | DataHub | Catalog, glossary, lineage, quality | `<CẦN ĐIỀN>` | `<CẦN ĐIỀN>` |
| Federation | Dremio | Query engine và semantic layer | `<CẦN ĐIỀN>` | `<CẦN ĐIỀN>` |
| Consumption | Apache Superset/BI | Dashboard và phân tích | `<CẦN ĐIỀN>` | `<CẦN ĐIỀN>` |
| AI | Dify, vLLM, Langfuse | Workflow, inference và LLM observability | `<CẦN ĐIỀN>` | `<CẦN ĐIỀN>` |
| Security | Ranger, Vault, IdP/SSO | Policy, secrets, xác thực | `<CẦN ĐIỀN>` | `<CẦN ĐIỀN>` |
| Operations | OpenObserve | Log, metrics, traces, alerting | `<CẦN ĐIỀN>` | `<CẦN ĐIỀN>` |

## 3. Profile catalog phải chốt

| Nội dung | Quickstart/dev | Production |
|---|---|---|
| Catalog | Hive Metastore | Apache Polaris hoặc catalog production đã được phê duyệt |
| Giao thức | Thrift | Iceberg REST API |
| Điểm mạnh | Dễ dựng lab, ít thành phần | Chuẩn hóa truy cập đa engine, quản lý role/credential |
| Không dùng cho | Dữ liệu production quan trọng | Môi trường chưa có PostgreSQL/backup/RBAC đã kiểm thử |
| Kiểm tra bắt buộc | Spark đọc/ghi table, Dremio refresh metadata | Spark/Dremio/dbt đọc/ghi cùng catalog, RBAC, credential vending, restore |

> **Quy tắc:** Không trộn `thrift://...:9083` và REST catalog cho cùng table trong cùng pipeline nếu chưa có quyết định kiến trúc và kế hoạch migration.

## 4. Version baseline

Các version dưới đây là baseline được ghi trong bộ tài liệu hiện tại. Khi phát hành, đối chiếu lại với image digest, Helm release, lock file và manifest thực tế.

| Thành phần | Baseline tài liệu | Bằng chứng cần lưu |
|---|---|---|
| Apache NiFi/Registry | `2.7.2` | Image digest, `nifi.sh status`, Registry bundle |
| Kafka profile V1 | Confluent `7.7.x` / Kafka `3.7.x` | Helm values, broker build info |
| Kafka profile V2 | Kafka `3.8.x`, Debezium `2.7.x` | Strimzi/connector manifest |
| MinIO | `RELEASE.2025-04-22T22-12-26Z` | Tenant manifest và `mc admin info` |
| Apache Spark | `3.5.1` | Spark image digest |
| Iceberg runtime | `1.8.1` theo Spark image | JAR list trong image |
| dbt-spark | `1.9.0` | Python lock/requirements |
| Apache Airflow | `2.x` | Image digest và provider list |
| DataHub | `v0.14.1` | Helm values/image digest |
| Dremio | `25.x` | Image digest và license/edition |
| Apache Ranger | `2.5.0` | Image/package manifest |
| HashiCorp Vault | `1.18.x` | Image digest và `vault version` |
| Apache Superset | `4.1.1` | Image digest/Python package lock |
| Apache Polaris | `1.3.0` nếu chọn production profile | Helm release và API health |
| OpenObserve | `<CẦN CHỐT>` | Image tag/digest và Helm release |
| Dify/vLLM/Langfuse | Theo từng trang version-info | Image digest và model manifest |

Nếu version thực tế khác baseline, cập nhật trang `version-info.md` tương ứng và ghi lý do thay đổi trong release record.

## 5. Thông tin hạ tầng và mạng

| Nhóm | Giá trị cần bàn giao |
|---|---|
| Kubernetes version/distribution | `<CẦN ĐIỀN>` |
| Số control-plane/worker node | `<CẦN ĐIỀN>` |
| CPU/RAM/Local disk theo node | `<CẦN ĐIỀN>` |
| StorageClass/PV capacity | `<CẦN ĐIỀN>` |
| CNI/Ingress/LoadBalancer | `<CẦN ĐIỀN>` |
| DNS/TLS certificate issuer | `<CẦN ĐIỀN>` |
| VLAN/firewall/egress rules | `<CẦN ĐIỀN>` |
| Namespace và ResourceQuota | `<CẦN ĐIỀN>` |
| Registry/mirror nội bộ | `<CẦN ĐIỀN>` |
| Proxy/NTP/DNS nội bộ | `<CẦN ĐIỀN>` |

Không đưa password, token hoặc private key vào bảng này. Chỉ ghi tên Secret/Vault path và owner quản lý.

## 6. Endpoint và quyền truy cập

| Dịch vụ | Endpoint/UI | API/port | Cách xác thực | Nhóm được cấp quyền |
|---|---|---|---|---|
| NiFi | `<CẦN ĐIỀN>` | `8443` hoặc theo ingress | SSO/local break-glass | `<CẦN ĐIỀN>` |
| Kafka/Connect | `<CẦN ĐIỀN>` | `9092/9093/8083` theo profile | SASL/mTLS | `<CẦN ĐIỀN>` |
| MinIO | `<CẦN ĐIỀN>` | `9000`, console theo tenant | SSO/service account | `<CẦN ĐIỀN>` |
| Airflow | `<CẦN ĐIỀN>` | `8080`/Ingress | SSO/local break-glass | `<CẦN ĐIỀN>` |
| Dremio | `<CẦN ĐIỀN>` | `9047/31010/32010` theo deployment | SSO/local | `<CẦN ĐIỀN>` |
| DataHub | `<CẦN ĐIỀN>` | `9002/8080` theo deployment | SSO/local | `<CẦN ĐIỀN>` |
| Superset | `<CẦN ĐIỀN>` | `8088`/Ingress | SSO/local | `<CẦN ĐIỀN>` |
| OpenObserve | `<CẦN ĐIỀN>` | `5080`/Ingress | SSO/basic/service token | `<CẦN ĐIỀN>` |
| Vault | `<CẦN ĐIỀN>` | `8200` | Kubernetes/LDAP/AppRole | `<CẦN ĐIỀN>` |

## 7. Chính sách dữ liệu

| Chính sách | Giá trị áp dụng |
|---|---|
| Vùng dữ liệu | `landing → raw-vault → business-vault → information-mart` |
| Định dạng chuẩn | Parquet + Iceberg format v2 cho bảng Lakehouse |
| Partition key | Theo access pattern; thường theo ngày nghiệp vụ/`OP_TIME`, phải ghi trong data contract |
| Retention Landing | `<CẦN ĐIỀN>` |
| Retention Raw/Business/Mart | `<CẦN ĐIỀN>` |
| Snapshot expiration/compaction | `<CẦN ĐIỀN>` |
| Data quality gate | Row count, null/duplicate, schema, reconciliation và business rule |
| Dữ liệu nhạy cảm | Phân loại, masking/row filter, export approval và audit |

## 8. RPO/RTO và vận hành

| Hạng mục | Mục tiêu được phê duyệt | Cách đo/biên bản |
|---|---|---|
| RPO object data | `<CẦN ĐIỀN>` | Replication lag và thời điểm object cuối cùng tại DR |
| RTO platform services | `<CẦN ĐIỀN>` | DR exercise từ backup đến smoke test |
| Velero backup frequency/TTL | `<CẦN ĐIỀN>` | Backup `Completed`, restore test định kỳ |
| Uptime | `<CẦN ĐIỀN>` | Monitoring report theo kỳ |
| Severity/SLA | Theo hợp đồng và service policy đã phê duyệt | Ticket report |

RPO của Site Replication là giá trị đo được theo độ trễ đồng bộ, không mặc định bằng 0; khi mất kết nối hoặc site lỗi phải tính phần dữ liệu chưa replicate.

## 9. Tiêu chí nghiệm thu tối thiểu

- Mỗi service được kiểm tra health/readiness và có owner vận hành.
- Pipeline mẫu chạy thành công từ source → landing → model → query → dashboard/consumer.
- Có kiểm tra reconciliation với nguồn, data quality gate và lineage tối thiểu.
- RBAC/SSO/masking/export/audit được kiểm thử bằng tài khoản đại diện từng role.
- Backup tạo thành công, restore thử được trên môi trường kiểm thử và có biên bản.
- Alert cho service down, pipeline failed, consumer lag, storage pressure và backup failed đã được kiểm tra.
- Tài liệu, manifest, sơ đồ mạng, danh sách endpoint và kênh hỗ trợ đã được bàn giao.

## 10. Hồ sơ cần đính kèm

1. BOM và image digest.
2. Sơ đồ triển khai thực tế và sơ đồ luồng dữ liệu.
3. Manifest/Helm values đã loại bỏ secret value.
4. Ma trận quyền và danh sách nhóm người dùng.
5. Data contract, glossary/KPI dictionary và tiêu chí chất lượng.
6. Báo cáo smoke test, performance baseline và reconciliation.
7. Biên bản backup/restore và DR exercise.
