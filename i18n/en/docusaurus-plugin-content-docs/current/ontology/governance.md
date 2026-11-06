---
title: Ontology governance
sidebar_label: Governance
sidebar_position: 7
description: The draft, review, publish, and deployment workflow, release gates, audit, roles, and ontology import/export.
---

This page describes how to control ontology changes: who can do what, which gates a change passes through before it reaches users, and how to export or import definitions between workspaces. It is intended for ontology admins and approvers.

## Roles

| Role | Permissions |
|---|---|
| `ontology-viewer` | Read the catalog, records, and queries; manage your own object sets. |
| `ontology-editor` | Same as viewer, plus author concepts, relationships, mappings, presentation, and metrics; validate and submit drafts. |
| `ontology-admin` | Same as editor, plus publish, roll back, manage deployments, manage workspaces and templates, and configure AI. |
| `ontology-action-worker` | A machine account that processes action requests; admins also have this permission. |

Roles come from the user's identity; see [Manage users, groups, and roles](../operate/user-management.md). The tenant is determined from the token, not from the request content.

:::caution Current limitations

A workspace is a project scope, but there is no separate member list for each workspace yet. Access is based on role and tenant. The `hidden` flag and business groups are not permission mechanisms; use grants, row access, and masking in the query engine, see [Data access control](../govern/access-control.md).

:::

## Draft, review, publish

1. **Draft**: an editor authors the canonical document and manifest. A draft does not change the serving runtime.
2. **Review**: an editor reviews the impact and submits the draft to `pending_approval`. The draft is locked for editing. The submitter or an admin can withdraw it; an admin can reject it with a reason.
3. **Publish**: an admin checks the checksum and the compiled preview, approves the revision, then creates and activates the deployment.

An admin can publish a valid draft directly, so submitting is not required for admins.

## Revisions and deployments

A revision, an approved revision, a deployment, and the serving runtime are different objects. A saved version is not necessarily serving.

| Deployment step | Meaning |
|---|---|
| Prepare | Prepare the projection from the approved revision. |
| Health check | Check the deployment status. |
| Preview activate | View the impact of changing the runtime. |
| Activate | Activate with a generation check to avoid overwrites caused by conflicts. |

The result cache is refreshed when the runtime changes. **Rollback** creates a draft from an older revision and then goes through the same release gates; confirmation is required for operations that destroy dependent resources.

## Governance gate

Before release, the system runs the following checks.

- Authorization: an editor cannot change the serving state, writeback or action rules, or interfaces, which are in the admin scope. The system compares the privileged parts of the manifest before and after.
- Checksum: content that changed after the preview must be reviewed again.
- Compile and source schema: datasets, columns, and types must still be valid.
- Mapping: entities that need a runtime must have a dataset and primary key.
- Agent: there are no active AI runs.
- Impact: review dependent resources before a breaking change.

This gate relies on roles and release checks. It does not automatically sync data classification from external governance systems to grant runtime permissions.

## Audit

The audit log records the tenant, actor, action, resource, and details. Important operations such as submit, reject, import, publish, activate, and action requests are all recorded. Admins read the audit log through the UI or API.

The audit log stores ontology changes, not a copy of business data, which remains in the query engine.

## Import and export

You can export definitions as a ZIP package and import them into another workspace. There are three package types.

| Package | Content |
|---|---|
| `ossie` | Canonical concepts and relationships, without mappings. |
| `mapping` | Mappings and manifest, with a reference to the ontology used. |
| `bundle` | Both the ontology and mappings. |

Export prefers the approved revision, then the serving revision, then the draft. The package does not contain records, action approvals, deployment state, or credentials; the system scans for and blocks keys that look like secrets, but this is a check by key name, not a guarantee against leaks in every description string.

The staged import process:

1. Upload the package to an import session; nothing changes in the runtime yet.
2. The system reconciles resources by canonical identity, not by display label.
3. For each resource, choose `CREATE_NEW`, `MATCH_EXISTING`, or `SKIP`; you can apply decisions in bulk.
4. Resolve blockers, then apply the import to the draft. The write to the draft is atomic.
5. Validate, review, and publish through the normal process.

You can also import a canonical YAML or JSON document directly into a draft. The file must be UTF-8, up to 5 MiB. A ZIP package is up to 20 MiB compressed and 50 MiB uncompressed.

:::caution Current limitations

Excel import and export are not supported. Only YAML, JSON, and ZIP packages are available.

:::

## Troubleshooting

| Symptom | Resolution |
|---|---|
| Cannot publish | Read the issues in the release preview; end any active agent run. |
| Checksum mismatch | Reload the draft and review the preview again. |
| Import is blocked | Resolve the decisions that are still `UNRESOLVED`, or conflicts. |
| Rollback asks for confirmation | Review the dependent resources that are affected. |

## Next steps

- [Ontology Workspace](workspace.md) for the authoring flow.
- [Banking industry ontology templates](industry-templates.md).
- [Ontology API](../develop/ontology-api.md) for deployment and portability.
