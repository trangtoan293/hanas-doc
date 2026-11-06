---
title: Troubleshooting
sidebar_label: Troubleshooting
sidebar_position: 12
description: Known issues when installing and operating Hanas Data Platform, organized by symptom, cause, and resolution.
---

This page collects issues recorded while building and deploying the installer. Each entry has a symptom, a cause, and a resolution. Some entries have been fixed in the current sample configuration; check your actual configuration before drawing conclusions.

## General diagnosis

```bash
kubectl -n <NAMESPACE> get pods,jobs
kubectl -n <NAMESPACE> describe pod <POD>
kubectl -n <NAMESPACE> logs <POD> --previous
helm history <RELEASE> -n <NAMESPACE>
```

Check Events before concluding that an image is broken. Do not include Secret contents in error reports.

## Query engine and Console

| Symptom | Cause | Resolution |
|---|---|---|
| ZooKeeper is `OOMKilled` and the query engine restarts with it | The old heap was larger than the container memory limit. | The current configuration reduces the heap and raises the RAM limit. Check your actual values and memory pressure on the node. |
| The query engine restarts before it finishes starting | The liveness probe initial delay is too short. | The current configuration uses a delay of `180s` and a release timeout of `1800s`. Check the probe Events. |
| `Failed to load private key` after a restart on an old PVC | The recursive ownership change caused by fsGroup left the security directory with the wrong owner. | The master coordinator sets `fsGroupChangePolicy: OnRootMismatch`. For a PVC whose permissions are already broken, take a snapshot, then fix the permissions together with the team responsible for the query engine. |
| SSO sign-in intermittently reports `400 Invalid state` | The OAuth request went through a different coordinator than the node that issued the state. | Console and the bootstrap Job must use headless DNS pinned to the master coordinator. Do not change it to a round-robin Service. |
| Console returns `502` after the query engine restarts | nginx kept the IP of the old pod. | Console uses dynamic DNS and a resolver; check the FQDN, that the template matches the image, and the resolve interval. |
| The Console chart blocks a tag upgrade | `templateForTag` differs from the image tag. | Synchronize the nginx template with the image, then update `templateForTag`. Do not skip the check. |
| Hanas Catalog or Ingestion API paths return `502` | The feature is disabled so the backend is not deployed, but the Console nginx is still running. | Enable the correct feature and its prerequisites if you need it. This is not a failure of the whole Console. |
| Ontology or dbt API paths return `404` in an older Console | The older Console does not proxy these paths automatically. | Create a separate APISIX route for the older version. For the current version, check that no old route overrides it. See [API gateway and domain names](gateway.md). |

## Sign-in and SSO

| Symptom | Cause | Resolution |
|---|---|---|
| Sign-in hangs or the browser tries to reach an internal Service address | Public and internal URLs are mixed up, or the port or redirect is wrong. | Compare `hosts`, `urls.*`, the realm issuer, and forwarded headers. See [Authentication and SSO](identity.md). |
| Pods cannot resolve public Keycloak | DNS, hostAliases, or `gatewayIP` is wrong. | Check `gatewayIP`, that the hostname in hostAliases is declared without a port, and connectivity from the pod to the gateway. The user's workstation DNS is a separate matter. |
| Kapas reports `sign-in link expired` and the log shows `cookie_present=False` | A secure cookie was set on an HTTP connection. | HTTP environments must keep `development` mode with the secure cookie set to `false`. For production you need TLS and must change the whole set of settings together. |
| Kapas SSO does not sign in | The client ID has the wrong case. | Keep the client ID exactly as seeded (case-sensitive) with its matching secret. |
| Ontology tool or chat returns `401` | Missing audience, missing tenant fallback, or the client is not allowed to perform token exchange. | Check the audience, the tenant mapping, and the exchange permission of the `ontology` client for the two audiences it needs. |
| An Ontology user gets `403` despite having the `admin` role | The application relies on the `ontology-*` roles. | Assign the corresponding `ontology-*` role. |
| Superset token exchange to the query engine fails with `401` | The actor PAT comes from the SSO user, or the PAT is invalid. | Use the local admin PAT created by the bootstrap Job; check the target Secret. Do not print the PAT to the terminal. |
| Errors after switching `scheme` to `https` | The production checks require HTTPS and exchange, while internal URLs are still HTTP. | Review all internal URLs, the authentication mode, and the production settings; do not change only `scheme`. |

## Kapas

| Symptom | Cause | Resolution |
|---|---|---|
| Does not start, the runtime path is not writable | PVC ownership for UID 10001. | Enable volumePermissions in the values; check the mount and owner. |
| Database or Redis DNS error, or an Alembic interpolation error | The password contains characters that break the connection URL. | Use a password made only of `A-Za-z0-9._~-`, kept in sync on the server and application sides. |
| `502` when NetworkPolicy is enabled | The default policy selects an ingress namespace that differs from the actual gateway. | Specify the correct namespace and labels of the gateway. Do not turn off the whole policy as a substitute for access design. |

## Superset

| Symptom | Cause | Resolution |
|---|---|---|
| `SQLAlchemyError`, cannot connect to the database | The PostgreSQL password on the server side differs from the application side. | Both take it from `superset.password`; check old Secrets and the already-initialized database. |
| Init deadlock, pod waits for a Secret | Migration and web hold the lock together, or waiting for Ready prevents the hook from running. | Keep the configuration that does not wait for Ready; check the `superset-migrated` Secret and the init log. A `CreateContainerConfigError` state while waiting at the initial gate is not necessarily a wrong password. |
| The gate does not appear with the right name | The release was renamed or fullname was overridden. | The release name must contain `superset`; do not use `nameOverride` or `fullnameOverride`. |
| PostgreSQL crash-loops on an old PVC | The PostgreSQL 14 binary meets PostgreSQL 18 data. | Stop the upgrade; convert or restore the data per major version. A Helm rollback does not downgrade data. |
| Alerts and reports do not run on schedule | Celery beat is missing. | The current configuration enables beat; check that beat is Ready and the scheduler log. |

## Ontology, dbt, and other components

| Symptom | Cause | Resolution |
|---|---|---|
| An Ontology upgrade reports `MigrationIntegrityError` | The old migration history does not match the squashed schema. | Back up, then agree on how to handle the ledger and data with the application team. Do not edit checksums yourself. |
| Ontology restarts when the database fails | The same readiness endpoint is used for both liveness and readiness. | Recognize this behavior when diagnosing; restore the database first. |
| A new dbt does not start, missing tables or columns | The initialization script runs only for a new database; the old database has not had its schema upgraded. | The `db-upgrade` step handles this when you use the bundled PostgreSQL. For an external database, run the full schema upgrade. See [Upgrade and rollback](upgrade.md). |
| dbt Git SSH fails to write files | The known_hosts directory is not writable. | Set `GIT_SSH_DIR=/data/storage/git-ssh` and `fsGroup` 10001, and check the PVC. |
| MinIO Console `ImagePullBackOff` | The old MinIO Console image is no longer in the registry. | The configuration disables the MinIO Console; the object API on port 9000 still works. |
| Enabling Compute reports an existing resource not owned by Helm | The namespace was created by hand earlier. | Verify ownership and adopt it in a controlled way. Do not delete a namespace that holds data. |

## When you need support

Collect the image versions, the `helmfile diff` output, Events, and relevant logs (with Secrets removed), then contact your support channel. See [Health checks and monitoring](health-checks.md) for the signals you should have ready.

## Next steps

- [Health checks and monitoring](health-checks.md).
- [Authentication and SSO with Keycloak](identity.md).
- [Upgrade and rollback](upgrade.md).
