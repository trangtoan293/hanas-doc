# Quy Trình Khôi Phục (Recovery Workflow)

## Khi Site DC Ngưng Hoạt Động

### Bước 1: Kiểm Tra Dữ Liệu
Xác nhận backup mới nhất từ DC đã đồng bộ sang MinIO tại DR.

### Bước 2: Cài Đặt Velero Tại DR
Thiết lập Velero trên cụm K8s DR trỏ vào bucket chứa backup.

### Bước 3: Thực Thi Restore
```bash
velero restore create --from-backup <backup-name>
```
Velero tự động tạo lại Namespace, Service, Pod và khôi phục dữ liệu.

### Bước 4: Kích Hoạt Dịch Vụ
- Kiểm tra kết nối Dremio/Spark tới MinIO mới tại DR
- Khôi phục metadata Dremio (nếu cần)

## RPO/RTO

| Metric | Giá trị |
|---|---|
| **RPO** (dữ liệu lớn) | ~0 (nhờ Site Replication) |
| **RTO** (hệ thống K8s) | Phụ thuộc tần suất backup Velero |
