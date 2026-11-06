---
title: Configuration reference
sidebar_label: Configuration
sidebar_position: 4
description: Feature flags, main operational parameters, and secret key names of the Hanas Data Platform installer.
---

This page is a reference for the configuration keys that operators commonly adjust. The values are the installer's sample configuration, not production recommendations. The page lists secret key names only, never values.

## Configuration sources

Helmfile loads three files in order: `images.yaml` (images and digests), the environment configuration file, then `secrets.yaml`. Internal and public URLs are derived from `hosts`, `scheme`, and the release name; override them through `urls.*` only when needed.

## Feature flags

| Key | Sample | Effect and requirements |
|---|---|---|
| `superset` | `true` | Enables Apache Superset and the PAT-issuing Job. Requires the Superset secrets and the matching client secret. |
| `kapas` | `true` | Enables Kapas. Ontology receives the internal chat URL. Requires PostgreSQL, Redis, JWT, and the credentials the validation check requires. |
| `dbtRunner` | `true` | Enables the dbt runner. Console receives the dbt URL; Hanas Catalog receives the dbt URL if enabled. |
| `minio` | `true` | Creates MinIO in the cluster. When disabled, you must point `externalS3` at external object storage. |
| `hanasCatalog` | `false` | Enables the Hanas Catalog API, runner, and PostgreSQL. Requires images, an encryption key, and a database password. |
| `ingestion` | `false` | Enables Ingestion, PostgreSQL, and a persistent working directory. Requires images, an encryption key, and a database password. |
| `compute` | `false` | Requires `dbtRunner`. Enables RBAC, quota, admission policies, and Spark Operator; requires a Spark image. |

Disabling a feature changes the release lifecycle: the next apply can remove the release. It is not an operation that hides a menu. Check the diff, the PVC retention policy, and backups before you disable a feature.

## Main operational parameters

| Group | Sample | Meaning |
|---|---|---|
| `scheme`, `hosts.*`, `gatewayIP` | HTTP, hosts per environment | Public issuer, redirects, browser URLs, and pod hostAliases. |
| `realm` | `data-platform` | A single Keycloak realm shared by the whole platform. |
| `clients.*` | See [Authentication and SSO](identity.md) | Client ID for each application. The Kapas client is case-sensitive. |
| `urls.*` | Empty | Use the derived URLs. Do not put internal Service DNS in a URL meant for browsers. |
| `storageClass` | `longhorn` | Must exist before installation. |
| `externalS3.*` | In-cluster MinIO | Endpoint, bucket, and path of the object storage for the query engine. Must stay consistent with existing data. |
| `minio.size` | `10Gi` | A small size for installer verification; increase it when you use real data. |
| `keycloakSeed.enabled` | `true` | Disabling it on a new installation loses the realm seed step that the query engine needs. |
| `keycloakSeed.groupsClaim` | `true` | Adds a `groups` claim mapper (full path); Ingestion uses it as the team. |
| `keycloakSeed.translations.enabled` | `true` | Imports vi/en translations into the realm; keys present in the file overwrite manual edits each time the Job reruns. |
| `keycloakSeed.compositeAdmin.skipClients` | Empty | By default, groups every client role into the `admin` realm role; this is not a least-privilege setting. |
| `dbtRunner.maxConcurrentRuns` | `10` | Limits the number of concurrent dbt runs. |
| `hanasCatalog.maxConcurrentRuns` | `4` | Number of concurrent runs for the Hanas Catalog runner. |
| `hanasCatalog.dbtStudioClientId` | Empty | Required when Hanas Catalog runs dbt sources on a schedule. |
| `ingestion.workerThreads` | `2` | Number of workers in the Ingestion pod. |
| `ontology.allowDestructiveMigrations` | `false` | Applies only to migrations the application marks; it does not guarantee blocking every delete statement. |
| Ontology `api.workers` | `4` | Affects the number of database connections and memory. |
| Kapas web | 1 replica, RWO PVC | Has shared state; do not increase replicas arbitrarily. |
| Kapas mode, cookie secure, TLS verification | `development`, `false`, `false` | Must be changed together when you move to production HTTPS. |

The keys of the bootstrap Job and the PAT-issuing Job keep their identifier names in the configuration:

```yaml
dremioBootstrap:
  localAdmin:
    username: admin      # local admin, different from the SSO admin identity
  patMaxDays: 36525      # PAT lifetime ceiling; the query engine accepts 1 to 36525
dremioPat:
  secretName: superset-dremio-pat   # Secret written by the Job, read by Superset
```

If you disable the PAT-issuing Job while Superset is enabled, nothing issues a PAT for Superset any more.

The Ontology parameters (query limits, graph, embedding) and the Kapas parameters (token budget, sandbox, NetworkPolicy) are also in the environment configuration. The sample values have not been tuned for real workloads.

## Secret key names

The block below lists the key names in `secrets.example.yaml`. Do not store values in Git or in documentation.

```yaml
# Client credentials
clientSecrets: [dremio, superset, bootstrap, ontology, kapas]
# Keycloak
keycloak: [masterAdminPassword, appAdminPassword, db.password, db.postgresPassword]
# Query engine and S3
dremio: [authPassword, s3AccessKeyID, s3AccessKeySecret, licenseKeyB64]
# Ontology
ontology: [postgresPassword, embeddingApiKey, graphWorkerSharedSecret, dremioPat]
# Superset
superset: [secretKey, guestTokenJwtSecret, postgresPassword, password]
# Kapas
kapas: [postgresPassword, redisPassword, jwtSecret, authPassword, hanasPassword, kpServiceToken, braveApiKey, vnstockApiKey]
# dbt
dbtRunner: [appEncryptionKey, postgresPassword, postgresAdminPassword, redisPassword]
# Hanas Catalog
hanasCatalog: [databasePassword, appEncryptionKey, dremioServicePat, dbtStudioClientSecret]
# Ingestion
ingestion: [databasePassword, appEncryptionKey, datahubToken]
```

The groups above correspond to: client credentials, Keycloak, query engine and S3, Ontology, Superset, Kapas, dbt, Hanas Catalog, Ingestion.

Some keys are needed only when the related feature is enabled, for example the Hanas Catalog PAT for sources that run on a schedule. Conversely, helmfile validates `clientSecrets` for every declared client, so do not delete the whole group without checking.

Constraints to remember:

- The PostgreSQL and Redis passwords for Kapas and dbt may use only the characters `A-Za-z0-9._~-`, because they appear in connection URLs.
- Superset secrets must not contain the double template-opening sequence (two consecutive opening curly braces).
- The PostgreSQL password on both the server side and the application side of Superset comes from `superset.password`; the admin password is a different key.
- Encryption keys must stay unchanged for the databases already created.

## Next

- [Install with helmfile](install.md).
- [API gateway and domains](gateway.md).
- [Authentication and SSO with Keycloak](identity.md).
