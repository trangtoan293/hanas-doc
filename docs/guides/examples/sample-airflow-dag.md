# Code Example: Airflow DAG Mẫu — Spark-on-Kubernetes + dbt

> **Lưu ý**: Code dưới đây trích từ codebase thực tế (`airfow/dags/`).
> Pattern chính: `SparkKubernetesOperator` + reusable `TaskGroup` + dbt trên Spark.

---

## 1. DAG Production: Incremental Data Vault Pipeline

### 1.1 Execution Flow

```
start → build_vw_ref_eod → [raw_vault TaskGroup] → [data_mart TaskGroup] → end → notification
```

Mỗi TaskGroup gồm:
```
┌──────────────── TaskGroup: raw_vault ─────────────────────────┐
│                                                                │
│  ┌── load_and_logging ──┐   ┌── publish_datahub ────────────┐ │
│  │                       │   │                                │ │
│  │  load_job             │   │  extract_dbt_catalog           │ │
│  │     ↓                 │   │     ↓                          │ │
│  │  test_job             │──▶│  publish_dbt_transformation    │ │
│  │     ↓                 │   │     ↓                          │ │
│  │  logging_job          │   │  publish_iceberg_metadata      │ │
│  │                       │   │     ↓                          │ │
│  └───────────────────────┘   │  publish_dbt_tests             │ │
│                               └────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

### 1.2 DAG Code (Incremental)

```python
# dags/raw_vault/demo_data_pipeline_e2e_incremental.py
from __future__ import annotations

import json
import os
from datetime import timedelta
from typing import Dict, List, Optional

import pendulum
from airflow import DAG
from airflow.models import Variable
from airflow.models.param import Param
from airflow.operators.empty import EmptyOperator
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import (
    SparkKubernetesOperator,
)

from raw_vault.taskgroups.dbt_etl_jobs_taskgroup import create_dbt_etl_jobs_taskgroup
from taskgroups.maileroo_groups import maileroo_notification_group
from utils.callbacks import (
    on_failure_callback, on_retry_callback,
    on_success_callback, sla_miss_callback,
)


def _var(name: str, default: Optional[str] = None) -> Optional[str]:
    """Safe Variable.get with fallback"""
    try:
        value = Variable.get(name)
        return value if value != "" else default
    except KeyError:
        return default


# ── Default Args ──
default_args = {
    "owner": "data-engineering",
    "depends_on_past": False,
    "start_date": pendulum.datetime(2024, 1, 1, tz="UTC"),
    "email_on_failure": True,
    "email_on_retry": False,
    "retries": 3,
    "retry_delay": timedelta(seconds=15),
    "catchup": False,
    "sla": timedelta(hours=2),
    "on_retry_callback": on_retry_callback,
    "on_failure_callback": on_failure_callback,
}

# ── Configurable Groups ──
# Override via Airflow Variable DEMO_DATA_PIPELINE_E2E_INCREMENTAL_GROUPS (JSON)
DEFAULT_GROUPS: List[Dict[str, str]] = [
    {"group_id": "raw_vault",  "dbt_select": "integration.raw_vault"},
    {"group_id": "data_mart",  "dbt_select": "data_mart"},
]

groups_raw = _var("DEMO_DATA_PIPELINE_E2E_INCREMENTAL_GROUPS", "")
GROUPS = DEFAULT_GROUPS
if groups_raw:
    try:
        parsed = json.loads(groups_raw)
        validated = [e for e in parsed if e.get("group_id") and e.get("dbt_select")]
        if validated:
            GROUPS = validated
    except json.JSONDecodeError:
        pass


