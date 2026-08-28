# DataHub - Hướng Dẫn Sử Dụng

## 1. Truy Cập DataHub

| Thông tin | Giá trị |
|---|---|
| **URL** | `http://<DATAHUB_HOST>:9002` (Docker) hoặc qua Ingress/Port-forward (K8s) |
| **Credentials** | Secret/SSO do khách hàng cấp; không sử dụng credential mặc định |
| **SSO** | Nếu đã cấu hình OIDC → Login qua Identity Provider |

### Giao Diện Chính

Sau khi login, DataHub UI gồm các phần:

| Menu | Chức năng |
|---|---|
| **Home** | Dashboard tổng quan, recommendations, recent activity |
| **Search** | Tìm kiếm toàn bộ metadata (datasets, pipelines, glossary, ...) |
| **Browse** | Duyệt assets theo platform, domain, environment |
| **Govern** | Glossary, Domains, Policies management |
| **Ingestion** | Quản lý data sources và ingestion schedules |
| **Analytics** | Thống kê sử dụng, popular datasets, active users |
| **Settings** | User management, tokens, platform settings |

---

## 2. Search & Discovery

### Tìm Kiếm Dataset

Gõ từ khóa vào search bar trên top navigation:

```
Ví dụ search queries:
- "sat_gl"                    → Tìm satellite table GL
- "hub_customer"              → Tìm Hub customer
- "raw_vault"                 → Tất cả trong raw vault
- "tag:pii"                   → Tìm datasets có tag PII
- "owner:data-engineering"    → Datasets thuộc team DE
- "domain:finance"            → Datasets trong domain Finance
```

### Filters

Kết quả search hỗ trợ filter theo:
- **Entity Type**: Dataset, Dashboard, Pipeline, Chart, Glossary Term
- **Platform**: Iceberg, Kafka, Dremio, Airflow
- **Domain**: Finance, Risk, Operations, HR, ...
- **Tags**: PII, Sensitive, Deprecated, ...
- **Owner**: Teams hoặc individuals
- **Environment**: PROD, DEV, STAGING

### Browse

Duyệt assets theo cây thư mục:
1. Click **Browse** trên navbar
2. Chọn Platform (vd: `iceberg`)
3. Navigate theo hierarchy: `hanas` → `demo` → `raw_vault` → tables

---

## 3. Data Catalog

### Xem Chi Tiết Dataset

Click vào bất kỳ dataset nào để xem:

| Tab | Nội dung |
|---|---|
| **Schema** | Danh sách columns, data types, descriptions, tags |
| **Documentation** | Mô tả dataset, owner notes, wiki links |
| **Lineage** | Upstream/downstream dependencies (visual graph) |
| **Properties** | Technical metadata (platform, format, partitions) |
| **Queries** | SQL queries liên quan (nếu có) |
| **Stats** | Row count, freshness, profiling data |
| **Incidents** | Active incidents ảnh hưởng dataset |
| **Validation** | Kết quả dbt tests / data quality assertions |

### Thêm Documentation

1. Mở dataset → Tab **Documentation**
2. Click **Edit** (markdown editor)
3. Viết mô tả nghiệp vụ, data dictionary, usage notes
4. Click **Save**

### Gán Tags

1. Mở dataset → Click **+ Add Tag** (phía trên schema)
2. Chọn tag có sẵn hoặc tạo mới:
   - `pii` — Personally Identifiable Information
   - `sensitive` — Dữ liệu nhạy cảm
   - `deprecated` — Dataset không còn sử dụng
   - `golden-source` — Nguồn dữ liệu chuẩn
3. Tags cũng có thể gán **column-level**

### Gán Owner

1. Mở dataset → Click **+ Add Owners**
2. Chọn loại ownership:
   - **Technical Owner** — Team phát triển/bảo trì
   - **Business Owner** — Đơn vị nghiệp vụ sở hữu dữ liệu
   - **Data Steward** — Người quản trị chất lượng dữ liệu

---

## 4. Data Lineage

### Xem Lineage Graph

1. Mở bất kỳ dataset → Tab **Lineage**
2. Graph hiển thị:
   - **Upstream** ← Nguồn dữ liệu đầu vào (sources, transformations)
   - **Downstream** → Nơi dữ liệu được sử dụng (marts, reports)

### Ví Dụ Lineage Trong Hanas

```
Source DB → NiFi Flow → landing/ (MinIO)
    → Spark Job → raw_vault.hub_customer (Iceberg)
        → dbt Model → business_vault.pit_customer (Iceberg)
            → dbt Model → information_mart.dim_customer (Iceberg)
                → Dremio Virtual Dataset → Superset Dashboard
```

DataHub xây dựng lineage này qua package `ktl_airflow_utils`:

| Nguồn | Phương thức | Metadata |
|---|---|---|
| **dbt** | `publish_dbt_to_datahub` (acryl-datahub Pipeline) | Model lineage, column-level lineage |
| **Iceberg** | `publish_iceberg_from_catalog` (GMS MCP API) | Table schemas từ catalog.json |
| **dbt Tests** | `publish_test_results_to_datahub` (GMS MCP API) | Data quality assertions |
| **Dremio → Iceberg** | `emit_dremio_lineage` | View → Table lineage + column mapping |
| **Superset → Dremio** | `emit_superset_dataset_lineage` | Dataset → View column lineage |

### Column-Level Lineage

DataHub hỗ trợ truy vết lineage **xuống cấp column**:
- Column nào trong `dim_customer` đến từ đâu?
- Nếu thay đổi column `CUSTOMER_ID` ở source, ảnh hưởng gì downstream?
- BI lineage: Dremio view columns → upstream Iceberg table columns (tự động match bằng tên)

→ Xem trong tab Lineage, toggle **Column Lineage** mode.

