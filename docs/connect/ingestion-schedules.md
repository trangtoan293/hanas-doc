---
title: Lịch chạy, checkpoint và chạy lại
sidebar_label: Lịch chạy và chạy lại
sidebar_position: 4
description: Đặt lịch cho luồng nạp, hiểu checkpoint và watermark, chạy lại, tải lại dữ liệu, theo dõi run và xử lý lỗi trong Ingestion.
---

Trang này hướng dẫn vận hành luồng nạp sau khi đã tạo: đặt lịch, chạy tay, tải lại dữ liệu, theo dõi từng run và xử lý khi run thất bại. Khái niệm nền xem [Nạp dữ liệu vào lakehouse](./ingestion.md).

## Lịch chạy

Khi tạo hoặc sửa luồng nạp, chọn một trong các mức sau.

| Lịch | Ghi chú |
|---|---|
| Manual | Chỉ chạy khi bạn chọn **Run now**. |
| Mỗi 5 phút, mỗi 15 phút | Phù hợp luồng CDC hoặc Kafka. |
| Hằng giờ | Chọn phút trong giờ. |
| Hằng ngày | Chọn giờ và phút. |
| Custom | Biểu thức cron 5 hoặc 6 trường. |

Lịch tính theo múi giờ cấu hình của dịch vụ; mặc định là `Asia/Ho_Chi_Minh`. Tại mỗi thời điểm, một luồng nạp chỉ có tối đa một run đang hoạt động.

Dịch vụ chia run thành hai lane. Lane **stream** dành cho luồng có bảng đọc nhật ký thay đổi (CDC, Kafka, Debezium, T24); lane **batch** dành cho full refresh và incremental. Một lần nạp đầy đủ lớn không chặn run CDC hoặc Kafka. Các run đọc toàn bộ bảng, như lần nạp đầu, tải lại hoặc bảng mới thêm, vẫn chạy ở lane batch.

:::caution Giới hạn hiện tại

CDC và Kafka không chạy liên tục. Mỗi run đọc đến cuối nhật ký tại lúc bắt đầu, commit rồi kết thúc. Với luồng stream, đặt lịch 1 đến 5 phút. Mỗi run của OLake có chi phí khởi động cố định khoảng 20 giây, nên lịch quá dày làm tăng tải.

:::

## Checkpoint và watermark

- **Checkpoint**: trạng thái của engine được lưu sau mỗi run thành công. Run kế tiếp đọc từ checkpoint, nên không đọc lại dữ liệu đã nạp. Hệ thống giữ 10 phiên bản checkpoint gần nhất cho mỗi luồng.
- **Watermark**: mốc dữ liệu đã nạp của từng bảng, hiển thị trong giao diện chi tiết luồng.
- Run thất bại không ghi checkpoint. Run sau tiếp tục từ checkpoint cuối cùng thành công.
- Nếu pod chạy run bị dừng đột ngột, run được đánh dấu thất bại và run kế tiếp tiếp tục từ checkpoint, không cần can thiệp.

## Chạy lại và backfill

Trong trang chi tiết luồng nạp:

| Thao tác | Tác dụng |
|---|---|
| **Run now** | Chạy ngay một run, ngoài lịch. Không khả dụng khi luồng đang tạm dừng. |
| **Pause** và **Resume** | Dừng hoặc bật lại lịch. Pause luồng CDC cần xác nhận vì nhật ký nguồn tiếp tục phát sinh. |
| **Cancel** (trên run) | Huỷ run đang chạy. |
| **Reload all** (resnapshot) | Xoá bảng đích, quên vị trí đọc và đọc lại toàn bộ từ nguồn. Dùng để backfill hoặc sửa dữ liệu sai. |
| **Clear** (một hoặc nhiều bảng) | Chỉ xoá bảng đích và vị trí đọc, không đọc nguồn; lần chạy kế tiếp đọc lại từ đầu. Clear thất bại không tự thử lại. |
| Thêm bảng | Bảng mới được nạp đầy đủ; các bảng khác tiếp tục từ checkpoint. |

