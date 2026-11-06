---
title: Data access control
sidebar_label: Data access control
sidebar_position: 5
description: Permission domains in Hanas Data Platform, where to configure each type of permission, query engine grants, row access policies, and column masking.
---

Permissions in Hanas Data Platform are not in one place. Each component has its own mechanism, and granting permission in one domain does not automatically grant it in another. This page helps administrators know what to configure and where.

## Permission domains

| Domain | What it decides | Mechanism |
|---|---|---|
| Identity | Who the users are, and which groups and roles they belong to | Keycloak, managed in **Settings** > **User Administration** of Hanas Console |
| Query engine | Who can read, write, and modify each source, folder, table, view, and function | Object grants by user or role |
| Row and column | Who sees which rows and which column values | Row access policy, column masking |
| Hanas Catalog | Who edits metadata and manages ingestion | Roles `data-governance-viewer`, `editor`, `admin` |
| dbt | Who views, edits, and runs dbt | Roles `dbt-viewer`, `dbt-editor`, `dbt-admin` |
| Compute | Who runs Spark | Roles `compute-user`, `compute-admin` and per-project ACLs |
| Ingestion | Who manages connections and data loading jobs | Teams by Keycloak group; `ingest-viewer`, `ingest-admin` |
| Analytics | Who uses dashboards and BI datasets | Superset roles mapped from Keycloak |
| Ontology | Who views and edits ontologies | Roles `ontology-viewer`, `ontology-editor`, `ontology-admin` |

:::caution Current limitations

Role synchronization between Keycloak and the query engine synchronizes membership only. It does not automatically grant object grants, Superset permissions, or storage permissions. Hiding a menu in the UI also does not replace permission checks in the backend.

:::

## Where to configure

| Task | Where |
|---|---|
| Create users, groups, and roles; assign roles | **Settings** > **User Administration**, the **Users**, **Roles**, and **Permissions** tabs. See [Manage users, groups, and roles](../operate/user-management.md) |
| Grant permissions on tables, views, and folders | The object's permissions tab in Console, or the SQL `GRANT` statement |
| Attach row access policies and column masking | **SQL Editor** (menu **Workspaces**), with `ALTER TABLE` or `ALTER VIEW` statements |
| Assign Data Governance roles | The user's roles on the `data-governance` client in Keycloak |
| Assign dbt and Compute roles | The user's roles in Keycloak; Compute ACLs in the project configuration |
| Map Superset roles | Configure the mapping from Keycloak groups and roles to Superset roles at deployment |

User management is covered in [Manage users, groups, and roles](../operate/user-management.md); single sign-on is covered in [Authentication and SSO with Keycloak](../operate/identity.md).

## Hanas Catalog

Hanas Catalog has three levels, and each higher level includes the lower ones. When a user has multiple roles, the system takes the highest level. A user with no role is treated as a viewer.

| Function | Viewer | Editor | Admin |
|---|:-:|:-:|:-:|
| Search, browse, view details, lineage, tags, glossary, assertions | Yes | Yes | Yes |
| Apply and remove tags, terms, owners, links; edit descriptions; related terms | No | Yes | Yes |
| Add lineage manually | No | Yes | Yes |
| Create, edit, and delete tag definitions; manage the glossary | No | Yes | Yes |
| Delete entities from the catalog | No | No | Yes |
| Metadata ingestion and Secrets, including viewing | No | No | Yes |

A query engine admin is automatically a Data Governance admin. A role only decides what you can do; which datasets you see is still decided by the query engine, and an admin also cannot see datasets the query engine does not allow them to see. A new role takes effect after the user signs in again.

## Object grants on the query engine

Grant permissions to roles rather than to individual users to make them easier to manage. Permissions apply to sources, folders, tables, views, and functions.

```sql
GRANT SELECT ON TABLE "lakehouse"."gold_retail"."customer" TO ROLE data_reader;
```

Commonly used permissions include `SELECT`, `ALTER`, `MODIFY`, `INSERT`, `DELETE`, `UPDATE`, `DROP`, `EXECUTE`, `MANAGE_GRANTS`. The source, schema, and table names in the example are illustrative.

## Row access policies and column masking

These two mechanisms filter rows or mask column values based on a function (UDF) that you define. The function must return the column's type.

:::info

The query engine applies row access policies and column masking to every query that passes through it, including SQL Editor, BI, JDBC/ODBC, and Arrow Flight. Console has no separate screen to manage these policies; you work with them in SQL.

:::

Example of masking a phone number so that only an approved person sees the real value. The schema, function, and role names are illustrative.

```sql
CREATE FUNCTION security.mask_phone (v VARCHAR)
RETURNS VARCHAR
RETURN SELECT CASE
  WHEN query_user() = '<approved_user>' THEN v
  ELSE '***'
END;

ALTER TABLE "lakehouse"."gold_retail"."customer"
  MODIFY COLUMN phone_number
  SET MASKING POLICY security.mask_phone (phone_number);

GRANT SELECT ON TABLE "lakehouse"."gold_retail"."customer" TO ROLE data_reader;
GRANT EXECUTE ON FUNCTION security.mask_phone TO ROLE data_reader;
```

Attach a row access policy, then remove a policy:

```sql
ALTER TABLE "lakehouse"."gold_retail"."account"
  ADD ROW ACCESS POLICY security.branch_filter (branch_code);

ALTER TABLE "lakehouse"."gold_retail"."customer"
  MODIFY COLUMN phone_number UNSET MASKING POLICY security.mask_phone;
```

Some notes when applying them:

- Grant `EXECUTE` on the policy function together with `SELECT`.
- The schema that holds the function and the roles must exist before you attach the policy.
- If you attach a policy to a view, check that the masked person has no direct read path to the base table.
- Do not hard-code a list of users in the function when many people are allowed to view; use a role or a verified mapping table.
- Admins do not see raw values by default; define clearly who may unmask.

:::caution Current limitations

Query engine policies apply only to queries that go through the query engine. Compute (Spark) currently reads data with the lakehouse's shared identity, so a person with the `compute-user` role can read raw data and bypass masking. Grant `compute-user` selectively for sensitive data.

:::

## dbt, Analytics, and Ontology

- dbt: `dbt-viewer`, `dbt-editor`, `dbt-admin`. A query engine admin is not automatically `dbt-admin`. Viewers can only run read SQL. The dbt workspace is shared, so everyone with a dbt role sees the projects and connections.
- Analytics: queries from Superset to the query engine run with the user's own identity, so object grants and policies still apply. Superset roles are mapped from Keycloak groups and roles at sign-in.
- Ontology: a person with no Ontology role does not see the menu and is blocked from the route in the UI.

## Next steps

- [Manage users, groups, and roles](../operate/user-management.md)
- [Authentication and SSO with Keycloak](../operate/identity.md)
- [Speed up queries with Reflections](../query/acceleration.md)
- [Metadata ingestion](metadata-ingestion.md)
