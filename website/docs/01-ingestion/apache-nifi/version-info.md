# Apache NiFi - Thông Tin Version

## Version Hiện Tại

| Thông tin | Giá trị |
|---|---|
| **NiFi Version** | 2.7.2 |
| **NiFi Registry** | 2.7.2 |
| **Java Runtime** | JDK 21+ |
| **Ngày triển khai** | 2024 (Hanas Platform) |
| **Môi trường** | Kubernetes |

---

## NiFi 2.x — Điểm Nổi Bật

NiFi 2.x là bản nâng cấp lớn so với 1.x, mang đến nhiều cải tiến quan trọng cho Hanas Platform:

| # | Tính Năng | Mô Tả | Ảnh Hưởng Hanas |
|---|-----------|--------|-----------------|
| 1 | **Java 21** | Yêu cầu JDK 21+, hỗ trợ Virtual Threads | Performance tốt hơn |
| 2 | **Python API** | Viết custom processors bằng Python (Beta) | Tích hợp AI/ML pipelines |
| 3 | **Angular 18 UI** | Giao diện mới, responsive, dark mode | UX cải thiện đáng kể |
| 4 | **K8s Native** | ConfigMaps, Kubernetes leases cho leader election | Không cần ZooKeeper |
| 5 | **Kafka 3 Support** | Processors mới cho Kafka 3.x | Tương thích Hanas Kafka cluster |
| 6 | **Stateless Flows** | Chạy flow không lưu state | FaaS, edge use cases |
| 7 | **PEM Certificates** | Hỗ trợ ECDSA, Ed25519, RSA | Security hiện đại |
| 8 | **OIDC Client Credentials** | SSO cho UI và programmatic access | Tích hợp Keycloak |
| 9 | **Git Integration** | Tighter flow versioning với Git | CI/CD improvements |
| 10 | **New S3 Processors** | GetS3ObjectMetadata, CopyS3Object | Mở rộng MinIO ops |

### Breaking Changes Từ 1.x → 2.x

| Thay Đổi | Chi Tiết | Hành Động |
|----------|----------|-----------|
| Kafka processors rebuilt | Kafka 2.x processors bị loại bỏ | Dùng Kafka 3.x processors mới |
| HBase/Hive 3 loại bỏ | End-of-life components | Không ảnh hưởng (Hanas dùng Dremio) |
| Java 21 bắt buộc | Không hỗ trợ Java 8/11/17 | Đảm bảo JDK 21+ trên tất cả nodes |
| UI rebuilt | Angular 18, API endpoints thay đổi | Cập nhật automation scripts |

---

## Lịch Sử Thay Đổi

| Version | Ngày | Thay Đổi Chính |
|---------|------|----------------|
| **2.7.2** | 2025 | Version hiện tại trên Hanas Platform. Bug fixes, security patches |
| **2.0.0** | 2024 | Major release — Java 21, Python API, Angular 18 UI, K8s native |
| **1.26.0** | 2024 | Bản 1.x cuối cùng. ParquetRecordSetWriter (dùng trong template cũ) |
| **1.23.x** | 2023 | Stable 1.x series |

---

## Tương Thích

### Ma Trận Tương Thích Với Hanas Platform

| Service | Version | Tương Thích NiFi 2.7.2 | Ghi Chú |
|---------|---------|------------------------|---------|
| **Apache Kafka** | 3.8.0 | Có | ConsumeKafka/PublishKafka (Kafka 3.x processors) |
| **MinIO** | RELEASE.2024+ | Có | PutS3Object, GetS3Object (nifi-aws-nar) |
| **Dremio** | 24+ | Có | ExecuteSQLRecord via JDBC (dremio-jdbc-driver) |
| **Apache Iceberg** | 1.5+ | Có | Gián tiếp qua Dremio COPY INTO |
| **Hive Metastore** | 3.x | Có | Gián tiếp qua Dremio catalog |
| **PostgreSQL** | 14+ | Có | DBCPConnectionPool (postgresql-42.7.jar) |
| **Apache Airflow** | 2.9+ | Có | Có thể trigger NiFi qua REST API |
| **DataHub** | 0.13+ | Có | NiFi lineage ingestion |
| **NiFi Registry** | 2.7.2 | Có | Cùng version với NiFi |
| **Kubernetes** | 1.25+ | Có | Native leader election, ConfigMaps |
| **Java** | JDK 21+ | Có (bắt buộc) | Virtual Threads support |

### NAR Bundles Sử Dụng

| Bundle | Version | Processors |
|--------|---------|------------|
| **nifi-standard-nar** | 2.7.2 | GetFTP, ExecuteSQLRecord, EvaluateJsonPath, CompressContent, LogAttribute |
| **nifi-aws-nar** | 2.7.2 | PutS3Object, GetS3Object, AWSCredentialsProvider |
| **nifi-update-attribute-nar** | 2.7.2 | UpdateAttribute |
| **nifi-kafka-nar** | 2.7.2 | ConsumeKafka, PublishKafka |
| **nifi-parquet-nar** | 1.26.0 | ParquetRecordSetWriter (legacy compatibility) |
