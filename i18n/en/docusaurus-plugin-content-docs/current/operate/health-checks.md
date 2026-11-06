---
title: Health checks and monitoring
sidebar_label: Health checks
sidebar_position: 11
description: How to use the smoke test, additional functional checks, and daily monitoring signals for Hanas Data Platform.
---

This page helps you confirm the platform works after installation or an upgrade, and monitor its state daily. The smoke test shipped with the installer covers basic connectivity; business flows need additional checks.

## Smoke test

Run it from the root directory of the installer, because the script reads configuration through relative paths:

```bash
python3 tests/smoke.py
SKIP_PUBLIC=1 python3 tests/smoke.py
```

Supported environment variables: `HELMFILE` (command path), `CURL_IMAGE` (image for the temporary curl pod), and `SKIP_PUBLIC=1` (skip layer 3 when gateway routes have not been created). The script exits with code `0` when every check passes and `1` when there is a failure.

The script needs permission to create, delete, and attach to temporary pods in the namespaces, and the ability to pull the curl image. The script handles manifests and Secrets in memory; restrict access to the logs of the run.

| Layer | Check | Limitation |
|---|---|---|
| 0. Release and workload | Releases are in the deployed state; Deployments and StatefulSets have all replicas Ready; Jobs completed. | A Job that has been cleaned up is treated as done, and cannot be told apart from a Job deleted after a failure. |
| 1. Internal URLs | Calls each Service URL in the manifest from the caller's namespace. Passes when an HTTP response is received. | Codes `401`, `403`, `404`, and `500` still count as a response. Does not check TCP for PostgreSQL and Redis. |
| 2. Authentication and data | The public issuer matches; client secrets match Keycloak; the query engine returns status `OK`; pods reach public Keycloak through the gateway; the query engine can write to object storage; the Superset PAT Secret has data. | Does not prove token exchange works; the PAT is only checked for having data, not for validity or permissions. |
| 3. Public | Public hosts have routes through the gateway; Ontology returns `200` at the readiness endpoint; the public issuer matches. | Only rules out codes `000`, `404`, `502`, `503`, and `504`. Does not walk through the full sign-in flow. |

## Additional functional checks

The following cases cover what the smoke test does not. Include them in your acceptance steps.

1. Sign in to and out of Hanas Console, Superset, and Kapas as a regular user and as an administrator; check callbacks, cookies, issuer, and that the session belongs to the right person.
2. Run queries through Console, dbt, and Superset as a permission-restricted user; confirm there are no excess permissions because of the proxy or local admin.
3. Call Ontology, chat with Kapas, and test tools calling back in both directions; check the `ontology-*` roles and token exchange.
4. Create and run a dbt project; check storage folder permissions, the workspace, Git SSH, and concurrency.
5. If Hanas Catalog is enabled: check the health endpoint, ingest a test source, run on a schedule, and decrypt credentials after a restart.
6. If Ingestion is enabled: check the health endpoint, run one run that writes to a test destination, and check status, logs, and checkpoints.
7. If Compute is enabled: create a test SparkApplication and check the driver, executors, quota, admission policy, and logs.
8. Restore a backup into a separate environment and repeat the cases above. A dump file alone is not enough to consider a backup valid.

The dbt probes are mostly TCP, so the Ready state does not prove that the business dependencies work.

## Daily monitoring

Watch the following signals with your own tools:

| Signal | Command or source |
|---|---|
| Pod Ready, restarts, `OOMKilled` | `kubectl get pods -A`, `kubectl describe pod` |
| PVC capacity | StorageClass metrics or `kubectl get pvc -A` |
| PostgreSQL connections and locks | Database monitoring tools |
| Failed runs and run duration | The history screen in Hanas Console |
| Object storage errors | Query engine and MinIO logs |
| PAT expiry | Track the expiry of PATs issued to Superset and services |
| Authentication and exchange errors | Keycloak and application logs |

When you export logs to report a problem, do not include Secret contents in the report.

:::caution Current limitations

The installer does not include a centralized monitoring and alerting system. Query engine and Spark Operator metrics are disabled, and no dashboards or alert rules ship with it. You must deploy your own monitoring tools.

:::

## Next steps

- [Troubleshooting](troubleshooting.md).
- [Backup and recovery](backup-recovery.md).
- [Install with helmfile](install.md).
