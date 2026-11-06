---
title: Install with helmfile
sidebar_label: Install
sidebar_position: 3
description: Steps to install Hanas Data Platform on Kubernetes with helmfile, from environment preparation, secrets, and feature flags to gateway routes and post-install checks.
---

This page walks you through a first installation of Hanas Data Platform with the unified installer. You need cluster administrator permissions and should have read [Deployment architecture](deployment-architecture.md) and [System requirements and sizing](requirements.md).

:::note Scope

The commands below are a runbook for you to run in your own environment. The hosts, IPs, and namespaces in the examples are illustrative only; replace them with your organization's values.

:::

## Requirements

- Kubernetes, Helm, helmfile, and the diff plugin meet the [system requirements](requirements.md).
- A StorageClass that provisions PVCs dynamically (the sample configuration uses Longhorn).
- APISIX is running and can reach Services in the cluster. The installer does not install APISIX or Longhorn.
- Domain names (or hosts entries) for Hanas Console, Keycloak, and the applications you enable by feature, resolvable from the browser.
- Image pull credentials if your registry requires them.

## Steps

### Step 1. Check the environment

Work from the root directory of the installer. Do not layer hand-assembled configuration snippets from the old split packages onto the unified installer.

```bash
kubectl config current-context
kubectl version
helm version
helmfile --version
kubectl get nodes
kubectl get storageclass
```

Confirm you are on the right context and that the StorageClass you plan to use exists.

### Step 2. Fill in the environment configuration file

The environment configuration file is `environments/local.yaml`, but the helmfile environment is named `default`. So you run `helmfile` without `-e`.

Fill in the following groups consistently: `namespaces`, `releases`, `scheme`, `hosts`, `gatewayIP`, `realm`, `clients`, `storageClass`, `externalS3`. For example:

```yaml
scheme: http
hosts:
  console: console.hanas.example.com
  keycloak: auth.hanas.example.com
  superset: bi.hanas.example.com
  kapas: kapas.hanas.example.com
gatewayIP: "<GATEWAY_IP>"
realm: data-platform
storageClass: longhorn
```

Leave the `urls.*` keys empty if you want the installer to derive URLs from `hosts`; override them only when the actual endpoints differ. See also [Configuration reference](configuration.md).

:::caution Current limitations

Switching `scheme` to `https` is more than changing one value. You also need TLS and forwarded headers at the gateway, cookie policy, internal URLs, and the production checks of the applications. The sample configuration runs HTTP.

:::

### Step 3. Prepare secrets

Copy the sample file only for a new installation. Do not overwrite the secrets file of an environment in operation.

```bash
cp environments/secrets.example.yaml environments/secrets.yaml
```

Fill in the values using your organization's secret management process. The `secrets.yaml` file is excluded from Git, but that does not replace a secret manager, backup, or file permissions. The list of key names is in [Configuration reference](configuration.md).

Store the encryption keys (`appEncryptionKey` for Hanas Catalog, Ingestion, and dbt) from the start and keep them unchanged across every deployment. If you lose a key, the encrypted data cannot be decrypted; see [Backup and recovery](backup-recovery.md).

### Step 4. Choose feature flags and images

Enable or disable optional components in the `features` block of the configuration file:

```yaml
features:
  superset: true
  kapas: true
  dbtRunner: true
  minio: true
  hanasCatalog: false
  ingestion: false
  compute: false
```

Before you enable a feature, fill in all its secrets and prerequisites. `compute` requires `dbtRunner` to be enabled, and also needs a Spark image and permission to create cluster-scoped resources. The image list is in `environments/images.yaml`; see [Upgrade and rollback](upgrade.md).

### Step 5. Review the inventory and diff

```bash
helmfile list
helmfile diff
```

Helmfile loads configuration in the order `images.yaml`, `local.yaml`, `secrets.yaml`. Diff output can contain sensitive data, so store it only in an appropriate operations channel.

### Step 6. Apply and monitor bootstrap

```bash
helmfile apply
```

