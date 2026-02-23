# Velero - Sao Lưu K8s

## Tổng Quan

Velero thực hiện sao lưu toàn diện cụm K8s ở cấp độ Cluster.

## Backup Resources

- Cấu hình services: Rancher, Airflow, Hive, Spark
- Persistent Volumes (Kopia integration):
  - PostgreSQL/MySQL: Hive Metastore, Airflow DB
  - Dremio Metadata: nguồn dữ liệu, workspace

## Lưu Trữ

Velero đẩy backup vào MinIO → tự động đồng bộ qua Site Replication.

## Cấu Hình

<-r TODO: Velero schedule, backup policy -->

## Lịch Backup

<-r TODO: Tần suất, retention policy -->
