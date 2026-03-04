# Apache Polaris - Hướng Dẫn Sử Dụng

## Quản Lý Catalog

### Tạo Internal Catalog

Internal catalog được quản lý hoàn toàn bởi Polaris, hỗ trợ read/write:

```bash
# Lấy access token
TOKEN=$(curl -s -X POST http://polaris:8181/api/catalog/v1/oauth/tokens \
  -d "grant_type=client_credentials" \
  -d "client_id=root" \
  -d "client_secret=$POLARIS_SECRET" \
  -d "scope=PRINCIPAL_ROLE:ALL" | jq -r '.access_token')

# Tạo catalog cho Hanas Lakehouse
curl -s -X POST http://polaris:8181/api/management/v1/catalogs \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "catalog": {
      "name": "hanas_lakehouse",
      "type": "INTERNAL",
      "properties": {
        "default-base-location": "s3://data/warehouse/"
      },
      "storageConfigInfo": {
        "storageType": "S3",
        "allowedLocations": [
          "s3://data/warehouse/raw-vault",
          "s3://data/warehouse/business-vault",
          "s3://data/warehouse/information-mart",
          "s3://data/warehouse/landing"
        ],
        "s3": {
          "endpoint": "http://minio:9000",
          "region": "us-east-1",
          "pathStyleAccess": true
        }
      }
    }
  }' | jq .
```

### Liệt Kê Catalogs

```bash
curl -s http://polaris:8181/api/management/v1/catalogs \
  -H "Authorization: Bearer $TOKEN" | jq '.catalogs[].name'
```

### Xóa Catalog

```bash
# Phải xóa tất cả tables và namespaces trước
curl -s -X DELETE http://polaris:8181/api/management/v1/catalogs/test_catalog \
  -H "Authorization: Bearer $TOKEN"
```

---

## Quản Lý Namespace

Namespace tương tự database/schema trong RDBMS, dùng để tổ chức tables:

### Tạo Namespaces Theo Hanas Architecture

```bash
# Tạo namespace cho Raw Vault
curl -s -X POST http://polaris:8181/api/catalog/v1/hanas_lakehouse/namespaces \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "namespace": ["raw_vault"],
    "properties": {
      "description": "Raw Vault - Hub, Link, Satellite tables",
      "location": "s3://data/warehouse/raw-vault"
    }
  }' | jq .

# Tạo namespace cho Business Vault
curl -s -X POST http://polaris:8181/api/catalog/v1/hanas_lakehouse/namespaces \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "namespace": ["business_vault"],
    "properties": {
      "description": "Business Vault - PIT, Bridge, Business Satellite",
      "location": "s3://data/warehouse/business-vault"
    }
  }' | jq .

# Tạo namespace cho Information Mart
curl -s -X POST http://polaris:8181/api/catalog/v1/hanas_lakehouse/namespaces \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "namespace": ["information_mart"],
    "properties": {
      "description": "Information Mart - Star Schema, Wide Tables cho BI",
      "location": "s3://data/warehouse/information-mart"
    }
  }' | jq .
```

### Liệt Kê Namespaces

```bash
curl -s http://polaris:8181/api/catalog/v1/hanas_lakehouse/namespaces \
  -H "Authorization: Bearer $TOKEN" | jq .
```

### Nested Namespaces

Polaris hỗ trợ nested namespaces (up to 16 levels):

```bash
# Tạo nested namespace: raw_vault.hub
curl -s -X POST http://polaris:8181/api/catalog/v1/hanas_lakehouse/namespaces \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "namespace": ["raw_vault", "hub"],
    "properties": {
      "description": "Hub tables trong Raw Vault"
    }
  }' | jq .
```

---

## Quản Lý RBAC

### Tạo Principal

```bash
# Tạo principal cho Spark ETL
curl -s -X POST http://polaris:8181/api/management/v1/principals \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "principal": {
      "name": "spark-etl",
      "type": "SERVICE"
    }
  }' | jq .
# Response chứa client_id và client_secret — LƯU LẠI NGAY!

# Tạo principal cho Dremio
curl -s -X POST http://polaris:8181/api/management/v1/principals \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "principal": {
      "name": "dremio-query",
      "type": "SERVICE"
    }
  }' | jq .
```

### Tạo Principal Role

```bash
# Role cho data engineers
curl -s -X POST http://polaris:8181/api/management/v1/principal-roles \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "principalRole": {
      "name": "data_engineer"
    }
  }' | jq .

# Role cho BI readers
curl -s -X POST http://polaris:8181/api/management/v1/principal-roles \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "principalRole": {
      "name": "bi_reader"
    }
  }' | jq .
```

### Gán Principal Role Cho Principal

```bash
# Gán data_engineer role cho spark-etl
curl -s -X PUT http://polaris:8181/api/management/v1/principals/spark-etl/principal-roles \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "principalRole": {
      "name": "data_engineer"
    }
  }'

# Gán bi_reader role cho dremio-query
curl -s -X PUT http://polaris:8181/api/management/v1/principals/dremio-query/principal-roles \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "principalRole": {
      "name": "bi_reader"
    }
  }'
```

