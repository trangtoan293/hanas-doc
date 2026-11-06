---
title: JDBC, ODBC, and Arrow Flight
sidebar_label: SQL client
sidebar_position: 1
description: Connect BI tools and applications to the query engine with JDBC, ODBC, or Arrow Flight, authenticating with a Personal Access Token.
---

This page explains how to connect a SQL client to the Hanas Data Platform query engine. Use JDBC for Java applications and SQL tools, ODBC for BI tools, and Arrow Flight when you need to transfer large result sets to Python or Arrow libraries.

## Concepts

The query engine exposes three separate client endpoints, each on its own port.

| Protocol | Default port | Notes |
|---|---:|---|
| JDBC and ODBC | 31010 | Traditional client endpoint. |
| Arrow Flight / Flight SQL | 32010 | Separate port, not shared with JDBC/ODBC. |
| REST and web | 9047 | See [Query engine REST API](query-engine-api.md). |

In a Kubernetes cluster, these ports are on the query engine Service. The address that clients outside the cluster use is published by your infrastructure (NodePort, LoadBalancer, or tunnel); see [Ports and endpoints](../reference/ports-and-endpoints.md).

## Requirements

- A Hanas account with permission to query the data you need to read.
- A valid [Personal Access Token](index.md).
- A network path from the client to the corresponding query engine port.

:::note Requirements

By default configuration, ports 31010 and 32010 exist only on the internal Service. Ask your infrastructure administrator to publish them outside the cluster if the client runs outside the cluster.

:::

## Query engine JDBC driver

The JDBC driver is a package released with the query engine; get the `.jar` file from your deployment contact to ensure it matches the server version.

| Setting | Value |
|---|---|
| Driver class | `com.dremio.jdbc.Driver` |
| URL | `jdbc:dremio:direct=<host>:31010` |
| User | Hanas username |
| Password | PAT (or password, if you use an internal account) |

```text
jdbc:dremio:direct=<host>:31010
```

Example connection from a Java application:

```java
Class.forName("com.dremio.jdbc.Driver");
try (Connection c = DriverManager.getConnection(
         "jdbc:dremio:direct=<host>:31010", "<username>", System.getenv("HANAS_PAT"));
     Statement s = c.createStatement();
     ResultSet r = s.executeQuery("SELECT 1 AS ok")) {
  while (r.next()) System.out.println(r.getInt("ok"));
}
```

For GUI-based SQL tools, add the driver by pointing to the `.jar` file, select the driver class above, then enter the URL.

## ODBC

ODBC uses the same client endpoint, 31010. Configure a DSN on the client with the host, port 31010, username, and the PAT as the password. Most commercial BI tools connect this way; see also [Connect external BI tools](../bi/external-bi.md).

:::caution Current limitations

This documentation does not yet publish the ODBC driver version or the matrix of supported operating systems. Confirm the driver version with your deployment team before you standardize it for end users.

:::

## Arrow Flight

Arrow Flight transfers results in columnar form, faster than JDBC when you read many rows. Connect to port 32010 and send the PAT in the `authorization` header.

```python
from pyarrow import flight

client = flight.FlightClient("grpc+tcp://<host>:32010")
options = flight.FlightCallOptions(
    headers=[(b"authorization", b"Bearer <PAT>")]
)

sql = "SELECT * FROM lakehouse.sales.orders LIMIT 100"
descriptor = flight.FlightDescriptor.for_command(sql)

info = client.get_flight_info(descriptor, options)
table = client.do_get(info.endpoints[0].ticket, options).read_all()
print(table.to_pandas().head())
```

If the endpoint has TLS enabled, use `grpc+tls://` and pass the CA certificate through `tls_root_certs`. The authentication mode, TLS, and Flight sessions are set in the query engine configuration; see [Configuration reference](../operate/configuration.md).

## Authenticate with a PAT

A PAT is a query engine credential, different from a Keycloak token. How to use it for each protocol:

| Protocol | How to supply the PAT |
|---|---|
| JDBC, ODBC | Use the PAT as the password, together with the username. |
| Arrow Flight | Header `authorization: Bearer <PAT>`. |
| REST | Header `Authorization: Bearer <PAT>`. |

Data permissions (grants, row access, masking) apply according to the account that owns the PAT, the same as when you use the [SQL Editor](../query/sql-studio.md) (**Workspaces** menu).

## Troubleshooting

| Symptom | Common cause | Resolution |
|---|---|---|
| Connection refused or timeout | The port is not published or is blocked. | Check the network route to 31010 or 32010. |
| Authentication error | The PAT is expired, deleted, or the username is wrong. | Create a new PAT: account menu, **Access Tokens**, **Generate Token**. |
| Connection succeeds but tables are empty or report missing permission | The account has not been granted data permissions. | Ask an administrator to grant access. |
| Flight TLS error | The endpoint has TLS enabled but the client uses `grpc+tcp`. | Use `grpc+tls` and a suitable CA certificate. |

## Next steps

- [Submit SQL through the REST API](query-engine-api.md).
- [SQL reference](../query/sql-reference.md).
- [Integration overview](index.md).
