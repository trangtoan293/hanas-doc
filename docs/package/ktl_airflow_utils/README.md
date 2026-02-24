# ktl_airflow_utils

Reusable Airflow utilities package for dbt + Spark + DataHub pipelines.

## Package Structure

```
package/ktl_airflow_utils/
├── __init__.py              # get_var, get_bool_var, get_json_var, MailerooClient, callbacks
├── airflow_vars.py          # Airflow Variable helpers with env fallback
├── maileroo.py              # Maileroo email client
├── callbacks.py             # Task lifecycle callbacks (on_failure, on_retry, on_success)
├── spark/
│   └── k8s.py               # create_spark_kubernetes_operator
├── datahub/
│   ├── __init__.py          # All exports
│   ├── publishers.py        # publish_dbt_to_datahub, publish_iceberg_from_catalog, etc.
│   └── utils.py             # URN builders, API helpers, lineage helpers
└── taskgroups/
    ├── __init__.py          # All taskgroup exports
    ├── dbt_spark.py         # create_dbt_spark_taskgroup, create_dbt_etl_taskgroup, create_dbt_step_taskgroup
    ├── datahub_publish.py   # create_publish_to_datahub_taskgroup, create_unified_publish_to_datahub_taskgroup
    └── notifications.py     # create_maileroo_notification_group
```

## Quick Start

```python
from package.ktl_airflow_utils.airflow_vars import get_var
from package.ktl_airflow_utils.taskgroups import (
    create_dbt_etl_taskgroup,
    create_unified_publish_to_datahub_taskgroup,
    create_maileroo_notification_group,
)

with DAG(...) as dag:
    # ETL taskgroup: load -> test -> logging
    etl = create_dbt_etl_taskgroup(
        "raw_vault_etl",
        dag=dag,
        dbt_select="integration.raw_vault",
        full_refresh=True,
    )
    
    # Publish to DataHub
    publish = create_unified_publish_to_datahub_taskgroup(
        group_id="publish_datahub",
        run_prefix_value="dbt-artifacts/run",
        test_prefix_value="dbt-artifacts/test",
        run_artifacts_suffix="raw_vault/run",
        test_artifacts_suffix="raw_vault/test",
        dag=dag,
    )
    
    # Notification
    notify = create_maileroo_notification_group("notification", dag=dag)
    
    etl >> publish >> notify
```

## TaskGroups

### `create_dbt_spark_taskgroup`
Simple dbt run taskgroup using Spark on Kubernetes.

### `create_dbt_etl_taskgroup`
Full ETL taskgroup with separate run/test artifact folders:
- `load_job` → `test_job` → `logging_job`
- Artifact structure: `<group_id>/run/` and `<group_id>/test/`

### `create_dbt_step_taskgroup`
Generic pipeline step with configurable artifact base:
- Use `artifacts_base="mdm_etl_job"` for MDM pipelines
- Use `artifacts_base="daily_pipeline"` for custom pipelines

### `create_unified_publish_to_datahub_taskgroup`
4-step DataHub publishing:
1. `extract_dbt_catalog` - Validate/rebuild catalog.json
2. `publish_dbt_transformation` - Publish dbt metadata + lineage
3. `publish_iceberg_metadata` - Publish Iceberg schemas
4. `publish_dbt_tests` - Publish test assertions

### `create_maileroo_notification_group`
Email notification via Maileroo API on DAG success/failure.

## DataHub Utilities

```python
from package.ktl_airflow_utils.datahub import (
    build_iceberg_urn,
    build_dremio_urn,
    emit_upstream_lineage,
    graphql_query,
    make_s3_client,
)

# Build URNs
urn = build_iceberg_urn("demo", "integration", "hub_customer")

# Emit lineage
emit_upstream_lineage(
    gms_host="http://datahub:8080",
    downstream_urn=downstream,
    upstream_urns=[upstream1, upstream2],
    token="...",
)
```

## Configuration

When this package needs configuration values, it uses `get_var(...)`:

1. Try **Airflow Variables** (`Variable.get(name)`)
2. Fallback to **environment variables** (`os.environ[name]`)
3. Fallback to provided default

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATAHUB_GMS_HOST` | DataHub GMS URL | `http://datahub-gms:8080` |
| `MAILEROO_API_KEY` | Maileroo API key | `...` |
| `SENDER_EMAIL` | Email sender address | `no-reply@example.com` |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATAHUB_TOKEN` | `""` | DataHub bearer token |
| `DATAHUB_ENV` | `PROD` | Environment for URNs |
| `DATAHUB_PLATFORM_INSTANCE` | `demo` | dbt platform instance |
| `DATAHUB_ICEBERG_PLATFORM_INSTANCE` | `LakeHouse` | Iceberg platform instance |
| `DATAHUB_ASSET_TAG_NAME` | `data platform demo` | Tag for ingested assets |
| `DBT_ARTIFACTS_BUCKET` | `data` | S3 bucket for dbt artifacts |
| `DBT_ARTIFACTS_PREFIX` | `dbt-artifacts/{{ dag_run.run_id }}` | Artifact prefix |
| `DEFAULT_NOTIFICATION_EMAIL` | `""` | Default email recipient |
| `AIRFLOW_BASE_URL` | `""` | Airflow webserver URL for email links |

### AWS / S3 Variables

| Variable | Description |
|----------|-------------|
| `AWS_ENDPOINT_URL` | S3-compatible endpoint (e.g., MinIO) |
| `AWS_DEFAULT_REGION` | AWS region |
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `AWS_SESSION_TOKEN` | AWS session token |

## Expected Artifacts in S3

The publishing code expects these objects:

```
s3://$DBT_ARTIFACTS_BUCKET/$prefix/manifest.json
s3://$DBT_ARTIFACTS_BUCKET/$prefix/run_results.json
s3://$DBT_ARTIFACTS_BUCKET/$prefix/catalog.json
```

## Airflow Ignore

This package must be excluded from DAG parsing. Add to `dags/.airflowignore`:

```
package/ktl_airflow_utils/.*
package/ktl_airflow_utils
```
