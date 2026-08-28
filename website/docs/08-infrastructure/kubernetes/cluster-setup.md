# Chuẩn Bị Và Thiết Lập Kubernetes Cluster

## 1. Phạm vi

Runbook này mô tả các điều kiện cần có trước khi cài service Hanas. Việc cài distribution cụ thể (RKE2, kubeadm, OpenShift hoặc distribution khác) phải theo chuẩn hạ tầng của khách hàng; không nên dùng lệnh mẫu này trực tiếp cho production nếu chưa có change ticket.

## 2. Yêu cầu đầu vào

| Nhóm | Tối thiểu cần xác nhận |
|---|---|
| Topology | Control plane HA, worker pool, failure domain/zone |
| OS/runtime | Linux được phê duyệt, containerd hoặc runtime tương thích |
| Network | CNI, Pod/Service CIDR, DNS, NTP, egress/ingress và firewall allowlist |
| Storage | CSI driver, StorageClass, IOPS/throughput, snapshot và capacity |
| Registry | Registry/mirror nội bộ, image pull secret và quy trình scan image |
| Access | `kubectl`, Helm, quyền RBAC, break-glass account được kiểm soát |
| Security | TLS/CA, IdP/SSO, secret store, audit log và policy baseline |
| DR | Cluster/site DR, object storage endpoint và đường truyền giữa site |

## 3. Sizing tham chiếu

| Môi trường | Gợi ý topology | Ghi chú |
|---|---|---|
| Dev/lab | 1 control plane + 1–2 worker | Không dùng cho production hoặc DR |
| Test/staging | 3 control plane + worker theo workload | Có staging restore/performance test |
| Production | 3 control plane + tối thiểu 3 worker; storage/compute/GPU pool theo capacity | Cần thiết kế failure domain và headroom |

Sizing cuối cùng phải tính theo data volume, tăng trưởng, retention, concurrency, throughput, query SLA, số pipeline, backup window và GPU model. Ghi kết quả tại [Baseline triển khai](../../00-overview/platform-baseline.md).

## 4. Kiểm tra client và cluster

```bash
# Kiểm tra client
kubectl version --client
helm version

# Kiểm tra quyền và cluster
kubectl cluster-info
kubectl get nodes -o wide
kubectl auth can-i get pods --all-namespaces
kubectl get storageclass
```

## 5. Tạo namespace và quota mẫu

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: hanas-platform
  labels:
    pod-security.kubernetes.io/enforce: restricted
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: hanas-platform-quota
  namespace: hanas-platform
spec:
  hard:
    requests.cpu: "20"
    requests.memory: 64Gi
    limits.cpu: "40"
    limits.memory: 128Gi
    persistentvolumeclaims: "20"
```

Điều chỉnh quota theo workload đã được phê duyệt; không sao chép giá trị mẫu vào mọi namespace.

## 6. Storage và networking

1. Cài CSI driver theo chuẩn của hạ tầng và tạo StorageClass cho workload phù hợp.
2. Kiểm tra dynamic provisioning, reclaim policy, snapshot/restore và encryption at rest.
3. Tách traffic quản trị, service nội bộ, data plane và backup nếu có thể.
4. Cấu hình Ingress/LoadBalancer, DNS và TLS certificate; chỉ expose endpoint cần thiết.
5. Tạo NetworkPolicy mặc định deny rồi mở các flow cần cho từng service.

```bash
# Kiểm tra provision một PVC test trước khi deploy stateful service
kubectl get storageclass
kubectl get csidrivers
kubectl get pvc -A
```

## 7. Thứ tự triển khai tham chiếu

1. Cluster, CNI, CSI, DNS, NTP, registry và policy baseline.
2. Namespace, RBAC, quota, secret integration, ingress và certificate.
3. MinIO/catalog và database stateful dependencies.
4. Kafka/NiFi, Airflow/Spark/dbt, DataHub, Dremio/Superset.
5. Ranger/Vault, OpenObserve, alerting và backup/Velero.
6. AI services nếu có GPU/model approval.
7. Smoke test, security test, performance baseline và DR exercise.

## 8. Tiêu chí sẵn sàng

- Tất cả node ready, thời gian hệ thống đồng bộ và không có resource pressure.
- CNI/CSI/DNS/Ingress/registry hoạt động và có log.
- Pod disruption, probe, quota, RBAC và NetworkPolicy đã được kiểm thử.
- PVC test tạo/xóa/restore được; object storage health và replication được kiểm tra.
- Có danh sách endpoint, port, firewall rule, owner và ticket thay đổi.
