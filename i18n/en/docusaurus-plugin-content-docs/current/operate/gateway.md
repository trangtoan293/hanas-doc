---
title: API gateway and domains
sidebar_label: API gateway
sidebar_position: 5
description: Configure APISIX, domains, upstreams, routes, and forwarded headers to access Hanas Data Platform from outside the cluster.
---

APISIX is the entry point from outside the cluster, and the installer does not manage it. This page lists the domains, upstreams, and routes you need to create so users can reach Hanas Console and the accompanying applications.

## Domains

Each application with its own interface needs a domain name that the browser can resolve. For example:

| Application | Example domain | When needed |
|---|---|---|
| Hanas Console | `console.hanas.example.com` | Always |
| Keycloak | `auth.hanas.example.com` | Always |
| Superset | `bi.hanas.example.com` | When Superset is enabled |
| Kapas | `kapas.hanas.example.com` | When Kapas is enabled |

These domains are declared in the `hosts` block of the environment configuration. The `hosts` field of an APISIX route does not include a port; if the gateway listens on a port other than 80/443, the public URLs and OIDC redirect URIs must still include that port.

The Superset and Kapas pods must be able to reach the public Keycloak domain. The installer adds hostAliases based on `gatewayIP` for this, but DNS on users' machines is still yours to configure.

## Upstreams and routes

| Host and path | Upstream (Service in the cluster) | Notes |
|---|---|---|
| Console, `/*` | `console-ui.dataplatform.svc.cluster.local:80` | Preserve the URI and set the correct forwarded scheme. |
| Keycloak, `/*` | `keycloak.keycloak-dp.svc.cluster.local:80` | Preserve the URI. Keycloak runs in production mode behind a proxy, so it needs correct `X-Forwarded-*` headers. |
| Superset, `/*` | `superset.superset-dp.svc.cluster.local:8088` | When Superset is enabled. |
| Kapas, `/*` | `kapas-web.kapas.svc.cluster.local:8088` | When Kapas is enabled. |

Console proxies the internal APIs (ontology, dbt, Hanas Catalog, Ingestion, Kapas) itself through nginx in the image, so with the current Console version you usually do not need separate routes for these paths. If you created separate routes for an older Console, review them, because a specific high-priority route can override the Console proxy.

## Route creation example

Set the variable for the Admin API, and provide the key through your organization's secret management mechanism:

```bash
export APISIX_ADMIN='http://<APISIX_ADMIN_HOST>:9180/apisix/admin'
# Provide the APISIX_KEY variable through your organization's secret management mechanism.
```

Create the upstream and route for Keycloak:

```bash
curl -sS -X PUT "$APISIX_ADMIN/upstreams/keycloak" \
  -H "X-API-KEY: $APISIX_KEY" -H 'Content-Type: application/json' \
  -d '{"name":"keycloak","type":"roundrobin","scheme":"http","nodes":{"keycloak.keycloak-dp.svc.cluster.local:80":1}}'

curl -sS -X PUT "$APISIX_ADMIN/routes/keycloak" \
  -H "X-API-KEY: $APISIX_KEY" -H 'Content-Type: application/json' \
  -d '{"name":"keycloak","hosts":["auth.hanas.example.com"],"uris":["/*"],"upstream_id":"keycloak","plugins":{"proxy-rewrite":{"headers":{"set":{"X-Forwarded-Proto":"http"}}}}}'
```

Use the same pattern for Console, Superset, and Kapas, replacing the host and upstream according to the table above. When you use HTTPS, set `X-Forwarded-Proto` to `https` and terminate TLS at the gateway.

## Forwarded headers and HTTPS

Keycloak, Console, and Superset use `X-Forwarded-*` to build public URLs. Wrong headers make redirects and the issuer differ from the configuration. Switching to HTTPS requires aligning TLS at the gateway, `scheme` in the environment configuration, cookie policy, and the production settings of each application.

:::caution Current limitations

The installer has no sample configuration for gateway timeouts, body size limits, WebSocket, or SSE. For long-running flows such as dbt or Kapas chat, check these limits on your gateway.

:::

## Troubleshooting

- Opening Console returns `404` or `502`: check that the route and upstream exist and that the Service is in the correct namespace.
- Sign-in repeats or redirects to the wrong host: check `X-Forwarded-Proto`, the host in the environment configuration, and the Keycloak issuer.

See also [Troubleshooting](troubleshooting.md).

## Next

- [Authentication and SSO with Keycloak](identity.md).
- [Install with helmfile](install.md).
- [Health checks and monitoring](health-checks.md).
