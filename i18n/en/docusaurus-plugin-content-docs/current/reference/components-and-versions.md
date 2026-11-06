---
title: Components and versions
sidebar_label: Components and versions
sidebar_position: 3
description: List of Hanas Data Platform components, the images and tags pinned in the installation bundle, and how to record versions during operations.
---

This page lists the components of Hanas Data Platform and the images that the installation bundle pins. Use it to know which version your environment runs, and to cross-check when you upgrade or contact [support](support.md).

:::note Scope

The data comes from the bundle's image declaration file as of 05/11/2026. The images actually running may differ if your organization changed tags; check `helmfile diff` or `kubectl get pod -o wide` for the current state.

:::

## Components and roles

| Component | Role | Helm release |
|---|---|---|
| Hanas Console | Web UI and reverse proxy to the APIs | `console` |
| User API | API for users, groups, roles, and synchronization with the query engine | `console` |
| Query engine | SQL, Reflection, catalog, Arrow Flight, JDBC/ODBC | `dremio` |
| Keycloak | Identity, SSO, OIDC | `keycloak` |
| Ontology (API and graph worker) | Ontology layer | `ontology` |
| Kapas | AI assistant | `kapas` |
| dbt Studio runner | dbt Studio and Compute | `dbtRunner` |
| Hanas Catalog | Metadata catalog, lineage, glossary | `hanasCatalog` |
| Ingestion service | Loads data into Iceberg | `ingestion` |
| Apache Superset | Dashboards and BI | `superset` |
| Initialization hook job | Seed, bootstrap, and initial PAT creation | Job in the bundle |

The bundle also deploys infrastructure components: MinIO (S3), a dedicated PostgreSQL and Redis for each application, ZooKeeper for the query engine, APISIX as the gateway, and the Spark operator for Compute. The versions of these components are declared in each chart's values.

## Pinned images and tags

Tags with the suffix `@sha256:...` are pinned by digest, because tags in a registry can be overwritten. The table below lists only the tag part; the digest is in the image declaration file.

| Image key | Repository | Tag |
|---|---|---|
| `consoleUi` | `katalysthub/dremio-ee-ui` | `20261105-e706ad90` (digest) |
| `consoleUserApi` | `silver13072002/dremio-user-api` | `08_10` |
| `dremio` | `nghnhhquang/dremio-kt` | `26.1.6` |
| `zookeeper` | `katalyst147/bitnami_zookeeper` | `3.9.5-UBI9-r1` |
| `dremioInitBase` | `katalyst147/base` | `UBI9.3-r1` |
| `keycloak` | `katalyst147/keycloak-dataplatform` | `26.3.3-2.1` |
| `dpHooks` | `katalyst147/dp-hooks` | `1.3` |
| `ontologyApi` | `katalysthub/ontology-api` | `20261029-1bf7dd85` (digest) |
| `ontologyGraphWorker` | `katalysthub/ontology-graph-worker` | `20261029-1bf7dd85` (digest) |
| `superset` | `tranphat2911/superset-kt` | `6.1.0-authlib` |
| `kapas` | `katalysthub/qwenpaw-kapas` | `20261029-0a45f100` (digest) |
| `dbtRunner` | `katalysthub/dbt-studio-runner` | `20261105-e706ad90` (digest) |
| `computeSpark` | `katalysthub/spark-compute` | `20261105-e706ad90` (digest) |
| `hanasCatalog` | `katalysthub/hanas-catalog` | `20261102-4ee4410f` (digest) |
| `ingestionService` | `katalysthub/ingestion-service` | `20261102-4ee4410f` (digest) |

The tag convention for images built by the development team is `<YYYYMMDD>-<8-character commit hash>`. The date is the build date, and the commit hash points to the exact source revision.

## Open-source component versions

| Component | Version in the bundle |
|---|---|
| Query engine | 26.1.6 |
| Keycloak | 26.3.3 |
| Apache Superset | 6.1.0 |
| Apache Spark (Compute image) | 4.1.3 |
| ZooKeeper | 3.9.5 |
| Ingestion (data loading engine) | OLake v1.1.0 |

## Recording versions during operations

Before and after each upgrade, save the following:

1. The contents of the image declaration file and the tag or digest of each release.
2. The approved `helmfile diff` output.
3. The enabled feature flags, because they determine which releases exist.

The procedure for changing tags, handling migrations, and rolling back is in [Upgrade and rollback](../operate/upgrade.md). When you submit a support request, attach this list of tags or digests.

## Next

- [Upgrade and rollback](../operate/upgrade.md).
- [Ports and endpoints](ports-and-endpoints.md).
- [Support and maintenance](support.md).
