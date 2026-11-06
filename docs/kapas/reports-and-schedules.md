---
title: Báo cáo, trích dẫn và lịch chạy
sidebar_label: Báo cáo và lịch chạy
sidebar_position: 3
description: Tạo dashboard và báo cáo với Kapas, kiểm chứng số liệu qua trích dẫn truy vấn và đặt lịch chạy lặp lại.
---

Trang này nói về ba việc: lưu kết quả thành báo cáo hoặc dashboard, kiểm chứng số liệu trong câu trả lời và đặt lịch để Kapas chạy lặp lại.

## Báo cáo và dashboard

| Cách | Agent | Kết quả lưu ở |
|---|---|---|
| Bảng, biểu đồ trong chat | Hanas Analyst | Hội thoại (hiển thị tạm thời) |
| Dataset, chart, dashboard trên Superset | Analytics Studio Copilot | Superset |
| Dashboard theo spec YAML, bản nháp | Dashboard Copilot | Superset (chưa phát hành) |
| Board trong project dbt | Project Copilot | Thư mục `charts/` của project |

Dashboard Copilot đọc dataset, đo hình dạng dữ liệu để chọn loại chart, rồi chạy kiểm tra và lint trước khi tạo bản nháp. Loại chart hỗ trợ gồm bar, line, big number, pie, table, treemap và sunburst. Bạn xem bản nháp trong Superset rồi mới phát hành, xem [Superset trong Console](../bi/superset.md).

:::caution Giới hạn hiện tại

Tạo dashboard gọi nhiều API của Superset nối tiếp nhau và không có giao dịch xuyên suốt. Nếu lỗi giữa chừng, một số object có thể đã được tạo; Kapas không tự hoàn tác. Kiểm tra lại dashboard sau khi áp.

:::

Kapas cũng có các skill tạo tệp Word, PDF, Excel, PowerPoint, nhưng chúng chỉ dùng được khi quản trị viên bật cho agent tương ứng. Không mặc định Hanas Analyst xuất được các định dạng này.

## Trích dẫn số liệu

Hanas Analyst bật trích dẫn truy vấn. Mỗi lần chạy truy vấn có một mã tham chiếu `Qn`, và agent được yêu cầu gắn số trong câu trả lời với nguồn theo dạng `[Qn.TÊN_CỘT]`.

Sau khi agent trả lời, Kapas đối chiếu những số có gắn tag với kết quả truy vấn và phân loại:

| Nhãn | Ý nghĩa |
|---|---|
| `verified` | Số khớp với giá trị trong kết quả truy vấn. |
| `derived` | Số được tính ra từ kết quả. |
| `unverified` | Không đối chiếu được. |

Mở trích dẫn để xem câu SQL, schema, mã job của query engine và danh tính người chạy. Bạn có thể dùng mã job để xem lại ở [Lịch sử job](../query/jobs.md).

:::caution Giới hạn hiện tại

Trích dẫn chỉ kiểm tra các số được gắn tag. Số không có tag và phần diễn giải nghiệp vụ không được kiểm chứng. Cách hiển thị trích dẫn phụ thuộc giao diện; ứng dụng nhúng có thể không hiển thị đầy đủ.

:::

## Lịch chạy (Cron job)

Bạn đặt lịch để Kapas gửi một thông điệp hoặc gọi một agent lặp lại theo giờ.

### Các bước

1. Trong Kapas Console, mở mục **Cron jobs** của agent đang chọn.
2. Chọn loại lịch: `cron` (biểu thức lặp lại) hoặc `once` (một lần).
3. Chọn loại tác vụ: gửi văn bản, hoặc gọi agent với một câu lệnh (ví dụ yêu cầu tóm tắt số liệu hằng tuần).
4. Đặt múi giờ, giới hạn chạy đồng thời, thời gian chờ tối đa và cách dùng phiên (chung hoặc tách).
5. Lưu. Bạn có thể tạm dừng, tiếp tục, chạy ngay và xem lịch sử chạy.

Kết quả chạy xuất hiện trong **Inbox**, nơi bạn cũng xem được trace của lần chạy.

Mục **Heartbeat** là cơ chế chạy định kỳ của agent, cấu hình cùng khu vực lịch. Hanas không đóng gói sẵn lịch nghiệp vụ nào.

:::caution Giới hạn hiện tại

Job chạy nền không có người dùng đang đăng nhập. Job không được bảo đảm tự lấy token mới khi token của bạn hết hạn, nên báo cáo tự động cần truy vấn dữ liệu có thể thất bại sau khi phiên hết hạn. Hãy kiểm tra lịch sử chạy và Inbox sau những lần chạy đầu tiên trước khi dựa vào báo cáo định kỳ.

:::

## Xử lý sự cố

| Triệu chứng | Cách xử lý |
|---|---|
| Job chạy nhưng báo lỗi xác thực | Token hết hạn. Chạy lại bằng **Run now** khi đang đăng nhập. |
| Dashboard nháp thiếu chart | Mở lại trong Superset, kiểm tra từng chart; yêu cầu agent áp lại. |
| Số trong câu trả lời không có trích dẫn | Yêu cầu agent chạy truy vấn và gắn nguồn cho số đó. |

## Tiếp theo

- [An toàn và kiểm soát truy cập](safety.md)
- [Analytics với Superset](../bi/superset.md)
- [Kapas API và SSE](../develop/kapas-api.md)
