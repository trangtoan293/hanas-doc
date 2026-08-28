# Mục Tiêu Data Platform

## 1. Mục Tiêu Về Dữ Liệu Và Tích Hợp

- Thiết lập nền tảng thu nhận và tích hợp dữ liệu từ nhiều hệ thống nghiệp vụ (batch & near real-time)
- Hỗ trợ dữ liệu có cấu trúc, bán cấu trúc và phi cấu trúc
- Tổ chức theo các vùng: Landing → Raw → Processed → Curated
- Mở rộng dung lượng theo lộ trình dài hạn

## 2. Mục Tiêu Về Xử Lý Và Khai Thác

- Làm sạch, chuẩn hóa, biến đổi và tổng hợp dữ liệu
- Tái sử dụng pipeline xử lý
- Hỗ trợ báo cáo, phân tích qua công cụ truy vấn
- Khả năng mở rộng xử lý khi tải cao điểm

## 3. Mục Tiêu Về Quản Trị Dữ Liệu (Data Governance)

- Quản lý metadata kỹ thuật và nghiệp vụ
- Quản lý danh mục dữ liệu, business glossary
- Theo dõi lineage từ nguồn đến lớp khai thác
- Giám sát chất lượng dữ liệu
- Minh bạch phục vụ kiểm toán, thanh tra

## 4. Mục Tiêu Về An Toàn, Bảo Mật Và Tuân Thủ

- Kiểm soát truy cập theo vai trò, người dùng, nhóm
- Phân quyền chi tiết đến mức bảng, cột, trường
- Bảo vệ dữ liệu trong suốt vòng đời
- Tuân thủ quy định về ATTT

## 5. Mục Tiêu Về Giám Sát, Vận Hành

- Giám sát tài nguyên, hiệu năng xử lý và lưu trữ
- Theo dõi trạng thái pipeline và dịch vụ
- Phát hiện sớm sự cố, đảm bảo tính sẵn sàng
- Vận hành ổn định, liên tục, dễ mở rộng

## 6. Mục Tiêu Về AI Service

- Tích hợp AI Service layer khai thác dữ liệu Lakehouse cho ứng dụng AI
- Host và vận hành LLM models (inference, embedding, reranking) trên GPU servers
- Xây dựng AI workflows (chatbot, RAG, agent) phục vụ nghiệp vụ nội bộ
- Giám sát chất lượng, hiệu suất và chi phí AI thông qua LLM observability
- Không phụ thuộc cứng vào một mô hình đơn lẻ — hỗ trợ đa models và mở rộng trong tương lai
- Nền tảng thống nhất phục vụ chuyển đổi số toàn diện (dữ liệu + AI)

## 7. Tiêu chí thành công và nghiệm thu

Các mục tiêu trên cần được chuyển thành tiêu chí đo được theo từng dự án:

| Nhóm | Bằng chứng nghiệm thu tham chiếu |
|---|---|
| Kết nối nguồn | Source inventory, data contract, full-load/CDC test và reconciliation |
| Pipeline | Run thành công, retry/backfill, throughput/latency baseline và alert |
| Data Lakehouse | Đúng zone, schema/partition evolution, snapshot/compaction và retention |
| Governance | Asset, owner, glossary, lineage, quality result và certification |
| Security | SSO/MFA, RBAC, row/column masking, export control và audit evidence |
| Khai thác | Query/Dashboard đúng KPI, freshness và quyền consumer |
| Vận hành/DR | Health dashboard, backup `Completed`, restore test và RPO/RTO đo được |
| AI (nếu áp dụng) | Model/version, prompt/data policy, latency, quality, cost và trace |

Ngưỡng số liệu, owner, thời hạn và môi trường áp dụng phải được ghi trong [Baseline triển khai](platform-baseline.md) và biên bản nghiệm thu; không dùng các giá trị tham khảo làm cam kết mặc định.
