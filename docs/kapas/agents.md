---
title: Agent, skill và tool
sidebar_label: Agent, skill và tool
sidebar_position: 2
description: Danh sách system agent của Kapas trong Hanas, công cụ mỗi agent được dùng và cách skill hỗ trợ agent.
---

Kapas tổ chức công việc theo **agent**. Mỗi agent có chỉ dẫn riêng, một tập tool được bật và, nếu cần, các skill đi kèm. Trang này liệt kê các agent hệ thống phục vụ data platform và nhóm tool chính của chúng.

## Khái niệm

| Khái niệm | Ý nghĩa |
|---|---|
| Agent | Trợ lý chuyên một nhiệm vụ, tạo từ template. |
| Tool | Hành động agent có thể gọi, như đọc schema, chạy truy vấn, tạo chart. |
| Skill | Gói hướng dẫn nghiệp vụ mà agent nạp khi cần (ví dụ cách chọn chart). |
| System agent | Agent do Hanas cung cấp sẵn, xuất hiện cho mọi người dùng. |

Bạn chỉ thấy và dùng được tool mà template của agent đã bật. Một agent không tự động có mọi quyền của agent khác.

## Chín system agent

| Agent | Dùng để | Kênh |
|---|---|---|
| Hanas Analyst | Hỏi đáp dữ liệu, chạy metric, truy vấn chỉ đọc, trích dẫn số liệu | Console |
| Analytics Studio Copilot | Tạo dataset, chart, dashboard trên Superset | Console, nhúng |
| Dashboard Copilot | Chỉnh dashboard qua spec YAML, kiểm tra rồi tạo dashboard bản nháp | Console, nhúng |
| SQL Copilot | Viết, sửa, giải thích, kiểm tra SQL trong SQL Editor | Console, nhúng |
| Catalog Steward | Tìm asset, lineage, độ mới; kiểm tra và cập nhật metadata trong Hanas Catalog | Console, nhúng |
| Ontology Assistant | Duyệt object, quan hệ và metric Ontology | Console, nhúng |
| Project Copilot | Hỗ trợ project dbt: model, lineage, lệnh dbt, báo cáo dạng board | Console, nhúng |
| Concept Copilot | Đề xuất concept và quan hệ trong draft Ontology | Console, nhúng |
| Mapping Copilot | Đề xuất, kiểm tra mapping và xử lý các điểm chặn do server quản lý | Console, nhúng |

:::note Điều kiện

Agent chỉ hoạt động khi dịch vụ đích tương ứng đã bật: Superset cho hai agent dashboard, Hanas Catalog cho Catalog Steward, dbt Studio cho Project Copilot, Ontology cho ba agent Ontology.

:::

Một số điểm cần biết:

- Hanas Analyst không tạo dashboard. Yêu cầu dựng dashboard được chuyển sang Analytics Studio Copilot.
- Dashboard Copilot chỉ tạo dashboard **chưa phát hành** (draft). Khi nhập dashboard có sẵn, Kapas làm việc trên bản sao, không sửa bản gốc.
- Concept Copilot và Mapping Copilot ghi đề xuất vào draft Ontology. Hai agent này không có tool phát hành Ontology; việc publish vẫn do quản trị viên thực hiện, xem [Quản trị ontology](../ontology/governance.md).
- Project Copilot được nhúng theo từng project dbt.

## Nhóm tool chính

### Query engine

| Tool | Chức năng |
|---|---|
| Duyệt catalog, tìm đường dẫn bảng | Liệt kê source, space, folder; tìm đường dẫn đầy đủ thay vì đoán tên. |
| Đọc schema | Lấy tên và kiểu cột. |
| Kiểm tra SQL | Dùng `EXPLAIN` để kiểm tra, không trả dữ liệu. |
| Truy vấn an toàn (đơn lẻ hoặc theo lô) | Chạy `SELECT`/`WITH` chỉ đọc. Xem [An toàn](safety.md). |
| Đọc thông tin Reflection, user, role | Chỉ đọc metadata; vẫn tuân theo quyền của bạn. |
| Lưu truy vấn đã được chấp nhận | Hanas Analyst lưu cặp câu hỏi và SQL bạn xác nhận để tham khảo sau. |

### Ontology và metric

| Tool | Chức năng |
|---|---|
| Danh mục object type | Xem danh sách, rồi chi tiết property, link, metric. |
| Truy vấn, tìm kiếm, tổng hợp | Lọc, sắp xếp, tìm theo chuỗi con, group và tính count/sum/avg/min/max. |
| Lấy object, đi theo link | Đọc một object theo khóa chính, đi theo quan hệ đã khai báo. |
| Tìm và chạy metric | Dựng SQL từ định nghĩa metric (đơn giản, tỷ lệ, dẫn xuất) rồi chạy truy vấn chỉ đọc. |
| Tool Concept và Mapping | Đọc ngữ cảnh run, ghi đề xuất, kiểm tra và xử lý blocker. |

### BI, catalog và dbt

| Nhóm | Chức năng |
|---|---|
| Superset | Tìm object có sẵn, đọc ngữ cảnh dataset, tạo hoặc sửa dataset, chart, dashboard, layout; dùng template dashboard. |
| Spec dashboard | Mở, đọc, sửa, ghi, hoàn tác spec; kiểm tra rồi áp thành dashboard nháp, kèm ảnh chụp để agent tự đánh giá khi có. |
| Hanas Catalog | Tìm asset, xem lineage, kiểm tra độ đầy đủ metadata và độ mới; sửa mô tả, tag, owner, tạo glossary term. |
| dbt | Đọc và ghi file project, xem model và lineage, chạy lệnh dbt, truy vấn warehouse chỉ đọc, dựng và render board. |

Tool ghi (tạo chart, sửa metadata, ghi file dbt) thay đổi hệ thống thật. Hãy kiểm tra đề xuất của agent trước khi xác nhận; xem [An toàn](safety.md) về giới hạn của cơ chế phê duyệt.

## Skill

Skill đi kèm agent cung cấp hướng dẫn nghiệp vụ, ví dụ cách chọn loại chart theo mục đích và hình dạng dữ liệu, bố cục 12 cột, cách hỏi đáp trên dữ liệu dự án. Quản trị viên xem và bật skill cho từng agent trong Kapas Console. Có skill trong hệ thống không đồng nghĩa mọi agent đều đang dùng nó.

## Agent tùy chọn

Ngoài chín system agent, Kapas có thể được cấu hình thêm agent hỏi đáp tài liệu (dùng Knowledge Platform, giới hạn theo các kho tri thức bạn được phép truy cập, có thể chỉ định bằng `@`). Agent này chỉ hoạt động khi Knowledge Platform được kết nối.

## Giới hạn

:::caution Giới hạn hiện tại

- Các agent nhúng (Catalog Steward, Project Copilot...) chỉ có ích khi ứng dụng host gắn chúng vào giao diện. Trong Kapas Console, bạn vẫn chat trực tiếp với từng agent.
- Chưa có máy chủ MCP nào của Hanas được bật sẵn. Tích hợp với dịch vụ dữ liệu dùng tool tích hợp sẵn.

:::

## Tiếp theo

- [Hỏi đáp dữ liệu](chat-with-data.md)
- [Báo cáo, trích dẫn và lịch chạy](reports-and-schedules.md)
- [Nhúng Kapas vào ứng dụng](../develop/kapas-embed.md)
