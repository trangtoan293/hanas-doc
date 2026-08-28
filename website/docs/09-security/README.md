# An Toàn Thông Tin (Security)

## Tổng Quan

Hệ thống bảo mật xuyên suốt nền tảng, bao gồm kiểm soát truy cập, phân quyền, quản lý secrets, audit và đánh giá ATTT. Các chính sách cụ thể phải theo yêu cầu của khách hàng và được ghi nhận trong baseline triển khai.

## Thành Phần

- [Apache Ranger](apache-ranger/README.md) — Authorization & Access Control
- [HashiCorp Vault](hashicorp-vault/README.md) — Secrets Management
- [Baseline triển khai](../00-overview/platform-baseline.md) — Mapping IdP, endpoint và owner

## Tài Liệu Bổ Sung

- [Kiểm tra & Xác thực](authentication.md)
- [Phân quyền](authorization.md)
- [Đánh giá ATTT](security-assessment.md)

## Nguyên tắc bắt buộc

- SSO/MFA cho người dùng quản trị khi IdP của khách hàng hỗ trợ.
- RBAC theo group và least privilege; không dùng tài khoản dùng chung.
- Secret được lưu trong Vault/Kubernetes Secret, không ghi trong Git, image hoặc tài liệu bàn giao.
- Row/column masking và export control phải có test allow/deny cùng audit evidence.
