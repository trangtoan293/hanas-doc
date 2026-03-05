# Dremio - Best Practices

## 1. Thiết Kế & Kiến Trúc

### 1.1 Tổ Chức Spaces

```
✅ ĐÚNG — Tổ chức theo domain nghiệp vụ
DATA_MART/
├── PL/              # Profit & Loss
├── DP/              # Deposits
├── LN/              # Loans
├── BACKDATE/        # Backdate tables
└── DIMENSIONS/      # Shared dimensions

❌ SAI — Flat structure không phân nhóm
DATA_MART/
├── FACT_PL_DETAIL
├── FACT_PL_SUMMARY
├── FACT_DP_DETAIL
├── ... (hàng chục views lẫn lộn)
```

### 1.2 Naming Conventions

| Loại | Convention | Ví dụ |
|---|---|---|
| **Space** | UPPER_SNAKE_CASE | `DATA_MART`, `INTEGRATION` |
| **Folder** | UPPER_SNAKE_CASE | `PL`, `BACKDATE` |
| **View (Fact)** | `FACT_<domain>_<detail>` | `FACT_PL_DETAIL`, `FACT_LN_SUMMARY` |
| **View (Dim)** | `DIM_<entity>` | `DIM_CUSTOMER`, `DIM_BRANCH` |
| **View (Backdate)** | `FACT_<domain>_<type>_BACKDATE` | `FACT_PL_DETAIL_BACKDATE` |
| **Reflection** | `<Type> Reflection` | `Raw Reflection`, `Agg - Monthly Summary` |

### 1.3 Virtual Dataset Design Patterns

```sql
-- ✅ Pattern 1: Thin view — ánh xạ trực tiếp, chọn columns cần thiết
CREATE VDS DATA_MART.FACT_PL_DETAIL AS
SELECT
    transaction_id,
    account_number,
    transaction_date,
    amount,
    currency
FROM hive_catalog.data_mart.fact_pl_detail;

-- ✅ Pattern 2: Business logic view — encapsulate logic nghiệp vụ
CREATE VDS DATA_MART.FACT_PL_SUMMARY AS
SELECT
    DATE_TRUNC('MONTH', transaction_date) AS month,
    branch_code,
    SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) AS total_income,
    SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END) AS total_expense,
    SUM(amount) AS net_amount
FROM hive_catalog.data_mart.fact_pl_detail
GROUP BY DATE_TRUNC('MONTH', transaction_date), branch_code;

-- ❌ SAI — SELECT * không filter, không alias
CREATE VDS DATA_MART.MY_VIEW AS
SELECT * FROM hive_catalog.data_mart.fact_pl_detail;
```

### 1.4 Layer Architecture

```
Source Layer (MinIO / Hive)         ← Physical Iceberg tables
    │
    ▼
Integration Views (optional)       ← Join/transform logic
    │
    ▼
Data Mart Views (DATA_MART)        ← Business-ready views
    │
    ▼
Reflections                        ← Pre-computed acceleration
    │
    ▼
BI Tools                           ← Query qua JDBC/Arrow Flight
```

> **Nguyên tắc:** BI tools chỉ truy cập views trong `DATA_MART` space. Không truy cập trực tiếp source tables.

---

## 2. Hiệu Năng

### 2.1 Reflection Strategy

| Workload | Reflection Type | Cấu hình |
|---|---|---|
| Dashboard với nhiều filter | **Raw** | Chọn tất cả columns thường filter |
| KPI summary | **Aggregation** | Dimension = time/region, Measure = SUM/COUNT |
| Ít query, data lớn | **Không cần** | Tránh tốn storage/refresh resource |

```
Reflection Decision Flow:

Query chậm? ──▶ Kiểm tra Query Profile
                    │
              ┌─────┴──────┐
              │ Full scan? │
              └─────┬──────┘
                    │ YES
              ┌─────┴──────────────┐
              │ Cần tất cả columns?│
              └─────┬──────────────┘
                    │
              ┌─────┴──────┐
              │     NO     │──── YES ──▶ Raw Reflection
              └─────┬──────┘
                    │
              Aggregation Reflection
```

