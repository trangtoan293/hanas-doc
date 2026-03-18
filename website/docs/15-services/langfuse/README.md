# Langfuse

## Tổng Quan

Langfuse là nền tảng **LLM Observability** mã nguồn mở, cung cấp khả năng tracing, evaluation và prompt management cho ứng dụng AI. Trong Hanas Platform, Langfuse đóng vai trò **giám sát toàn bộ AI workflows** — tracking hiệu suất, chi phí, chất lượng của các AI applications chạy trên Dify.

## Kiến Trúc

```mermaid
flowchart TB
    subgraph AIApps["AI Applications"]
        Dify["Dify Workflows"]
        Custom["Custom AI Apps"]
    end

    subgraph LangfusePlatform["Langfuse Platform"]
        subgraph Ingestion["Ingestion Layer"]
            SDK["SDK / API<br/>Trace Collection"]
            DifyInt["Dify Native<br/>Integration"]
        end

        subgraph Core["Core Engine"]
            Tracing["Tracing Engine<br/>Traces → Spans → Events"]
            Eval["Evaluation Engine<br/>Scoring & Assessment"]
            Prompt["Prompt Management<br/>Versioning & Deployment"]
        end

        subgraph Storage["Data Layer"]
            PG[(PostgreSQL<br/>Traces, Scores, Prompts)]
        end

        subgraph UI["Web Dashboard"]
            TraceDash["Trace Explorer"]
            MetricsDash["Metrics & Analytics"]
            PromptDash["Prompt Playground"]
        end
    end

    subgraph Integration["🔗 Integration"]
        OpenObserve["OpenObserve<br/>(Hanas L7)"]
        Alert["Alerting<br/>Webhook/Email"]
    end

    AIApps --> Ingestion
    Ingestion --> Core
    Core --> Storage
    Core --> UI
    Langfuse --> Integration

    style LangfusePlatform fill:#e8f5e9,stroke:#388e3c
    style Ingestion fill:#fff3e0,stroke:#ef6c00
    style Core fill:#e8eaf6,stroke:#3f51b5
    style Storage fill:#fce4ec,stroke:#c2185b
    style UI fill:#e0f7fa,stroke:#00838f
    style AIApps fill:#f3e5f5,stroke:#7b1fa2
```

### Tracing Model

```mermaid
flowchart LR
    subgraph Trace["Trace (1 user request)"]
        direction TB
        Span1["Span: Question Classifier<br/>150ms"]
        Span2["Span: Knowledge Retrieval<br/>200ms"]
        Gen1["Generation: Embedding<br/>512 tokens"]
        Gen2["Generation: Reranking<br/>256 tokens"]
        Span3["Span: LLM Response<br/>1200ms"]
        Gen3["Generation: Qwen3-14B<br/>1024 tokens, $0.003"]
    end

    Span1 --> Span2
    Span2 --> Gen1
    Span2 --> Gen2
    Span2 --> Span3
    Span3 --> Gen3
```

## Vai Trò Trong Platform

- **AI Observability**: Giám sát chi tiết mọi bước trong AI workflow
- **Cost Tracking**: Theo dõi token usage và chi phí inference
- **Quality Evaluation**: Đánh giá chất lượng câu trả lời AI
- **Prompt Optimization**: Versioning và so sánh hiệu suất prompts
- **Debug & Troubleshoot**: Truy vết lỗi trong multi-step workflows
- **Bổ sung cho OpenObserve** (L7): OpenObserve giám sát infrastructure, Langfuse giám sát AI quality

## Tính Năng Chính

1. **Tracing**: Record mọi LLM call, tool usage, agent action — inputs, outputs, latency, costs
2. **Evaluation**: Automated scoring (relevance, hallucination, toxicity) + human feedback
3. **Prompt Management**: Version control, A/B testing, deploy prompts without code changes
4. **Analytics Dashboard**: Token usage, cost breakdown, latency percentiles, error rates
5. **Dataset Management**: Curate datasets từ production traces cho testing
6. **Session Tracking**: Group traces theo user sessions
7. **Self-hosted**: Triển khai on-premise, dữ liệu không rời khỏi infrastructure

## Tài Liệu

- [Cài đặt & Triển khai](installation.md) — Docker Compose, Kubernetes
- [Cấu hình](configuration.md) — Dify integration, SDK setup, auth
- [Hướng dẫn sử dụng](user-guide.md) — Trace analysis, evaluation, prompt management
- [Best Practices](best-practices.md) — Evaluation strategies, alerting, data retention
- [Thông tin Version](version-info.md) — Version matrix, SDK compatibility
