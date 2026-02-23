# Giải Pháp DC-DR

## Tổng Quan

Giải pháp DC-DR kết hợp sao lưu cấu hình định kỳ và đồng bộ dữ liệu thời gian thực:

| Tầng | Công cụ | Cơ chế |
|---|---|---|
| **Dữ liệu** (Object Storage) | MinIO Site Replication | Đồng bộ real-time |
| **Ứng dụng & Metadata** (K8s) | Velero | Backup định kỳ |

## Tài Liệu

- [MinIO Site Replication](minio-replication.md)
- [Velero Backup](velero-backup.md)
- [Quy trình khôi phục](recovery-workflow.md)
