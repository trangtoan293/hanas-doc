---
title: JDBC, ODBC và Arrow Flight
sidebar_label: SQL client
sidebar_position: 1
description: Kết nối công cụ BI và ứng dụng tới query engine bằng JDBC, ODBC hoặc Arrow Flight, xác thực bằng Personal Access Token.
---

Trang này hướng dẫn kết nối SQL client tới query engine của Hanas Data Platform. Bạn dùng JDBC cho ứng dụng Java và công cụ SQL, ODBC cho công cụ BI, và Arrow Flight khi cần truyền khối lượng kết quả lớn sang Python hoặc các thư viện Arrow.

## Khái niệm

Query engine mở ba endpoint riêng cho client, mỗi endpoint một cổng.

| Giao thức | Cổng mặc định | Ghi chú |
|---|---:|---|
| JDBC và ODBC | 31010 | Endpoint client truyền thống. |
| Arrow Flight / Flight SQL | 32010 | Cổng riêng, không dùng chung với JDBC/ODBC. |
| REST và web | 9047 | Xem [REST API của query engine](query-engine-api.md). |

Trong cụm Kubernetes, các cổng này nằm trên Service của query engine. Địa chỉ mà máy khách bên ngoài cụm dùng do hạ tầng của bạn công bố (NodePort, LoadBalancer hoặc đường hầm); xem [Cổng và endpoint](../reference/ports-and-endpoints.md).

## Điều kiện cần

- Tài khoản Hanas có quyền truy vấn trên dữ liệu cần đọc.
- Một [Personal Access Token](index.md) còn hạn.
- Đường mạng từ máy khách tới cổng tương ứng của query engine.

:::note Điều kiện

Cổng 31010 và 32010 chỉ có ở Service nội bộ theo cấu hình mặc định. Hãy nhờ quản trị viên hạ tầng công bố chúng ra ngoài cụm nếu client chạy ngoài cụm.

:::

## driver JDBC của query engine

Driver JDBC là gói phát hành cùng query engine; hãy lấy tệp `.jar` từ đầu mối triển khai để đảm bảo cùng phiên bản với máy chủ.

| Thông số | Giá trị |
|---|---|
| Lớp driver | `com.dremio.jdbc.Driver` |
| URL | `jdbc:dremio:direct=<host>:31010` |
| User | Tên đăng nhập Hanas |
| Password | PAT (hoặc mật khẩu nếu dùng tài khoản nội bộ) |

```text
jdbc:dremio:direct=<host>:31010
```

Ví dụ kết nối bằng một ứng dụng Java:

```java
Class.forName("com.dremio.jdbc.Driver");
try (Connection c = DriverManager.getConnection(
         "jdbc:dremio:direct=<host>:31010", "<username>", System.getenv("HANAS_PAT"));
     Statement s = c.createStatement();
     ResultSet r = s.executeQuery("SELECT 1 AS ok")) {
  while (r.next()) System.out.println(r.getInt("ok"));
}
```

Với công cụ SQL dạng GUI, thêm driver bằng cách trỏ tới tệp `.jar`, chọn lớp driver ở trên rồi nhập URL.

## ODBC

ODBC dùng cùng endpoint client 31010. Cấu hình DSN trên máy khách với host, cổng 31010, tên đăng nhập và PAT làm mật khẩu. Hầu hết công cụ BI thương mại kết nối theo cách này; xem thêm [Kết nối công cụ BI bên ngoài](../bi/external-bi.md).

:::caution Giới hạn hiện tại

Tài liệu này chưa công bố phiên bản driver ODBC và ma trận hệ điều hành được hỗ trợ. Hãy xác nhận bản driver với đội triển khai trước khi chuẩn hoá cho người dùng cuối.

:::

## Arrow Flight

Arrow Flight truyền kết quả dạng cột, nhanh hơn JDBC khi tải nhiều dòng. Kết nối tới cổng 32010 và gửi PAT qua header `authorization`.

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

Nếu endpoint bật TLS, dùng `grpc+tls://` và truyền chứng chỉ CA qua `tls_root_certs`. Chế độ xác thực, TLS và phiên của Flight được đặt ở cấu hình query engine; xem [Tham chiếu cấu hình](../operate/configuration.md).

## Xác thực bằng PAT

PAT là credential của query engine, khác với token Keycloak. Cách dùng theo từng giao thức:

| Giao thức | Cách đưa PAT vào |
|---|---|
| JDBC, ODBC | Dùng PAT làm mật khẩu, kèm tên đăng nhập. |
| Arrow Flight | Header `authorization: Bearer <PAT>`. |
| REST | Header `Authorization: Bearer <PAT>`. |

Quyền dữ liệu (grant, row access, masking) áp dụng theo tài khoản sở hữu PAT, như khi bạn dùng [SQL Editor](../query/sql-studio.md) (menu **Workspaces**).

## Xử lý sự cố

| Triệu chứng | Nguyên nhân thường gặp | Cách xử lý |
|---|---|---|
| Connection refused hoặc timeout | Cổng chưa được công bố hoặc bị chặn. | Kiểm tra route mạng tới 31010 hoặc 32010. |
| Lỗi xác thực | PAT hết hạn, bị xoá hoặc sai tên đăng nhập. | Tạo PAT mới: menu tài khoản, **Access Tokens**, **Generate Token**. |
| Kết nối được nhưng bảng trống hoặc báo thiếu quyền | Tài khoản chưa được cấp quyền dữ liệu. | Nhờ quản trị viên cấp grant. |
| Flight lỗi TLS | Endpoint bật TLS nhưng client dùng `grpc+tcp`. | Dùng `grpc+tls` và chứng chỉ CA phù hợp. |

## Tiếp theo

- [Gửi SQL qua REST API](query-engine-api.md).
- [Tham chiếu SQL](../query/sql-reference.md).
- [Tổng quan tích hợp](index.md).