---

## 5. Business Glossary

### Tạo Glossary Term

1. Navigate: **Govern** → **Glossary**
2. Click **+ Create Term**
3. Điền thông tin:
   - **Name**: vd `Close of Business Date`
   - **Description**: Ngày cuối cùng trong kỳ xử lý dữ liệu
   - **Related Terms**: Liên kết với term khác
4. Click **Create**

### Tạo Term Group (Phân Nhóm)

Tổ chức glossary terms theo nhóm nghiệp vụ:

```
Business Glossary
├── Finance
│   ├── Close of Business Date (COB)
│   ├── General Ledger (GL)
│   └── Net Interest Margin (NIM)
├── Risk Management
│   ├── Credit Risk Score
│   └── Loss Given Default (LGD)
└── Customer
    ├── Customer ID (CIF)
    ├── Know Your Customer (KYC)
    └── Anti-Money Laundering (AML)
```

### Liên Kết Term → Dataset

1. Mở dataset → Tab **Schema**
2. Click vào column cần liên kết
3. Click **+ Add Glossary Term**
4. Chọn term từ glossary
5. Giờ column đã được "tag" bằng business term → tìm kiếm được theo nghiệp vụ

---

## 6. Domains

### Tạo Domain

Domains giúp phân nhóm dữ liệu theo đơn vị nghiệp vụ:

1. Navigate: **Govern** → **Domains**
2. Click **+ Create Domain**
3. Điền:
   - **Name**: vd `Finance`, `Risk`, `Operations`
   - **Description**: Mô tả phạm vi domain
4. Click **Create**

### Gán Dataset Vào Domain

1. Mở dataset → Click **+ Set Domain**
2. Chọn domain phù hợp
3. Giờ dataset xuất hiện khi browse theo domain

---

## 7. RBAC — Phân Quyền

### Roles Mặc Định

| Role | Quyền | Phù hợp cho |
|---|---|---|
| **Admin** | Toàn quyền platform + metadata | Platform admin |
| **Editor** | Edit metadata, tags, docs trên tất cả entities | Data Engineer, Data Steward |
| **Reader** | Chỉ xem metadata, không edit | Business Analyst, Developer |

### Tạo Custom Policy

1. Navigate: **Settings** → **Permissions** → **Policies**
2. Click **Create New Policy**
3. Chọn loại:
   - **Platform Policy**: Quản lý users, secrets, ingestion
   - **Metadata Policy**: Edit tags, docs, lineage trên entities cụ thể

#### Ví Dụ: Policy Cho Data Steward

```
Policy Name: Finance Data Steward
Type: Metadata Policy
Privileges:
  - Edit Documentation
  - Edit Tags
  - Edit Glossary Terms
  - Edit Owners
  - Edit Domain
Resources:
  - Entity Type: Dataset
  - Domain: Finance
Actors:
  - Group: "finance-data-stewards"
```

#### Ví Dụ: Policy Restrict PII

```
Policy Name: Restrict PII Access
Type: Metadata Policy
Effect: Deny
Privileges:
  - View Entity Page
Resources:
  - Entity Type: Dataset
  - Tag: "pii"
Actors:
  - Role: Reader (trừ group "compliance-team")
```

---

## 8. Quản Lý Ingestion Từ UI

### Tạo Ingestion Source

1. Navigate: **Ingestion** → **Create New Source**  
2. Chọn loại source (vd: `Iceberg`, `Kafka`, `dbt`, ...)
3. Điền recipe YAML hoặc dùng form wizard
4. Chọn schedule:
   - **Manual**: Chạy thủ công
   - **Hourly / Daily / Weekly**: Tự động theo lịch
5. Click **Create & Run**

### Giám Sát Ingestion

- Mỗi ingestion run hiển thị status: `Running`, `Succeeded`, `Failed`
- Click vào run để xem chi tiết: entities ingested, errors, warnings
- Logs chi tiết cho debug nếu có lỗi

---

## 9. Monitoring & Troubleshooting

### Health Check

```bash
# Kiểm tra GMS
curl -s http://<DATAHUB_HOST>:8080/health
# Expected: {"status":"UP"}

# Kiểm tra Elasticsearch
curl -s http://<ES_HOST>:9200/_cluster/health
# Expected: status: "green" hoặc "yellow"

# Kiểm tra Kafka topics
kafka-topics.sh --bootstrap-server <KAFKA_HOST>:9092 --list | grep datahub
# Expected: MetadataChangeEvent_v4, MetadataAuditEvent_v4, etc.
```

### Troubleshooting Thường Gặp

| Vấn đề | Nguyên nhân | Giải pháp |
|---|---|---|
| Search không trả kết quả | Elasticsearch chưa index | Kiểm tra MAE Consumer logs, reindex nếu cần |
| Lineage không hiển thị | Ingestion recipe chưa chạy | Chạy ingestion hoặc trigger Airflow publish TaskGroup |
| UI chậm | ES heap thấp | Tăng `ES_JAVA_OPTS` lên `2g–4g` |
| Login thất bại | OIDC config sai | Kiểm tra `AUTH_OIDC_*` env vars, discovery URI |
| Ingestion failed | Kết nối source lỗi | Kiểm tra network, credentials, firewall |
| Dataset duplicate | Platform instance không nhất quán | Đảm bảo `platform_instance: "hanas"` trong tất cả recipes |

### Reindex Elasticsearch

Khi search index bị corrupt hoặc sau upgrade:

```bash
# Sử dụng datahub CLI
datahub docker quickstart --restore-indices

# Hoặc call API
curl -X POST http://<DATAHUB_HOST>:8080/gms/operations?action=restoreIndices \
  -H "Content-Type: application/json" \
  -d '{"aspectName": "ALL", "urn": "ALL"}'
```
