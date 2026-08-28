# Dremio - Thông Tin Version

## Version Hiện Tại

| Thông tin | Giá trị |
|---|---|
| **Dremio Version** | 25.x (Community Edition) |
| **Deployment** | Kubernetes (namespace `dremio`) |
| **Coordinator** | 1 pod |
| **Executors** | 3 pods |
| **UI/API Port** | 9047 |
| **JDBC Port** | 31010 |
| **Arrow Flight Port** | 32010 |
| **Internal IP** | `<CẦN ĐIỀN / KHÔNG CÔNG BỐ>` |
| **URL** | `<CẦN ĐIỀN THEO ENVIRONMENT>` |

---

## Compatibility Matrix

### Với Hanas Platform Services

| Service | Version | Tích hợp | Giao thức |
|---|---|---|---|
| **Apache Iceberg** | 1.8.1 theo runtime Spark (format v2) | Native read/write | Hive Metastore / S3 |
| **MinIO** | `RELEASE.2025-04-22T22-12-26Z` theo baseline | Data source (S3-compat) | S3A protocol |
| **Hive Metastore** | 3.x | Catalog source | Thrift (port 9083) |
| **Apache Spark** | 3.5.1 | Multi-engine access | Shared Iceberg tables |
| **dbt** | 1.x | dbt tạo tables → Dremio views | Qua Iceberg tables |
| **Apache Airflow** | 2.x | DremioClient API | REST API v3 |
| **DataHub** | v0.14.1 theo baseline | Metadata ingestion | API / Lineage |
| **Apache Ranger** | Optional | Tùy chọn | Plugin |

### BI Tools

| Tool | Kết nối | Driver | Port |
|---|---|---|---|
| **Apache Superset** | Có | Arrow Flight JDBC / dremio-sqlalchemy | 32010 |
| **Tableau** | Có | Dremio JDBC Driver | 31010 |
| **PowerBI** | Có | Dremio ODBC Driver | 31010 |
| **Python (pyarrow)** | Có | Arrow Flight gRPC | 32010 |
| **DBeaver** | Có | JDBC | 31010 |
| **Custom Apps** | Có | REST API v3 | 9047 |

### Client Drivers

| Driver | Version | Download |
|---|---|---|
| **Arrow Flight JDBC** | Apache open-source | [Download](https://arrow.apache.org/docs/java/flight_sql_jdbc_driver.html) |
| **Dremio JDBC** | Bundled with Dremio | [Dremio Downloads](https://www.dremio.com/drivers/) |
| **Dremio ODBC** | Bundled with Dremio | [Dremio Downloads](https://www.dremio.com/drivers/) |

---

## Dremio Editions

| Feature | Community Edition (OSS) | Hanas Platform Edition |
|---|---|---|
| Query Engine | Có | Có |
| Reflections | Có | Có |
| Semantic Layer | Có | Có |
| Arrow Flight | Có | Có |
| Iceberg Support | Có | Có |
| Kubernetes Deploy | Có | Có |
| **HA Coordinator** | Không | Có |
| **Column Masking** | Không | Có |
| **Row Filtering** | Không | Có |
| **Audit Logging** | Không | Có |
| **Enterprise Support** | Không | Có |

---

## Iceberg Compatibility

| Iceberg Feature | Dremio Support | Ghi chú |
|---|---|---|
| Read Iceberg tables | Có | Qua Hive / S3 source |
| Write Iceberg tables (CTAS) | Có | CREATE TABLE AS SELECT |
| DML (INSERT/UPDATE/DELETE) | Có | Yêu cầu format v2 |
| MERGE INTO | Có | Yêu cầu format v2 |
| Time Travel | Có | `AT TIMESTAMP` / `AT SNAPSHOT` |
| Schema Evolution | Có | Auto-detect schema changes |
| Partition Pruning | Có | Tự động dựa trên WHERE clause |
| Hidden Partitioning | Có | Transparent cho user |
| Metadata Pruning | Có | Min/max file statistics |


---

## API Versions

| API | Endpoint | Sử dụng |
|---|---|---|
| **V2 (Legacy)** | `/apiv2/...` | Login (`/apiv2/login`) |
| **V3 (Current)** | `/api/v3/...` | Catalog, Reflections, SQL, Users |

> **Lưu ý:** `DremioClient` trong platform sử dụng `/apiv2/login` cho authentication và `/api/v3/*` cho tất cả operations khác.

---

## Lịch Sử Thay Đổi

| Ngày | Thay đổi |
|---|---|
| 2025-Q2 | Initial deployment: Dremio 25.x trên Kubernetes |
| 2025-Q2 | Cấu hình MinIO + Hive Metastore sources |
| 2025-Q2 | Tạo DATA_MART space, initial views |
| 2025-Q3 | Tích hợp Airflow: DremioClient cho backdate/backfill DAGs |
| 2025-Q3 | Triển khai raw reflections cho backdate views |

---

## Tham Khảo

- [Dremio Official Documentation (25.x)](https://docs.dremio.com/25.x/)
- [Dremio REST API Reference](https://docs.dremio.com/25.x/reference/api/)
- [Dremio Helm Charts (GitHub)](https://github.com/dremio/dremio-cloud-tools)
- [Arrow Flight SQL JDBC Driver](https://arrow.apache.org/docs/java/flight_sql_jdbc_driver.html)
- [Dremio + Apache Iceberg Guide](https://docs.dremio.com/25.x/sonar/data-sources/object-storage/)
- [Apache Iceberg Official Docs](https://iceberg.apache.org/docs/latest/)
