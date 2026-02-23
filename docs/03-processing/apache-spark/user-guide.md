# Apache Spark - Hướng Dẫn Sử Dụng

## Submit SparkApplication

SparkApplication là Kubernetes CRD (Custom Resource Definition) được Spark Operator quản lý. Mỗi job được submit qua một manifest YAML.

### Cấu Trúc SparkApplication Manifest

```yaml
apiVersion: "sparkoperator.k8s.io/v1beta2"
kind: SparkApplication
metadata:
  name: <job-name>
  namespace: spark-jobs
spec:
  type: Python
  mode: cluster
  image: "<REGISTRY>/dbt-spark-k8s-ktl:<TAG>"
  imagePullPolicy: IfNotPresent
  mainApplicationFile: "local:///opt/spark/work-dir/dbt-project/dbt_runner.py"
  arguments: ["run", "--target", "dev"]
  sparkVersion: "3.5.1"

  sparkConf:
    # ... (xem configuration.md)

  driver:
    cores: 1
    memory: "1g"
    serviceAccount: spark
    initContainers:
      - name: git-sync
        # ... (xem phần Git-Sync bên dưới)
    envFrom:
      - secretRef:
          name: spark-k8s-aws-credentials
      - configMapRef:
          name: spark-k8s-config

  executor:
    cores: 1
    memory: "1g"
    instances: 2
    envFrom:
      - secretRef:
          name: spark-k8s-aws-credentials
      - configMapRef:
          name: spark-k8s-config

  volumes:
    - name: dbt-code
      emptyDir: {}

  restartPolicy:
    type: OnFailure
    onFailureRetries: 2
    onFailureRetryInterval: 10
```

### Application Code Patterns

Có 2 cách tham chiếu code trong SparkApplication:

| Pattern | mainApplicationFile | Mô tả |
|---|---|---|
| **Baked into image** | `local:///app/oracle_to_iceberg.py` | Code nằm sẵn trong Docker image tại `/app/` |
| **Git-sync** | `local:///opt/spark/work-dir/dbt-project/dbt_runner.py` | Code được pull runtime qua git-sync sidecar |

---

## Git-Sync Sidecar

Git-sync là **init container** chạy trước Driver container, clone code từ Git repo vào shared volume.

### Cách Hoạt Động

```
┌─────────────┐    ┌──────────────┐    ┌──────────────────┐
│ Git Repo    │───▶│ git-sync     │───▶│ Shared Volume    │
│ (dbt-project│    │ (init cont.) │    │ /opt/spark/      │
│  branch:dev)│    │              │    │  work-dir/       │
└─────────────┘    └──────────────┘    │  └─dbt-project/  │
                                       │    ├─dbt_runner.py│
                                       │    ├─models/      │
                                       │    └─profiles.yml │
                                       └──────────────────┘
                                              │
                                       ┌──────┴──────┐
                                       │ Driver Pod  │
                                       │ + Executors │
                                       └─────────────┘
```

### Cấu Hình Git-Sync trong SparkApplication

```yaml
driver:
  initContainers:
    - name: git-sync
      image: registry.k8s.io/git-sync/git-sync:v4.1.0
      imagePullPolicy: IfNotPresent
      securityContext:
        runAsUser: 1001       # Cùng UID với Spark user
        runAsGroup: 1001
      envFrom:
        - configMapRef:
            name: git-sync-config       # GIT_SYNC_REPO, BRANCH, ROOT, DEST, ...
            optional: false
        - secretRef:
            name: git-credentials       # GIT_USERNAME, GIT_PASSWORD (nếu private)
            optional: true
      volumeMounts:
        - name: dbt-code
          mountPath: /opt/spark/work-dir
      resources:
        requests:
          memory: "64Mi"
          cpu: "50m"
        limits:
          memory: "128Mi"
          cpu: "200m"

  volumeMounts:
    - name: dbt-code
      mountPath: /opt/spark/work-dir

executor:
  volumeMounts:
    - name: dbt-code
      mountPath: /opt/spark/work-dir

volumes:
  - name: dbt-code
    emptyDir: {}
```

