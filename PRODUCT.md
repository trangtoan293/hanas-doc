# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Doanh nghiệp nói chung (không nhắm một ngành cụ thể). Người quyết định mua và người đánh giá kỹ thuật: lãnh đạo dữ liệu/CNTT, kiến trúc sư, data engineer. Người dùng hằng ngày: analyst, người dùng nghiệp vụ, quản trị/vận hành, nhà phát triển tích hợp.

## Product Purpose

Hanas Data Platform gom kết nối, truy vấn, biến đổi, quản trị metadata, Ontology, phân tích và hỏi đáp AI trên dữ liệu vào một giao diện chung (Hanas Console), triển khai trên Kubernetes trong hạ tầng on-premise hoặc private cloud của tổ chức.

## Positioning

Một nền tảng dữ liệu, một lần đăng nhập, quyền đi theo người dùng. Query engine đọc dữ liệu tại chỗ (không bắt buộc sao chép trước); mọi dịch vụ cần dữ liệu đều đi qua query engine nên quyền được kiểm tra ở một chỗ, truy vấn chạy bằng danh tính của chính người dùng (Keycloak SSO). Giao diện tiếng Việt mặc định.

## Capabilities and Constraints

- Thành phần: Hanas Console, Query Engine (SQL, view, job, Reflection; REST, JDBC, ODBC, Arrow Flight), Ingestion vào Apache Iceberg, dbt Studio, Pipeline, Compute (Spark), Hanas Catalog, Ontology, Kapas AI, Analytics (Apache Superset), Keycloak.
- Tên gọi bắt buộc: không viết Dremio, QwenPaw, DataHub, Ossie, NiFi trong văn bản. Dùng "query engine", "Kapas", "Hanas Catalog", "Ontology Workspace".
- Không hứa: lineage mức cột, streaming thời gian thực, chất lượng dữ liệu trong Catalog, thông báo email/Slack, Helm chart trọn bộ (xem "Những điều không được hứa" trong `hanas-sales-kit/index.html`).

## Brand Commitments

- Tên: Hanas Data Platform, Hanas Console, Kapas, Hanas Catalog. Logo Katalyst trong `static/img/`.
- Song ngữ Việt (mặc định) + Anh.
- Văn phong theo `.claude/agents/hanas-doc-writer.md`: không tính từ rỗng (đột phá, vượt trội, hàng đầu, toàn diện, mạnh mẽ).

## Evidence on Hand

- 6 sơ đồ kiến trúc/luồng (sáng + tối) trong `static/img/diagrams/{vi,en}/`.
- Video commercial: người dùng sẽ cung cấp sau.
- Chưa có: khách hàng có thể nêu tên, testimonial, benchmark, bảng giá, ảnh chụp UI (môi trường thật chứa dữ liệu khách hàng, không được chụp). Không bịa các mục này.

## Product Principles

1. Nói đúng những gì đang chạy; giới hạn ghi rõ, không hứa roadmap.
2. Dữ liệu ở lại hạ tầng của khách hàng; kiểm soát và quyền là lý do mua.
3. Một điểm vào cho mọi vai trò.
