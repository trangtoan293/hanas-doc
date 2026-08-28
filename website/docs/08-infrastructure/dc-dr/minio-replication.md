# MinIO Site Replication

## 1. Mục tiêu

MinIO Site Replication đồng bộ object data và các cấu hình/IAM thuộc phạm vi Site Replication giữa site DC và DR. Cơ chế này hỗ trợ phục hồi site nhưng vẫn cần backup/retention và kiểm tra lag; dữ liệu vừa ghi có thể chưa xuất hiện ở site còn lại khi đường truyền hoặc peer lỗi.

## 2. Dữ liệu trong phạm vi

| Nhóm | Chính sách cần chốt |
|---|---|
| Landing/raw/vault/mart objects | Bucket, versioning, retention và replication scope |
| Velero backup objects | Bucket backup, TTL và immutability |
| IAM/bucket configuration | Đồng bộ theo Site Replication; phân quyền thao tác admin hạn chế |
| Local/PV metadata của service | Không tự động được bảo vệ chỉ bằng object replication; dùng Velero/DB backup |

## 3. Điều kiện trước khi cấu hình

- Hai deployment MinIO được sizing, version và topology theo compatibility matrix.
- Endpoint DC/DR có TLS, DNS/route, firewall allowlist và latency/bandwidth đã đo.
- Dùng tài khoản admin/service account dành riêng cho thao tác replication; credentials lấy từ Vault/Secret.
- Đã bật versioning/retention theo policy và loại bỏ bucket replication rule xung đột nếu triển khai Site Replication.
- Có kế hoạch xử lý khi mất một peer và khi đưa peer trở lại.

## 4. Cấu hình tham chiếu

```bash
# Khai báo alias; thay bằng endpoint và secret được cấp qua kênh an toàn
mc alias set dc https://<MINIO_DC_ENDPOINT> <REPLICATION_ACCESS_KEY> <REPLICATION_SECRET_KEY>
mc alias set dr https://<MINIO_DR_ENDPOINT> <REPLICATION_ACCESS_KEY> <REPLICATION_SECRET_KEY>

# Kiểm tra thông tin trước khi add peer
mc admin info dc
mc admin info dr

# Thiết lập site replication theo thiết kế đã phê duyệt
mc admin replicate add dc dr

# Kiểm tra cấu hình và trạng thái
mc admin replicate info dc
mc admin replicate status dc
mc replicate status dc
```

Lệnh và option phụ thuộc version MinIO; chạy `mc admin replicate --help` và đối chiếu release đang dùng trước khi thực hiện production. Không ghi access key/secret key vào shell history hoặc ticket.

## 5. Giám sát

| Kiểm tra | Ngưỡng/action |
|---|---|
| Peer reachable/healthy | Alert ngay khi peer unavailable |
| Replication lag | `<NGƯỠNG RPO ĐÃ CHỐT>`; mở incident nếu vượt ngưỡng |
| Failed/pending objects | Retry theo policy, kiểm tra network/quota/permission |
| Object count/size/checksum mẫu | Đối soát định kỳ giữa DC và DR |
| IAM/bucket drift | Chỉ thay đổi tại quy trình quản trị, ghi audit |

```bash
# Kiểm tra chi tiết khi có cảnh báo; không chạy resync tùy tiện trên production
mc admin replicate status dc
mc admin trace dc --errors --verbose
mc du --recursive dc/<BUCKET>
mc du --recursive dr/<BUCKET>
```

## 6. Peer failure và resync

Khi mất hẳn một peer, người có thẩm quyền quyết định chuyển site phải ghi nhận thời điểm, replication lag và phạm vi dữ liệu có thể thiếu. Khi dựng lại peer, giữ version/topology tương thích, kiểm tra kết nối hai chiều rồi dùng quy trình `replicate add`/resync theo hướng dẫn version cụ thể. Không upload hoặc tự cấu hình dữ liệu mới lên peer thay thế trước khi hoàn tất bước resync.

## 7. Tiêu chí nghiệm thu

- Replication group được tạo và có status healthy.
- Object mẫu, versioning/retention và IAM/bucket policy đạt kết quả mong đợi.
- Đo được lag trong điều kiện bình thường và khi mô phỏng nghẽn mạng.
- Thực hiện được resync/restore test và có biên bản.

Tham khảo: [MinIO Admin Client](https://min.io/docs/minio/linux/reference/minio-mc-admin.html) và [Site Failure Recovery](https://min.io/docs/minio/container/operations/data-recovery/recover-after-site-failure.html).
