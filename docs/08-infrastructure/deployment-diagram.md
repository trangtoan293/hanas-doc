# Sơ Đồ Triển Khai

## Tổng Quan

<-r TODO: Thêm hình sơ đồ triển khai thực tế -->

## Mô Tả

Các thành phần được container hóa và triển khai trên cụm:
- **Master Nodes**: Control plane, scheduling
- **Worker Nodes**: Workload (NiFi, Kafka, Spark, Airflow, Dremio, DataHub, OpenObserve)

## Luồng Dữ Liệu

1. Dữ liệu nguồn → NiFi (batch) / Kafka (streaming)
2. Landing zone trên MinIO
3. Airflow + Spark + dbt → Raw Vault / Business Vault
4. Information Mart → Dremio → BI/Ứng dụng

## Danh Mục Thành Phần

| Thành phần | Mô tả |
|---|---|
| Kubernetes | Container orchestration |
| MinIO | Object Storage (2 site: DC + DR) |
| Velero | K8s backup |
| Rancher | K8s management UI |
