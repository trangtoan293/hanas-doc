---
title: Authentication and SSO with Keycloak
sidebar_label: Authentication and SSO
sidebar_position: 6
description: Realm, clients, roles, mappers, SSO across components, token exchange, and how to tell public URLs from internal URLs in Keycloak.
---

import Diagram from '@site/src/components/Diagram';

Hanas Data Platform uses Keycloak as its shared identity provider. This page describes the realm, clients, roles, and how components use tokens, so you can configure and diagnose sign-in.

## Realm and administrator accounts

The whole platform uses one application realm, named `data-platform` in the sample configuration. There are two different kinds of administration:

- Keycloak administration: sign in to the `master` realm. This is used for the Admin API and Admin Console.
- Application administration: a user in the application realm, granted the `admin`, `ontology-admin`, and `ingest-admin` roles and realm management permissions by the seed Job.

Keycloak runs in production mode, accepts `X-Forwarded-*` headers from the gateway, and uses the public hostname. The seed Job creates the realm before the query engine starts.

## Clients

| Client ID | Type | Role |
|---|---|---|
| `odc` | Public SPA, PKCE | Signs in to Hanas Console; has the `groups` mapper. |
| `hd` | Confidential | OAuth for the query engine; the callback returns to the Console SSO sign-in page. |
| `superset` | Confidential | Superset sign-in. |
| `bootstrap` | Direct access grant | Used by the bootstrap Job during the first installation. |
| `ontology-web` | Public SPA | Audience for tokens that tools use to call back into Ontology. |
| `ontology` | Confidential | Token exchange for the Ontology integration. |
| `dbt` | Role holder, sign-in disabled | Holds the client roles for dbt and Compute. |
| `data-governance` | Role holder, sign-in disabled | Holds the Hanas Catalog roles. |

The Kapas client ID is case-sensitive and must match the seeded value exactly:

```yaml
clients:
  kapas: KaPaS
```

Changing the case makes Keycloak treat it as a different client, and Kapas cannot sign in.

:::note Requirements

Some clients exist only when the corresponding feature is enabled or when the client name is set in the environment configuration. Role holder clients are not created if the corresponding key is left empty.

:::

## Roles and how they map to applications

Realm roles: `admin`, `user`, `ontology-viewer`, `ontology-editor`, `ontology-admin`, `ingest-admin`, `ingest-viewer`. The seed Job groups client roles into the composite realm role `admin`.

| Component | Roles to assign |
|---|---|
| Ontology | Realm roles `ontology-viewer`, `ontology-editor`, `ontology-admin`. The `admin` role alone does not guarantee ontology permissions. |
| dbt | Client roles `dbt-viewer`, `dbt-editor`, `dbt-admin` on the `dbt` client. |
| Compute | `compute-user`, `compute-admin` on the `dbt` client; running jobs also requires `dbt-editor` or higher. |
| Hanas Catalog | `data-governance-viewer`, `data-governance-editor`, `data-governance-admin`. Users without a role are treated as viewers. |
| Ingestion | `ingest-admin`, `ingest-viewer`; the team comes from the `groups` claim. |
| Superset | `superset_admin` maps to the Admin role and `superset_user` to Gamma; roles are synchronized at every sign-in. |

The `groups` mapper adds the `groups` claim, with full paths (for example `/crm`), to the access token, ID token, and userinfo. The seed Job does not grant permissions to users that already exist.

:::caution Current limitations

The `skipClients` setting is empty by default, so every client role is grouped into `admin`. This is convenient for the initial installation but is not a least-privilege design. Review it before using the platform in a multi-user environment.

:::

## SSO and token exchange

<Diagram name="03-dang-nhap-phan-quyen" alt="One sign-in, permissions follow the user" />

1. The browser signs in to Keycloak through the `odc` client. The applications share the realm, but each backend still verifies tokens and permissions on its own.
2. The query engine exchanges the OIDC code on the server side and issues its own session. Hanas Console also obtains a Keycloak token to call other services.
3. Ontology accepts tokens with a configured audience; when a token lacks the `tenant` claim, Ontology derives it from the client that issued the token.
4. When Ontology calls Kapas chat, or Kapas calls a tool back, the token is exchanged (RFC 8693) for the matching audience. Keycloak must allow these exchanges; having a client secret does not mean the client has exchange permission.
5. Superset signs in through OAuth, then exchanges the token to the query engine, using the local admin PAT as the actor and the current user as the subject. The configuration describing this flow stops on error and does not fall back to the proxy account's permissions.
6. Hanas Catalog checks permissions against the viewer's query engine session. Scheduled sources use a service PAT or a dedicated service account, which differs from the viewer's identity.

There is no end-to-end verification yet of token exchange permissions and claims in a real environment; check them as described in [Health checks and monitoring](health-checks.md).

In the UI, tokens for external integrations are managed under **Settings** > **Integrations** > **External Tokens**. Your personal tokens are under the account menu, **Access Tokens**.

## Public URLs and internal URLs

Mixing up the two kinds of URL is a common cause of sign-in failures.

| Flow | URL to use |
|---|---|
| Browser sign-in, iframes, redirect URIs, issuer in tokens | Public URL with the correct scheme and port. |
| Query engine calling Keycloak | Internal URL; the authentication URL opened in the browser is the public URL. |
| Ontology, dbt, and Ingestion verifying JWTs | Compare `iss` with the public issuer, and fetch JWKS through the internal URL. |
| Kapas, Superset | Use the public issuer; pods must resolve the public domain name through the gateway. |
| Hanas Catalog | Verifies the signature and expiry through internal JWKS and does not check `iss`, as described in the chart. |
| Console to query engine | Pinned to the master coordinator through headless DNS, so the node that issued the OAuth state handles the callback. |

Console provides the public URL to the SPA and the internal URL to the User API. If you put the internal Service DNS name into a public URL, the browser cannot resolve it and sign-in does not complete.

## Troubleshooting

For `Invalid state` errors, `401` errors in Ontology, and Kapas sign-in, see [Troubleshooting](troubleshooting.md).

## Next steps

- [Manage users, groups, and roles](user-management.md).
- [API gateway and domain names](gateway.md).
- [Configuration reference](configuration.md).
