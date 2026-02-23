# Lớp Thu Thập Dữ Liệu (Data Ingestion)

## Tổng Quan

Lớp thu thập dữ liệu chịu trách nhiệm kéo dữ liệu thô từ các nguồn vào Data Lakehouse. Hệ thống hỗ trợ hai cơ chế thu thập song song:

| Cơ chế | Service | Mô tả |
|---|---|---|
| **Batch** | Apache NiFi | Thu thập định kỳ, ETL visual, kết nối đa nguồn |
| **Streaming** | Apache Kafka | Truyền phát thời gian thực, độ trễ thấp |

## Kiến Trúc

```mermaid
flowchart LR
    subgraph Sources["Data Sources"]
        DB[(Database)]
        File[File]
        API[API]
        CDC[CDC]
        Events[Events]
    end
    
    subgraph Ingestion["Lớp Thu Thập"]
        NiFi[Apache NiFi<br/>Batch ETL]
        Kafka[Apache Kafka<br/>Streaming]
    end
    
    subgraph Storage["Lớp Lưu Trữ"]
        MinIO[(Data Lake<br/>MinIO)]
    end
    
    DB --> NiFi
    File --> NiFi
    API --> NiFi
    CDC --> Kafka
    Events --> Kafka
    NiFi --> MinIO
    Kafka --> MinIO
    
    style Sources fill:#e1f5fe
    style Ingestion fill:#fff3e0
    style Storage fill:#e8f5e9
```

## Services

- [Apache NiFi](apache-nifi/README.md) — Thu thập batch, ETL visual
- [Apache Kafka](apache-kafka/README.md) — Streaming, real-time
