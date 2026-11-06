---
title: dbt Studio — projects and IDE
sidebar_label: dbt Studio
sidebar_position: 1
description: Create dbt projects, develop models in the IDE, check SQL, and manage changes with Git in Hanas Console.
---

dbt Studio in Hanas Data Platform helps you develop SQL models, test data, and manage projects directly in Hanas Console. This page guides analytics engineers and data engineers in preparing a project before running or scheduling dbt.

## Concepts

A project contains SQL models, YAML files, macros, packages, and configuration for dbt. A connection identifies the target system; a target identifies the set of configuration used for one execution environment.

The IDE provides a file tree, an editor, Source Control, and the compile, preview, query, and explain tools. The project lineage is built from the dbt manifest and shows dependencies between models.

| Component | Purpose |
|---|---|
| Model | A SQL statement that defines the output data and can reference other models. |
| Source | A declaration of the source tables the project uses. |
| Test | A data check based on declared conditions. |
| Macro, package | Reuse logic and project components. |
| Connection, target | Choose the connection destination and the run environment configuration. |
| Git | Store history and exchange changes with the repository. |

## Requirements

:::note Requirements

dbt Studio requires the development feature to be enabled and the dbt runner to be serving. You need `dbt-editor` or `dbt-admin` to create projects, edit files, use Git, and run dbt. `dbt-viewer` can only use the read operations that are allowed.

:::

A dbt administrator prepares connections and attaches connections and targets to the project. Query engine admin permission does not automatically grant `dbt-admin`.

:::caution Current limitations

dbt projects share a common workspace: people with a dbt role see the projects, connection names, schedules, and runs in the workspace. Do not use creating a separate project as a permission boundary between teams.

:::

## Prepare a project

1. Open **dbt** or **Develop** in Hanas Console to see the list of available projects.
2. Choose **Create project**, **Import**, or **Clone**, whichever fits your existing code source.
3. Enter a meaningful project name that matches the naming conventions of your development team.
4. Choose a template if you are starting from a template, or provide the repository when cloning existing code.
5. Ask a dbt administrator to attach the connection and target used for the project's development environment.
6. Open the project to check the file structure, packages, and source declarations before you edit models.

A project can be created from the Data Vault template. You still need to review the business keys, source schema, and history rules of the template before using it.

## Develop your first model

The example below assumes a bronze table already exists and is declared as a source in the project. The names in the example are illustrative; replace them with your actual sources and tables.

Declare the source in a YAML file of the project:

```yaml
version: 2

sources:
  - name: bronze_retail
    database: Lakehouse
    schema: bronze_retail
    tables:
      - name: account
```

Create a model named `stg_retail_account.sql` in the project:

```sql
select
    account_id,
    customer_id,
    account_status
from {{ source('bronze_retail', 'account') }}
```

This model keeps the grain of one row per source record. If the source stores multiple versions or CDC, you need to add logic to select the version and handle deletes appropriately.

1. Select the model file in the file tree to open the project's SQL editor.
2. Save your edits before you use the check or run operations on the model.
3. Choose **Compile** to see the SQL generated after dbt processes the configuration and references.
4. Choose **Preview** to see sample data and check column names, data types, and null values.
5. Choose **Explain** when you need to see the query plan of the compiled SQL.
6. Add descriptions and tests in YAML before you move the model to the official run step.

Preview helps you find query errors and data structure problems; you still need to run tests and reconcile the results. Viewers can only submit read SQL in the `SELECT` or `WITH` group through the read tools that are allowed.

## Work with Git

Source Control supports viewing diffs, stage, unstage, commit, branch, fetch, pull, and push. Branch merge, conflict resolution, and stash operations support development workflows from a shared repository.

1. Open **Source Control** to check the changed files and diffs before adding them to a commit.
2. Stage the files that belong to the same change so the commit history has a clear scope.
3. Enter a message describing the business or technical change, then choose **Commit**.
4. Sync the branch from the remote before you push if the repository already has new commits from other members.
5. Resolve each conflict in the file, stage the resolved version, and complete the merge.
6. Choose **Push** to send commits to the remote using your own Git credentials.

Git credentials are managed per user. Initializing Git or adding or changing a remote requires dbt admin permission; regular development Git operations require editor or higher.

When someone is editing the project, the edit session mechanism coordinates write access on the project. Talk to the person who is editing before you change the same model or switch a shared branch.

## Limitations

Lineage in the IDE is currently available at the model level from the manifest; runner column lineage is not provided. View column lineage in Hanas Catalog once the connector has collected enough schema and transformation information.

Python running locally in the runner is a conditional feature and is off by default. For PySpark or notebooks on a cluster, use Compute and the corresponding permissions.

## Troubleshooting

| Symptom | What to check |
|---|---|
| The dbt menu does not appear | Check the development feature and the dbt role, then sign in again. |
| The IDE is read-only | Check the viewer role and the project's edit session status. |
| You cannot select a connection or target | Ask a dbt admin to check the configuration attached to the project. |
| Compile fails on a source or ref | Check the declared names, dependencies, and installed packages. |
| Git refuses to switch branches | Commit, stash, or resolve unsaved changes before checkout. |

## Next steps

- [Run, test, and schedule dbt](dbt-runs.md).
- [Modeling standards](modeling-standards.md).
- [Lineage in Hanas Catalog](../govern/lineage.md).
