# Apache Superset - Thông Tin Version

## Version Được Sử Dụng

| Service | Version | Ghi chú |
|---|---|---|
| **Apache Superset** | **4.1.1** | Stable release, November 2024 |
| **Python** | 3.10+ | Runtime cho Flask backend |
| **Node.js** | 18+ | Build frontend assets |
| **PostgreSQL** | 15+ | Metadata database |
| **Redis** | 7+ | Cache, message broker |
| **sqlalchemy_dremio** | 3.0.2+ | Dremio Arrow Flight connector |

## Ma Trận Tương Thích

### Superset ↔ Hanas Services

| Hanas Service | Version | Tương thích Superset 4.1.x | Giao thức |
|---|---|---|---|
| **Dremio** | 25.x | ✅ Tương thích | Arrow Flight (sqlalchemy_dremio) |
| **MinIO** | RELEASE.2024-x | ✅ Gián tiếp qua Dremio | — |
| **Apache Iceberg** | 1.4+ | ✅ Gián tiếp qua Dremio | — |
| **Apache Airflow** | 2.8+ | ✅ REST API integration | HTTP |
| **Apache Kafka** | 3.6+ | ✅ Gián tiếp (Kafka → Iceberg → Dremio → Superset) | — |
| **Apache Spark** | 3.5+ | ✅ Gián tiếp qua Dremio | — |
| **dbt** | 1.7+ | ✅ Gián tiếp (dbt → Iceberg → Dremio → Superset) | — |
| **DataHub** | 0.12+ | ✅ Metadata ingestion | REST API |
| **Apache Ranger** | 2.4+ | ✅ Security policies qua Dremio | — |
| **HashiCorp Vault** | 1.15+ | ✅ Secrets management | Vault Agent Injector |
| **OpenObserve** | 0.9+ | ✅ Monitoring | Logs, Metrics |

### Superset ↔ Database Drivers

| Database | Python Driver | SQLAlchemy URI Format |
|---|---|---|
| **Dremio (Arrow Flight)** | `sqlalchemy-dremio` | `dremio+flight://user:pass@host:32010/dremio` |
| **PostgreSQL** | `psycopg2` | `postgresql://user:pass@host:5432/db` |
| **MySQL** | `mysqlclient` | `mysql://user:pass@host:3306/db` |
| **Trino/Presto** | `trino` | `trino://user@host:8080/catalog` |
| **Apache Hive** | `pyhive` | `hive://host:10000/default` |
| **ClickHouse** | `clickhouse-connect` | `clickhousedb://user:pass@host:8123/db` |
| **BigQuery** | `pybigquery` | `bigquery://project_id` |

---

## Lịch Sử Phiên Bản

### Apache Superset 4.1 (November 2024) — **Đang sử dụng**

**Tính năng mới:**
- Improved Alerts & Reports modal UX
- Enhanced drag-and-drop dashboard editing
- Bug fixes và stability improvements
- No breaking changes từ 4.0

### Apache Superset 4.0 (April 2024)

**Tính năng chính:**
- New ECharts: Heatmap, Histogram, Sankey đã built-in
- Redesigned CSV/Excel/Columnar upload forms
- Dashboard metadata bar (owners, last modified)
- Slack Upload Files V2 API support
- Native dashboard filters (thay thế Filter Box đã deprecated)

**Breaking Changes:**
- Filter Box visualization bị loại bỏ → migrate sang Native Filters
- Filter Sets bị deprecated
- Dependency upgrades (Python 3.9+ required)

### Apache Superset 3.1 (October 2023)

- Sunburst V2 (ECharts-based)
- Improved API security
- Performance optimizations

### Apache Superset 3.0 (April 2023)

**Breaking Changes:**
- Loại bỏ nhiều legacy chart plugins (NVD3-based)
- Migration sang ECharts cho hầu hết charts
- Python 3.9+ required
- Node.js 16+ required

---

## Upgrade Path

### Từ 3.x lên 4.x

1. **Backup** metadata database (PostgreSQL)
2. **Kiểm tra** [UPDATING.md](https://github.com/apache/superset/blob/master/UPDATING.md) cho breaking changes
3. **Migrate** Filter Box → Native Filters trước khi upgrade
4. **Test** trên staging với data backup
5. **Upgrade** image tag và chạy `superset db upgrade`

### Từ 4.0 lên 4.1

- Không có breaking changes
- Upgrade image tag trực tiếp
- Chạy `superset db upgrade` (auto-migrate)

### Ví dụ Upgrade trên Kubernetes

```bash
# 1. Backup metadata DB
kubectl exec -n superset superset-postgresql-0 -- \
  pg_dump -U superset -d superset > backup_before_upgrade.sql

# 2. Update image tag trong values
sed -i 's/tag: "4.0.0"/tag: "4.1.1"/' superset-values.yaml

# 3. Apply upgrade
helm upgrade superset superset/superset \
  -f superset-values.yaml \
  --namespace superset \
  --wait

# 4. Verify
kubectl get pods -n superset -w
```

---

## Roadmap

> ⚠️ Roadmap chỉ mang tính tham khảo, không phải cam kết của Apache Superset project.

### Superset 5.0 (June 2025)

- Significant UX enhancements
- Performance optimizations
- Expanded database connectivity

### Superset 6.0 (Late 2025)

- Full migration to Ant Design v5
- True Dark Mode
- Dynamic per-dashboard theming
- AG Grid Table chart
- Extensions framework improvements
- Model Context Protocol (MCP) integration

---

## Tài Liệu Tham Khảo

| Nguồn | URL |
|---|---|
| **Apache Superset Official Docs** | [superset.apache.org](https://superset.apache.org/) |
| **GitHub Repository** | [github.com/apache/superset](https://github.com/apache/superset) |
| **Helm Chart** | [github.com/apache/superset/tree/master/helm/superset](https://github.com/apache/superset/tree/master/helm/superset) |
| **CHANGELOG** | [github.com/apache/superset/blob/master/CHANGELOG.md](https://github.com/apache/superset/blob/master/CHANGELOG.md) |
| **UPDATING.md** | [github.com/apache/superset/blob/master/UPDATING.md](https://github.com/apache/superset/blob/master/UPDATING.md) |
| **SQLAlchemy Dremio Connector** | [pypi.org/project/sqlalchemy-dremio](https://pypi.org/project/sqlalchemy-dremio/) |
| **Dremio + Superset Guide** | [docs.dremio.com/current/sonar/client-applications/clients/superset](https://docs.dremio.com/current/sonar/client-applications/clients/superset/) |
| **Superset API Docs** | [superset.apache.org/docs/api](https://superset.apache.org/docs/api) |
