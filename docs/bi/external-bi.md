---
title: Kết nối công cụ BI bên ngoài
sidebar_label: BI bên ngoài
sidebar_position: 2
description: Kết nối Power BI, Tableau và Excel tới query engine qua JDBC, ODBC hoặc Arrow Flight bằng token truy cập cá nhân.
---

Bạn có thể dùng công cụ BI sẵn có để đọc dữ liệu từ query engine của Hanas Data Platform. Trang này hướng dẫn nguyên tắc chung; chi tiết driver và chuỗi kết nối nằm ở [JDBC, ODBC và Arrow Flight](../develop/sql-clients.md).

## Giao thức

| Giao thức | Dùng cho |
|---|---|
| JDBC | Công cụ dựa trên Java, ví dụ Tableau qua driver JDBC hoặc các client SQL. |
| ODBC | Power BI, Excel và công cụ Windows. |
| Arrow Flight | Client cần truyền dữ liệu cột tốc độ cao. |

Endpoint client JDBC/ODBC mặc định dùng cổng 31010. Nền tảng có driver JDBC; ODBC driver cần lấy từ nguồn tương ứng và kiểm tra tương thích với hệ điều hành trước khi triển khai diện rộng.

## Tích hợp trong Settings

Trong Hanas Console, **Settings** → **Integrations** → **BI Applications** cung cấp mục cho **Power BI** và **Tableau**. Dùng mục này cùng hướng dẫn kết nối dưới đây khi bạn thiết lập công cụ BI.

## Điều kiện cần

:::note Điều kiện

Máy khách truy cập được địa chỉ query engine (thường qua gateway hoặc cổng client mở cho mạng của bạn). Bạn cần một token truy cập cá nhân (PAT) và quyền đọc trên dữ liệu cần dùng.

:::

## Tạo token và kết nối

1. Trong Hanas Console, mở menu tài khoản, chọn **Access Tokens**, rồi chọn **Generate Token** trong hộp thoại **Personal Access Tokens** để tạo PAT. Đặt thời hạn ngắn nhất phù hợp.
2. Sao chép token ngay khi hiển thị; token không xem lại được.
3. Trong công cụ BI, chọn nguồn dữ liệu theo driver (ODBC hoặc JDBC) và nhập host, cổng.
4. Dùng tên đăng nhập của bạn và dán token vào ô mật khẩu theo hướng dẫn của driver.
5. Kiểm tra kết nối, chọn namespace và bảng hoặc view cần đọc.

Chuỗi kết nối và thuộc tính xác thực chính xác có trong [JDBC, ODBC và Arrow Flight](../develop/sql-clients.md).

PAT của query engine và token JWT từ Keycloak là hai loại credential khác nhau; hãy dùng PAT cho công cụ BI.

## Khuyến nghị

- Dùng view gold hoặc bảng đã chuẩn hóa, không trỏ BI vào bronze.
- Dùng Reflection cho các truy vấn lặp lại của dashboard.
- Mỗi dashboard dùng tài khoản và token riêng khi chạy làm mới theo lịch, thay vì token của cá nhân.
- Không lưu token trong tệp dùng chung, và thu hồi khi không dùng.

## Giới hạn

:::caution Giới hạn hiện tại

Quyền dữ liệu áp dụng theo danh tính của token. Row access và masking của query engine có hiệu lực với truy vấn qua các giao thức này; tuy nhiên công cụ BI có thể lưu đệm dữ liệu cục bộ (chế độ import), nên cần quản lý quyền trên tệp báo cáo được xuất bản.

:::

## Xử lý sự cố

| Hiện tượng | Cách xử lý |
|---|---|
| Từ chối kết nối | Kiểm tra mạng, cổng 31010 và tên host. |
| Lỗi xác thực | Kiểm tra token còn hạn và đúng tài khoản. |
| Không thấy bảng | Kiểm tra grant của bạn trên namespace, bảng hoặc view. |
| Làm mới chậm | Dùng view đã tổng hợp hoặc Reflection. |

## Tiếp theo

- [JDBC, ODBC và Arrow Flight](../develop/sql-clients.md).
- [Xác thực API và PAT](../develop/index.md).
- [Tăng tốc truy vấn với Reflection](../query/acceleration.md).
