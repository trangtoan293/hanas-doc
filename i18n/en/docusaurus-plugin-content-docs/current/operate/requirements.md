---
title: System requirements and sizing
sidebar_label: System requirements
sidebar_position: 2
description: Kubernetes prerequisites, tools, storage, and reference resources for sizing a Hanas Data Platform deployment.
---

Hanas Data Platform needs Kubernetes infrastructure, persistent storage, and an application access path prepared before installation. This page provides reference resource configuration and guidance for planning by usage load.

## Infrastructure prerequisites

| Item | Requirement |
|---|---|
| Kubernetes | 1.30 or later when using Kapas in the current installer; Compute admission policies also need the corresponding API. |
| Helm and Helmfile | The README states Helm 3.14 or later and Helmfile 1.0 or later; the installer was verified with Helmfile 1.8.2. |
| Tools | `kubectl`, kubeconfig, `curl`; Python 3 and PyYAML to run the smoke test. |
| Diff | Helm must have a plugin that supports the diff command used by Helmfile. |
| Storage | A StorageClass that provisions PVCs dynamically; the sample configuration uses Longhorn. |
| Gateway | A running APISIX that resolves Service DNS and can reach the upstreams. |
| DNS and TLS | Application domains reachable from browsers and from pods that need to call the public issuer. |
| Image | Nodes can pull the pinned images, with registry credentials if your environment requires them. |
| Deployment permissions | Create namespaces, releases, PVCs, Jobs, and RBAC; Compute also needs permissions on cluster-scoped resources. |

The installer does not deploy Longhorn or APISIX. Check the CPU architecture of the images before you choose nodes; do not assume the images support every architecture.

## Resources in the sample configuration

The table below combines chart defaults with the installer values, one row per instance unless noted. CPU is expressed in cores or millicores; RAM and PVC use Kubernetes units.

A `—` in the CPU limit column means the installer does not declare an explicit CPU limit. The cluster's LimitRange or ResourceQuota can still impose an effective limit.

| Component | CPU request / limit | RAM request / limit | Logical PVC |
|---|---|---|---|
| Query engine master coordinator | `1 / 3` | `3Gi / 6Gi` | `8Gi` |
| Query engine coordinator | `1 / 3` | `3Gi / 6Gi` | `8Gi` |
| Query engine default executor | `1 / 3` | `3Gi / 6Gi` | `8Gi` |
| ZooKeeper | `250m / 1` | `512Mi / 768Mi` | `4Gi` |
| Keycloak | `100m / —` | `512Mi / 1Gi` | None |
| Keycloak PostgreSQL | `50m / —` | `256Mi / 512Mi` | `4Gi` |
| MinIO standalone | `250m / 375m` | `256Mi / 384Mi` | `10Gi` |
| Console UI | `100m / —` | `128Mi / 256Mi` | None |
| Console User API | `250m / —` | `512Mi / 1Gi` | None |
| Ontology API, 4 workers | `500m / —` | `512Mi / 2Gi` | None |
| Ontology graph-worker | `250m / —` | `512Mi / 1Gi` | None |
| Ontology PostgreSQL | `250m / —` | `512Mi / 2Gi` | `4Gi` |
| Ontology Redis | `50m / —` | `128Mi / 640Mi` | None |
| Superset web | `250m / —` | `1Gi / 2Gi` | None |
| Superset worker | `250m / —` | `1Gi / 2Gi` | None |
| Superset Celery beat | `50m / —` | `256Mi / 512Mi` | None |
| Superset PostgreSQL | `100m / —` | `256Mi / 512Mi` | `4Gi` |
| Superset Redis | `50m / —` | `64Mi / 256Mi` | None |
| Kapas web | `500m / 2` | `1Gi / 4Gi` | Data `4Gi`, secrets `1Gi`, backups `4Gi` |
| Kapas PostgreSQL | `250m / 1` | `512Mi / 2Gi` | `4Gi` |
| Kapas Redis | `100m / 500m` | `128Mi / 512Mi` | `2Gi` |
| dbt runner | `250m / 2` | `1Gi / 2Gi` | Storage `4Gi`, workspace `4Gi` |
| dbt PostgreSQL | `100m / —` | `256Mi / 512Mi` | `2Gi` |
| dbt Redis | `50m / —` | `64Mi / 256Mi` | `2Gi` |
| Each seed, bootstrap, or PAT-issuing Job | `50m / —` | `64Mi / 256Mi` | None |

