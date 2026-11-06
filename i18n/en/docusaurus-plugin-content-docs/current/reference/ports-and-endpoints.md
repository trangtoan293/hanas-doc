---
title: Ports and endpoints
sidebar_label: Ports and endpoints
sidebar_position: 2
description: Table of ports and Services of Hanas Data Platform components in the Kubernetes cluster, and API paths through the gateway.
---

This page lists the Services, ports, and paths that Hanas Data Platform uses. Use it when you configure a firewall, gateway, or NetworkPolicy, or when you need to know where a client should connect.

:::note Scope

The tables are derived from the installation bundle configuration as of 05/11/2026. Confirm the actual Service names and ports after installation with `kubectl get svc,endpoints` in each namespace.

:::

## Services in the cluster

All application Services are ClusterIP. Headless Services (`clusterIP: None`) provide stable DNS and internal communication between pods.

| Namespace | Service | Port | Role |
|---|---|---|---|
| `dataplatform` | `console-ui` | 80 (container 8080) | Entry point to Hanas Console, nginx reverse proxy |
| `dataplatform` | `console-user-api` | 8081 | User and permissions API |
| `dataplatform` | `dremio-26` | 9047, 31010, 32010 | Query engine: REST/web, SQL client, Arrow Flight |
| `dataplatform` | `dremio-26-headless` | 9047, 31010, 32010, 45678, 45679, 44349, 50000 | Stable DNS and internal communication between roles |
| `dataplatform` | `dremio-26-zookeeper` | 2181 (2888, 3888 internal) | Query engine coordination |
| `keycloak-dp` | `keycloak` | 80 (container 8080) | Realm, OIDC, and Admin API |
| `keycloak-dp` | `keycloak-postgresql` | 5432 | Keycloak database |
| `hanas-minio` | `hanas-minio` | 9000 | S3 API (MinIO Console is off) |
| `superset-dp` | `superset` | 8088 | Superset UI and API |
| `superset-dp` | `superset-superset-postgresql` | 5432 | Superset metadata |
| `superset-dp` | `superset-superset-redis-master` | 6379 | Cache and Celery |
| `ontology` | `ontology-ontology-platform-api` | 8200 | Ontology REST, readiness `/readyz` |
| `ontology` | `ontology-ontology-platform-graph-worker` | 8210 | Graph processing, internal |
| `ontology` | `ontology-ontology-platform-postgres` | 5432 | Ontology database |
| `ontology` | `ontology-ontology-platform-redis` | 6379 | Cache |
| `kapas` | `kapas-web` | 8088 | Kapas UI and API, SSO callback |
| `kapas` | `kapas-postgres`, `kapas-redis` | 5432, 6379 | Kapas's own datastores |
| `dbt-studio` | `dbt-dbt-runner` | 8080 | dbt Studio API |
| `dbt-studio` | `dbt-postgresql`, `dbt-redis-master` | 5432, 6379 | dbt Studio metadata and Redis |
| `hanas-catalog` | `hanas-catalog-api`, `hanas-catalog-postgres` | 8091, 5432 | Present only when Hanas Catalog is enabled; the runner has no HTTP Service |
| `ingestion` | `ingestion-service`, `ingestion-service-postgres` | 8090, 5432 | Present only when Ingestion is enabled |
| `hanas-compute` | One Service per Spark run | Per run | Created dynamically when Compute runs |

The Hanas Catalog, Ingestion, and Compute Services appear only when you enable the corresponding feature in the [Configuration reference](../operate/configuration.md).

## Query engine ports

| Port | Protocol | Used by |
|---:|---|---|
| 9047 | HTTP: web and REST API | Users, [REST API](../develop/query-engine-api.md) |
| 31010 | JDBC and ODBC | [SQL clients](../develop/sql-clients.md) |
| 32010 | Arrow Flight / Flight SQL | [SQL clients](../develop/sql-clients.md) |
| 45678 | Node-to-node communication | Cluster-internal only, not a user API |
| 2181 | ZooKeeper | Cluster-internal only |

Ports 31010 and 32010 are two separate endpoints; do not use the JDBC port for Arrow Flight.

## Paths through Hanas Console

Nginx in Hanas Console forwards the following prefixes to the services behind it. A production gateway may use different paths; check against your configuration in [API gateway and domain names](../operate/gateway.md).

| Prefix | Service | Documentation |
|---|---|---|
| `/ontology-api` | Ontology | [Ontology API](../develop/ontology-api.md) |
| `/api/chat` | Kapas | [Kapas API and SSE](../develop/kapas-api.md) |
| `/catalog-api` | Hanas Catalog | [Hanas Catalog API](../develop/catalog-api.md) |
| `/dbt-runner` | dbt Studio | [dbt Studio](../transform/dbt-studio.md) |
| `/ingest-api` | Ingestion | [Data ingestion](../connect/ingestion.md) |

## Network notes

- Expose outside the cluster only the ports that are truly needed: the gateway's web port, and 31010 or 32010 if SQL clients run outside the cluster.
- Keep datastores (PostgreSQL, Redis) and the query engine's internal communication ports inside the cluster.
- Details on dependency order and network boundaries are in [Deployment architecture](../operate/deployment-architecture.md).

## Next

- [Components and versions](components-and-versions.md).
- [API gateway and domain names](../operate/gateway.md).
- [Health checks and monitoring](../operate/health-checks.md).
