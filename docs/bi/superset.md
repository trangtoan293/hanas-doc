---
title: Analytics với Superset trong Console
sidebar_label: Superset
sidebar_position: 1
description: Dùng Apache Superset nhúng trong Hanas Console để tạo dataset, chart và dashboard trên dữ liệu của query engine.
---

Menu Analytics trong Hanas Console nhúng Apache Superset để bạn tạo chart và dashboard trên dữ liệu lakehouse. Trang này dành cho analyst và BI developer; phần cấu hình dành cho quản trị viên.

## Khái niệm

| Thành phần | Mô tả |
|---|---|
| Database connection | Kết nối từ Superset tới query engine, do nền tảng cấu hình sẵn. |
| Dataset | Bảng hoặc view của query engine, hoặc một câu SQL, dùng làm nguồn cho chart. |
| Chart | Biểu đồ trên một dataset. |
| Dashboard | Tập chart cùng bộ lọc, chia sẻ cho người khác. |

Superset gửi truy vấn tới query engine, nên kết quả chịu cùng quyền, Reflection và giới hạn tải như truy vấn từ [SQL Editor](../query/sql-studio.md) (menu **Workspaces**).

## Điều kiện cần

:::note Điều kiện

Superset là thành phần tuỳ chọn. Khi bật, nền tảng chạy Superset cùng PostgreSQL và Redis riêng, đăng nhập qua Keycloak. Một tác vụ khởi tạo cấp token truy cập cá nhân (PAT) để Superset kết nối tới query engine và lưu vào Kubernetes Secret. Nếu bạn không thấy menu Analytics, hãy nhờ quản trị viên kiểm tra thành phần này.

:::

## Truy cập và đăng nhập

1. Mở **Analytics** trong Hanas Console. Superset nhúng hiển thị các tab **Dashboards**, **Charts**, **Template**, **Report**, **Datasets** và **SQL**.
2. Superset tự đăng nhập bằng danh tính Keycloak của bạn; không cần tài khoản riêng.
3. Lần đầu đăng nhập, Superset tạo người dùng tương ứng và gán role theo group Keycloak.

## Tạo dataset, chart và dashboard

1. Mở **Datasets** và chọn tạo dataset mới.
2. Chọn database của query engine, schema (namespace hoặc space) và bảng hoặc view. Có thể dùng tab **SQL** để viết truy vấn rồi lưu thành dataset.
3. Đặt tên rõ ràng, định nghĩa cột tính toán và metric dùng chung.
4. Mở **Charts**, chọn dataset và loại biểu đồ, cấu hình dimension, metric, bộ lọc, rồi lưu.
5. Mở **Dashboards**, tạo dashboard và thêm các chart.
6. Chia sẻ dashboard cho người dùng hoặc role phù hợp.

Nên dựng dataset trên view gold đã chuẩn hóa. Logic nghiệp vụ nằm ở view giúp mọi chart nhất quán, và Reflection tăng tốc truy vấn lặp lại.

## Quyền

| Lớp | Cơ chế |
|---|---|
| Role Superset | Cấu hình sẵn: `superset_admin` ánh xạ role Admin, `superset_user` ánh xạ role Gamma. Role đồng bộ mỗi lần đăng nhập. |
| Quyền dữ liệu | Do query engine quyết định, theo grant trên source, space, folder, bảng và view. |

Đồng bộ role từ Keycloak không tự cấp quyền đọc dữ liệu trong query engine. Một người có quyền xem dashboard vẫn có thể thấy dữ liệu theo danh tính mà Superset dùng để truy vấn.

:::caution Giới hạn hiện tại

Superset kết nối tới query engine bằng một PAT dịch vụ do tác vụ khởi tạo tạo ra. Cơ chế giả danh người dùng (impersonation) phụ thuộc cấu hình tích hợp của từng bản triển khai; PAT lấy từ người dùng đăng nhập SSO không dùng được cho luồng này. Trước khi chia sẻ dashboard chứa dữ liệu nhạy cảm, hãy xác nhận với quản trị viên danh tính thực sự dùng khi truy vấn và kiểm tra bằng một tài khoản bị hạn chế. Thời hạn của PAT dịch vụ do quản trị viên đặt; cần có chính sách luân chuyển.

:::

## Xử lý sự cố

| Hiện tượng | Cách xử lý |
|---|---|
| Không thấy Analytics | Superset chưa bật hoặc chưa sẵn sàng; hoàn tất triển khai chưa đồng nghĩa Superset đã Ready. |
| Dataset không liệt kê bảng | Kiểm tra quyền của danh tính truy vấn trên schema và bảng đó. |
| Lỗi xác thực khi truy vấn | Nhờ quản trị viên kiểm tra PAT của Superset còn hiệu lực. |
| Chart chậm | Dựng dataset trên view gold và cân nhắc Reflection. |

## Tiếp theo

- [Tăng tốc truy vấn với Reflection](../query/acceleration.md).
- [Kết nối công cụ BI bên ngoài](external-bi.md).
- [Phân quyền dữ liệu](../govern/access-control.md).