Helmfile orders the apply by dependency: Keycloak, the realm seed Job, the query engine, the identity bootstrap Job, then the remaining applications. Monitor the state without printing Secrets:

```bash
kubectl -n keycloak-dp get pods,jobs
kubectl -n dataplatform get pods,jobs
kubectl -n superset-dp get pods,jobs
kubectl -n ontology get pods,jobs
kubectl -n dbt-studio get pods
kubectl -n kapas get pods
```

Two points to know while you observe:

- The query engine enables OAuth from its first start. The bootstrap Job uses the seeded SSO account to create the first identity, then creates a separate local admin and configures a Personal Access Token (PAT) for Superset. By default, the SSO admin and local admin have different names; do not use the same name for both kinds of identity.
- To apply a single release, use a selector by name. Do this only when the releases it depends on are ready:

```bash
helmfile -l name=ontology diff
helmfile -l name=ontology apply
```

For a first installation, use the full `helmfile apply`.

### Step 7. Create upstreams and routes on APISIX

APISIX is outside helmfile, so a successful apply does not create a public access path. After the Services exist, create upstreams and routes through the gateway's Admin API. Route, upstream, and rewrite details are in [API gateway and domains](gateway.md). Example for Hanas Console:

```bash
export APISIX_ADMIN='http://<APISIX_ADMIN_HOST>:9180/apisix/admin'
# Provide the APISIX_KEY variable through your organization's secret management mechanism.

curl -sS -X PUT "$APISIX_ADMIN/upstreams/console-ui" \
  -H "X-API-KEY: $APISIX_KEY" -H 'Content-Type: application/json' \
  -d '{"name":"console-ui","type":"roundrobin","scheme":"http","nodes":{"console-ui.dataplatform.svc.cluster.local:80":1}}'

curl -sS -X PUT "$APISIX_ADMIN/routes/console-ui" \
  -H "X-API-KEY: $APISIX_KEY" -H 'Content-Type: application/json' \
  -d '{"name":"console-ui","hosts":["console.hanas.example.com"],"uris":["/*"],"upstream_id":"console-ui","plugins":{"proxy-rewrite":{"headers":{"set":{"X-Forwarded-Proto":"http"}}}}}'
```

Repeat for Keycloak, Superset, and Kapas.

### Step 8. Check the Keycloak client and dbt roles

With the unified installer, the seed Job creates the `dbt` client as a role holder, along with the roles `dbt-viewer`, `dbt-editor`, `dbt-admin`, `compute-user`, and `compute-admin`, and groups them into the composite realm role `admin`. You do not need to import a client JSON file for a new installation.

1. Sign in to the Keycloak Admin Console and open the platform realm.
2. Open **Clients** and confirm the `dbt` client exists and has no sign-in flow enabled.
3. Assign roles to regular users as needed. The seed Job grants permissions only to the app admin; it does not grant them to every user automatically.

If Hanas Catalog needs to call dbt on a schedule, create a separate client with a service account and the `dbt-viewer` role, then enter the matching client ID and secret in the Hanas Catalog configuration. Do not enable a service account on the role-holder client just for convenience. See [Authentication and SSO](identity.md).

### Step 9. Verify after installation

```bash
python3 tests/smoke.py
# When the public routes are not yet created:
SKIP_PUBLIC=1 python3 tests/smoke.py
```

Run the command from the root directory of the installer, because the script reads configuration by relative path. Then run the functional checks in [Health checks and monitoring](health-checks.md). A passing smoke test does not prove that every SSO, query, or recovery flow works.

## Notes on disabling a feature

Helmfile removes a release when its feature is disabled on a later apply. Review `helmfile diff` and check the PVC retention policy, the StorageClass reclaim policy, and backups before you disable a feature.

## Troubleshooting

Common installation errors (sign-in hangs, a pod cannot resolve the public Keycloak, Superset cannot connect to its database) are covered in [Troubleshooting](troubleshooting.md).

## Next

- [Configuration reference](configuration.md).
- [API gateway and domains](gateway.md).
- [Authentication and SSO with Keycloak](identity.md).
- [Health checks and monitoring](health-checks.md).