# ── DAG Definition ──
with DAG(
    dag_id="demo_data_pipeline_e2e_incremental",
    default_args=default_args,
    schedule_interval=None,         # Triggered manually or by external scheduler
    catchup=False,
    max_active_runs=1,
    tags=["dbt", "spark", "kubernetes", "raw_vault", "data_mart", "incremental"],
    params={
        "cob_date": Param(default=None, type=["null", "string"]),
        "eod_ref_model": Param(default=None, type=["null", "string"]),
        "notification_email": Param(
            default=None, type=["null", "string"],
            description="Recipient email for DAG run notifications.",
        ),
    },
    template_searchpath=[os.path.join(os.path.dirname(__file__), "k8s")],
    sla_miss_callback=sla_miss_callback,
) as dag:

    start = EmptyOperator(task_id="start")
    end = EmptyOperator(
        task_id="end",
        trigger_rule="all_done",
        on_success_callback=on_success_callback,
    )

    # ── Step 1: Build EOD reference view (always full refresh) ──
    eod_view_job = SparkKubernetesOperator(
        task_id="build_vw_ref_eod",
        namespace="spark-jobs",
        application_file="dbt-runner.yaml",     # K8s YAML template
        random_name_suffix=True,
        kubernetes_conn_id="k8s_conn_id",
        dag=dag,
        params={
            "dbt_select": "vw_ref_eod",
            "full_refresh": True,
            "artifacts_suffix": "vw_ref_eod",
        },
    )

    start >> eod_view_job

    # ── Step 2: Chain dbt ETL taskgroups ──
    upstream = eod_view_job
    asset_tag_name = _var("DATAHUB_ASSET_TAG_NAME", "data platform demo")

    for group in GROUPS:
        select = group["dbt_select"]
        # Exclude backdate tables từ data_mart incremental
        if "data_mart" in select:
            select = f"{select} --exclude *_backdate"

        taskgroup = create_dbt_etl_jobs_taskgroup(
            group["group_id"],
            dbt_select=select,
            full_refresh=False,
            dag=dag,
            load_job_task_id="data_incre_load_job",
            asset_tag_name=asset_tag_name,
        )
        upstream >> taskgroup
        upstream = taskgroup

    upstream >> end

    # ── Step 3: Email notification (Maileroo) ──
    notification = maileroo_notification_group("notification", dag=dag)
    end >> notification
```

---

## 2. DAG: Initial Load (Full Refresh)

```python
# dags/raw_vault/demo_data_pipeline_e2e_init.py
with DAG(
    dag_id="demo_data_pipeline_e2e_init",
    default_args=default_args,
    schedule_interval=None,
    description="Reusable dbt taskgroups (full refresh)",
    catchup=False,
    max_active_runs=1,
    tags=["dbt", "spark", "kubernetes", "raw_vault", "data_mart", "data_init"],
    params={
        "notification_email": Param(default=None, type=["null", "string"]),
    },
    template_searchpath=[os.path.join(os.path.dirname(__file__), "k8s")],
) as dag:
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end", trigger_rule="all_done")

    eod_view_job = SparkKubernetesOperator(
        task_id="build_vw_ref_eod",
        namespace="spark-jobs",
        application_file="dbt-runner.yaml",
        random_name_suffix=True,
        kubernetes_conn_id="k8s_conn_id",
        dag=dag,
        params={
            "dbt_select": "vw_ref_eod",
            "full_refresh": True,
            "artifacts_suffix": "vw_ref_eod",
        },
    )

    asset_tag_name = _var("DATAHUB_ASSET_TAG_NAME", "data platform demo")

    # Raw Vault = full refresh
    taskgroup_1 = create_dbt_etl_jobs_taskgroup(
        "raw_vault_etl_job",
        dbt_select="integration.raw_vault",
        full_refresh=True,            # ← Full refresh cho init
        dag=dag,
        load_job_task_id="raw_vault_init_load_job",
        logging_job_task_id="raw_vault_init_logging_job",
        asset_tag_name=asset_tag_name,
    )

    # Data Mart = full refresh, exclude backdate
    taskgroup_1a = create_dbt_etl_jobs_taskgroup(
        "data_mart_etl_job",
        dbt_select="data_mart --exclude *_backdate",
        full_refresh=True,
        dag=dag,
        load_job_task_id="data_mart_init_load_job",
        logging_job_task_id="data_mart_init_logging_job",
        asset_tag_name=asset_tag_name,
    )

    start >> eod_view_job >> taskgroup_1 >> taskgroup_1a >> end

    notification = maileroo_notification_group("notification", dag=dag)
    end >> notification
```

---

## 3. DAG: MDM Pipeline (Incremental)

```python
# dags/raw_vault/demo_mdm_pipeline_e2e_incremental.py
from raw_vault.taskgroups.dbt_etl_jobs_taskgroup import create_mdm_step_taskgroup

# MDM steps chạy tuần tự, mỗi step = load → test → publish
MDM_STEPS = [
    ("mdm_source",    "mdm.mdm_source_corecif"),
    ("mdm_cleansed",  "mdm.mdm_corecif_cleansed"),
    ("mdm_validated", "mdm.mdm_corecif_validate mdm.mdm_corecif_invalid"),
    ("mdm_match",     "mdm.mdm_corecif_match"),
    ("mdm_merge",     "mdm.mdm_corecif_merge"),
    ("mdm_golden",    "mdm.mdm_corecif_golden_records"),
]

