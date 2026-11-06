---
title: An toàn và kiểm soát truy cập trong Kapas
sidebar_label: An toàn
sidebar_position: 4
description: Kapas truy vấn dữ liệu dưới danh tính nào, SQL chỉ đọc được kiểm soát ra sao, vai trò của sandbox và các giới hạn quản trị cần biết.
---

Trang này mô tả trung thực cách Kapas bảo vệ dữ liệu và những chỗ bạn không nên giả định. Quản trị viên nên đọc trước khi cấp Kapas cho nhiều người dùng.

## Nguyên tắc

Kapas không tự cấp quyền dữ liệu. Quyền bảng, dòng và cột do query engine, Ontology, Superset và dbt Studio quyết định. Kapas cố gắng gọi các dịch vụ này bằng danh tính của bạn; một số nhánh có ngoại lệ, nêu bên dưới.

## Danh tính truy vấn

| Tích hợp | Chạy dưới danh tính | Ghi chú |
|---|---|---|
| query engine (Kapas Console) | Người dùng cuối | Kapas dùng token query engine của bạn, hoặc đổi token Keycloak của bạn sang token query engine (RFC 8693). Thiếu hoặc hết hạn token thì báo lỗi, không có tài khoản dịch vụ dự phòng. |
| Ontology (object, metric, Concept, Mapping) | Người dùng cuối | JWT của bạn được chuyển tiếp; Ontology kiểm tra quyền workspace. |
| Superset | Người dùng cuối | Token của bạn hoặc token đổi cho Superset; Superset phải chấp nhận token này. |
| Knowledge Platform | Người dùng cuối | Đổi token sang audience riêng; phạm vi tìm kiếm do dịch vụ đích giới hạn. |
| Hanas Catalog | Có thể là tài khoản dùng chung | Nếu không đổi được token, Kapas đăng nhập bằng một tài khoản dịch vụ. Nhánh này không ghi nhận được từng người. |
| dbt Studio | Người dùng cuối, có ngoại lệ | Khi thiếu token hoặc không phân giải được kết nối, một nhánh dự phòng cũ dùng token của tài khoản dịch vụ. |
| Ứng dụng nhúng (embed) và API đồng bộ | Phụ thuộc ứng dụng host | Xem bên dưới. |

:::caution Giới hạn hiện tại

Với tích hợp nhúng, Kapas không tự động chuyển token query engine như Console. Ứng dụng host phải gửi đúng token của người dùng cuối trong request. Nếu host gửi sai hoặc dùng chung một token, truy vấn chạy với quyền đó. Xem [Nhúng Kapas](../develop/kapas-embed.md).

API key của Kapas đại diện cho tài khoản dịch vụ, không đóng vai người dùng cụ thể. Đừng dùng một key chung cho chat của nhiều người dùng.

Job chạy theo lịch không có phiên người dùng; xem [Báo cáo và lịch chạy](reports-and-schedules.md).

:::

Mỗi người dùng có không gian làm việc, lịch sử chat và memory riêng. Kapas phân tách theo từng người dùng, không phải theo tổ chức; các đồng nghiệp không tự động chia sẻ agent hay hội thoại.

## SQL chỉ đọc

Các tool truy vấn của Hanas Analyst và SQL Copilot chỉ chấp nhận câu lệnh `SELECT` hoặc `WITH`:

1. Từ khóa thay đổi dữ liệu hoặc quyền (như `INSERT`, `UPDATE`, `DELETE`, `DROP`, `CREATE`, `ALTER`, `TRUNCATE`, `MERGE`, `GRANT`, `REVOKE`) bị chặn.
2. Câu lệnh thiếu `LIMIT` được thêm `LIMIT 100`.
3. `EXPLAIN` chạy trước, rồi mới thực thi; có thời gian chờ cho cả hai bước.

Đây là kiểm tra theo mẫu chuỗi, không phải bộ phân tích SQL đầy đủ, và `LIMIT 100` không phải trần cứng. Lớp bảo vệ thật sự vẫn là quyền của tài khoản bạn tại query engine: nếu bạn chỉ có quyền đọc thì không thể ghi dù lệnh vượt qua kiểm tra. Dùng workload management để giới hạn tài nguyên, xem [Engine, queue và điều phối tải](../query/workload-management.md).

