# Đào Tạo Quản Trị Dữ Liệu (Data Governance)

## Tổng Quan

| Thông tin | Chi tiết |
|-----------|---------|
| **Đối tượng** | Data Steward, Data Owner, Data Custodian |
| **Thời lượng** | 1 tuần (full-time) |
| **Lịch học** | Mỗi ngày 8 giờ: 4 giờ theory + 4 giờ hands-on |
| **Điều kiện** | Hiểu biết cơ bản về database, SQL, quy trình nghiệp vụ |

## Kết Quả Sau Đào Tạo

Sau 1 tuần, học viên có khả năng:

- Sử dụng DataHub để quản lý metadata, tìm kiếm và khám phá datasets
- Theo dõi data lineage từ nguồn đến báo cáo
- Quản lý Business Glossary — thuật ngữ nghiệp vụ thống nhất
- Thiết lập và giám sát Data Quality assertions
- Cấu hình access control policies với Apache Ranger
- Đảm bảo compliance theo yêu cầu (SOC2, GDPR, PCI-DSS)

---

## Ngày 1-2: DataHub — Metadata Management (16 giờ)

### Nội dung lý thuyết

| Chủ đề | Nội dung | Thời lượng |
|--------|---------|-----------|
| Data Governance fundamentals | Tại sao cần governance, metadata management, data lineage | 2 giờ |
| DataHub Platform | Architecture, ingestion, UI navigation | 2 giờ |
| Data Catalog | Tìm kiếm datasets, xem schema, owners, tags | 2 giờ |
| Data Lineage | Xem dòng dữ liệu end-to-end, impact analysis | 2 giờ |

### Hands-on

- Truy cập DataHub UI → Tìm kiếm và khám phá datasets
- Xem schema, owners, tags cho `hub_customer`, `sat_customer_details`
- Theo dõi lineage: Source → NiFi → Spark → Iceberg → dbt → Dremio
- Gán ownership và tags cho datasets

📖 Tài liệu: [DataHub Documentation](../05-governance/datahub/README.md)

---

## Ngày 3: Business Glossary (8 giờ)

### Nội dung lý thuyết

| Chủ đề | Nội dung | Thời lượng |
|--------|---------|-----------|
| Business Glossary | Tại sao cần, tổ chức thuật ngữ, quản lý phiên bản | 2 giờ |
| Glossary Management | Tạo terms, groups, liên kết với datasets | 2 giờ |

### Hands-on

- Tạo Business Glossary cho domain (VD: Customer, Product, Finance)
- Định nghĩa terms: Customer ID, Revenue, Active Customer...
- Liên kết terms với datasets và columns trong DataHub
- Review và phê duyệt glossary entries

📖 Tham khảo: [Bảng thuật ngữ platform](../00-overview/glossary.md)

---

## Ngày 4: Data Quality & Compliance (8 giờ)

### Nội dung lý thuyết

| Chủ đề | Nội dung | Thời lượng |
|--------|---------|-----------|
| Data Quality Assertions | Freshness, volume, schema, custom SQL assertions | 2 giờ |
| Quality Monitoring | Dashboard, alerts, trend analysis | 1 giờ |
| Compliance | SOC2, GDPR, PCI-DSS requirements | 1 giờ |

### Hands-on: Data Quality Assertions

- Tạo assertions cho datasets:
  - **Freshness**: Data phải được cập nhật trong 1 giờ
  - **Volume**: Row count không giảm quá 10% ngày trước
  - **Schema**: Không có column bị remove bất ngờ
- Xem test results và trend
- Thiết lập alerts khi assertion fail

---

## Ngày 5: Access Control & Tổng Kết (8 giờ)

### Nội dung lý thuyết

| Chủ đề | Nội dung | Thời lượng |
|--------|---------|-----------|
| Apache Ranger | Policies, access types, audit logs | 2 giờ |
| RBAC | Role-based access, column-level security, row-level filtering | 1 giờ |
| Audit | Access reviews, evidence collection | 1 giờ |

### Hands-on

- Cấu hình Ranger policies cho datasets
- Thiết lập column-level masking (VD: mask email, phone)
- Review audit logs — ai truy cập dữ liệu gì
- Tạo compliance report

📖 Tài liệu: [An toàn thông tin — Ranger](../09-security/README.md)

---

## Kiểm Tra & Đánh Giá

| Phần | Nội dung | Tiêu chí |
|------|----------|---------|
| Lý thuyết | 20 câu hỏi (DataHub, glossary, quality, compliance) | ≥ 80% |
| Thực hành | Tạo glossary + quality assertions + access policies cho dataset mới | Hoàn thành đúng |
| Scenario | Phát hiện và xử lý data quality issue | Đúng quy trình |

## Tài Liệu Tham Khảo

- [Quản trị dữ liệu — DataHub](../05-governance/README.md)
- [An toàn thông tin](../09-security/README.md)
- [Bảng thuật ngữ](../00-overview/glossary.md)
- [Kiến trúc tổng thể](../00-overview/architecture.md)