with DAG(
    dag_id="demo_mdm_pipeline_e2e_incremental",
    default_args=default_args,
    schedule_interval=None,
    description="MDM incremental pipeline with per-step load/test/publish",
    max_active_runs=1,
    tags=["dbt", "spark", "kubernetes", "mdm", "incremental"],
    params={
        "cob_date": Param(default=None, type=["null", "string"]),
        "eod_ref_model": Param(default=None, type=["null", "string"]),
        "notification_email": Param(default=None, type=["null", "string"]),
    },
    template_searchpath=[os.path.join(os.path.dirname(__file__), "k8s")],
) as dag:
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end", trigger_rule="all_done")

    eod_view_job = SparkKubernetesOperator(
        task_id="build_vw_ref_eod",
        namespace="spark-jobs",
        application_file="dbt-runner.yaml",
        random_name_suffix=True,
        kubernetes_conn_id="k8s_conn_id",
        dag=dag,
        params={"dbt_select": "vw_ref_eod", "full_refresh": True, "artifacts_suffix": "vw_ref_eod"},
    )

    # Chain MDM steps sequentially
    upstream = eod_view_job
    asset_tag_name = _var("DATAHUB_ASSET_TAG_NAME", "data platform demo")
    for step_id, dbt_select in MDM_STEPS:
        step_taskgroup = create_mdm_step_taskgroup(
            group_id=step_id,
            dbt_select=dbt_select,
            full_refresh=False,       # Incremental mode
            dag=dag,
            asset_tag_name=asset_tag_name,
        )
        upstream >> step_taskgroup
        upstream = step_taskgroup

    start >> eod_view_job
    upstream >> end

    notification = maileroo_notification_group("notification", dag=dag)
    end >> notification
```

```
MDM Pipeline Flow:
start → build_vw_ref_eod → mdm_source → mdm_cleansed → mdm_validated
                                                              ↓
notification ← end ←── mdm_golden ←── mdm_merge ←── mdm_match
```

---

## 4. DAG: Ad-hoc dbt ETL

```python
# dags/raw_vault/dbt_adhoc_etl.py
with DAG(
    dag_id="dbt_adhoc_etl",
    default_args=default_args,
    schedule_interval=None,    # Manual trigger only
    catchup=False,
    max_active_runs=1,
    tags=["dbt", "raw_vault", "spark", "kubernetes"],
    sla_miss_callback=sla_miss_callback,
    params={
        "dbt_select": Param(description="Space-separated dbt selectors", type="string"),
        "full_refresh": Param(default=False, type="boolean"),
        "notification_email": Param(default=None, type=["null", "string"]),
    },
    template_searchpath=[os.path.join(os.path.dirname(__file__), "k8s")],
) as dag:
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end", trigger_rule="all_done")

    asset_tag_name = _var("DATAHUB_ASSET_TAG_NAME", "data platform demo")

    # Sử dụng cùng reusable TaskGroup
    adhoc_etl_job = create_dbt_etl_jobs_taskgroup(
        "adhoc_etl_job",
        dbt_select="{{ params.dbt_select }}",   # Templated from DAG params
        full_refresh=False,
        dag=dag,
        load_job_task_id="load_job",
        logging_job_task_id="logging_job",
        asset_tag_name=asset_tag_name,
    )

    start >> adhoc_etl_job >> end

    notification = maileroo_notification_group("notification", dag=dag)
    end >> notification
```

---

## 5. DAG: Backfill ETL Pipeline

```python
# dags/backfill/backfill_etl_dag.py
import yaml
from pathlib import Path

# Load config từ YAML file
config_path = Path(__file__).parent / "config" / "backfill_config.yaml"
with open(config_path, 'r') as f:
    config = yaml.safe_load(f)

DATE_CONFIG = config['date_range']
RAW_VAULT_CONFIG = config['dbt_raw_vault']
DATA_MART_CONFIG = config['dbt_data_mart']

