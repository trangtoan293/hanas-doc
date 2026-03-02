# Đào Tạo Khai Thác Dữ Liệu (Data Consumer)

## Tổng Quan

| Thông tin | Chi tiết |
|-----------|---------|
| **Đối tượng** | Business Analyst, Report Users, End Users |
| **Thời lượng** | 1 tuần (full-time) |
| **Lịch học** | Mỗi ngày 8 giờ: 4 giờ theory + 4 giờ hands-on |
| **Điều kiện** | SQL cơ bản, hiểu biết nghiệp vụ |

## Kết Quả Sau Đào Tạo

Sau 1 tuần, học viên có khả năng:

- Truy vấn dữ liệu qua Dremio bằng SQL
- Tạo Virtual Datasets và Reflections để tăng tốc query
- Xây dựng dashboard trên BI tools (Superset, Tableau, PowerBI)
- Tìm kiếm và khám phá dữ liệu qua DataHub catalog
- Sử dụng AI Service (Dify) để hỏi đáp dữ liệu bằng ngôn ngữ tự nhiên

---

## Ngày 1-2: Dremio — Query & Analytics (16 giờ)

### Nội dung lý thuyết

| Chủ đề | Nội dung | Thời lượng |
|--------|---------|-----------|
| Dremio Interface | UI navigation, SQL editor, datasets browser | 2 giờ |
| SQL Fundamentals | SELECT, JOIN, GROUP BY, window functions trên Dremio | 3 giờ |
| Virtual Datasets | Tạo views, organize datasets, spaces | 2 giờ |
| Reflections | Raw/Aggregation reflections, query acceleration | 1 giờ |

### Hands-on

```sql
-- Basic query
SELECT * FROM raw_vault.hub_customer LIMIT 10;

-- Join tables
SELECT
    h.customer_id,
    s.full_name,
    s.email,
    s.city
FROM raw_vault.hub_customer h
JOIN raw_vault.sat_customer_details s
    ON h.hub_customer_hk = s.hub_customer_hk;

-- Aggregation
SELECT
    s.city,
    COUNT(DISTINCT h.customer_id) as total_customers,
    MAX(s.load_date) as last_updated
FROM raw_vault.hub_customer h
JOIN raw_vault.sat_customer_details s
    ON h.hub_customer_hk = s.hub_customer_hk
GROUP BY s.city
ORDER BY total_customers DESC;

-- Tạo Virtual Dataset
CREATE VIRTUAL DATASET customer_360 AS
SELECT
    h.customer_id,
    s.full_name,
    s.email,
    s.phone,
    s.city
FROM raw_vault.hub_customer h
JOIN raw_vault.sat_customer_details s
    ON h.hub_customer_hk = s.hub_customer_hk;

-- Tạo Reflection (tăng tốc query)
ALTER DATASET customer_360 CREATE RAW REFLECTION customer_360_raw;
```

📖 Tài liệu: [Dremio Documentation](../06-federation/dremio/README.md)

---

## Ngày 3: BI Tools & Dashboard (8 giờ)

### Nội dung lý thuyết

| Chủ đề | Nội dung | Thời lượng |
|--------|---------|-----------|
| BI Connectivity | JDBC/ODBC/REST connection từ BI tools đến Dremio | 1 giờ |
| Superset | Tạo charts, dashboards, filters | 1.5 giờ |
| Tableau/PowerBI | Connection setup, live query vs extract | 1.5 giờ |

### Hands-on: Dashboard Workshop

**Bài tập**: Tạo Sales Dashboard hoàn chỉnh

| Yêu cầu | Mô tả |
|----------|-------|
| Monthly Revenue Trend | Line chart hiển thị doanh thu theo tháng |
| Top 10 Customers | Bar chart top 10 khách hàng theo doanh thu |
| Sales by Region | Pie chart phân bổ theo khu vực |
| Date Range Filter | Filter cho phép chọn khoảng thời gian |

Thời gian: 2 giờ, Support Engineer hỗ trợ.

---

## Ngày 4: Data Catalog & AI Service (8 giờ)

### Nội dung lý thuyết

| Chủ đề | Nội dung | Thời lượng |
|--------|---------|-----------|
| DataHub for Consumers | Tìm kiếm datasets, xem schema, owners, descriptions | 1.5 giờ |
| Self-Service Analytics | Khám phá dữ liệu, hiểu lineage, business glossary | 1 giờ |
| AI Service — Dify | Chatbot hỏi đáp dữ liệu, RAG từ Lakehouse | 1.5 giờ |

### Hands-on

**DataHub:**
- Tìm kiếm datasets bằng keyword, tags, domain
- Xem schema, sample data, lineage graph
- Đọc Business Glossary để hiểu thuật ngữ nghiệp vụ

**AI Service (Dify):**
- Truy cập Dify chatbot để hỏi đáp dữ liệu bằng ngôn ngữ tự nhiên
- Sử dụng RAG workflow: hỏi câu hỏi → tìm kiếm dữ liệu → trả lời
- Hiểu khả năng và giới hạn của AI chatbot

📖 Tài liệu:
- [DataHub](../05-governance/datahub/README.md)
- [AI Service — Dify](../12-ai-service/README.md)
- [Hướng dẫn Dify + vLLM + Langfuse](../guides/integration/dify-vllm-langfuse.md)

---

## Ngày 5: Best Practices & Tổng Kết (8 giờ)

### SQL Best Practices

| Nguyên tắc | Giải thích |
|------------|-----------|
| Luôn dùng `LIMIT` khi explore | Tránh query toàn bộ dataset |
| Sử dụng Virtual Datasets | Tái sử dụng logic, không viết lại SQL |
| Request Reflections | Liên hệ admin khi query chậm để tạo reflection |
| Dùng Catalog | Tìm trong DataHub trước khi viết query mới |
| Date filters | Luôn filter theo thời gian để tăng hiệu suất |

### Tổng Kết & Thực Hành

- Review toàn bộ nội dung tuần
- Q&A giải đáp
- Bài tập cuối: tự tạo dashboard hoàn chỉnh từ A→Z

---

## Kiểm Tra & Đánh Giá

| Phần | Nội dung | Tiêu chí |
|------|----------|---------|
| Lý thuyết | 15 câu hỏi (Dremio, BI, DataHub) | ≥ 80% |
| Thực hành | Tạo virtual dataset + dashboard + tìm kiếm catalog | Hoàn thành đúng |
| Self-service | Tự tìm và trình bày một insight từ dữ liệu | Hợp lý, có giá trị |

## Tài Liệu Tham Khảo

- [Liên kết dữ liệu — Dremio](../06-federation/README.md)
- [Quản trị dữ liệu — DataHub](../05-governance/README.md)
- [AI Service](../12-ai-service/README.md)
- [Kiến trúc tổng thể](../00-overview/architecture.md)
- [Bảng thuật ngữ](../00-overview/glossary.md)
