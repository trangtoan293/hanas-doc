# Velero — Sao Lưu Kubernetes

## 1. Phạm vi backup

Velero backup Kubernetes resources và, khi đã cài provider phù hợp, dữ liệu Persistent Volume. Object storage nơi Velero lưu backup phải nằm trong scope bảo vệ của DC-DR hoặc có bản sao/immutability riêng.

| Nhóm | Ví dụ |
|---|---|
| Kubernetes resources | Namespace, Deployment, StatefulSet, Service, Ingress, ConfigMap, Secret, CRD |
| Persistent data | Metadata DB, Airflow DB, catalog, Dremio metadata, service state theo scope |
| Không mặc định | External database, object data ngoài BSL, secret ngoài cluster, license ngoài manifest |

## 2. Chuẩn bị

- Cài Velero CLI/server tương thích Kubernetes và provider object/PV.
- Tạo bucket riêng, policy least privilege, versioning/retention/immutability theo yêu cầu.
- Tạo `BackupStorageLocation` và `VolumeSnapshotLocation` nếu provider hỗ trợ.
- Xác định namespace/resource/PV cần backup, loại trừ cache/temp và lưu danh sách vào change record.

## 3. Cấu hình tham chiếu

```bash
# Ví dụ khung; plugin, URL và secret file phụ thuộc provider/on-prem setup
velero install \
  --provider aws \
  --plugins <AWS_OR_S3_PLUGIN_IMAGE> \
  --bucket <VELERO_BUCKET> \
  --secret-file ./credentials-velero \
  --backup-location-config \
    region=<REGION>,s3ForcePathStyle="true",s3Url=<MINIO_S3_URL>

# Kiểm tra BSL và server
kubectl get pods -n velero
velero backup-location get
velero plugin get
```

Secret file chỉ tồn tại trên máy/secret store được kiểm soát; không commit hoặc paste nội dung vào tài liệu.

## 4. Lịch backup tham chiếu

```bash
# Điều chỉnh cron/namespace/TTL theo hợp đồng và capacity
velero schedule create hanas-daily \
  --schedule "CRON_TZ=Asia/Ho_Chi_Minh 0 2 * * *" \
  --include-namespaces ingestion,storage,processing,orchestration,governance,serving,security,observability \
  --ttl 720h

velero schedule get
velero backup get
```

| Policy | Tần suất tham chiếu | Retention tham chiếu | Mục đích |
|---|---|---|---|
| Daily | Hàng ngày | 30 ngày | Khôi phục vận hành thường ngày |
| Weekly | Hàng tuần | 12 tuần | Điểm khôi phục dài hơn |
| Pre-change | Trước upgrade/migration | Theo change record | Rollback an toàn |

## 5. Kiểm tra backup

```bash
velero backup describe <BACKUP_NAME> --details
velero backup logs <BACKUP_NAME>
velero backup get --output wide

# Tạo restore vào namespace test/cô lập trước khi thực hiện DR thật
velero restore create restore-test-<DATE> \
  --from-backup <BACKUP_NAME> \
  --namespace-mappings <SOURCE_NAMESPACE>:restore-test
velero restore describe restore-test-<DATE> --details
```

Backup `Completed` là điều kiện cần, không phải bằng chứng restore thành công. Restore test phải kiểm tra service health, PV data, catalog, pipeline, query và quyền.

## 6. Chính sách và cảnh báo

- Alert khi backup `Failed`/`PartiallyFailed`, BSL unavailable, expired backup hoặc dung lượng bucket thấp.
- Ghi backup name, thời điểm, scope, size, phase, lỗi và người kiểm tra vào báo cáo.
- Tách quyền tạo/xóa backup; bật retention/immutability nếu yêu cầu chống xóa nhầm/ransomware.
- Không backup secret plaintext ra nơi không được phê duyệt; mã hóa object storage và đường truyền.

Tham khảo: [Velero Basic Install](https://velero.io/docs/main/basic-install/), [Backup Reference](https://velero.io/docs/main/backup-reference/) và [Disaster Recovery](https://velero.io/docs/main/disaster-case/).