with DAG(
    dag_id="backfill_etl_pipeline",
    default_args=default_args,
    schedule_interval=None,
    max_active_runs=1,
    tags=["backfill", "spark", "dbt"],
    params={
        "start_date": DATE_CONFIG['start_date'],
        "end_date": DATE_CONFIG['end_date'],
        # Spark resource overrides
        "backfill_sql_driver_cores": 3,
        "backfill_sql_driver_memory": "6g",
        "backfill_sql_executor_cores": 3,
        "backfill_sql_executor_memory": "4g",
        "backfill_sql_executor_instances": 3,
    },
    template_searchpath=[os.path.join(os.path.dirname(__file__), "k8s")],
) as dag:
    start = EmptyOperator(task_id="start")

    # Step 1: Fix source data
    fix_dr_cr_flag = SparkKubernetesOperator(
        task_id="fix_dr_cr_flag",
        namespace="spark-jobs",
        application_file="backfill-spark-sql-fix.yaml",
        random_name_suffix=True,
        kubernetes_conn_id="k8s_conn_id",
    )

    # Step 2: Delete old raw vault data
    delete_raw_vault_data = SparkKubernetesOperator(
        task_id="delete_raw_vault_data",
        namespace="spark-jobs",
        application_file="backfill-spark-sql-delete.yaml",
        random_name_suffix=True,
        kubernetes_conn_id="k8s_conn_id",
    )

    # Step 3: Rebuild raw vault with dbt
    rebuild_raw_vault = SparkKubernetesOperator(
        task_id="rebuild_raw_vault",
        namespace="spark-jobs",
        application_file="spark-dbt-backfill-rawvault-run.yaml",
        random_name_suffix=True,
        kubernetes_conn_id="k8s_conn_id",
        params={
            "dbt_select": " ".join(RAW_VAULT_CONFIG['models']),
            "dbt_full_refresh": "true",
        },
    )

    # Step 4: Rebuild data mart
    rebuild_data_mart = SparkKubernetesOperator(
        task_id="rebuild_data_mart",
        namespace="spark-jobs",
        application_file="spark-dbt-backfill-datamart-run.yaml",
        random_name_suffix=True,
        kubernetes_conn_id="k8s_conn_id",
        params={
            "dbt_select": " ".join(DATA_MART_CONFIG['models']),
            "dbt_vars": f"backfill_start_date: '{DATE_CONFIG['start_date']}'",
        },
    )

    end = EmptyOperator(task_id="end", trigger_rule="all_done")

    start >> fix_dr_cr_flag >> delete_raw_vault_data >> rebuild_raw_vault >> rebuild_data_mart >> end
```

---

## 6. DAG: Backdate with Dremio Integration

```python
# dags/backdate/backdate_etl_dag.py
from utils.dremio_client import DremioClient

# Load Dremio config from Airflow Variables
DREMIO_CONFIG = {
    'base_url': Variable.get('dremio_host') + ':9047',
    'username': Variable.get('dremio_username'),
    'password': Variable.get('dremio_password'),
    'space': Variable.get('dremio_space', default_var='DATA_MART'),
}


def create_dremio_views(**context):
    """Create views in Dremio using REST API."""
    client = DremioClient(base_url=DREMIO_CONFIG['base_url'], ...)
    client.login()
    for view_config in VIEWS_CONFIG:
        sql = open(sql_dir / view_config['sql_file']).read()
        result = client.create_vds(space=DREMIO_CONFIG['space'], view_name=view_config['name'], sql=sql)
        context['ti'].xcom_push(key=f"{view_config['name']}_id", value=result['id'])


with DAG(dag_id="backdate_etl_pipeline", schedule_interval=None, ...) as dag:
    start = EmptyOperator(task_id="start")

    # Step 1: Create Iceberg table via Spark
    create_backdate_table = SparkKubernetesOperator(
        task_id="create_backdate_table",
        application_file="backdate-spark-job.yaml",
        ...
    )

    # Step 2: Run dbt backdate models
    run_dbt_backdate_models = SparkKubernetesOperator(
        task_id="run_dbt_backdate_models",
        application_file="spark-dbt-backdate-run.yaml",
        ...
    )

    # Step 3: Create Dremio views via API
    create_views = PythonOperator(
        task_id="create_dremio_views",
        python_callable=create_dremio_views,
    )

    end = EmptyOperator(task_id="end", trigger_rule="all_done")

    start >> create_backdate_table >> run_dbt_backdate_models >> end
```

---

## 7. Reusable TaskGroup Pattern

### 7.1 ETL TaskGroup (load → test → logging → publish)

```python
# dags/raw_vault/taskgroups/dbt_etl_jobs_taskgroup.py