> **Quan trọng**: Volume `dbt-code` phải được mount trên **cả Driver và Executor** nếu executors cần truy cập code/config.

### Biến Môi Trường cho dbt Runner

```yaml
driver:
  env:
    - name: DBT_PROFILES_DIR
      value: "/opt/spark/work-dir/dbt-project"
    - name: DBT_PROJECT_DIR
      value: "/opt/spark/work-dir/dbt-project"
    - name: SCHEMA_NAME
      value: "integration"
```

---

## Deploy & Quản Lý Job

### Submit Job

```bash
kubectl apply -f k8s/jobs/spark-dbt-job.yaml
```

### Theo Dõi Trạng Thái

```bash
# Liệt kê tất cả SparkApplications
kubectl get sparkapplications -n spark-jobs

# Theo dõi real-time
kubectl get sparkapplications -n spark-jobs -w

# Chi tiết job
kubectl describe sparkapplication <job-name> -n spark-jobs
```

**Các trạng thái SparkApplication:**

| Status | Mô tả |
|---|---|
| `SUBMITTED` | Manifest đã được submit cho Operator |
| `RUNNING` | Driver + Executors đang chạy |
| `COMPLETED` | Job hoàn thành thành công |
| `FAILED` | Job thất bại |
| `PENDING_RERUN` | Đang chờ restart (nếu có restart policy) |

### Xem Logs

```bash
# Driver logs
kubectl logs -f <driver-pod-name> -n spark-jobs

# Tìm driver pod tự động
kubectl logs -f $(kubectl get pods -n spark-jobs -l spark-role=driver -o name | head -1) -n spark-jobs

# Logs theo label
kubectl logs -l sparkoperator.k8s.io/app-name=<job-name> -n spark-jobs --tail=100
```

### Cập Nhật / Restart Job

```bash
# Xóa job cũ rồi apply lại
kubectl delete sparkapplication <job-name> -n spark-jobs
kubectl apply -f k8s/jobs/<job-manifest>.yaml
```

### Xóa Job

```bash
kubectl delete sparkapplication <job-name> -n spark-jobs
```

---

## Monitoring

### Spark UI

Truy cập Spark UI qua port-forward tới Driver pod:

```bash
# Tìm driver pod
kubectl get pods -n spark-jobs -l spark-role=driver

# Port-forward
kubectl port-forward <driver-pod> 4040:4040 -n spark-jobs

# Mở browser
open http://localhost:4040
```

### Job Events

```bash
# Xem events
kubectl get events -n spark-jobs --field-selector involvedObject.name=<job-name>

# Watch events real-time
kubectl get events -n spark-jobs -w
```

### Prometheus Metrics (Nếu đã cấu hình)

```yaml
sparkConf:
  "spark.ui.prometheus.enabled": "true"
  "spark.metrics.conf.*.sink.prometheusServlet.class": "org.apache.spark.metrics.sink.PrometheusServlet"
  "spark.metrics.conf.*.sink.prometheusServlet.path": "/metrics/prometheus"
```

---

## Tích Hợp Airflow

Airflow trigger SparkApplication qua `SparkKubernetesOperator`:

```python
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import SparkKubernetesOperator
from airflow.providers.cncf.kubernetes.sensors.spark_kubernetes import SparkKubernetesSensor

# Submit SparkApplication
submit_spark = SparkKubernetesOperator(
    task_id="submit_spark_job",
    namespace="spark-jobs",
    application_file="k8s/jobs/spark-dbt-job.yaml",
    kubernetes_conn_id="kubernetes_default",
)

# Chờ job hoàn thành
monitor_spark = SparkKubernetesSensor(
    task_id="monitor_spark_job",
    namespace="spark-jobs",
    application_name="{{ task_instance.xcom_pull(task_ids='submit_spark_job')['metadata']['name'] }}",
    kubernetes_conn_id="kubernetes_default",
    poke_interval=30,
    timeout=3600,
)

submit_spark >> monitor_spark
```
