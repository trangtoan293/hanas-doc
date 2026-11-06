---
title: Connect External BI Tools
sidebar_label: External BI
sidebar_position: 2
description: Connect Power BI, Tableau, and Excel to the query engine through JDBC, ODBC, or Arrow Flight using a personal access token.
---

You can use your existing BI tools to read data from the query engine of Hanas Data Platform. This page covers the general principles; driver details and connection strings are in [JDBC, ODBC, and Arrow Flight](../develop/sql-clients.md).

## Protocols

| Protocol | Used for |
|---|---|
| JDBC | Java-based tools, for example Tableau through the JDBC driver, or SQL clients. |
| ODBC | Power BI, Excel, and Windows tools. |
| Arrow Flight | Clients that need high-speed columnar data transfer. |

The default JDBC/ODBC client endpoint uses port 31010. The platform provides a JDBC driver; you need to obtain the ODBC driver from the appropriate source and check its compatibility with your operating system before wide deployment.

## Integrations in Settings

In Hanas Console, **Settings** → **Integrations** → **BI Applications** offers entries for **Power BI** and **Tableau**. Use it together with the connection guidance below when you set up a BI tool.

## Requirements

:::note Requirements

The client machine can reach the query engine address (usually through a gateway or a client port opened to your network). You need a personal access token (PAT) and read permission on the data you want to use.

:::

## Create a token and connect

1. In Hanas Console, open the account menu, select **Access Tokens**, and then select **Generate Token** in the **Personal Access Tokens** dialog to create a PAT. Set the shortest expiration that fits your use.
2. Copy the token as soon as it is shown; you cannot view it again.
3. In the BI tool, choose the data source by driver (ODBC or JDBC) and enter the host and port.
4. Use your username and paste the token into the password field, following the driver's instructions.
5. Test the connection, then choose the namespace and the tables or views to read.

The exact connection strings and authentication properties are in [JDBC, ODBC, and Arrow Flight](../develop/sql-clients.md).

A query engine PAT and a JWT from Keycloak are two different types of credentials; use a PAT for BI tools.

## Recommendations

- Use gold views or standardized tables; do not point BI at bronze.
- Use Reflections for repeated dashboard queries.
- Give each dashboard its own account and token when it runs scheduled refreshes, instead of using a personal token.
- Do not store tokens in shared files, and revoke them when you no longer use them.

## Limitations

:::caution Current limitations

Data permissions apply according to the identity of the token. Query engine row access and masking take effect for queries over these protocols; however, BI tools can cache data locally (import mode), so you need to manage permissions on the published report files.

:::

## Troubleshooting

| Symptom | Resolution |
|---|---|
| Connection refused | Check the network, port 31010, and host name. |
| Authentication error | Check that the token has not expired and belongs to the right account. |
| You do not see tables | Check your grants on the namespace, table, or view. |
| Slow refresh | Use an aggregated view or a Reflection. |

## Next

- [JDBC, ODBC, and Arrow Flight](../develop/sql-clients.md).
- [API authentication and PATs](../develop/index.md).
- [Accelerate queries with Reflections](../query/acceleration.md).
