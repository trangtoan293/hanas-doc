---
title: Job history and query profiles
sidebar_label: Jobs
sidebar_position: 5
description: View the query engine's job history, filter by status and user, read SQL, timing, and profile details, and cancel jobs.
---

Every query that runs through the query engine creates a job. The **Jobs** page in Hanas Console lists these jobs so you can check status, find slow or failed queries, and read execution profiles.

## Job list

The Jobs page shows a table of jobs with information such as status, query type, user, queue, dataset, and duration. You choose which columns to display.

| Filter | Purpose |
|---|---|
| Search | Search by content or job ID. |
| Start time | Choose a preset time range or a custom range. |
| Status | Filter by running, completed, failed, or cancelled jobs. |
| Type | Filter by the origin of the query, for example run from the interface or from an external client. |
| User | Filter by the user who submitted the query. |
| Queue | Filter by the queue the job was routed to. |

Filters are kept when you open a job's details and then return to the list.

## Job details

Select a job to open the details page, which has these tabs:

| Tab | Contents |
|---|---|
| **Overview** | Status, timing, user, related datasets, Reflections used, and the error message if the job failed. |
| **SQL** | The submitted SQL statement. |
| **Visual profile** | The execution operator graph, for finding time-consuming steps. |
| **Raw profile** | The profile content in raw form, with an option to download the profile to share when you need support. |

When looking for the cause of a slow query, compare the time of each phase in the visual profile and check whether the query used a [Reflection](acceleration.md).

## Cancel a job

You cancel a running job from the job status in SQL Studio or from the Jobs page. A cancelled job moves to the cancelled state; in a sequence of multiple statements, the later statements do not run.

:::note Requirements

Regular users can only view and cancel their own jobs. Administrators can view the jobs of all users.

:::

## Troubleshooting

| Symptom | What to check |
|---|---|
| You cannot see other users' jobs | You need administrative permission to view other users' jobs. |
| A job stays in the waiting state for a long time | Check the queue and concurrency limits in [Engines, queues, and workload management](workload-management.md). |
| A job fails | Open the Overview tab and read the error message, then compare it with the SQL on the SQL tab. |

## Next steps

- [SQL Studio](sql-studio.md).
- [Accelerate with Reflections](acceleration.md).
- [Engines, queues, and workload management](workload-management.md).