### 2.2 Cloud Columnar Cache (C3)

C3 cache data trên executor nodes ở columnar format. Bật trong `values.yaml`:

```yaml
executor:
  cloudCache:
    enabled: true
    # Sử dụng NVMe local disks cho C3
    storageClass: "local-nvme"
    quota:
      fs_pct: 70  # 70% disk cho C3
```

> **Lưu ý:** C3 hiệu quả nhất với NVMe/SSD. Tránh sử dụng HDD hoặc network-attached storage.

### 2.3 Query Optimization Tips

```sql
-- ✅ ĐÚNG — Predicate pushdown: filter TRƯỚC join
SELECT f.*, d.customer_name
FROM DATA_MART.FACT_PL_DETAIL f
JOIN DATA_MART.DIM_CUSTOMER d ON f.customer_id = d.customer_id
WHERE f.transaction_date >= '2025-01-01';

-- ❌ SAI — Filter SAU join → scan toàn bộ trước
SELECT * FROM (
    SELECT f.*, d.customer_name
    FROM DATA_MART.FACT_PL_DETAIL f
    JOIN DATA_MART.DIM_CUSTOMER d ON f.customer_id = d.customer_id
) t
WHERE t.transaction_date >= '2025-01-01';
```

**Checklist tối ưu:**

- [ ] Sử dụng `WHERE` clause với partition columns (Iceberg auto-prune)
- [ ] Tránh `SELECT *` — chọn chỉ columns cần thiết
- [ ] Dùng `LIMIT` khi preview data
- [ ] Kiểm tra Query Profile để xác nhận reflection được sử dụng
- [ ] Tối ưu joins: đưa bảng nhỏ vào bên phải

---

## 3. Bảo Mật

### 3.1 Quản Lý Credentials

```
✅ ĐÚNG — Credentials trong Airflow Variables
password = Variable.get('dremio_password')

✅ ĐÚNG — K8s Secrets cho Helm values
kubectl create secret generic dremio-minio-creds ...

❌ SAI — Hardcode trong code
password = 'my_secret_password'

❌ SAI — Commit vào Git
dremio_password: plain_text_password
```

### 3.2 Access Control Strategy

| Nhóm | Quyền | Scope |
|---|---|---|
| **Admin** | Full access | Tất cả Sources, Spaces, Settings |
| **Data Engineer** | Read/Write | DATA_MART, INTEGRATION spaces |
| **BI User** | Read only | DATA_MART space (chỉ views) |
| **Service Account** | API access | DATA_MART space (Airflow DremioClient) |

### 3.3 Source Isolation

```
Nguyên tắc: Users KHÔNG truy cập trực tiếp Sources

Sources (minio_lakehouse, hive_catalog)
    │
    │ Admin only
    ▼
Virtual Datasets (DATA_MART space)
    │
    │ BI users
    ▼
BI Tools
```

> **Tại sao:** Source access cho phép query bất kỳ table nào (kể cả sensitive data). Views trong Space cho phép kiểm soát chính xác data nào được expose.

---

## 4. Vận Hành Production

### 4.1 Monitoring Checklist

| Metric | Kiểm tra | Frequency |
|---|---|---|
| **Cluster health** | Tất cả coordinator/executor pods Running | Liên tục |
| **Query latency** | P95 < 5s cho dashboard queries | Daily |
| **Reflection status** | Tất cả reflections ở trạng thái ACTIVE | Daily |
| **Failed jobs** | Kiểm tra Jobs page cho failed queries | Daily |
| **Disk usage** | C3 cache + spilling < 80% capacity | Weekly |
| **Connection count** | JDBC/Flight connections không quá limit | Weekly |

### 4.2 Reflection Maintenance