:::caution Giới hạn hiện tại

**Reload all** không khả dụng với Debezium và T24 vì vị trí đọc nằm trong chính bảng đích; muốn dựng lại, xoá luồng cùng bảng đích rồi tạo lại. Với Kafka, dữ liệu chỉ đọc lại được từ bản tin cũ nhất mà topic còn giữ.

:::

Đổi chế độ đồng bộ, cột theo dõi, khoá hoặc cấu hình bảng của một bảng đã nạp sẽ đặt cờ đọc lại: run kế tiếp xoá bảng đó rồi đọc lại từ đầu. Hãy kiểm tra danh sách bảng bị ảnh hưởng trước khi xác nhận.

## Theo dõi run

Mở luồng nạp, vào tab **Runs**:

- Bảng run cho biết trạng thái, thời điểm và kết quả. Mở một run để xem log theo thời gian thực.
- **View log** hiển thị số hàng đã ghi cho từng bảng và 200 dòng cuối của log engine.
- **Download full log** tải toàn bộ log của run. Log đầy đủ được giữ 30 ngày; run cũ hơn chỉ còn các dòng cuối. Secret được che trong mọi log.
- Trong lúc run chạy, giao diện cập nhật thống kê (số hàng, tốc độ, thời gian ước tính, bộ nhớ, CPU) khoảng 5 giây một lần với engine hỗ trợ.
- Lịch sử run được giữ 14 ngày; run thành công không ghi gì được giữ 1 ngày.

Quản trị viên có thể đặt webhook (Slack hoặc Teams) để nhận cảnh báo khi một run thất bại hết lượt thử. Cảnh báo `IngestionStreamLagging` kích hoạt khi bảng thuộc luồng stream chậm 30 phút.

## Xử lý lỗi

Run thất bại được thử lại tự động tối đa 3 lần, cách nhau 1 phút và tăng gấp đôi. Sau 5 run thất bại liên tiếp, luồng chuyển sang trạng thái **error**: lịch dừng và giao diện hiển thị các bước khôi phục. Sửa nguyên nhân, rồi chọn **Run now** để thử một lần hoặc **Resume** để bật lại lịch.

| Thông báo lỗi chứa | Nguyên nhân | Cách xử lý |
|---|---|---|
| `Connection refused`, `timeout`, `UnknownHost` | Dịch vụ không tới được nguồn hoặc catalog | Kiểm tra mạng, quy tắc egress của team, tên host. |
| `password authentication failed`, `Access denied` | Sai thông tin xác thực | Sửa connection và **Test**. |
| `wider than`, `refused`, `DOUBLE` | OLake không giữ chính xác kiểu số | Nạp bảng bằng dlt hoặc Debezium. |
| `replication slot`, `binlog`, `CDC is not enabled` | Thiếu điều kiện CDC | Chạy câu lệnh mà preflight hiển thị. |
| `Worker stopped responding` | Pod chạy run bị dừng | Không cần sửa; run kế tiếp tiếp tục từ checkpoint. Kiểm tra bộ nhớ và restart của pod. |
| `consumer_group_id mismatch` | Kafka: checkpoint và bảng đã lệch consumer group | Chọn **Reload all**. |
| `Decimal value would cause data loss` | dlt: giá trị có nhiều chữ số lẻ hơn kiểu đích | Khai báo precision và scale ở nguồn. |

Với luồng CDC, đừng để luồng dừng quá lâu: nguồn giữ lại nhật ký (WAL, binlog) cho tới khi được đọc. Xoá hoặc tải lại luồng không còn dùng.

## Tiếp theo

- [Nạp dữ liệu vào lakehouse (Ingestion)](./ingestion.md)
- [Xử lý sự cố](../operate/troubleshooting.md)
- [Cấu hình](../operate/configuration.md) để đổi múi giờ, số lần thử lại và thời gian lưu log
