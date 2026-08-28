# Đào Tạo Và Chuyển Giao

## Mục tiêu

Chương trình đào tạo giúp đội ngũ khách hàng tự vận hành, phát triển pipeline, quản trị metadata/bảo mật và khai thác dữ liệu sau nghiệm thu. Nội dung được thực hành trên môi trường khách hàng hoặc một môi trường lab có cấu hình tương đương.

## Lộ trình đề xuất

| Nhóm học viên | Nội dung chính | Tài liệu |
|---|---|---|
| Quản trị hệ thống/vận hành | Kubernetes, service health, backup/restore, monitoring, incident response | [Đào tạo vận hành](operations-training.md) |
| Data engineer | NiFi, Kafka, Airflow, Spark, dbt, Iceberg, Data Vault và data quality | [Đào tạo xử lý dữ liệu](data-processing-training.md) |
| Data steward/governance | Catalog, glossary, ownership, lineage, quality và approval workflow | [Đào tạo quản trị dữ liệu](data-governance-training.md) |
| Data consumer/BI | Dremio, SQL, dataset, KPI, dashboard, export và phân quyền | [Đào tạo khai thác dữ liệu](data-consumer-training.md) |
| Nhóm dự án khách hàng | Kickoff, sizing, kết nối nguồn, migration, parallel run và go-live | [Onboarding](customer-onboarding-guide.md) |

## Hình thức và thời lượng

- **Onsite:** dùng cho cài đặt, vận hành, bảo mật và hands-on trên hệ thống thực tế.
- **Online:** dùng cho lý thuyết, review sau đào tạo và hỗ trợ bổ sung.
- **Workshop/lab:** mỗi nhóm hoàn thành một bài thực hành có đầu ra kiểm tra được.
- Thời lượng tham khảo: quản trị/vận hành 4–5 buổi, data engineering 4–5 buổi, governance 2–3 buổi, data consumer 1–2 buổi. Lịch chính thức phụ thuộc phạm vi hợp đồng và mức độ tùy biến.

## Điều kiện chuẩn bị

Khách hàng chuẩn bị danh sách học viên, vai trò, tài khoản test, quyền truy cập môi trường, dữ liệu mẫu đã loại bỏ thông tin nhạy cảm, use case/KPI đại diện và đầu mối phê duyệt. Bên triển khai chuẩn bị agenda, slide/runbook, bài lab, môi trường thực hành và biểu mẫu đánh giá.

## Đầu ra bàn giao

1. Agenda, danh sách học viên và tài liệu theo từng vai trò.
2. Runbook vận hành, xử lý sự cố, backup/restore và security checklist.
3. Bài lab, kết quả thực hành và câu hỏi thường gặp.
4. Danh sách tài khoản/role được cấp theo nguyên tắc least privilege.
5. Biên bản đào tạo, kết quả đánh giá và các action item sau đào tạo.
6. Video hoặc bản ghi buổi học nếu có thỏa thuận.

## Tiêu chí hoàn thành

- Học viên tham dự tối thiểu theo tỷ lệ được thống nhất.
- Nhóm vận hành thực hiện được health check, xem log/alert, backup và restore thử.
- Nhóm data engineer chạy được pipeline mẫu và xử lý một tình huống retry/backfill.
- Nhóm governance tạo/tra cứu asset, glossary, owner và lineage mẫu.
- Nhóm data consumer truy vấn dataset, đọc đúng KPI, tạo dashboard mẫu và kiểm tra quyền export.
- Các điểm chưa hoàn thành được ghi vào biên bản và có owner/ngày xử lý.

## Thông tin cần chốt trước lịch đào tạo

| Hạng mục | Giá trị |
|---|---|
| Môi trường thực hành | `<CẦN ĐIỀN>` |
| Số học viên theo nhóm | `<CẦN ĐIỀN>` |
| Ngày/giờ và hình thức | `<CẦN ĐIỀN>` |
| Bộ dữ liệu mẫu | `<CẦN ĐIỀN>` |
| Bộ KPI/use case | `<CẦN ĐIỀN>` |
| Đầu mối đào tạo | `<CẦN ĐIỀN>` |
| Tiêu chí ký biên bản | `<CẦN ĐIỀN>` |
