---
title: Run, test, and schedule dbt
sidebar_label: Run and schedule dbt
sidebar_position: 2
description: Run dbt commands with targets and selectors, read logs and artifacts, test data, and configure run schedules.
---

Hanas Data Platform stores the status, logs, and artifacts of dbt executions in Hanas Console. This page shows you how to choose a command, check the results, and add verified work to a schedule.

## Concepts

A run is one execution of a command on a project with a chosen target and model scope. A selector limits the dbt resources to process; the target determines which connection configuration is used.

| Command | Purpose |
|---|---|
| `dbt compile` | Compile models into SQL to check logic and dependencies. |
| `dbt run` | Build the models in the selected scope. |
| `dbt build` | Execute resources and tests following dbt dependencies. |
| `dbt test` | Run the tests declared in the project. |
| `dbt seed` | Load the project's seed data. |
| `dbt snapshot` | Run the snapshot definitions provided by the project. |
| `dbt source freshness` | Check freshness according to the source's freshness configuration. |
| `dbt deps` | Install the dependencies declared for the project. |
| `dbt docs generate` | Generate artifacts for documentation and metadata collection. |

A successful command does not by itself confirm that the data meets every business requirement. You need to declare tests, freshness conditions, and reconciliation checks that fit the model you are building.

## Requirements

:::note Requirements

You need `dbt-editor` or `dbt-admin` to run, cancel, and schedule dbt. Viewers can see history, logs, and the read tools that are allowed. Connections, targets, and data permissions must be prepared before you run.

:::

No one is acting at the moment a schedule triggers. The scheduled query engine run path needs the offline credential of the person who created the schedule; a missing or expired credential makes the job fail.

## Run manually

1. Open the project in **dbt Studio** to check the saved model content.
2. Choose the **Target** that matches the environment you want to run in, to avoid writing data to the reporting zone by mistake.
3. Choose a command such as **Build**, **Run**, or **Test** according to the goal of the execution.
4. Enter a selector when you want to limit the run to a specific model or group of dependencies.
5. Start the run and open the log to follow progress, warnings, and the first error message.
6. Open the run details to compare the status with the result of each dbt resource after it completes.

The equivalent commands below use the `dev` target and a transaction model that already exists in the project:

```bash
dbt compile --target dev --select fct_transaction
dbt build --target dev --select +fct_transaction
dbt test --target dev --select fct_transaction
```

The plus sign before a model name also selects its upstream dependencies, following dbt selector syntax. Check the selection scope before you run models that write data.

## Add data tests

The YAML below shows a check that the transaction key is not null and not duplicated. Use the `unique` test only when the grain defines exactly one row per `transaction_id`.

```yaml
version: 2

models:
  - name: fct_transaction
    description: Each row is one standardized transaction.
    columns:
      - name: transaction_id
        tests:
          - not_null
          - unique
      - name: account_id
        tests:
          - not_null
```

Add relationship checks, valid-status checks, and total-amount-per-period checks if the model needs reconciliation. Freshness is only meaningful when the source has time configuration and thresholds agreed on by the data team.

## Monitor and cancel runs

Open **dbt Studio** → **Orchestrate** and then choose **Runs** to see the history of recorded runs. The run details show the command, target, time, status, and logs for diagnosis.

Live logs are streamed from the runner; artifacts are stored according to the execution result. When you need to stop a job, choose **Cancel** on the active run, then check the final status.

Canceling or failing midway does not automatically roll back all the data that earlier models already wrote. Before you rerun, check idempotency, materialization, and the scope of the models that already succeeded.

## Create a dbt schedule

1. Open **dbt Studio** → **Orchestrate** and then choose **Schedules** to manage the workspace schedules.
2. Choose to create a schedule and enter a name that clearly describes the job to run.
3. Choose the project, command, target, and selector, matching the configuration that already ran successfully.
4. Enter a cron expression or choose a built-in schedule template to define the trigger times.
5. Check the list of upcoming run times calculated by the backend before you save the schedule.
6. Enable the schedule and watch the first run to verify credentials, data permissions, and results.

:::note Requirements

dbt schedules currently evaluate cron in UTC. For example, `0 2 * * *` is 02:00 UTC, which is 09:00 in Vietnam. Compare the times displayed in the UI before you confirm the schedule.

:::

| Field | Meaning |
|---|---|
| Project | The project containing the dbt resources to execute. |
| Command | The command the schedule triggers. |
| Selector | The scope of models and dependencies selected. |
| Target | The run environment configuration prepared by the dbt admin. |
| Cron | The schedule expression; check the upcoming runs. |
| Active | Enable or pause new triggers. |
| Webhook | The channel that receives failure notifications, once configured and accessible. |

## Limitations

The runner has a mechanism that skips some nodes it has proven unchanged. For table, incremental, and snapshot nodes, the decision also relies on Iceberg snapshot history when the required metadata can be read.

If the runner cannot prove that the state is unchanged, it still builds the node. You can force a rebuild with `--rebuild-unchanged`; `--full-refresh` also disables this optimization when used.

:::caution Current limitations

The `publish_schema` field in a dbt schedule does not yet perform Iceberg publishing. Do not use this field as a data release step; model the target table in the project and check the write result.

:::

## Troubleshooting

| Symptom | Resolution |
|---|---|
| Run fails on the target | Check that the target belongs to the project and the connection is still usable. |
| The schedule does not run on time | Check the UTC cron, the Active status, and the next run time. |
| Manual runs work, but the schedule fails authentication | Ask an administrator to check the offline credential of the person who created the schedule. |
| A test fails after the model has written | Read the failed resource and reconcile the data before you rerun. |
| A run waits or is rejected due to load | Check the active runs and the runner's concurrency limit. |

## Next steps

- [Orchestrate multiple steps with Pipeline](pipelines.md).
- [Collect dbt metadata](../govern/metadata-ingestion.md).
- [Modeling standards](modeling-standards.md).
