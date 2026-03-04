# Apache Airflow

## Tổng Quan

Apache Airflow là nền tảng điều phối (orchestration) trung tâm của Hanas Data Platform. Airflow quản lý toàn bộ lifecycle của data pipeline — từ việc trigger Spark jobs trên Kubernetes, chạy dbt transformations, đến publishing metadata lên DataHub.

### Kiến Trúc Tích Hợp

```mermaid
flowchart TB
    subgraph AirflowLayer["Airflow Orchestration"]
        AF[Airflow Scheduler]
    end
    
    subgraph ProcessingLayer["Processing Layer"]
        SPK[Spark on Kubernetes]
        DBT[dbt Project]
    end
    
    subgraph StorageLayer["Storage Layer"]
        ICE[Iceberg Tables]
        MIN[(MinIO Warehouse)]
        HMS[Hive Metastore]
    end
    
    subgraph Notification["Notifications"]
        SLACK[Slack / SMTP ]
    end
    
    subgraph Governance["Governance"]
        DH[DataHub]
    end
    
    AF -->|SparkKubernetesOperator<br/>K8s YAML| SPK
    AF -->|Callbacks| SLACK
    
    SPK -->|git-sync| DBT
    SPK -->|ktl_dbt| ICE
    
    DBT -->|SQL Transform| ICE
    
    ICE -->|S3FileIO| MIN
    ICE -->|Metadata| HMS
    
    HMS -->|Publish| DH
    
    style AirflowLayer fill:#fff3e0,stroke:#ef6c00
    style ProcessingLayer fill:#e3f2fd,stroke:#1976d2
    style StorageLayer fill:#e8f5e9,stroke:#388e3c
    style Notification fill:#fce4ec,stroke:#c2185b
    style Governance fill:#f3e5f5,stroke:#7b1fa2
```

## Vai Trò Trong Platform

- **Điều phối pipeline ETL/ELT** end-to-end qua `SparkKubernetesOperator`
- **Quản lý dbt transformations** trên Spark (Data Vault, Data Mart, MDM)
- **Publishing metadata** tự động lên DataHub (lineage, schema, data quality)
- **Email notifications** qua SMTP khi DAG hoàn thành
- **Alerting real-time** qua Slack/Teams khi task fail, retry, hoặc SLA breach

## Kiến Trúc Components

| Component | Mô tả |
|---|---|
| **Scheduler** | Lập lịch và trigger DAG runs |
| **Webserver** | UI theo dõi DAGs, task logs, parameters |
| **Kubernetes Executor** | Chạy tasks như Spark pods trên K8s |
| **Metadata DB** | PostgreSQL lưu trạng thái DAG/task |
| **Spark Operator** | Submit SparkApplication CRDs lên K8s cluster |


## Tài Liệu

- [Cài đặt & Triển khai](installation.md)
- [Cấu hình](configuration.md)
- [Hướng dẫn sử dụng](user-guide.md)
- [Best Practices](best-practices.md)
- [Thông tin Version](version-info.md)