The query engine roles use the chart preset with a request of `1 CPU/3072Mi` and a limit of `3 CPU/6144Mi`. The preset also sets an ephemeral-storage request of `50Mi` and a limit of `2Gi`; do not ignore temporary storage when you calculate node resources.

The Ontology migration Job does not declare explicit requests and limits in its template. InitContainers and other Jobs can create resource needs beyond the permanent containers in the table above.

### Optional components

:::note Requirements

The following rows apply only when you enable the corresponding feature. Spark drivers and executors are created per run, so there is no single fixed sizing for all Compute tasks.

:::

| Component | CPU request / limit | RAM request / limit | Storage |
|---|---|---|---|
| Hanas Catalog API | `100m / —` | `256Mi / 1Gi` | No dedicated PVC |
| Hanas Catalog runner | `250m / —` | `512Mi / 4Gi` | `emptyDir` up to `10Gi` |
| Hanas Catalog PostgreSQL | `100m / —` | `256Mi / 1Gi` | `4Gi` PVC |
| Ingestion API and worker | `500m / —` | `2Gi / 8Gi` | `20Gi` PVC, `4Gi` temporary dumps area |
| Ingestion PostgreSQL | `100m / —` | `256Mi / 1Gi` | `4Gi` PVC |
| Spark Operator controller | `100m / 1` | `512Mi / 1Gi` | No dedicated PVC |
| Spark driver and executor | Per run | Per run | Per run configuration |

Compute initializes a quota of `16 CPU` and `64Gi RAM` in requests, with at most `40` pods. The LimitRange sets a per-container ceiling of `4 CPU/18Gi` and a defaultRequest of `100m/256Mi`; a quota does not mean the resources are already reserved.

## Using the figures for sizing

The arithmetic total of the permanent containers currently enabled is approximately `7 CPU`, `18.25Gi RAM requests`, and `77Gi logical PVC`. This total does not include Kubernetes, CNI, APISIX, Longhorn, Jobs, image layers, rollouts, or failure headroom.

Each pod still needs a node with enough available resources to satisfy its own requests. Logical PVC capacity also differs from physical capacity when the storage uses replication or snapshots.

:::caution Current limitations

The values above support installer verification; they are not a minimum production configuration or a capacity commitment. No capacity benchmark, HA matrix, or minimum node count has been confirmed for every environment.

:::

## Recommendations by scale

The table below gives planning recommendations that you must adjust with real workloads and measurements. Do not convert a number of users into CPU/RAM without information about queries and concurrency.

| Usage scale | Recommendation |
|---|---|
| Functional testing | Start from the sample values, leave resources for Jobs, and run the acceptance cases one at a time. |
| Shared team use | Measure queries, dbt concurrency, and metadata growth; adjust requests, limits, and PVCs per component. |
| Many concurrent workloads | Budget separately for query executors, Ingestion, and Spark; check queues, quotas, and the impact on datastores. |
| Environments that need service recovery | Design storage, topology, and off-cluster backup, and rehearse restores against the agreed objectives. |

The sample MinIO has only `10Gi` and runs standalone. With real data, account for retention time, object growth, temporary data, and backup policy.

Kapas and dbt currently use RWO PVCs; increasing replicas requires evaluating shared state and how the volume is accessed. For PostgreSQL outside the cluster, confirm extensions, migration permissions, TLS, and recoverability before you switch.

## Next

- [Install with helmfile](install.md).
- [Configuration reference](configuration.md).
- [Backup and recovery](backup-recovery.md).