def create_dbt_etl_jobs_taskgroup(
    group_id: str,
    *,
    dbt_select: str,
    full_refresh: bool,
    dag=None,
    ref_eod_table: Optional[str] = None,
    load_job_task_id: str = "load_job",
    logging_job_task_id: str = "logging_job",
    dbt_exclude: Optional[str] = None,
    asset_tag_name: Optional[str] = None,
) -> TaskGroup:
    """
    Artifact structure (trên MinIO):
        dbt-artifacts/<run_id>/<group_id>/run/   ← dbt run artifacts
        dbt-artifacts/<run_id>/<group_id>/test/  ← dbt test artifacts
    """
    run_suffix = f"{group_id}/run"
    test_suffix = f"{group_id}/test"

    with TaskGroup(group_id=group_id, dag=dag) as tg:
        # Sub-group: load → test → logging
        load_and_logging = _create_load_test_logging_subgroup(
            dbt_select=dbt_select,
            full_refresh=full_refresh,
            run_suffix=run_suffix,
            test_suffix=test_suffix,
            ...
        )

        # Unified publish: catalog → dbt transform → iceberg metadata → dbt tests
        publish_datahub = create_unified_publish_to_datahub_taskgroup(
            run_prefix_value=f"dbt-artifacts/{{{{ dag_run.run_id }}}}/{run_suffix}",
            test_prefix_value=f"dbt-artifacts/{{{{ dag_run.run_id }}}}/{test_suffix}",
            asset_tag_name=asset_tag_name,
            ...
        )

        load_and_logging >> publish_datahub

    return tg
```

### 7.2 Load/Test/Logging Sub-group

```python
def _create_load_test_logging_subgroup(...) -> TaskGroup:
    with TaskGroup(group_id="load_and_logging", dag=dag) as tg:
        # Load job - dbt run → /run folder
        load_job = SparkKubernetesOperator(
            task_id=load_job_task_id,
            application_file="dbt-runner.yaml",
            params={
                "dbt_select": dbt_select,
                "full_refresh": full_refresh,
                "artifacts_suffix": run_suffix,
            },
        )

        # Test job - dbt test → /test folder (separate artifacts)
        test_job = SparkKubernetesOperator(
            task_id="test_job",
            application_file="dbt-test.yaml",
            retries=0,                            # No retry for tests
            on_failure_callback=on_failure_callback,
            params={
                "dbt_select": dbt_select,
                "artifacts_suffix": test_suffix,
            },
        )

        # Logging job - ETL metrics → LakeHouse.etladmin tables
        logging_job = SparkKubernetesOperator(
            task_id=logging_job_task_id,
            application_file="dbt-logger.yaml",
            trigger_rule="all_done",              # Run even if test fails
            params={"artifacts_suffix": run_suffix},
        )

        load_job >> test_job >> logging_job

    return tg
```

---

## 8. Callback Pattern (Production)

```python
# dags/utils/callbacks.py

def on_failure_callback(context: Dict[str, Any]):
    """Send Slack/Teams notification on task failure."""
    from utils.notification_service import NotificationService

    task = context.get('task')
    task_id = task.task_id if task else 'unknown'
    dag_id = context.get('dag').dag_id if context.get('dag') else 'unknown'
    exception = context.get('exception')

    message = f"Task `{task_id}` in DAG `{dag_id}` failed."
    if exception:
        message += f"\nError: {str(exception)[:200]}"

    # Channels configurable via Airflow Variable
    immediate_channels_str = Variable.get("IMMEDIATE_ALERT_CHANNELS", default_var='["slack"]')
    try:
        immediate_channels = json.loads(immediate_channels_str)
    except Exception:
        immediate_channels = ["slack"]

    NotificationService().notify(
        context=context, status='FAILED',
        message=message, failed_tasks=task_id,
        channels=immediate_channels,
    )


def on_retry_callback(context: Dict[str, Any]):
    """Alert on retry with attempt count."""
    from utils.notification_service import NotificationService

    ti = context.get('task_instance')
    task_id = context.get('task').task_id
    message = f"Task `{task_id}` retrying (attempt {ti.try_number}/{ti.max_tries})"

    retry_channels_str = Variable.get("RETRY_ALERT_CHANNELS", default_var='["slack"]')
    channels = json.loads(retry_channels_str)
    NotificationService().notify(context=context, status='RETRYING', message=message, channels=channels)


def on_success_callback(context: Dict[str, Any]):
    """Log success, optionally notify (disabled by default to reduce noise)."""
    if Variable.get("NOTIFY_ON_TASK_SUCCESS", default_var="false").lower() == "true":
        NotificationService().notify(context=context, status='TASK_SUCCESS', channels=["slack"])