Tool ghi vào hệ thống khác (tạo dashboard, sửa metadata, ghi file dbt) tồn tại ở các agent tương ứng và không bị ràng buộc bởi quy tắc chỉ đọc này.

## Sandbox

Có hai lớp khác nhau:

| Lớp | Mục đích | Mặc định trong Helm của Hanas |
|---|---|---|
| Sandbox cấp hệ điều hành cho tool | Giới hạn tool chạy lệnh và file | Chính sách production yêu cầu bật |
| Không gian thực thi từ xa theo người dùng | Chạy mã của agent trong Pod riêng, có giới hạn tài nguyên và mạng | **Tắt** |

Khi không gian thực thi từ xa tắt, bạn không nên mô tả triển khai là đã cách ly mọi người dùng ở mức container. Bật nó cần runtime, lưu trữ và chính sách mạng phù hợp, và chính sách mạng mặc định có thể chặn truy cập các endpoint nội bộ.

Hầu hết agent dữ liệu của Hanas tắt shell, Python, file và trình duyệt trong template. Hanas Analyst khai báo không đầy đủ nên có thể dùng một số tool mặc định như chạy Python; quản trị viên nên rà soát tool bật cho từng agent trong Kapas Console.

## Phê duyệt và kiểm soát tool

Kapas có cơ chế chính sách cho tool với các kết quả cho phép, từ chối, hỏi xác nhận. Mức phê duyệt phụ thuộc cấu hình thực thi:

- Chỉ dẫn "luôn hỏi trước khi tạo" trong prompt chỉ định hướng cho mô hình, không phải cổng bắt buộc.
- Nhiều tool ghi mặc định ở chế độ cho phép. Nếu mức phê duyệt đặt là tắt, kiểm tra quyền bị bỏ qua.
- Ứng dụng nhúng nhận sự kiện yêu cầu phê duyệt qua SSE và phải hiển thị cho người dùng, xem [Kapas API](../develop/kapas-api.md).

Nếu cần cổng xác nhận chắc chắn cho thao tác ghi, hãy cấu hình mức phê duyệt ở cấp triển khai và kiểm thử trước khi dùng thật.

## Guardrails nội dung

Kapas có module guardrails (che PII, kiểm tra đầu vào và đầu ra) và màn hình cấu hình. Mô-đun này tắt theo mặc định và chưa được hỗ trợ chính thức trên luồng chat chính. Đừng xem đây là lớp chặn dữ liệu nhạy cảm.

## Giới hạn quản trị

:::caution Giới hạn hiện tại

- Kapas không chứa chính sách row access hay masking. Cấu hình chúng tại query engine, xem [Phân quyền dữ liệu](../govern/access-control.md).
- Bộ nhớ đệm metadata catalog và schema (300 giây) được dùng chung trong một tiến trình và chưa phân theo người dùng. Trong môi trường nhiều người dùng, metadata đã cache có thể được trả cho người dùng khác. Đánh giá rủi ro này trước khi dùng với metadata nhạy cảm.
- Bản triển khai mặc định chạy một replica; giới hạn request và ngân sách token chỉ áp theo tiến trình và là giới hạn mềm.
- Quyền truy cập agent là danh sách chia sẻ do quản trị viên cấp; nếu cơ sở dữ liệu lỗi khi nạp danh sách, hệ thống có thể cho phép truy cập thay vì từ chối.
- Vai trò quản trị lấy từ role Keycloak khi tạo người dùng lần đầu; thay đổi role về sau có thể không đồng bộ ngay. Kiểm tra lại sau khi đổi role, xem [Quản lý người dùng](../operate/user-management.md).
- Có thể bật Langfuse để truy vết; mặc định để trống thì không chạy.

:::

## Khuyến nghị cho quản trị viên

1. Dùng SSO Keycloak cho mọi người dùng Kapas; không dùng tài khoản dùng chung.
2. Giữ quyền dữ liệu chặt tại query engine; xem như Kapas có đúng quyền của người dùng đang hỏi.
3. Rà soát tool bật cho từng agent; tắt tool không cần.
4. Với tích hợp nhúng, kiểm tra host gửi đúng token người dùng cuối.
5. Theo dõi mức dùng token và lịch sử job tại query engine để audit.

## Tiếp theo

- [Xác thực và SSO với Keycloak](../operate/identity.md)
- [Cấu hình mô hình AI](../operate/ai-models.md)
- [Phân quyền dữ liệu](../govern/access-control.md)