### Tạo Catalog Role và Grant Privileges

```bash
# Tạo catalog role: vault_writer
curl -s -X POST http://polaris:8181/api/management/v1/catalogs/hanas_lakehouse/catalog-roles \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "catalogRole": {
      "name": "vault_writer"
    }
  }' | jq .

# Grant privileges cho vault_writer
for PRIV in TABLE_WRITE_DATA TABLE_READ_DATA TABLE_CREATE TABLE_LIST NAMESPACE_CREATE NAMESPACE_LIST; do
  curl -s -X PUT \
    "http://polaris:8181/api/management/v1/catalogs/hanas_lakehouse/catalog-roles/vault_writer/grants" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"grant\": {
        \"catalogName\": \"hanas_lakehouse\",
        \"type\": \"catalog\",
        \"privilege\": \"$PRIV\"
      }
    }"
done

# Gán catalog role cho principal role
curl -s -X PUT \
  "http://polaris:8181/api/management/v1/principal-roles/data_engineer/catalog-roles/hanas_lakehouse" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "catalogRole": {
      "name": "vault_writer"
    }
  }'
```

### Tạo Read-Only Role Cho BI

```bash
# Tạo catalog role: mart_reader
curl -s -X POST http://polaris:8181/api/management/v1/catalogs/hanas_lakehouse/catalog-roles \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "catalogRole": {
      "name": "mart_reader"
    }
  }' | jq .

# Grant read-only privileges
for PRIV in TABLE_READ_DATA TABLE_LIST TABLE_READ_PROPERTIES NAMESPACE_LIST NAMESPACE_READ_PROPERTIES VIEW_LIST VIEW_READ_PROPERTIES; do
  curl -s -X PUT \
    "http://polaris:8181/api/management/v1/catalogs/hanas_lakehouse/catalog-roles/mart_reader/grants" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"grant\": {
        \"catalogName\": \"hanas_lakehouse\",
        \"type\": \"catalog\",
        \"privilege\": \"$PRIV\"
      }
    }"
done

# Gán catalog role cho bi_reader principal role
curl -s -X PUT \
  "http://polaris:8181/api/management/v1/principal-roles/bi_reader/catalog-roles/hanas_lakehouse" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "catalogRole": {
      "name": "mart_reader"
    }
  }'
```

---

## Sử Dụng Với Spark SQL

### Kết Nối Spark Với Polaris

```python
from pyspark.sql import SparkSession

spark = (SparkSession.builder
    .config("spark.jars.packages",
            "org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.9.0,"
            "org.apache.iceberg:iceberg-aws-bundle:1.9.0")
    .config("spark.sql.extensions",
            "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")

    # Polaris REST Catalog
    .config("spark.sql.catalog.polaris", "org.apache.iceberg.spark.SparkCatalog")
    .config("spark.sql.catalog.polaris.type", "rest")
    .config("spark.sql.catalog.polaris.uri", "http://polaris:8181/api/catalog")
    .config("spark.sql.catalog.polaris.credential", "<CLIENT_ID>:<CLIENT_SECRET>")
    .config("spark.sql.catalog.polaris.warehouse", "hanas_lakehouse")
    .config("spark.sql.catalog.polaris.scope", "PRINCIPAL_ROLE:ALL")
    .config("spark.sql.catalog.polaris.token-refresh-enabled", "true")
    .config("spark.sql.catalog.polaris.header.X-Iceberg-Access-Delegation",
            "vended-credentials")
    .config("spark.sql.catalog.polaris.io-impl",
            "org.apache.iceberg.io.ResolvingFileIO")

    .config("spark.sql.defaultCatalog", "polaris")
    .getOrCreate()
)
```

### Ví Dụ Spark SQL Operations

```sql
-- Liệt kê namespaces
SHOW NAMESPACES IN polaris;

-- Tạo bảng Hub (Raw Vault)
CREATE TABLE polaris.raw_vault.hub_customer (
    hub_customer_hashkey STRING,
    load_datetime TIMESTAMP,
    record_source STRING,
    customer_id STRING
) USING iceberg
PARTITIONED BY (days(load_datetime));

-- Insert dữ liệu
INSERT INTO polaris.raw_vault.hub_customer VALUES
('abc123hash', current_timestamp(), 'ORACLE_ERP', 'CUST001');

-- Query với time travel
SELECT * FROM polaris.raw_vault.hub_customer VERSION AS OF <snapshot_id>;

-- Schema evolution
ALTER TABLE polaris.raw_vault.hub_customer ADD COLUMN email STRING;

-- Table maintenance
CALL polaris.system.rewrite_data_files('raw_vault.hub_customer');
CALL polaris.system.expire_snapshots('raw_vault.hub_customer',
    TIMESTAMP '2024-01-01 00:00:00');
```

---

## Sử Dụng Với Dremio

