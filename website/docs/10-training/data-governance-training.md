# Đào tạo quản trị dữ liệu và DataHub

## Mục tiêu

Sau khóa học, data steward và data owner có thể tìm kiếm asset, quản lý glossary/owner/domain, đọc lineage, theo dõi chất lượng và xử lý yêu cầu truy cập theo quy trình của khách hàng.

## Đối tượng và điều kiện

| Đối tượng | Vai trò trong khóa học |
|---|---|
| Data owner | Phê duyệt định nghĩa, classification, quyền và chất lượng |
| Data steward | Cập nhật metadata, glossary, owner, domain và issue |
| Data engineer | Publish schema/lineage/test result từ pipeline |
| Security auditor | Kiểm tra policy, audit và evidence |
| BI/data consumer | Tìm dataset được phê duyệt và hiểu freshness/KPI |

Điều kiện: có tài khoản DataHub theo role, dataset mẫu đã redact, glossary/KPI mẫu, domain owner và quyền truy cập môi trường test. Không đưa dữ liệu production nhạy cảm vào bài lab nếu chưa có phê duyệt.

## Nội dung

| Module | Nội dung | Đầu ra |
|---|---|---|
| 1. Metadata model | Dataset, schema, field, platform, environment, ownership | Asset map của một domain |
| 2. Search & discovery | Search, browse, filter, tag, domain và related assets | Tìm đúng dataset theo business question |
| 3. Glossary & KPI | Term, definition, owner, synonym, metric và approval | Glossary cho bộ KPI use case |
| 4. Lineage | Upstream/downstream, pipeline, column lineage và freshness | Lineage report từ source đến mart |
| 5. Quality | Test result, assertion, freshness, issue và remediation | Một quality issue có owner/deadline |
| 6. Access & compliance | Classification, access request, masking, export và audit | Access request đúng thông tin |

## Bài thực hành

1. Tạo hoặc kiểm tra asset `customer_360` trong môi trường test.
2. Gán domain, owner/steward, mô tả, classification, tag và term nghiệp vụ.
3. Kiểm tra schema, freshness, upstream/downstream và liên kết dashboard.
4. Ghi nhận một quality issue, gán owner, deadline và trạng thái xử lý.
5. Tạo access request cho role consumer; kiểm tra allow/deny và export policy.
6. Xuất báo cáo metadata đã redact và lưu evidence theo quy định.

## Quy tắc quản trị

- Dataset production phải có owner, steward, description, classification và freshness.
- Thay đổi định nghĩa KPI cần version, lý do, approver và ngày hiệu lực.
- Không đánh dấu asset “certified” khi chưa có owner và quality evidence.
- Lineage tự động phải được review; không coi ingestion thành công là lineage đúng.
- Access/permission thực hiện theo [quy trình phân quyền](../09-security/authorization.md), không cấp quyền trực tiếp ngoài ticket.

## Tiêu chí hoàn thành

| Kiểm tra | Kết quả cần đạt |
|---|---|
| Tìm asset và đọc metadata | Đúng dataset, môi trường và freshness |
| Tạo/cập nhật glossary | Có definition, owner và approval |
| Đọc lineage | Xác định được upstream/downstream và điểm lỗi |
| Theo dõi quality issue | Có evidence, owner, deadline, trạng thái |
| Access request | Đủ scope, mục đích, thời hạn và approver |
| Audit/export | Không xuất dữ liệu ngoài policy; lưu evidence |

## Thông tin cần chốt

| Hạng mục | Giá trị |
|---|---|
| DataHub URL/organization | `<CẦN ĐIỀN>` |
| Domain và data owner | `<CẦN ĐIỀN>` |
| Bộ glossary/KPI sử dụng | `<CẦN ĐIỀN>` |
| Dataset lab đã redact | `<CẦN ĐIỀN>` |
| Quy trình certification/approval | `<CẦN ĐIỀN>` |
| Người đánh giá và tiêu chí ký biên bản | `<CẦN ĐIỀN>` |

Tham khảo chi tiết: [DataHub User Guide](../05-governance/datahub/user-guide.md) và [DataHub Best Practices](../05-governance/datahub/best-practices.md).
