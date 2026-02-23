from __future__ import annotations

import pendulum

from airflow import DAG
from airflow.operators.empty import EmptyOperator

from package.ktl_airflow_utils.taskgroups.dbt_spark import create_dbt_spark_taskgroup
from package.ktl_airflow_utils.taskgroups.datahub_publish import (
    create_publish_to_datahub_taskgroup,
)
from package.ktl_airflow_utils.taskgroups.notifications import (
    create_maileroo_notification_group,
)


dag = DAG(
    dag_id="package_demo_dbt_datahub_notification",
    start_date=pendulum.datetime(2025, 1, 1, tz="UTC"),
    schedule=None,
    catchup=False,
    max_active_runs=1,
)

with dag:
    start = EmptyOperator(task_id="start")

    dbt_tg = create_dbt_spark_taskgroup(
        "dbt",
        dag=dag,
        dbt_select="path:models/integration/raw_vault",
        full_refresh=False,
        use_spark_operator=False,
    )

    publish_to_datahub = create_publish_to_datahub_taskgroup(
        prefix_value="dbt-artifacts/{{ dag_run.run_id }}/demo",
        dag=dag,
    )

    end = EmptyOperator(task_id="end")

    notify = create_maileroo_notification_group("notification", dag=dag)

    start >> dbt_tg >> publish_to_datahub >> end >> notify
