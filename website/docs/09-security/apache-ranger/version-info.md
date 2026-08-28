# Apache Ranger — Thông Tin Version

## 1. Phiên Bản Hiện Tại

| Thông tin | Chi tiết |
|-----------|---------|
| **Phiên bản sử dụng** | Apache Ranger 2.5.0 |
| **Ngày phát hành** | Tháng 8, 2024 |
| **License** | Apache License 2.0 |
| **Source Code** | [github.com/apache/ranger](https://github.com/apache/ranger) |
| **Official Site** | [ranger.apache.org](https://ranger.apache.org/) |
| **JIRA** | [issues.apache.org/jira/projects/RANGER](https://issues.apache.org/jira/projects/RANGER) |

---

## 2. Tính Năng Nổi Bật — Ranger 2.5.0

| # | Tính năng | Mô tả |
|---|-----------|-------|
| 1 | **Policy Item Validity Period** | Hỗ trợ thiết lập thời hạn hiệu lực cho từng policy item |
| 2 | **Import/Export Roles API** | REST API mới cho import/export Ranger Admin roles |
| 3 | **KMS Health Metrics** | Ranger KMS cung cấp health metrics cho monitoring |
| 4 | **Force Delete Users/Groups** | API mới cho phép force-delete users và groups |
| 5 | **x_auth_sess Retention** | Control retention period của session table data |
| 6 | **File Sync Source in Docker** | Hỗ trợ File Sync Source cho Usersync trong Docker environment |
| 7 | **Multi Resource-Sets UI** | Policy UI hỗ trợ multiple resource-sets |
| 8 | **Row Draggable Policy Items** | Cải thiện UX — kéo thả thứ tự policy items |
| 9 | **Library Upgrades** | Nâng cấp httpclient, json-smart, Netty |

---

## 3. Lịch Sử Phiên Bản

| Version | Release Date | Highlights |
|---------|-------------|------------|
| **2.5.0** | 08/2024 | Policy validity period, Roles import/export, KMS metrics |
| **2.4.0** | 03/2023 | Admin header validation, MySQL charset fix, API metrics |
| **2.3.0** | 06/2022 | GDS (Governed Data Sharing), Dataset/Project policies |
| **2.2.0** | 01/2022 | Role-based policies, plugin policy delta download |
| **2.1.0** | 06/2021 | Schema Registry plugin, improved zone support |
| **2.0.0** | 07/2020 | Major re-architecture, new REST API v2, improved audit |
| **1.2.0** | 10/2019 | Tag-based policies, Dremio integration support |

---

## 4. Ma Trận Tương Thích — Hanas Platform

| Service | Phiên bản trong Platform | Ranger Plugin | Tương thích | Ghi chú |
|---------|------------------------|---------------|-------------|---------|
| **Apache Kafka** | Confluent 7.x / Apache 3.x | `ranger-kafka-plugin` 2.5.0 | Có | Thay thế Kafka ACLs |
| **Apache NiFi** | 1.x / 2.x | `ranger-nifi-plugin` 2.5.0 | Có | Thay thế file-based authorizer |
| **Apache Spark** | 3.4+ | `ranger-spark-plugin` 2.5.0 | Có | SparkSQL authorization |
| **Hive Metastore** | 3.x (standalone) | `ranger-hive-plugin` 2.5.0 | Có | Core catalog authorization |
| **Dremio** | 24.x+ | Ranger-based auth (built-in) | Có | Ranger 1.2+ protocol |
| **MinIO** | Theo baseline triển khai | `ranger-s3-plugin` | Hạn chế | Community plugin, cần custom build |
| **PostgreSQL** | 15+ | N/A | Có | Backend database cho Ranger Admin |
| **Elasticsearch** | 7.x / 8.x | N/A | Có | Audit log backend |
| **OpenSearch** | 2.x | N/A | Có | Thay thế Elasticsearch |
| **Kubernetes** | 1.24+ | N/A | Có | Container orchestration |

---

## 5. Yêu Cầu Java

| Ranger Version | Java Minimum | Java Khuyến nghị | Ghi chú |
|---------------|-------------|-------------------|---------|
| 2.5.0 | JDK 11 | JDK 17 | OpenJDK hoặc Oracle JDK |
| 2.4.0 | JDK 8 | JDK 11 | |
| 2.3.0 | JDK 8 | JDK 11 | |
| 2.0.x | JDK 8 | JDK 8 | End of support |

---

## 6. Upgrade Path

### 6.1 Từ Ranger 2.4.0 → 2.5.0

| Bước | Hành động | Chi tiết |
|------|-----------|---------|
| 1 | **Backup** | Export tất cả policies và database dump |
| 2 | **Stop Usersync** | Scale down usersync deployment |
| 3 | **Upgrade Admin** | Update container image → `apache/ranger-admin:2.5.0` |
| 4 | **Run DB Migration** | Tự động chạy khi Admin khởi động với version mới |
| 5 | **Verify Admin** | Kiểm tra UI, API health |
| 6 | **Upgrade Plugins** | Update plugin jars trong từng service container |
| 7 | **Start Usersync** | Scale up usersync deployment |
| 8 | **Verify Policies** | Kiểm tra policy enforcement trên tất cả services |

### 6.2 Downtime Expectations

| Thành phần | Downtime |
|------------|----------|
| **Ranger Admin** | 5-10 phút (during restart + DB migration) |
| **Policy Enforcement** | **Zero downtime** — plugins sử dụng local cache |
| **Audit** | Audit events buffer tại plugin, gửi lại sau khi Admin up |

> **Quan trọng**: Plugin cache đảm bảo policy enforcement tiếp tục hoạt động ngay cả khi Ranger Admin tạm thời unavailable. Đây là ưu điểm quan trọng của kiến trúc pull-based.

---

## 7. Tham Khảo

| Nguồn | URL |
|-------|-----|
| **Apache Ranger Official** | [ranger.apache.org](https://ranger.apache.org/) |
| **GitHub Repository** | [github.com/apache/ranger](https://github.com/apache/ranger) |
| **Release Notes 2.5.0** | [cwiki.apache.org — Ranger 2.5.0 Release](https://cwiki.apache.org/confluence/display/RANGER/Apache+Ranger+2.5.0+-+Release+Notes) |
| **REST API Documentation** | [ranger.apache.org/apidocs](https://ranger.apache.org/apidocs/index.html) |
| **Quick Start Guide** | [ranger.apache.org/quick_start_guide](https://ranger.apache.org/quick_start_guide.html) |
| **Dremio Ranger Integration** | [docs.dremio.com — Ranger Authorization](https://docs.dremio.com/current/admin/auth/ranger) |
| **Helm Chart (ArtifactHub)** | [artifacthub.io — ranger](https://artifacthub.io/packages/search?ts_query_web=ranger) |
