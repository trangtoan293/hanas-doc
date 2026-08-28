# Đào Tạo Khai Thác Dữ Liệu (Data Consumer)

## Mục tiêu

Sau khóa học, người dùng có thể truy cập dữ liệu đúng quyền, tìm và hiểu dataset/KPI, truy vấn Dremio, sử dụng dashboard Superset/BI và xuất kết quả theo chính sách của tổ chức.

## Đối tượng và điều kiện

| Đối tượng | Phạm vi |
|---|---|
| Lãnh đạo/người xem báo cáo | Đọc KPI, lọc, drill-down và nhận biết cảnh báo |
| Business analyst | SQL cơ bản, dataset, semantic layer và phân tích |
| Report builder | Tạo chart/dashboard, KPI và bộ lọc trong phạm vi được cấp quyền |
| Data owner/steward | Duyệt định nghĩa KPI, owner, glossary và quyền chia sẻ |

Điều kiện: có tài khoản test theo role, đã đọc [Kiến trúc](../00-overview/architecture.md), có bộ KPI/dataset mẫu và có dữ liệu đã được phê duyệt để dùng trong lab.

## Nội dung đào tạo

### 1. Truy cập và an toàn dữ liệu

- Đăng nhập SSO/MFA, kiểm tra workspace và role.
- Phân biệt Raw Vault, Business Vault, Information Mart và semantic dataset.
- Hiểu masking, row-level filter, export policy và audit.
- Không tải dữ liệu nhạy cảm về máy cá nhân nếu chưa có phê duyệt.

### 2. Dremio và SQL

- Tìm source, space, folder, physical dataset và virtual dataset.
- Đọc schema, owner, mô tả, freshness và trạng thái refresh.
- Dùng `SELECT`, `WHERE`, `GROUP BY`, `JOIN`, khoảng thời gian và giới hạn kết quả.
- Kiểm tra query profile; tránh `SELECT *` trên bảng lớn và lọc theo partition/date.

```sql
-- Truy vấn mẫu; thay tên dataset theo catalog của khách hàng
SELECT
  business_date,
  service_code,
  COUNT(*) AS total_records,
  SUM(amount) AS total_amount
FROM "<SPACE>"."<DATASET>"
WHERE business_date >= DATE '<YYYY-MM-DD>'
  AND business_date < DATE '<YYYY-MM-DD>'
GROUP BY business_date, service_code
ORDER BY business_date, service_code;
```

### 3. Dashboard và báo cáo

- Mở dashboard, áp dụng filter, đổi khoảng thời gian, drill-down và đọc định nghĩa KPI.
- Tạo chart từ dataset được cấp phép; đặt tên, mô tả, owner và thời điểm refresh.
- Sử dụng template màu/đơn vị đo thống nhất.
- Phân biệt số liệu chưa hoàn tất (in-flight) và số liệu đã đóng kỳ.

### 4. Thực hành

| Bài lab | Đầu ra kiểm tra được |
|---|---|
| Tra cứu dataset | Tìm đúng dataset theo domain/tag/owner |
| Truy vấn KPI | Trả về kết quả đúng bộ câu hỏi mẫu và lưu query |
| Phân tích dashboard | Lọc theo thời gian/đơn vị, giải thích biến động |
| Tạo báo cáo | Tạo một dashboard có tối thiểu 3 biểu đồ và mô tả KPI |
| Kiểm tra quyền | Chứng minh user chỉ thấy dữ liệu đúng phạm vi và export bị kiểm soát |

## Quy tắc sử dụng dữ liệu

- Ưu tiên Information Mart hoặc semantic dataset đã được phê duyệt.
- Không tự định nghĩa lại KPI trong từng dashboard; tham chiếu KPI dictionary và glossary.
- Không dùng dữ liệu Raw Vault để chia sẻ trực tiếp cho người dùng nghiệp vụ nếu chưa có phê duyệt.
- Khi phát hiện sai số, ghi nhận dataset, thời điểm truy vấn, filter, query ID và ảnh hưởng; không tự sửa dữ liệu nguồn.

## Xử lý sự cố thường gặp

| Triệu chứng | Kiểm tra đầu tiên | Hành động |
|---|---|---|
| Không thấy dataset | Role, domain, space và metadata refresh | Liên hệ Data Owner/Steward; không xin quyền rộng hơn cần thiết |
| Dashboard không có dữ liệu | Khoảng thời gian, refresh time, upstream pipeline | Kiểm tra Airflow/Dremio; ghi query ID vào ticket |
| Số liệu khác báo cáo cũ | Định nghĩa KPI, snapshot kỳ và filter | Đối chiếu KPI dictionary và biên bản reconciliation |
| Không export được | Export policy hoặc giới hạn dữ liệu | Xin phê duyệt đúng quy trình; không dùng tài khoản người khác |

## Đánh giá và bàn giao

Học viên hoàn thành khi thực hiện đúng bài lab, giải thích được KPI đại diện và tuân thủ quy định truy cập. Hồ sơ gồm danh sách học viên, kết quả lab, feedback, câu hỏi mở và biên bản xác nhận.
