# Apache Spark - Cài Đặt & Triển Khai

Hướng dẫn chi tiết cài đặt Spark on Kubernetes, từ build Docker image đến deploy Spark Operator trên cụm K8s.

## Yêu Cầu Hệ Thống

### Infrastructure

- **Kubernetes Cluster**: v1.24+
- **kubectl**: Đã cấu hình kết nối cluster
- **Helm**: v3.0+
- **Docker**: Để build Spark image
- **Container Registry**: Để push image (Docker Hub, Harbor, ...)

### External Dependencies

| Service | Mục đích | Port mặc định |
|---|---|---|
| **Hive Metastore** | Quản lý metadata cho Iceberg tables | `9083` (Thrift) |
| **MinIO / S3** | Object storage cho Iceberg data | `9000` |
| **Git Server** | Lưu trữ dbt-project code (Gitea, GitHub, ...) | `80/443` |

### Resource Tối Thiểu

| Môi trường | CPU/node | RAM/node | Số node |
|---|---|---|---|
| **Development** | 2 cores | 4 GB | 3+ worker |
| **Production** | 8+ cores | 32+ GB | 5+ worker |

---

## Bước 1: Build Spark Docker Image

### Cấu Trúc Dockerfile

Image được build từ Bitnami Spark 3.5.1 với các layer:

```dockerfile
# Base: Bitnami Spark 3.5.1
FROM bitnami/spark:3.5.1

# 1. System packages
RUN apt-get update && apt-get install -y curl python3-pip python3-dev python3-venv

# 2. Python dependencies
COPY requirements.txt .
RUN python3 -m pip install --no-cache-dir -r requirements.txt

# 3. Application code
COPY spark_code/ /app/

# 4. Download JAR dependencies
#    - Iceberg Spark Runtime 1.8.1
#    - Iceberg AWS Bundle 1.8.1
#    - Hadoop AWS 3.3.4
#    - AWS Java SDK Bundle 1.12.772
#    - Oracle JDBC Driver 23.7.0.25.01
RUN curl -L -o /dbt/jars/iceberg-spark-runtime-3.5_2.12-${ICEBERG_VERSION}.jar \
    https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/${ICEBERG_VERSION}/...
# ... (các JARs khác)

# 5. Copy JARs vào Spark classpath
RUN cp /dbt/jars/*.jar /opt/bitnami/spark/jars/

# 6. Non-root user (UID 1001)
USER 1001
```

### Python Dependencies (`requirements.txt`)

```text
pyspark>=3.5.1
pandas>=2.0.0
numpy>=2.0.0,<3.0.0
dbt-spark==1.9.0
boto3>=1.26.0
s3fs>=2023.6.0
pyarrow>=12.0.0
pyiceberg[hive,s3fs]>=0.7.0
oracledb>=2.0.0
```

### Build & Push Image

```bash
# Build cho linux/amd64 (K8s standard)
docker buildx build \
  --platform linux/amd64 \
  -f docker/Dockerfile \
  -t <REGISTRY>/<NAMESPACE>/dbt-spark-k8s-ktl:latest \
  --progress=plain .

# Push lên registry
docker push <REGISTRY>/<NAMESPACE>/dbt-spark-k8s-ktl:latest
```

> **Lưu ý**: Nếu cần thêm JDBC driver cho MySQL/MSSQL, sử dụng `docker/Dockerfile.new` (extended image).

### Kiểm Tra Image

```bash
# Chạy thử container
docker run --rm -it <REGISTRY>/<NAMESPACE>/dbt-spark-k8s-ktl:latest bash

# Verify JARs
ls /opt/bitnami/spark/jars/ | grep -i iceberg
# iceberg-spark-runtime-3.5_2.12-1.8.1.jar
# iceberg-aws-bundle-1.8.1.jar

# Verify Python
python3 -c "import pyspark; print(pyspark.__version__)"
# 3.5.1
python3 -c "import dbt; print(dbt.__version__)"
```

---

## Bước 2: Cài Đặt Spark Operator

Spark Operator là Kubernetes operator quản lý lifecycle của SparkApplication.

### Cài Đặt Bằng Helm

```bash
# Thêm Helm repository
helm repo add spark-operator https://kubeflow.github.io/spark-operator
helm repo update

# Cài đặt Spark Operator
helm install spark-operator spark-operator/spark-operator \
  --namespace spark-operator \
  --create-namespace \
  --set webhook.enable=true \
  --set "spark.jobNamespaces={spark-jobs}"
```

**Giải thích tham số:**

| Tham số | Giá trị | Mô tả |
|---|---|---|
| `webhook.enable` | `true` | Cho phép mutating webhook để inject sidecar, validate manifests |
| `spark.jobNamespaces` | `{spark-jobs}` | Namespace mà Operator sẽ quản lý SparkApplication |

### Xác Minh Cài Đặt

```bash
# Kiểm tra Operator pod đang chạy
kubectl get pods -n spark-operator
# NAME                                READY   STATUS    RESTARTS   AGE
# spark-operator-5d7c6b8d9c-xxxxx     1/1     Running   0          30s

# Kiểm tra CRD đã được tạo
kubectl get crd sparkapplications.sparkoperator.k8s.io
# NAME                                           CREATED AT
# sparkapplications.sparkoperator.k8s.io          2025-...

# Kiểm tra API resource
kubectl api-resources | grep sparkoperator
# sparkapplications    sparkoperator.k8s.io/v1beta2    true    SparkApplication
```

---

