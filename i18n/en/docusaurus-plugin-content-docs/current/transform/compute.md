---
title: Compute — Spark and notebooks
sidebar_label: Compute
sidebar_position: 4
description: Develop and run PySpark projects, notebooks, declarative pipelines, and streaming jobs on Spark, and view logs and results in Hanas Console.
---

Compute (the **Compute Engine** menu) is the Apache Spark execution environment on Kubernetes in Hanas Data Platform. You write Python or PySpark directly in Hanas Console, run it, and read logs without managing a cluster yourself. This page is for data engineers who process large volumes or logic that SQL cannot express.

## Requirements

:::note Requirements

Compute is off by default. An administrator must enable Compute and provide the Spark Operator, the Spark image, and the lakehouse catalog configuration. You need the `compute-user` or `compute-admin` role, plus a project-level permission: view, run, edit, or manage.

:::

Each run creates its own Spark application with a driver and executors on Kubernetes. Your code does not run in the shared runner container. You choose resources at run time (Small, Medium, Large, or Custom) within the limits set by the admin.

## Concepts

| Component | Description |
|---|---|
| Compute project | A set of Python/SQL files, Spark configuration, libraries, and variables, managed with Git. |
| Notebook | An `.ipynb` file that runs through Spark Connect and can reuse a session during development. |
| Declarative pipeline | Spark Declarative Pipelines datasets and flows, displayed as a dataset graph. |
| Streaming job | A Python or SQL job that runs continuously, with checkpoints and its own lifecycle. |

Unlike a Python run in dbt Studio, which runs inside the runner container with a short time limit, Compute is for distributed Spark jobs and has a longer timeout.

## Create a project and run

1. Open **Compute Engine** in Hanas Console. The page has the tabs **Projects**, **Runs**, **Streaming jobs**, and **Sessions**.
2. In the **Projects** tab, choose **New project**.
3. Create a Python file, SQL file, or notebook in the file tree.
4. Choose a catalog in the Catalog panel to browse lakehouse tables.
5. Choose **Run**, select a resource size, and confirm.
6. Open the **Output** tab to read logs in real time. Choose Driver or Executor to view the logs of each component, or download them.
7. After the run finishes, open the Run details to see who ran it, the configuration, parameters, errors, and where it ran.

Example PySpark script that reads an Iceberg table and writes the result:

```python
from pyspark.sql import SparkSession, functions as F

spark = SparkSession.builder.getOrCreate()

df = spark.table("lakehouse.silver.transaction")
daily = (
    df.groupBy(F.to_date("transaction_ts").alias("txn_date"))
      .agg(F.sum("amount").alias("total_amount"))
)
daily.writeTo("lakehouse.gold.daily_transaction").createOrReplace()
```

Catalog and namespace names depend on the lakehouse configuration of your deployment.

## Declarative pipelines

A declarative pipeline describes datasets and the relationships between them; Spark determines the order on its own. You can run an update or a dry run, refresh everything, and pass parameters specific to a run. Each project runs only one pipeline at a time.

In `expectations.yml`, a quality rule with `on_fail: drop` removes violating rows before writing and keeps them in the quarantine table `<dataset>__dropped`. This rule applies to datasets written in Python; `unique` cannot drop rows and only raises a warning.

## Streaming jobs

A streaming job runs continuously, stores checkpoints, and can be restarted automatically. A job that fails several times in a row within a short period stops permanently and records the reason. You view the job's metrics, events, and alerts in the UI. Resetting a checkpoint makes the source be read again from the beginning, so the target table may receive data twice.

## Logs and notifications

Driver logs are stored in full; executor logs are copied before the pod is deleted. The log table filters by level and source, and includes platform logs, Spark logs, and your own output. The default Spark log level is WARN; raise it when debugging, then set it back. The admin configures the log retention period.

Failure notification webhooks are configured per project and by default apply to runs with no one watching, such as scheduled or continuous runs. There is no email notification yet.

## Limitations

:::caution Current limitations

- Runs use the platform's lakehouse identity, not each person's identity. Query engine row access and masking do not apply when Spark reads files directly; control project permissions and data zones instead.
- A compressed project package is limited to 8 MB.
- Notebooks do not yet support character-level co-editing; text files do.
- There is no terminal into the pod.
- The cost shown is an estimate based on the platform's calculation method, not an invoice.
- Spark Steps in the new Pipeline engine are not officially supported yet; see [Pipeline](pipelines.md).

:::

## Troubleshooting

| Symptom | Resolution |
|---|---|
| The Compute Engine menu does not appear | Compute is not enabled, or you lack a Compute role. |
| A run stays pending for a long time and then fails | The cluster lacks resources or the image has an error; the run fails after the pod stays Pending too long. |
| Library installation error | Check the `pip install` log in the Environment panel. |
| A run is canceled midway | Check the data that was already written before you rerun. |

## Next steps

- [Orchestrate with Pipeline](pipelines.md).
- [Modeling standards](modeling-standards.md).
- [Understand permission domains](../govern/access-control.md).
