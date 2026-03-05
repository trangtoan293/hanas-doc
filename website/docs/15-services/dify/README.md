# Dify

## Tổng Quan

Dify là nền tảng phát triển ứng dụng AI mã nguồn mở, cung cấp giao diện visual để xây dựng **chatbot, AI workflow, RAG pipeline và Agent** mà không cần viết nhiều code. Trong Hanas Platform, Dify đóng vai trò **AI Workflow Platform** — nơi tổ chức, điều phối và triển khai toàn bộ ứng dụng AI.

## Kiến Trúc

```mermaid
flowchart TB
    subgraph DifyPlatform["Dify Platform"]
        subgraph Frontend["Frontend (React)"]
            Studio["Workflow Studio<br/>Visual Builder"]
            KBMgmt["Knowledge Base<br/>Management"]
            Monitor["Monitoring<br/>Dashboard"]
        end

        subgraph Backend["Backend (Flask + Celery)"]
            API["REST API Server"]
            WorkflowEngine["Workflow Engine<br/>Graph-based"]
            RAGEngine["RAG Engine<br/>Hybrid Retrieval"]
            AgentFW["Agent Framework<br/>Tool Calling"]
            PluginSys["Plugin System<br/>Marketplace"]
        end

        subgraph DataStores["Data Stores"]
            PG[(PostgreSQL<br/>App Data)]
            Redis[(Redis<br/>Cache & Queue)]
            VectorDB[(Vector DB<br/>Weaviate/Qdrant)]
            ObjStore[(Object Storage<br/>S3/MinIO)]
        end
    end

    subgraph External["External Services"]
        vLLM["vLLM Server<br/>OpenAI-compatible"]
        Langfuse["Langfuse<br/>Observability"]
        OCR["Katalyst OCR<br/>Document Extraction"]
        GLPI["GLPI/SOTs<br/>Ticket System"]
    end

    Studio --> API
    KBMgmt --> API
    Monitor --> API
    API --> WorkflowEngine
    API --> RAGEngine
    API --> AgentFW
    WorkflowEngine --> PluginSys
    RAGEngine --> VectorDB
    API --> PG
    API --> Redis
    API --> ObjStore

    Backend --> vLLM
    Backend --> Langfuse
    AgentFW --> OCR
    AgentFW --> GLPI

    style DifyPlatform fill:#fff3e0,stroke:#ef6c00
    style Frontend fill:#e8eaf6,stroke:#3f51b5
    style Backend fill:#fce4ec,stroke:#c2185b
    style DataStores fill:#e8f5e9,stroke:#388e3c
    style External fill:#e0f7fa,stroke:#00838f
```

### Luồng Xử Lý Chatflow

```mermaid
sequenceDiagram
    participant User as Người dùng
    participant Dify as Dify Chatflow
    participant QC as Question Classifier
    participant KB as Knowledge Base
    participant Agent as Agent (Tool Calling)
    participant vLLM as vLLM (Qwen3-14B)
    participant GLPI as GLPI System

    User->>Dify: Câu hỏi / Yêu cầu
    Dify->>QC: Phân loại câu hỏi
    
    alt Truy vấn văn bản nội bộ
        QC->>KB: Knowledge Retrieval
        KB->>vLLM: Embedding + Reranking
        vLLM-->>KB: Ranked documents
        KB->>vLLM: Generate answer with context
        vLLM-->>Dify: Câu trả lời
    else Tương tác hệ thống (GLPI)
        QC->>Agent: Agent Strategy
        Agent->>GLPI: API call (search/create/update)
        GLPI-->>Agent: Response data
        Agent->>vLLM: Format response
        vLLM-->>Dify: Kết quả xử lý
    else Câu hỏi chung
        QC->>vLLM: Direct LLM call
        vLLM-->>Dify: Câu trả lời
    end

    Dify-->>User: Response + Suggested questions
```

## Vai Trò Trong Platform

- **AI Application Hub**: Điểm trung tâm xây dựng và quản lý tất cả ứng dụng AI
- **RAG Engine**: Kết nối Knowledge Base với dữ liệu từ Hanas Lakehouse
- **Agent Orchestration**: Điều phối multi-agent cho các tác vụ phức tạp
- **Model Gateway**: Quản lý kết nối đến vLLM và các model providers khác
- **Observability Hub**: Tích hợp Langfuse để giám sát hiệu suất AI

## Tính Năng Chính

1. **Visual Workflow Builder**: Kéo-thả nodes để thiết kế chatbot, workflow AI phức tạp
2. **RAG Pipeline**: Upload tài liệu → embedding → indexing → hybrid retrieval (vector + keyword)
3. **Agent Framework**: Tool calling, function calling, multi-step reasoning
4. **Knowledge Base**: Quản lý nhiều knowledge base với các chiến lược retrieval khác nhau
5. **Prompt IDE**: Quản lý, versioning, A/B testing prompts
6. **Plugin Ecosystem**: 500+ plugins cho models, tools, agent strategies
7. **Backend-as-a-Service**: Auto-generated REST API cho mỗi ứng dụng
8. **Multi-tenant**: Phân quyền truy cập theo workspace và role

## Use Cases Triển Khai

| Use Case | Loại Workflow | Mô Tả |
|---|---|---|
| **Demo GLPI Chatflow** | Advanced Chat | Chatbot hỗ trợ quản lý phiếu đề xuất trong GLPI, hỏi đáp văn bản nội bộ |
| **Smart Office** | Chatflow + Agent | Tóm tắt tài liệu, truy vấn trạng thái, tạo ticket tự động |
| **Smart Documents** | Workflow + RAG | OCR → trích xuất → tra cứu → hỏi đáp tài liệu nội bộ |
| **AI Data Analytics** | Workflow | Kết nối Dremio/Lakehouse → phân tích → biểu diễn charts |

## Tài Liệu

- [Cài đặt & Triển khai](installation.md) — Docker Compose, Kubernetes, prerequisites
- [Cấu hình](configuration.md) — Model provider, Knowledge Base, Langfuse, plugins
- [Hướng dẫn sử dụng](user-guide.md) — Tạo workflow, Knowledge Base, agent, tool
- [Best Practices](best-practices.md) — Prompt engineering, RAG optimization, security
- [Thông tin Version](version-info.md) — Version matrix, changelog
