# Kubernetes — Best Practices

## 1. Resource management

Mỗi container production phải khai báo `requests` và `limits`. Scheduler dùng request để đặt Pod; limit là giới hạn runtime. Đặt memory limit quá thấp có thể gây OOMKill, còn CPU limit quá thấp có thể gây throttling.

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "1Gi"
  limits:
    cpu: "2"
    memory: "4Gi"
```

- Theo dõi `kubectl top`, OOMKill, throttling, pending Pod và eviction.
- Dành headroom cho system daemon, rolling update và node failure.
- Dùng ResourceQuota/LimitRange theo namespace; không dùng cùng một profile cho Spark executor, Kafka broker và UI service.

## 2. High availability và rollout

- Stateful service cần replica, anti-affinity/topology spread, PDB và storage failure domain phù hợp.
- Dùng rolling update có `maxUnavailable`/`maxSurge` đã kiểm thử; không scale/upgrade hàng loạt trong giờ cao điểm.
- Đặt `podAntiAffinity` cho replica quan trọng và `topologySpreadConstraints` khi cluster có nhiều zone.
- Dùng `startupProbe` cho service khởi động lâu; `readinessProbe` để ngừng nhận traffic; `livenessProbe` để restart khi process bị treo.
- Kiểm tra capacity trước khi drain node và luôn có rollback.

## 3. Security

- RBAC theo namespace và service account; chỉ dùng ClusterRole khi thật sự cần.
- Bật Pod Security Admission theo baseline/restricted phù hợp, `runAsNonRoot`, read-only root filesystem khi service hỗ trợ.
- NetworkPolicy default deny, chỉ allow flow đã nêu trong sơ đồ triển khai.
- Image pin bằng digest, scan CVE, registry allowlist và provenance/signature nếu có.
- Secret lưu trong Vault/KMS hoặc Kubernetes Secret được mã hóa at rest; không ghi secret vào log/manifest/Git.
- Audit API server, ingress, security service và truy cập dữ liệu; forward về OpenObserve/SIEM theo policy.

## 4. Storage và dữ liệu

- Không dùng local ephemeral disk làm nơi duy nhất cho dữ liệu hoặc metadata production.
- Kiểm tra PV capacity, IOPS, inode, snapshot, reclaim policy và thời gian restore.
- Không xóa PVC/PV/object/snapshot trong thao tác bảo trì nếu chưa có phê duyệt.
- Test failover storage và restore theo lịch; ghi rõ RPO/RTO đo được.

## 5. Monitoring và cảnh báo

Theo dõi tối thiểu:

| Nhóm | Chỉ số/cảnh báo |
|---|---|
| Cluster | Node not ready, API latency, etcd health, CPU/memory/disk pressure |
| Workload | Pod restart, OOMKill, pending/evicted, probe failure, deployment unavailable |
| Storage | PV usage, IOPS/latency, MinIO capacity/drive/replication |
| Data | Kafka lag, NiFi queue/backpressure, Airflow failed DAG, Spark failed job |
| Backup | Velero backup failed/partial, BSL unavailable, restore test failed |
| Security | Unauthorized API, certificate/secret expiry, policy/audit ingestion gap |

## 6. Nâng cấp và thay đổi

1. Đọc compatibility matrix/release notes và xác nhận cửa sổ bảo trì.
2. Backup cluster/stateful data; test restore hoặc rollback point.
3. Thử trên staging, chạy smoke/performance/security checks.
4. Nâng từng pool/service theo dependency order; theo dõi rollout.
5. Xác minh data pipeline, query, dashboard, audit và alert.
6. Cập nhật version matrix, manifest digest và change record.

## 7. Checklist review

- [ ] Tất cả workload có owner, requests/limits và health probes.
- [ ] Replica/anti-affinity/PDB phù hợp với mức độ quan trọng.
- [ ] RBAC, NetworkPolicy, Pod Security và image policy đã review.
- [ ] Backup/restore và DR exercise có lịch, kết quả và action item.
- [ ] Dashboard/alert có người trực và test notification.
- [ ] Không còn credential thật trong manifest, log, tài liệu hoặc image.
