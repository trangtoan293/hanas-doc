# Kiến Trúc Tổng Thể Hanas Data Platform

## Sơ Đồ Kiến Trúc Tổng Thể

```mermaid
flowchart TB
    subgraph Sources["🌐 Data Sources"]
        DB[(Databases)]
        Files[Files/APIs]
        CDC[CDC/Events]
    end
    
    subgraph L1["📥 Lớp 1: Thu Thập (Ingestion)"]
        NiFi[Apache NiFi
        <br/>Batch ETL]
        Kafka[Apache Kafka
        <br/>Streaming]
    end
    
    subgraph L2["💾 Lớp 2: Lưu Trữ (Storage)"]
        MinIO[(MinIO
        <br/>S3 Object Storage)]
        Iceberg[Apache Iceberg
        <br/>Open Table Format]
    end
    
    subgraph L3["⚡ Lớp 3: Xử Lý (Processing)"]
        Airflow[Apache Airflow
        <br/>Orchestration]
        Spark[Apache Spark
        <br/>Distributed Compute]
    end
    
    subgraph L4["🏗️ Lớp 4: Mô Hình (Data Model)"]
        dbt[dbt
        <br/>SQL Transform]
        DV[Data Vault 2.0
        <br/>Hub/Link/Sat]
    end
    
    subgraph L5["🔍 Lớp 5: Quản Trị (Governance)"]
        DataHub[DataHub
        <br/>Metadata & Lineage]
    end
    
    subgraph L6["🔗 Lớp 6: Liên Kết (Federation)"]
        Dremio[Dremio
        <br/>Query Engine]
    end
    
    subgraph L7["📊 Lớp 7: Tiêu Thụ (Consumption)"]
        BI[BI Tools
        <br/>Superset/Tableau]
        Apps[Applications]
    end
    
    subgraph Security["🔒 Security Layer"]
        Ranger[Apache Ranger
        <br/>Authorization]
        Vault[HashiCorp Vault
        <br/>Secrets]
    end
    
    subgraph Infra["☸️ Infrastructure"]
        K8s[Kubernetes]
        Velero[Velero Backup]
        OO[OpenObserve
        <br/>Monitoring]
    end
    
    Sources --> NiFi
    Sources --> Kafka
    
    NiFi --> MinIO
    Kafka --> MinIO
    
    MinIO --> Iceberg
    
    Airflow --> Spark
    Spark --> Iceberg
    
    Spark --> dbt
    dbt --> DV
    DV --> Iceberg
    
    Iceberg --> DataHub
    
    Iceberg --> Dremio
    Dremio --> BI
    Dremio --> Apps
    
    K8s -.-> NiFi
    K8s -.-> Kafka
    K8s -.-> MinIO
    K8s -.-> Airflow
    K8s -.-> Spark
    K8s -.-> Dremio
    K8s -.-> DataHub
    
    style Sources fill:#e3f2fd,stroke:#1976d2
    style L1 fill:#fff3e0,stroke:#ef6c00
    style L2 fill:#e8f5e9,stroke:#388e3c
    style L3 fill:#fce4ec,stroke:#c2185b
    style L4 fill:#f3e5f5,stroke:#7b1fa2
    style L5 fill:#fff8e1,stroke:#ff6f00
    style L6 fill:#e0f7fa,stroke:#00838f
    style L7 fill:#e8eaf6,stroke:#3f51b5
    style Security fill:#ffebee,stroke:#c62828
    style Infra fill:#f5f5f5,stroke:#616161
```

## Mô Tả Các Lớp

### 1. Lớp Thu Thập Dữ Liệu (Data Ingestion)

Kéo dữ liệu thô từ các nguồn dữ liệu vào Data Lakehouse thông qua hai cơ chế:
- **Batch** (định kỳ): Apache NiFi xử lý ETL visual, kết nối đa nguồn
- **Streaming** (liên tục): Apache Kafka truyền phát dữ liệu real-time, độ trễ thấp

### 2. Lớp Lưu Trữ Dữ Liệu (Data Storage)

Dữ liệu sau thu thập được đưa vào vùng Landing trên Data Lake:
- **MinIO**: Object Storage phân tán, S3-compatible, lưu trữ tập trung
- **Apache Iceberg**: Open Table Format, ACID transactions, time travel, schema evolution

### 3. Lớp Xử Lý Dữ Liệu (Data Processing)

Điều phối và thực thi toàn bộ pipeline xử lý dữ liệu:
- **Apache Airflow**: Orchestration theo mô hình DAG, lập lịch, kiểm soát lỗi
- **Apache Spark**: Compute engine phân tán, xử lý batch và streaming quy mô lớn

### 4. Lớp Mô Hình Dữ Liệu (Data Model)

Tổ chức dữ liệu theo phương pháp Data Vault 2.0:
- **Raw Vault**: Hub, Link, Satellite — lưu trữ dữ liệu gốc đã chuẩn hóa
- **Business Vault**: Logic nghiệp vụ nâng cao (PIT, Bridge, Business Satellite)
- **Information Mart**: Star Schema, Wide Table phục vụ BI và báo cáo
- **dbt**: Công cụ transformation SQL-based, quản lý mô hình dữ liệu

### 5. Lớp Quản Trị Dữ Liệu (Data Governance)

- **DataHub**: Metadata management, data catalog, data lineage, business glossary, data quality tracking

### 6. Lớp Liên Kết Dữ Liệu (Data Federation)

- **Dremio**: Query engine thống nhất, semantic layer, virtual datasets, acceleration layer, BI connectivity (JDBC/ODBC/REST)

### 7. Lớp Quản Trị Hệ Thống (System Management)

- **OpenObserve**: Thu thập log, metrics, traces; dashboard giám sát; cảnh báo sự cố

## Các Thành Phần Bổ Trợ

| Thành phần | Vai trò |
|---|---|
| **Kubernetes** | Container orchestration, triển khai microservices |
| **Apache Ranger** | Authorization, phân quyền truy cập dữ liệu |
| **HashiCorp Vault** | Quản lý secrets, credentials |
| **Velero** | Backup & recovery cụm K8s |
| **MinIO Site Replication** | Đồng bộ dữ liệu DC-DR |

## Luồng Dữ Liệu End-to-End

```mermaid
sequenceDiagram
    participant Source as Data Sources
    participant L1 as Layer 1: Ingestion
    participant L2 as Layer 2: Storage
    participant L3 as Layer 3: Processing
    participant L4 as Layer 4: Data Model
    participant L5 as Layer 5: Governance
    participant L6 as Layer 6: Federation
    participant L7 as Layer 7: Consumption
    
    Source->>L1: Raw Data
    L1->>L2: Landing Zone
    Note over L2: MinIO + Iceberg
    
    L2->>L3: Raw Data
    L3->>L4: Processed Data
    L4->>L2: Vault/Mart Tables
    
    L2->>L5: Metadata
    L5-->>L2: Lineage Tracking
    
    L2->>L6: Query
    L6->>L7: Results
```

## Nguyên Tắc Kiến Trúc

1. **Data Lakehouse hợp nhất**: Kết hợp Data Lake + Data Warehouse
2. **Open-source first**: Sử dụng công nghệ mã nguồn mở, không vendor lock-in
3. **Cloud-native**: Triển khai trên Kubernetes, container hóa
4. **Separation of concerns**: Tách biệt rõ ràng giữa các lớp
5. **Scalability**: Mở rộng theo chiều ngang (horizontal scaling)
6. **Security by design**: Bảo mật xuyên suốt từ thiết kế