### Truy Vấn Tables Từ Polaris Trong Dremio

Sau khi cấu hình Polaris làm data source trong Dremio (xem [configuration.md](configuration.md)):

```sql
-- Liệt kê tables từ Polaris source
SELECT * FROM polaris_lakehouse.raw_vault.hub_customer;

-- Tạo Virtual Dataset trên Polaris table
CREATE VDS DATA_MART.dim_customer AS
SELECT
    hub_customer_hashkey,
    customer_id,
    email
FROM polaris_lakehouse.raw_vault.hub_customer
WHERE load_datetime = (
    SELECT MAX(load_datetime)
    FROM polaris_lakehouse.raw_vault.hub_customer
);

-- Time travel qua Dremio
SELECT * FROM polaris_lakehouse.raw_vault.hub_customer
AT SNAPSHOT '<snapshot_id>';
```

---

## REST API Reference

### Base URLs

| API | Base URL | Mô tả |
|---|---|---|
| **Iceberg Catalog API** | `http://polaris:8181/api/catalog/v1` | Iceberg REST API (namespaces, tables, views) |
| **Management API** | `http://polaris:8181/api/management/v1` | Polaris management (catalogs, principals, roles) |
| **OAuth2** | `http://polaris:8181/api/catalog/v1/oauth/tokens` | Token endpoint |
| **Health** | `http://polaris:8182/q/health` | Health check |

### Các API Endpoints Chính

#### Catalog Management

| Method | Endpoint | Mô tả |
|---|---|---|
| `GET` | `/api/management/v1/catalogs` | List all catalogs |
| `POST` | `/api/management/v1/catalogs` | Create catalog |
| `GET` | `/api/management/v1/catalogs/{name}` | Get catalog |
| `PUT` | `/api/management/v1/catalogs/{name}` | Update catalog |
| `DELETE` | `/api/management/v1/catalogs/{name}` | Delete catalog |

#### Namespace Operations

| Method | Endpoint | Mô tả |
|---|---|---|
| `GET` | `/api/catalog/v1/{catalog}/namespaces` | List namespaces |
| `POST` | `/api/catalog/v1/{catalog}/namespaces` | Create namespace |
| `GET` | `/api/catalog/v1/{catalog}/namespaces/{ns}` | Get namespace |
| `DELETE` | `/api/catalog/v1/{catalog}/namespaces/{ns}` | Delete namespace |

#### Table Operations

| Method | Endpoint | Mô tả |
|---|---|---|
| `GET` | `/api/catalog/v1/{catalog}/namespaces/{ns}/tables` | List tables |
| `POST` | `/api/catalog/v1/{catalog}/namespaces/{ns}/tables` | Create table |
| `GET` | `/api/catalog/v1/{catalog}/namespaces/{ns}/tables/{table}` | Load table |
| `POST` | `/api/catalog/v1/{catalog}/namespaces/{ns}/tables/{table}` | Commit updates |
| `DELETE` | `/api/catalog/v1/{catalog}/namespaces/{ns}/tables/{table}` | Drop table |

#### Principal & Role Management

| Method | Endpoint | Mô tả |
|---|---|---|
| `GET` | `/api/management/v1/principals` | List principals |
| `POST` | `/api/management/v1/principals` | Create principal |
| `GET` | `/api/management/v1/principal-roles` | List principal roles |
| `POST` | `/api/management/v1/principal-roles` | Create principal role |
| `GET` | `/api/management/v1/catalogs/{catalog}/catalog-roles` | List catalog roles |
| `POST` | `/api/management/v1/catalogs/{catalog}/catalog-roles` | Create catalog role |

---

## Monitoring & Troubleshooting

### Health Checks

```bash
# Liveness check
curl -s http://polaris:8182/q/health/live | jq .

# Readiness check
curl -s http://polaris:8182/q/health/ready | jq .

# Full health
curl -s http://polaris:8182/q/health | jq .
```

### Logs

```bash
# Kubernetes logs
kubectl logs -f deployment/polaris -n polaris

# Tăng log level cho debug
kubectl set env deployment/polaris \
  QUARKUS_LOG_CATEGORY__ORG_APACHE_POLARIS__LEVEL=DEBUG \
  -n polaris
```

### Common Issues

| Vấn đề | Nguyên nhân | Giải pháp |
|---|---|---|
| `401 Unauthorized` | Token hết hạn hoặc credentials sai | Kiểm tra client_id/secret, request token mới |
| `403 Forbidden` | Thiếu privileges | Kiểm tra catalog role → principal role mapping |
| `404 Not Found` | Catalog/namespace/table không tồn tại | Verify tên entity chính xác |
| `409 Conflict` | Entity đã tồn tại | Dùng GET để verify trước khi create |
| `500 Internal Server Error` | Lỗi server (PostgreSQL connection, etc.) | Kiểm tra logs, PostgreSQL connectivity |
| Spark `NoSuchTableException` | Table không tồn tại hoặc credentials sai | Verify token, warehouse name, table path |
