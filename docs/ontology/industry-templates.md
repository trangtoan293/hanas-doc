---
title: Mẫu ontology ngành ngân hàng
sidebar_label: Mẫu ngành ngân hàng
sidebar_position: 8
description: Dùng mẫu ontology ngân hàng và template library để khởi tạo mô hình nghiệp vụ, sau đó bổ sung mapping cho dữ liệu của bạn.
---

Mẫu ontology ngành giúp bạn bắt đầu từ một mô hình nghiệp vụ có sẵn thay vì tạo từng concept từ đầu. Trang này giới thiệu các mẫu ngân hàng và cách dùng template library trong Hanas Data Platform.

## Các mẫu hiện có

| Mẫu | Phạm vi | Mapping dữ liệu |
|---|---|---|
| `BankingVN` | Mô hình ngân hàng bán lẻ và vận hành, 99 entity type và 165 value type. | Có sẵn mapping tham chiếu cho 11 dataset datamart. |
| `BankingT24` | Mô hình hóa các tham số và đối tượng của một hệ thống core banking, 73 entity type và 87 value type. | Không có mapping; bạn phải tự ánh xạ. |

Số lượng trên đếm từ các tệp mẫu hiện tại và có thể thay đổi theo phiên bản template.

:::note Điều kiện

Mẫu chỉ cung cấp mô hình canonical. Record chỉ xuất hiện khi bạn ánh xạ concept vào dataset của mình, kiểm tra và phát hành. Có concept trong mẫu không có nghĩa là có sẵn dữ liệu hay KPI tương ứng.

:::

## Nhóm đối tượng chính

Mẫu `BankingVN` tổ chức các đối tượng theo miền nghiệp vụ.

| Nhóm | Ví dụ đối tượng |
|---|---|
| Khách hàng và đối tác | `Customer`, `IndividualCustomer`, `CorporateCustomer`, `CustomerGroup`, `PartyRelationship` |
| Tổ chức | `Branch`, `Employee`, `Company`, `BusinessDate` |
| Tiền gửi và cho vay | `DepositAccount`, `DepositProduct`, `LoanAccount`, `LoanProduct`, `RepaymentSchedule` |
| Tín dụng và tài sản bảo đảm | `CreditFacility`, `CollateralAsset`, `Guarantee`, `NonPerformingLoan` |
| Thanh toán và thẻ | `Transaction`, `Payment`, `Card`, `CardTransaction`, `StandingOrder` |
| Ngoại hối và thị trường tiền tệ | `FxDeal`, `MoneyMarketDeal`, `FxPosition`, `RepoTransaction` |
| Kế toán và báo cáo | `GlAccount`, `GlBalance`, `ProfitAndLoss`, `FinancialSummary` |
| Rủi ro và tuân thủ | `AssetClassification`, `LoanLossProvision`, `RiskWeightedAsset`, `RegulatoryRatio` |
| Tổng hợp theo ngày | `CustomerDailySummary`, `BranchDailySummary`, `LoanDailySummary` |

Các subtype như khách hàng cá nhân hay nợ xấu có ý nghĩa trong mô hình; hãy compile và kiểm tra mapping để xác nhận runtime cụ thể.

Mẫu `BankingT24` tập trung vào khách hàng, kiến trúc sản phẩm (product line, nhóm, property, condition), tài khoản, cho vay, thấu chi, tài trợ thương mại, tài sản bảo đảm, hạn mức và hạch toán.

:::caution Giới hạn hiện tại

Nội dung liên quan quy định ngân hàng trong mẫu là mô hình tham khảo. Hanas không xác nhận tính cập nhật hay mức tuân thủ pháp lý; hãy đối chiếu với yêu cầu của tổ chức bạn.

:::

## Dùng template library

Template library lưu các template và version để nhiều workspace dùng chung. Admin quản lý thư viện.

1. Nhập một seed template có sẵn trong bản triển khai vào thư viện, hoặc tải lên template của riêng bạn.
2. Kiểm tra nội dung bằng **validate preview**, sau đó lưu thành một version.
3. Đánh dấu version là đã xác minh trước khi cho nhóm sử dụng. Version có thể được đánh dấu không khuyến nghị (deprecate) hoặc khôi phục.
4. Trong workspace, tạo draft từ template và version đã chọn.
5. Hoàn thành [mapping](mapping.md), kiểm tra, rồi phát hành theo [quy trình quản trị](governance.md).

Thư viện ghi nhận workspace nào đang dùng version nào, giúp bạn đánh giá tác động trước khi đổi hoặc xóa version. Template version là tài nguyên khác với deployment đang phục vụ.

## Gợi ý áp dụng

- Chỉ chọn các concept cần runtime; giữ phần còn lại làm vocabulary.
- Bắt đầu từ khách hàng, tài khoản và sản phẩm rồi mở rộng dần.
- Dùng automap để tạo bản mapping đầu tiên, sau đó kiểm tra khóa và join thủ công.
- Giữ nguyên tên API của concept để cập nhật template sau này dễ đối chiếu.

## Tiếp theo

- [Ánh xạ dữ liệu](mapping.md) cho dataset của bạn.
- [Ontology Workspace](workspace.md) cho quy trình authoring.
- [Quản trị ontology](governance.md) cho import, export và phát hành.
