# Information Mart

## Tổng Quan

Information Mart là lớp dữ liệu cuối cùng phục vụ người dùng cuối (BI, dashboard, báo cáo).

## Cấu Trúc Dữ Liệu

| Loại | Mô tả |
|---|---|
| **Star Schema** | Fact + Dimension tables cho BI truyền thống |
| **Wide Table** | Bảng rộng denormalized cho phân tích |
| **Analytical Views** | View phân tích chuyên biệt |
| **Semantic Layer** | Lớp ngữ nghĩa chuẩn hóa logic |

## Vai Trò

- Tối ưu truy vấn cho BI, dashboard, báo cáo
- Dữ liệu dễ hiểu, giảm độ phức tạp
- Phục vụ: PowerBI, Tableau, Superset, Cognos