```
Reflection Refresh Flow:

Data thay đổi (dbt build) 
    │
    ▼
Reflection auto-refresh (theo schedule)
    │
    ├── Thành công → ACTIVE
    │
    └── Thất bại → FAILED → Kiểm tra:
            ├── Source table còn tồn tại?
            ├── Schema có thay đổi?
            └── Đủ resource (memory/disk)?
```

**Manual refresh khi cần:**
1. Mở dataset → Reflections tab → click "Refresh Now"
2. Hoặc disable → re-enable reflection

### 4.3 Backup & Recovery

| Component | Backup method | Frequency |
|---|---|---|
| **KV Store** (metadata) | PVC snapshot trên coordinator | Daily |
| **Reflections** | Không cần backup — tự rebuild | N/A |
| **Configuration** | `values.yaml` trong Git | Mỗi thay đổi |
| **Source configs** | Export qua API | Weekly |

---

## 5. Tích Hợp Airflow — DremioClient Pattern

### 5.1 Pattern Chuẩn

```python
from utils.dremio_client import DremioClient
from airflow.models import Variable

# 1. Khởi tạo client từ Airflow Variables
client = DremioClient(
    base_url=Variable.get('dremio_host') + ':9047',
    username=Variable.get('dremio_username'),
    password=Variable.get('dremio_password'),
    ssl_verify=Variable.get('dremio_ssl_verify', 'false').lower() == 'true'
)

try:
    # 2. Login
    client.login()
    
    # 3. Tạo view
    result = client.create_vds(
        space=Variable.get('dremio_space', 'DATA_MART'),
        view_name='MY_VIEW',
        sql='SELECT * FROM hive_catalog.data_mart.my_table'
    )
    
    # 4. Tạo reflection (optional)
    client.create_raw_reflection(dataset_id=result['id'])
    
finally:
    # 5. Luôn đóng session
    client.close()
```

### 5.2 Error Handling

`DremioClient` xử lý các edge cases:

| Tình huống | Xử lý tự động |
|---|---|
| View đã tồn tại | Xóa reflections → xóa view → tạo lại |
| Reflection đã tồn tại | Skip creation |
| Delete conflict (409) | Retry sau 3s với fresh tag |
| API timeout/500 | Retry 3 lần với backoff |

---

## 6. Troubleshooting

### 6.1 Không Kết Nối Được Dremio API

```
requests.exceptions.ConnectionError: Connection refused
```

**Giải pháp:**
- Verify Dremio pod đang Running: `kubectl get pods -n dremio`
- Kiểm tra port: `nc -zv <DREMIO_HOST> 9047`
- Kiểm tra Airflow Variable `dremio_host` đúng format (bao gồm http://)

### 6.2 Reflection Build Failed

**Giải pháp:**
- Kiểm tra source table còn tồn tại
- Kiểm tra schema không bị thay đổi đột ngột
- Kiểm tra resources: executor pods có đủ memory?
- Kiểm tra logs: `kubectl logs dremio-executor-0 -n dremio`

### 6.3 Query Chậm — Reflection Không Được Sử Dụng

**Kiểm tra:**
1. Jobs → click query → Query Profile → xem "Reflection matched"
2. Nếu không match:
   - Reflection columns có bao gồm tất cả columns trong query?
   - Reflection type đúng (raw vs aggregation)?
   - Reflection ở trạng thái ACTIVE?

### 6.4 View Creation Fails (409 Conflict)

```
requests.exceptions.HTTPError: 409 Conflict
```

**Giải pháp:**
- View đang bị lock bởi active query hoặc reflection refresh
- Đợi 30s và retry
- `DremioClient` đã xử lý tự động (retry sau 3s)

### 6.5 BI Tool Không Kết Nối Được

**Checklist:**
- [ ] Đúng port? (31010 JDBC, 32010 Arrow Flight)
- [ ] Firewall cho phép kết nối?
- [ ] Driver version tương thích?
- [ ] Username/password đúng?
- [ ] SSL setting khớp? (disable cho nội bộ)
