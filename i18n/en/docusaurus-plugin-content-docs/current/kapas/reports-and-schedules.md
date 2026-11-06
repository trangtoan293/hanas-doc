---
title: Reports, citations, and schedules
sidebar_label: Reports and schedules
sidebar_position: 3
description: Create dashboards and reports with Kapas, verify figures through query citations, and set up recurring runs.
---

This page covers three tasks: saving results as a report or dashboard, verifying figures in an answer, and scheduling recurring Kapas runs.

## Reports and dashboards

| Method | Agent | Result is stored in |
|---|---|---|
| Table or chart in chat | Hanas Analyst | The conversation (temporary display) |
| Dataset, chart, dashboard on Superset | Analytics Studio Copilot | Superset |
| Dashboard from a YAML spec, draft | Dashboard Copilot | Superset (unpublished) |
| Board in a dbt project | Project Copilot | The project's `charts/` folder |

Dashboard Copilot reads the dataset, measures the data shape to choose a chart type, then runs validation and lint before creating a draft. Supported chart types are bar, line, big number, pie, table, treemap, and sunburst. You review the draft in Superset before publishing, see [Superset in Console](../bi/superset.md).

:::caution Current limitations

Creating a dashboard calls several Superset APIs in sequence with no end-to-end transaction. If an error occurs partway, some objects may already have been created; Kapas does not roll them back automatically. Check the dashboard again after applying.

:::

Kapas also has skills that create Word, PDF, Excel, and PowerPoint files, but they are available only when an administrator enables them for the relevant agent. Hanas Analyst cannot be assumed to export these formats by default.

## Figure citations

Hanas Analyst has query citations enabled. Each query run has a reference ID `Qn`, and the agent is required to tie figures in the answer to their source in the form `[Qn.COLUMN_NAME]`.

After the agent answers, Kapas compares the tagged figures against the query results and classifies them:

| Label | Meaning |
|---|---|
| `verified` | The figure matches a value in the query result. |
| `derived` | The figure is computed from the result. |
| `unverified` | It could not be matched. |

Open the citation to see the SQL statement, the schema, the query engine job ID, and the identity of the user who ran it. You can use the job ID to review it in [Job history](../query/jobs.md).

:::caution Current limitations

Citations check only tagged figures. Untagged figures and business interpretation are not verified. How citations are displayed depends on the UI; embedded applications may not display them fully.

:::

## Schedules (Cron jobs)

You set up a schedule so Kapas sends a message or calls an agent repeatedly on a timetable.

### Steps

1. In Kapas Console, open the **Cron jobs** section of the selected agent.
2. Choose the schedule type: `cron` (a recurring expression) or `once` (one time).
3. Choose the task type: send text, or call the agent with a prompt (for example, ask for a weekly summary of figures).
4. Set the time zone, the concurrent run limit, the maximum timeout, and session usage (shared or separate).
5. Save. You can pause, resume, run now, and view the run history.

Run results appear in the **Inbox**, where you can also see the trace of a run.

The **Heartbeat** section is the agent's periodic run mechanism, configured in the same area as schedules. Hanas does not ship any business schedule out of the box.

:::caution Current limitations

Background jobs run with no signed-in user. A job is not guaranteed to obtain a new token automatically when your token expires, so automated reports that need to query data can fail after the session expires. Check the run history and Inbox after the first few runs before relying on a recurring report.

:::

## Troubleshooting

| Symptom | Resolution |
|---|---|
| The job runs but reports an authentication error | The token expired. Rerun with **Run now** while you are signed in. |
| The draft dashboard is missing charts | Reopen it in Superset and check each chart; ask the agent to apply it again. |
| A figure in the answer has no citation | Ask the agent to run a query and tag the source for that figure. |

## Next

- [Safety and access control](safety.md)
- [Analytics with Superset](../bi/superset.md)
- [Kapas API and SSE](../develop/kapas-api.md)