def sla_miss_callback(dag, task_list, blocking_task_list, slas, blocking_tis):
    """Alert when DAG misses SLA deadline (2 hours default)."""
    NotificationService().notify_sla_breach(dag_id=dag.dag_id, slas=slas)
```

---

## 9. K8s YAML Template Example

```yaml
# dags/raw_vault/k8s/dbt-runner.yaml (simplified)
apiVersion: "sparkoperator.k8s.io/v1beta2"
kind: SparkApplication
metadata:
  name: dbt-run-rawvault
  namespace: spark-jobs
spec:
  type: Python
  mode: cluster
  image: "trangtoan293/dbt-spark-k8s-ktl:ktl-dbt"
  mainApplicationFile: "local:///opt/spark/work-dir/dbt-project/dbt-project/dbt_runner.py"
  arguments:
    - "--use-subprocess"
    - "--dbt-command"
    - "ktl_dbt"
    - "--upload-artifacts"
    - "--s3-bucket"
    - "data"
    - "run"
    - "--target"
    - "dev"
    {% if params.full_refresh %}
    - "--full-refresh"
    {% endif %}
    {% if params.dbt_select %}
    - "--select"
    {% for tok in params.dbt_select.split(' ') if tok %}
    - "{{ tok }}"
    {% endfor %}
    {% endif %}

  sparkVersion: "3.5.1"
  sparkConf:
    spark.sql.extensions: "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"
    spark.sql.catalog.demo: "org.apache.iceberg.spark.SparkCatalog"
    spark.sql.catalog.demo.type: "hive"
    spark.sql.defaultCatalog: "demo"

  driver:
    cores: 3
    memory: "5g"
    serviceAccount: spark
    initContainers:
      - name: git-sync
        image: registry.k8s.io/git-sync/git-sync:v4.1.0
        envFrom:
          - configMapRef:
              name: git-sync-config
    envFrom:
      - secretRef:
          name: spark-k8s-aws-credentials

  executor:
    cores: 3
    memory: "4g"
    instances: 2

  restartPolicy:
    type: OnFailure
    onFailureRetries: 2
```

---

## 10. Airflow Variables Reference

| Variable | Default | Mô tả |
|---|---|---|
| `DEMO_DATA_PIPELINE_E2E_INCREMENTAL_GROUPS` | _(JSON)_ | Override ETL groups `[{group_id, dbt_select}]` |
| `DATAHUB_ASSET_TAG_NAME` | `data platform demo` | Tag name cho DataHub assets |
| `DBT_ARTIFACTS_PREFIX` | `dbt-artifacts/<run_id>` | S3 prefix cho dbt artifacts |
| `DBT_ARTIFACTS_BUCKET` | `data` | S3 bucket cho artifacts |
| `IMMEDIATE_ALERT_CHANNELS` | `["slack"]` | Channels cho failure alerts |
| `RETRY_ALERT_CHANNELS` | `["slack"]` | Channels cho retry alerts |
| `NOTIFY_ON_TASK_SUCCESS` | `false` | Enable per-task success notifications |
| `MAILEROO_API_KEY` | _(required)_ | Maileroo sending key |
| `SENDER_EMAIL` | _(required)_ | Verified sender email |
| `AIRFLOW_BASE_URL` | `http://localhost:8080` | Airflow UI URL cho email links |
| `DEFAULT_NOTIFICATION_EMAIL` | _(optional)_ | Default recipient email |

---

## 11. DAG Summary

| DAG | Purpose | Schedule | Mode |
|---|---|---|---|
| `demo_data_pipeline_e2e_init` | Initial load: Raw Vault + Data Mart | Manual | Full refresh |
| `demo_data_pipeline_e2e_incremental` | Daily load: Raw Vault + Data Mart | Manual/External | Incremental |
| `demo_mdm_pipeline_e2e_incremental` | MDM pipeline: 6 steps tuần tự | Manual/External | Incremental |
| `demo_mdm_pipeline_e2e_init` | MDM initial load | Manual | Full refresh |
| `dbt_adhoc_etl` | Ad-hoc dbt runs | Manual | Configurable |
| `backfill_etl_pipeline` | Data correction + rebuild | Manual | Backfill |
| `backdate_etl_pipeline` | Backdate processing + Dremio | Manual | Backdate |
| `iceberg_maintenance` | Iceberg table maintenance | Scheduled | Maintenance |
