# Code Example: Spark Job Mẫu — Iceberg Operations

> **Lưu ý**: Ví dụ dựa trên `airfow/dags/utils/iceberg_table_manager.py` thực tế.

---

## 1. IcebergTableManager Class (Production)

```python
# dags/utils/iceberg_table_manager.py
import logging
from typing import Dict, Any, List, Optional
import json
import uuid
from datetime import datetime

import pyarrow as pa
import pandas as pd
import numpy as np
from pyiceberg.catalog import load_catalog
from pyiceberg.partitioning import PartitionSpec
from pyiceberg.transforms import DayTransform, IdentityTransform


class IcebergTableManager:
    """Apache Iceberg table management — production pattern"""

    def __init__(self, catalog_config: Dict[str, str], output_bucket: str = "data"):
        self.catalog_config = catalog_config
        self.catalog = None
        self.OUTPUT_BUCKET = output_bucket
        self.partition_spec = PartitionSpec()

    def initialize_catalog(self):
        """Initialize Iceberg catalog connection"""
        self.catalog = load_catalog("minio_catalog", **self.catalog_config)
        logging.info("Iceberg catalog initialized successfully")

    def create_table_if_not_exists(
        self,
        namespace: str,
        table_name: str,
        schema: pa.Schema,
    ):
        """Create Iceberg table nếu chưa tồn tại"""
        table_identifier = f"{namespace}.{table_name}"
        try:
            table = self.catalog.load_table(table_identifier)
            logging.info(f"Table {table_identifier} already exists")
            return table
        except Exception:
            logging.info(f"Creating new table: {table_identifier}")
            table = self.catalog.create_table(
                identifier=table_identifier,
                schema=schema,
                location=f"s3a://{self.OUTPUT_BUCKET}/warehouse/{namespace}/{table_name}",
                partition_spec=self.partition_spec,
            )
            return table

    def insert_data(
        self,
        df: pd.DataFrame,
        namespace: str,
        table_name: str,
    ):
        """Insert pandas DataFrame vào Iceberg table"""
        table_identifier = f"{namespace}.{table_name}"
        table = self.catalog.load_table(table_identifier)

        # Normalize dtypes
        df['inserted_date'] = pd.Timestamp.utcnow().replace(tzinfo=None)
        for col in df.columns:
            if df[col].dtype == "datetime64[ns]":
                df[col] = df[col].astype("datetime64[ms]")
            elif df[col].dtype == "int64":
                df[col] = df[col].astype(np.int32)

        arrow_table = pa.Table.from_pandas(df)
        table.append(arrow_table)
        logging.info(f"Inserted {len(df)} rows into {table_identifier}")
```

---

## 2. Sử Dụng: Oracle → Iceberg

```python
# Pattern: Đọc từ Oracle, ghi vào Iceberg (từ production)
import oracledb

def write_to_iceberg_table(
    dsn: str,
    user: str,
    password: str,
    table_name_oracle: str,
    schema_oracle: str,
    ICEBERG_CATALOG_CONFIG: dict,
):
    """Oracle → Iceberg full load"""
    conn = oracledb.connect(user=user, password=password, dsn=dsn)
    query = f"SELECT * FROM {schema_oracle}.{table_name_oracle}"

    # Get Oracle schema & convert to Iceberg schema
    schema_oracle_table = get_schema_from_oracle(table_name_oracle, schema_oracle)
    schema_iceberg = convert_schema(schema_oracle_table)

    # Create/get Iceberg table
    manager = IcebergTableManager(catalog_config=ICEBERG_CATALOG_CONFIG)
    manager.initialize_catalog()
    table = manager.create_table_if_not_exists(
        namespace="integration",
        table_name=table_name_oracle,
        schema=schema_iceberg,
    )

    # Read & write
    df = pd.read_sql(query, conn)
    df.columns = [col.lower() for col in df.columns]

    for col in df.columns:
        if df[col].dtype == "datetime64[ns]":
            df[col] = df[col].astype("datetime64[ms]")
        elif df[col].dtype == "int64":
            df[col] = df[col].astype(np.int32)

    arrow_table = pa.Table.from_pandas(df)
    table.append(arrow_table)

    logging.info(f"Loaded {len(df)} rows from Oracle.{schema_oracle}.{table_name_oracle}")
```

---

## 3. Catalog Config (cho PyIceberg)

```python
ICEBERG_CATALOG_CONFIG = {
    "uri": "thrift://hive-metastore:9083",          # Hive Metastore
    "s3.endpoint": "http://minio:9000",
    "s3.access-key-id": os.environ["AWS_ACCESS_KEY_ID"],
    "s3.secret-access-key": os.environ["AWS_SECRET_ACCESS_KEY"],
    "s3.path-style-access": "true",
    "warehouse": "s3a://data/warehouse/",
}
```

---

## 4. PySpark Job: Raw Vault Load

```python
# spark_jobs/load_raw_vault.py
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--entity', required=True)
parser.add_argument('--date', required=True)
args = parser.parse_args()

spark = SparkSession.builder \
    .appName(f"load-{args.entity}-{args.date}") \
    .enableHiveSupport() \
    .getOrCreate()

# Đọc landing data
df_landing = spark.read.format("iceberg").load(
    f"demo.landing.{args.entity}"
).filter(col("dv_kaf_ldt") >= args.date)

if args.entity.startswith("hub_"):
    # Hub: MERGE chỉ insert key mới
    df_landing.createOrReplaceTempView("staging")
    spark.sql(f"""
        MERGE INTO demo.integration.{args.entity} AS target
        USING staging AS source
        ON target.{args.entity}_hk = source.{args.entity}_hk
        WHEN NOT MATCHED THEN INSERT *
    """)

elif args.entity.startswith("sat_") or args.entity.startswith("lsat_"):
    # Satellite: APPEND (full history, change detection bằng hash)
    df_landing.writeTo(f"demo.integration.{args.entity}").append()

elif args.entity.startswith("lnk_"):
    # Link: MERGE (similar to Hub)
    df_landing.createOrReplaceTempView("staging")
    spark.sql(f"""
        MERGE INTO demo.integration.{args.entity} AS target
        USING staging AS source
        ON target.{args.entity}_hk = source.{args.entity}_hk
        WHEN NOT MATCHED THEN INSERT *
    """)

print(f"Loaded {df_landing.count()} rows into {args.entity}")
spark.stop()
```

---

## 5. Best Practices

| Practice | Chi tiết |
|---|---|
| **PyIceberg cho ETL ngoài Spark** | Table management, schema tạo trước |
| **Spark cho xử lý lớn** | MERGE, aggregation, joins |
| **Hive Metastore catalog** | Metadata tập trung, shared giữa Spark/dbt/Dremio |
| **Normalize dtypes** | `datetime64[ms]`, `int32` trước khi ghi |
| **`lowercase` column names** | Oracle returns UPPERCASE → lowercase cho consistency |
| **Append cho Satellite** | Full history, không overwrite |
| **MERGE cho Hub/Link** | Idempotent, no duplicate keys |
