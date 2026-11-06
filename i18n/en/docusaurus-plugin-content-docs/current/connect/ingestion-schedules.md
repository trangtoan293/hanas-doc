---
title: Schedules, checkpoints, and reruns
sidebar_label: Schedules and reruns
sidebar_position: 4
description: Schedule ingestion flows, understand checkpoints and watermarks, rerun, reload data, monitor runs, and handle errors in Ingestion.
---

This page shows you how to operate an ingestion flow after you create it: set a schedule, run manually, reload data, monitor each run, and handle failed runs. For the underlying concepts, see [Ingest data into the lakehouse](./ingestion.md).

## Schedules

When you create or edit an ingestion flow, choose one of the following options.

| Schedule | Notes |
|---|---|
| Manual | Runs only when you select **Run now**. |
| Every 5 minutes, every 15 minutes | Suits CDC or Kafka flows. |
| Hourly | Choose the minute within the hour. |
| Daily | Choose the hour and minute. |
| Custom | A cron expression with 5 or 6 fields. |

The schedule uses the time zone configured for the service; the default is `Asia/Ho_Chi_Minh`. At any moment, an ingestion flow has at most one active run.

The service splits runs into two lanes. The **stream** lane is for flows that have tables reading a change log (CDC, Kafka, Debezium, T24); the **batch** lane is for full refresh and incremental. A large full load does not block CDC or Kafka runs. Runs that read an entire table, such as the first load, a reload, or a newly added table, still run in the batch lane.

:::caution Current limitations

CDC and Kafka do not run continuously. Each run reads to the end of the log as of its start, commits, and then finishes. For stream flows, set a schedule of 1 to 5 minutes. Each OLake run has a fixed startup cost of about 20 seconds, so a schedule that is too frequent increases load.

:::

## Checkpoints and watermarks

- **Checkpoint**: engine state saved after each successful run. The next run reads from the checkpoint, so it does not re-read data that was already ingested. The system keeps the 10 most recent checkpoint versions for each flow.
- **Watermark**: the point up to which each table's data has been ingested, shown in the flow detail view.
- A failed run does not write a checkpoint. The next run continues from the last successful checkpoint.
- If the pod running a run stops abruptly, the run is marked failed and the next run continues from the checkpoint, with no intervention needed.

## Rerun and backfill

On the ingestion flow detail page:

| Action | Effect |
|---|---|
| **Run now** | Runs one run immediately, outside the schedule. Not available while the flow is paused. |
| **Pause** and **Resume** | Stops or re-enables the schedule. Pausing a CDC flow requires confirmation because the source log keeps growing. |
| **Cancel** (on a run) | Cancels a running run. |
| **Reload all** (resnapshot) | Deletes the destination tables, forgets the read position, and re-reads everything from the source. Use it to backfill or to fix incorrect data. |
| **Clear** (one or more tables) | Only deletes the destination table and read position, without reading the source; the next run reads from the beginning. A failed Clear is not retried automatically. |
| Add table | The new table is loaded in full; other tables continue from the checkpoint. |

:::caution Current limitations

**Reload all** is not available with Debezium and T24 because the read position is stored in the destination table itself; to rebuild, delete the flow along with the destination tables, then recreate it. With Kafka, data can be re-read only from the oldest message that the topic still retains.

:::

Changing the sync mode, tracking column, key, or table configuration of an ingested table sets a re-read flag: the next run deletes that table and re-reads it from the beginning. Check the list of affected tables before you confirm.

## Monitor runs

Open the ingestion flow and go to the **Runs** tab:

- The runs table shows the status, time, and result. Open a run to view its log in real time.
- **View log** shows the number of rows written for each table and the last 200 lines of the engine log.
- **Download full log** downloads the entire log of the run. Full logs are kept for 30 days; older runs keep only the last lines. Secrets are masked in all logs.
- While a run is executing, the interface updates statistics (row count, speed, estimated time, memory, CPU) about every 5 seconds for engines that support it.
- Run history is kept for 14 days; successful runs that wrote nothing are kept for 1 day.

Administrators can set a webhook (Slack or Teams) to receive an alert when a run fails after exhausting its attempts. The `IngestionStreamLagging` alert fires when a table in a stream flow lags by 30 minutes.

## Handle errors

A failed run is retried automatically up to 3 times, 1 minute apart and doubling each time. After 5 consecutive failed runs, the flow moves to the **error** state: the schedule stops and the interface shows recovery steps. Fix the cause, then select **Run now** to try once or **Resume** to re-enable the schedule.

| Error message contains | Cause | Resolution |
|---|---|---|
| `Connection refused`, `timeout`, `UnknownHost` | The service cannot reach the source or catalog | Check the network, the team's egress rules, and the host name. |
| `password authentication failed`, `Access denied` | Wrong credentials | Fix the connection and **Test** it. |
| `wider than`, `refused`, `DOUBLE` | OLake does not preserve the numeric type exactly | Ingest the table with dlt or Debezium. |
| `replication slot`, `binlog`, `CDC is not enabled` | CDC prerequisites missing | Run the statements that preflight displays. |
| `Worker stopped responding` | The pod running the run was stopped | No fix needed; the next run continues from the checkpoint. Check the pod's memory and restarts. |
| `consumer_group_id mismatch` | Kafka: the checkpoint and the table have drifted out of sync on the consumer group | Select **Reload all**. |
| `Decimal value would cause data loss` | dlt: a value has more decimal places than the target type | Declare precision and scale at the source. |

For CDC flows, do not leave a flow stopped for too long: the source retains the log (WAL, binlog) until it is read. Delete or reload flows that are no longer used.

## Next steps

- [Ingest data into the lakehouse (Ingestion)](./ingestion.md)
- [Troubleshooting](../operate/troubleshooting.md)
- [Configuration](../operate/configuration.md) to change the time zone, retry count, and log retention
