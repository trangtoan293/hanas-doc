# Lớp AI Service

## Tổng Quan

Lớp AI Service mở rộng kiến trúc Hanas Data Platform với khả năng **trí tuệ nhân tạo**, cho phép xây dựng và vận hành các ứng dụng AI trên nền tảng dữ liệu sẵn có. Lớp này hoạt động song song với các lớp Data Lakehouse, khai thác dữ liệu từ Lakehouse để phục vụ các use case AI trong doanh nghiệp.

| Thành phần | Vai trò |
|---|---|
| **vLLM** | Inference engine — Host LLM/Embedding/Reranker models với OpenAI-compatible API |
| **Dify** | AI Workflow Platform — Visual builder cho chatbot, RAG, agent, workflow AI |
| **Langfuse** | LLM Observability — Tracing, evaluation, prompt management cho AI workflows |

## Kiến Trúc

```mermaid
flowchart TB
    subgraph DataPlatform["Hanas Data Platform"]
        Lakehouse[(Data Lakehouse<br/>MinIO + Iceberg)]
        Dremio[Dremio SQL Engine]
        DataHub[DataHub Metadata]
    end

    subgraph AIService["AI Service Layer"]
        subgraph Inference["⚡ Inference Engine"]
            vLLM["vLLM Server<br/>OpenAI-compatible API"]
            LLM["LLM<br/>Qwen3-14B-AWQ"]
            Embed["Embedding<br/>BGE-M3"]
            Rerank["Reranker<br/>BGE-Reranker-v2-M3"]
        end

        subgraph Workflow["AI Workflow"]
            Dify["Dify Platform<br/>Visual Workflow Builder"]
            KB["Knowledge Base<br/>RAG Engine"]
            Agent["Agent Framework<br/>Tool Calling"]
            OCR["OCR Service<br/>Document Extraction"]
        end

        subgraph Observability["Observability"]
            Langfuse["Langfuse<br/>Tracing & Evaluation"]
        end
    end

    subgraph Apps["AI Applications"]
        SmartOffice["Smart Office<br/>Tracking System"]
        SmartDoc["Smart Documents<br/>Management"]
        NBO["Next Best Offer"]
        RiskDetect["Real-time Risk<br/>Detection"]
    end

    DataPlatform --> AIService
    vLLM --> Dify
    LLM --> vLLM
    Embed --> vLLM
    Rerank --> vLLM
    Dify --> Langfuse
    KB --> Dify
    Agent --> Dify
    OCR --> Dify
    Dify --> Apps

    style AIService fill:#fce4ec,stroke:#c2185b
    style Inference fill:#e8eaf6,stroke:#3f51b5
    style Workflow fill:#fff3e0,stroke:#ef6c00
    style Observability fill:#e8f5e9,stroke:#388e3c
    style DataPlatform fill:#e0f7fa,stroke:#00838f
    style Apps fill:#f3e5f5,stroke:#7b1fa2
```

### Luồng Hoạt Động

```mermaid
sequenceDiagram
    participant User as Người dùng
    participant Dify as Dify Workflow
    participant KB as Knowledge Base
    participant vLLM as vLLM Server
    participant Langfuse as Langfuse
    participant Data as Hanas Lakehouse

    User->>Dify: Gửi câu hỏi / yêu cầu
    Dify->>Langfuse: Start trace
    Dify->>KB: Tìm kiếm tài liệu liên quan (RAG)
    KB->>vLLM: Embedding query (BGE-M3)
    vLLM-->>KB: Vector embeddings
    KB-->>Dify: Relevant documents
    Dify->>vLLM: Rerank documents (BGE-Reranker)
    vLLM-->>Dify: Ranked results
    Dify->>vLLM: Generate response (Qwen3-14B)
    vLLM-->>Dify: AI response
    Dify->>Langfuse: End trace (latency, tokens, cost)
    Dify-->>User: Trả lời
```

## Use Cases

| Use Case | Mô Tả | Tính Năng AI |
|---|---|---|
| **Smart Office Tracking** | Số hóa, tự động hóa luồng hồ sơ và ý kiến chỉ đạo | Chatbot hỏi đáp, tóm tắt văn bản, tạo ticket tự động |
| **Smart Documents Management** | Tương tác thông minh với tài liệu nội bộ | OCR, truy vấn văn bản, tra cứu API Customer360 |
| **Next Best Offer** | Dự đoán sản phẩm phù hợp cho khách hàng | ML models, phân tích hành vi, cross-selling |
| **Real-time Risk Detection** | Nhận diện giao dịch rủi ro theo thời gian thực | Anomaly detection, rule engine, alerting |

## Liên Kết Với Hanas Platform

| Lớp Hanas | Tích Hợp AI Service |
|---|---|
| **L1 — Thu Thập** (NiFi, Kafka) | Streaming events → AI real-time processing |
| **L2 — Lưu Trữ** (MinIO, Iceberg) | Dữ liệu Lakehouse → Knowledge Base (RAG) |
| **L3 — Xử Lý** (Airflow, Spark) | Orchestrate AI model training/batch inference |
| **L5 — Quản Trị** (DataHub) | AI-powered metadata exploration |
| **L6 — Liên Kết** (Dremio) | SQL query → AI Data Analytics |
| **L7 — Tiêu Thụ** (BI Tools) | AI insights → dashboards, reports |

## Services

- [Dify](dify/README.md) — AI Workflow Platform
- [vLLM](vllm/README.md) — LLM Inference Engine
- [Langfuse](langfuse/README.md) — LLM Observability
