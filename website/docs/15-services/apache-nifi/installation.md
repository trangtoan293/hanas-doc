# Apache NiFi - Cài Đặt & Triển Khai

## Yêu Cầu Hệ Thống

### Phần Cứng Tối Thiểu (Per Node)

| Tài Nguyên | Development | Production |
|------------|-------------|------------|
| **CPU** | 2 cores | 8+ cores |
| **RAM** | 4 GB | 16–32 GB |
| **Disk** | 50 GB SSD | 500 GB+ SSD/NVMe |
| **Network** | 1 Gbps | 10 Gbps |

> **Lưu ý**: NiFi sử dụng nhiều I/O cho Content Repository và Provenance Repository. Khuyến nghị tách riêng disk cho mỗi repository trong production. JVM Heap nên đặt 4–8 GB, phần RAM còn lại dành cho OS cache.

### Phần Mềm

| Phần mềm | Version |
|-----------|---------|
| **Java** | JDK 21+ (NiFi 2.x yêu cầu) |
| **Kubernetes** | 1.25+ |
| **Helm** | 3.x |
| **Docker** | 24+ (cho dev/test) |
| **NiFi** | 2.7.2 (Hanas Platform) |

---

## Cài Đặt Trên Kubernetes

### Bước 1: Tạo Namespace và Persistent Resources

```bash
# Tạo namespace
kubectl create namespace nifi
```

### Bước 2: Tạo Persistent Volumes

```yaml
# nifi-pv.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nifi-content-repo
  namespace: nifi
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: standard
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nifi-flowfile-repo
  namespace: nifi
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
  storageClassName: standard
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nifi-provenance-repo
  namespace: nifi
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: standard
```

```bash
kubectl apply -f nifi-pv.yaml
```

### Bước 3: Triển Khai NiFi StatefulSet

```yaml
# nifi-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nifi
  namespace: nifi
spec:
  serviceName: nifi
  replicas: 3
  selector:
    matchLabels:
      app: nifi
  template:
    metadata:
      labels:
        app: nifi
    spec:
      containers:
        - name: nifi
          image: apache/nifi:2.7.2
          ports:
            - containerPort: 8443
              name: https
            - containerPort: 11443
              name: cluster
          env:
            - name: NIFI_WEB_HTTPS_PORT
              value: "8443"
            - name: NIFI_CLUSTER_IS_NODE
              value: "true"
            - name: NIFI_CLUSTER_NODE_PROTOCOL_PORT
              value: "11443"
            - name: NIFI_ELECTION_MAX_WAIT
              value: "1 min"
            - name: NIFI_SENSITIVE_PROPS_KEY
              valueFrom:
                secretKeyRef:
                  name: nifi-secrets
                  key: sensitive-props-key
            - name: SINGLE_USER_CREDENTIALS_USERNAME
              valueFrom:
                secretKeyRef:
                  name: nifi-secrets
                  key: admin-username
            - name: SINGLE_USER_CREDENTIALS_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: nifi-secrets
                  key: admin-password
          resources:
            requests:
              cpu: "2"
              memory: "8Gi"
            limits:
              cpu: "8"
              memory: "16Gi"
          volumeMounts:
            - name: content-repo
              mountPath: /opt/nifi/nifi-current/content_repository
            - name: flowfile-repo
              mountPath: /opt/nifi/nifi-current/flowfile_repository
            - name: provenance-repo
              mountPath: /opt/nifi/nifi-current/provenance_repository
            - name: conf
              mountPath: /opt/nifi/nifi-current/conf
          livenessProbe:
            httpGet:
              path: /nifi-api/system-diagnostics
              port: 8443
              scheme: HTTPS
            initialDelaySeconds: 120
            periodSeconds: 30
          readinessProbe:
            httpGet:
              path: /nifi-api/system-diagnostics
              port: 8443
              scheme: HTTPS
            initialDelaySeconds: 60
            periodSeconds: 10
  volumeClaimTemplates:
    - metadata:
        name: content-repo
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 100Gi
    - metadata:
        name: flowfile-repo
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 50Gi
    - metadata:
        name: provenance-repo
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 100Gi
    - metadata:
        name: conf
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
```

### Bước 4: Tạo Service và Ingress

```yaml
# nifi-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nifi
  namespace: nifi
spec:
  type: ClusterIP
  selector:
    app: nifi
  ports:
    - name: https
      port: 8443
      targetPort: 8443
    - name: cluster
      port: 11443
      targetPort: 11443
---
apiVersion: v1
kind: Service
metadata:
  name: nifi-headless
  namespace: nifi
spec:
  type: ClusterIP
  clusterIP: None
  selector:
    app: nifi
  ports:
    - name: https
      port: 8443
    - name: cluster
      port: 11443
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nifi
  namespace: nifi
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
spec:
  rules:
    - host: nifi.hanas.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nifi
                port:
                  number: 8443
  tls:
    - hosts:
        - nifi.hanas.local
```

```bash
kubectl apply -f nifi-statefulset.yaml
kubectl apply -f nifi-service.yaml
```

### Bước 5: Triển Khai NiFi Registry (Optional)

