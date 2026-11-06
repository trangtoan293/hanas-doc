---
title: Upgrade and rollback
sidebar_label: Upgrade
sidebar_position: 9
description: The image upgrade procedure through the images.yaml file, per-component migrations, and how to return to a previous version.
---

Hanas Data Platform images are pinned centrally in `environments/images.yaml`. This page describes the procedure for changing versions, the migrations to watch for per component, and rollback options.

## Upgrade procedure

1. Record the running versions (revision, digest) and feature flags. Create the appropriate backups as described in [Backup and recovery](backup-recovery.md).
2. Read the installer CHANGELOG and the warnings from the release pipeline. If the new version includes migrations or changes to environment variables, ports, or nginx, handle them before changing images.
3. Edit `repository`, every `tag` together with its digest, and `source.revision` (if the entry has one) in `environments/images.yaml`. The Ontology API and graph-worker images should come from the same compatible release.
4. For Hanas Console, synchronize the chart's nginx template with the correct image, then update the `ui.nginx.dynamicDns.templateForTag` key in the values. The chart blocks the upgrade if the tag does not match. This is an exception to the rule of editing only one file.
5. Handle migrations and prerequisites using the table below, review the diff, then apply.
6. Run the smoke test and functional checks ([Health checks and monitoring](health-checks.md)); watch the Ready state, restart counts, and logs.

```bash
helmfile diff
helmfile apply

# Or a single release, when its dependent releases are ready
helmfile -l name=ontology diff
helmfile -l name=ontology apply
```

Do not assume the `-l` selector pulls in every prerequisite. Enabling or disabling a feature, changing a namespace, or renaming a release changes data and lifecycle; it is not just an image upgrade.

## Migrations per component

| Component | Mechanism | Notes when upgrading |
|---|---|---|
| Ontology | A migration Job runs before the upgrade (`pre-upgrade` hook); the application checks the schema in verify mode. | The Job does not run on rollback. An older database can hit `MigrationIntegrityError` if the migration history was squashed; back up and agree on a resolution with the application team, and do not edit checksums yourself. |
| Ontology, destructive flag | `allowDestructiveMigrations` defaults to `false`. | This flag does not guarantee that every data-deleting command is blocked; read the release notes. |
| dbt, new database | The initialization script runs when the PostgreSQL data directory is empty. | Changing the ConfigMap does not recreate an existing database. |
| dbt, existing database | The `db-upgrade` init container adds schema changes before the application runs (when the bundled PostgreSQL is enabled). | For an external database, or when this step is disabled, you must run the upgrade SQL manually and compare the schema against the application. |
| dbt, Flyway | The new image migrates itself at startup. | Automatic migration does not mean downgrades are supported. |
| Kapas | The entrypoint runs migrations before serving. | A DDL or pgvector error prevents the application from starting. Some migrations drop tables; a downgrade does not restore lost data. Back up the PVC and agent configuration before upgrading. |
| Superset | The init Job runs `superset db upgrade`; a Secret gate coordinates ordering. | Keep the configuration that does not wait for Ready at the release level. The PostgreSQL major version of the PVC must match the binary. |
| Hanas Catalog | The API and runner migrate themselves and use an advisory lock. | Requires a database role with DDL permissions; keep the migration history and the encryption key. |
| Ingestion | Flyway migrates automatically when the pod starts. | The user database needs schema permissions; the Flyway history and the encryption key are in backup scope. |
| Spark Operator | Helm installs the CRDs only the first time. | When upgrading the chart, update the CRDs first using server-side apply. |

Example of updating the Spark Operator CRDs, after you have assessed compatibility with existing SparkApplication objects:

```bash
kubectl apply --server-side -f charts/spark-operator/crds/
```

:::caution Current limitations

Superset uses PostgreSQL 14 in the current configuration. If an old PVC contains data from a different major version, PostgreSQL cannot open the data directory. A Helm rollback does not resolve this; you must convert or restore the data per major version.

:::

## Rollback

There is no verified platform-wide rollback runbook yet. The approaches below are a reference outline for you to build a procedure and test it in an isolated environment.

**The schema is still compatible.** Return the images in `images.yaml` to the recorded versions, review the diff, then apply. Or use the Helm history of a release:

```bash
helm history ontology -n ontology
helm rollback ontology <CONFIRMED_REVISION> -n ontology --wait
```

After a Helm rollback, update the source configuration. Otherwise the next `helmfile apply` upgrades the release again.

**A migration has changed the schema or deleted data.** A Helm rollback does not undo SQL and does not restore lost objects. You must restore the database, PVCs, and object storage to a consistent point, then deploy a compatible application version.

When you restore, keep the encryption keys, source credentials, PATs, and realm that match the database version. Pause schedules and workers before restoring to avoid duplicate writes.

Downgrade support for Keycloak, Superset, dbt, Hanas Catalog, Ingestion, and the query engine for specific version pairs is not officially supported; always back up before upgrading.

## Next steps

- [Backup and recovery](backup-recovery.md).
- [Health checks and monitoring](health-checks.md).
- [Troubleshooting](troubleshooting.md).