## Bước 3: Tạo Namespace & RBAC

### Tạo Namespace

```bash
kubectl create namespace spark-jobs
kubectl label namespace spark-jobs app=spark-jobs
```

### Tạo RBAC

Spark cần ServiceAccount với quyền tạo/quản lý pods (executor):

```yaml
# k8s/base/rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: spark
  namespace: spark-jobs
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: spark-role
  namespace: spark-jobs
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps", "persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "create", "delete", "patch", "update"]
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: spark-role-binding
  namespace: spark-jobs
subjects:
  - kind: ServiceAccount
    name: spark
    namespace: spark-jobs
roleRef:
  kind: Role
  name: spark-role
  apiGroup: rbac.authorization.k8s.io
```

```bash
kubectl apply -f k8s/base/rbac.yaml
```

### Xác Minh RBAC

```bash
kubectl get serviceaccount spark -n spark-jobs
kubectl get role spark-role -n spark-jobs
kubectl get rolebinding spark-role-binding -n spark-jobs

# Test quyền
kubectl auth can-i create pods --as=system:serviceaccount:spark-jobs:spark -n spark-jobs
# yes
```

---

## Bước 4: Cấu Hình ConfigMaps

### ConfigMap Cơ Bản

Chứa các thông tin infrastructure (non-sensitive):

```yaml
# k8s/base/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: spark-k8s-config
  namespace: spark-jobs
data:
  HIVE_METASTORE_URI: "thrift://<HIVE_METASTORE_HOST>:9083"
  S3_ENDPOINT: "http://<MINIO_HOST>:9000"
  S3_WAREHOUSE_DIR: "s3a://data/warehouse/"
```

### ConfigMap Git-Sync

Cấu hình cho git-sync sidecar để pull dbt-project:

```yaml
# k8s/base/git-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: git-sync-config
  namespace: spark-jobs
data:
  GIT_SYNC_REPO: "http://gitea.example.com/team/dbt-project"
  GIT_SYNC_BRANCH: "dev"
  GIT_SYNC_ROOT: "/opt/spark/work-dir"
  GIT_SYNC_DEST: "dbt-project"
  GIT_SYNC_ONE_TIME: "true"       # Clone 1 lần khi init
  GIT_SYNC_DEPTH: "1"             # Shallow clone
  GIT_SYNC_PERMISSIONS: "0755"
```

```bash
kubectl apply -f k8s/base/configmap.yaml
kubectl apply -f k8s/base/git-configmap.yaml
```

---

## Bước 5: Tạo Secrets

> ⚠️ **KHÔNG BAO GIỜ** commit credentials vào Git! Luôn dùng Kubernetes Secrets.

### AWS/S3 Credentials (MinIO)

```bash
kubectl create secret generic spark-k8s-aws-credentials \
  --from-literal=AWS_ACCESS_KEY_ID=<access_key> \
  --from-literal=AWS_SECRET_ACCESS_KEY=<secret_key> \
  --from-literal=AWS_REGION=us-east-1 \
  -n spark-jobs
```

### Oracle Database Credentials

```bash
kubectl create secret generic spark-k8s-oracle-credentials \
  --from-literal=ORACLE_HOST=<host> \
  --from-literal=ORACLE_PORT=1521 \
  --from-literal=ORACLE_USERNAME=<user> \
  --from-literal=ORACLE_PASSWORD=<password> \
  --from-literal=ORACLE_SERVICE=<service_name> \
  -n spark-jobs
```

### Git Credentials (Nếu repo private)

```bash
kubectl create secret generic git-credentials \
  --from-literal=GIT_USERNAME=<git_user> \
  --from-literal=GIT_PASSWORD=<git_token> \
  -n spark-jobs
```

### Xác Minh Secrets

```bash
# Liệt kê secrets (không hiện values)
kubectl get secrets -n spark-jobs

# Xem keys của secret
kubectl describe secret spark-k8s-aws-credentials -n spark-jobs
```

---

## Bước 6: Kiểm Tra Sau Cài Đặt

### Test Kết Nối

```bash
# Test Hive Metastore connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -n spark-jobs -- \
  sh -c "telnet <HIVE_METASTORE_HOST> 9083"

# Test MinIO connectivity
kubectl run -it --rm aws-cli --image=amazon/aws-cli --restart=Never -n spark-jobs -- \
  s3 ls s3://data/ --endpoint-url http://<MINIO_HOST>:9000
```

### Test Job

Chạy một SparkApplication đơn giản để kiểm tra toàn bộ pipeline:

```bash
kubectl apply -f k8s/jobs/spark-sql-runner.yaml

# Theo dõi trạng thái
kubectl get sparkapplications -n spark-jobs -w

# Xem logs
kubectl logs -f $(kubectl get pods -n spark-jobs -l spark-role=driver -o name | head -1) -n spark-jobs
```

### Checklist Cài Đặt

- [ ] Spark Operator đang chạy (`spark-operator` namespace)
- [ ] SparkApplication CRD đã được tạo
- [ ] Namespace `spark-jobs` đã tạo
- [ ] RBAC (ServiceAccount `spark`, Role, RoleBinding) đã apply
- [ ] ConfigMaps đã tạo và cấu hình đúng endpoints
- [ ] Secrets đã tạo (AWS, Oracle, Git)
- [ ] Docker image đã build và push lên registry
- [ ] Hive Metastore accessible từ cluster
- [ ] MinIO/S3 accessible từ cluster
- [ ] Test job chạy thành công