```yaml
# nifi-registry.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nifi-registry
  namespace: nifi
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nifi-registry
  template:
    metadata:
      labels:
        app: nifi-registry
    spec:
      containers:
        - name: nifi-registry
          image: apache/nifi-registry:2.7.2
          ports:
            - containerPort: 18080
          volumeMounts:
            - name: data
              mountPath: /opt/nifi-registry/nifi-registry-current/database
            - name: flow-storage
              mountPath: /opt/nifi-registry/nifi-registry-current/flow_storage
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: nifi-registry-data
        - name: flow-storage
          persistentVolumeClaim:
            claimName: nifi-registry-flows
---
apiVersion: v1
kind: Service
metadata:
  name: nifi-registry
  namespace: nifi
spec:
  selector:
    app: nifi-registry
  ports:
    - port: 18080
      targetPort: 18080
  type: ClusterIP
```

```bash
kubectl apply -f nifi-registry.yaml
```

---

## Cài Đặt Docker Compose (Dev/Test)

```yaml
# docker-compose-nifi.yml
version: "3.8"
services:
  nifi:
    image: apache/nifi:2.7.2
    hostname: nifi
    ports:
      - "8443:8443"
    environment:
      NIFI_WEB_HTTPS_PORT: "8443"
      SINGLE_USER_CREDENTIALS_USERNAME: admin
      SINGLE_USER_CREDENTIALS_PASSWORD: "Hanas@NiFi2024"
      NIFI_SENSITIVE_PROPS_KEY: "hanas-nifi-secret-key-12345"
      NIFI_JVM_HEAP_INIT: "2g"
      NIFI_JVM_HEAP_MAX: "4g"
    volumes:
      - nifi-conf:/opt/nifi/nifi-current/conf
      - nifi-content:/opt/nifi/nifi-current/content_repository
      - nifi-flowfile:/opt/nifi/nifi-current/flowfile_repository
      - nifi-provenance:/opt/nifi/nifi-current/provenance_repository
      - nifi-state:/opt/nifi/nifi-current/state
      - nifi-logs:/opt/nifi/nifi-current/logs
      # Mount thư mục chứa JDBC drivers
      - ./drivers:/opt/nifi/nifi-current/drivers
    restart: unless-stopped

  nifi-registry:
    image: apache/nifi-registry:2.7.2
    hostname: nifi-registry
    ports:
      - "18080:18080"
    volumes:
      - nifi-registry-data:/opt/nifi-registry/nifi-registry-current/database
      - nifi-registry-flows:/opt/nifi-registry/nifi-registry-current/flow_storage
    restart: unless-stopped

volumes:
  nifi-conf:
  nifi-content:
  nifi-flowfile:
  nifi-provenance:
  nifi-state:
  nifi-logs:
  nifi-registry-data:
  nifi-registry-flows:
```

```bash
# Khởi chạy
docker compose -f docker-compose-nifi.yml up -d

# Kiểm tra
docker compose -f docker-compose-nifi.yml ps

# Xem logs
docker compose -f docker-compose-nifi.yml logs -f nifi
```

> **Truy cập**: https://localhost:8443/nifi — Login: `admin` / `Hanas@NiFi2024`

---

## Kiểm Tra Sau Cài Đặt

### 1. Kiểm Tra NiFi API

```bash
# Health check (Single User mode — chấp nhận self-signed cert)
curl -k -u admin:Hanas@NiFi2024 \
  https://localhost:8443/nifi-api/system-diagnostics

# Kiểm tra cluster status
curl -k -u admin:Hanas@NiFi2024 \
  https://localhost:8443/nifi-api/controller/cluster
```

### 2. Kiểm Tra Web UI

```bash
# Mở browser
open https://localhost:8443/nifi

# Hoặc trên K8s
open https://nifi.hanas.local/nifi
```

Sau khi login, xác nhận:
- Web UI hiển thị canvas trống (ready to design)
- Menu hamburger ở góc trái hoạt động
- Processor palette (thanh công cụ trên cùng) hiển thị đầy đủ

### 3. Kiểm Tra NiFi Registry

```bash
# Kiểm tra API
curl http://localhost:18080/nifi-registry-api/buckets

# Mở browser
open http://localhost:18080/nifi-registry
```

### 4. Kiểm Tra Kết Nối Kafka

```bash
# Trên NiFi UI:
# 1. Kéo processor ConsumeKafka vào canvas
# 2. Cấu hình Kafka Brokers: hanas-kafka-kafka-bootstrap:9092
# 3. Đặt Topic: test-ingestion
# 4. Verify connection thành công (không có bulletin lỗi)
```

### 5. Kiểm Tra Kết Nối MinIO/S3

```bash
# Trên NiFi UI:
# 1. Tạo Controller Service: AWSCredentialsProviderControllerService
# 2. Cấu hình Access Key / Secret Key cho MinIO
# 3. Kéo processor PutS3Object, cấu hình:
#    - Endpoint Override URL: http://<minio-host>:9000
#    - Bucket: data
# 4. Verify connection thành công
```

### 6. Import Template Test

```bash
# Upload file get_file_from_ftp_push_s3.json qua NiFi UI
# Menu → Upload Flow Definition → Chọn file JSON
# Verify flow hiển thị: GetFTP → PutS3Object → LogAttribute
```
