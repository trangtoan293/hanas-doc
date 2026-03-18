# Hướng Dẫn Sử Dụng Langfuse

## Trace Explorer

### Xem Traces

Truy cập **Langfuse Dashboard → Traces** để xem tất cả traces:

| Cột | Mô Tả |
|---|---|
| **Trace ID** | Unique identifier cho mỗi request |
| **Name** | Tên workflow/function |
| **User** | ID người dùng |
| **Latency** | Tổng thời gian xử lý |
| **Tokens** | Tổng tokens sử dụng |
| **Cost** | Chi phí ước tính |
| **Score** | Điểm đánh giá (nếu có) |

### Phân Tích Trace Chi Tiết

Mỗi trace chứa nhiều **observations** (spans/generations):

```
📋 Trace: "Demo GLPI Chatflow" — 2.5s total
  ├── 🔀 Span: Question Classifier — 150ms
  ├── 📚 Span: Knowledge Retrieval — 350ms
  │   ├── 🔢 Generation: Embedding (BGE-M3) — 50ms, 128 tokens
  │   └── 🔄 Generation: Reranking (BGE-Reranker) — 80ms, 256 tokens
  └── 🧠 Generation: LLM Response (Qwen3-14B) — 1200ms, 1024 tokens, $0.003
```

### Lọc Traces

| Filter | Mô Tả | Ví Dụ |
|---|---|---|
| **Date range** | Khoảng thời gian | Last 24h, Last 7d |
| **User** | Theo user ID | `user-123` |
| **Name** | Theo tên workflow | `Demo GLPI Chatflow` |
| **Tags** | Theo tags | `production`, `error` |
| **Score** | Theo điểm đánh giá | Score < 0.5 |
| **Latency** | Theo thời gian | > 5s |
| **Cost** | Theo chi phí | > $0.01 |

## Evaluation

### Automated Evaluation

Langfuse hỗ trợ tự động đánh giá chất lượng qua **Evaluators**:

| Evaluator | Mô Tả | Khi Nào Dùng |
|---|---|---|
| **Relevance** | Câu trả lời có liên quan đến câu hỏi không | RAG quality |
| **Faithfulness** | Câu trả lời có trung thực với context không | Hallucination check |
| **Toxicity** | Phát hiện nội dung không phù hợp | Content safety |
| **Custom** | Evaluator tự định nghĩa | Business-specific |

### LLM-as-Judge

Sử dụng LLM để đánh giá chất lượng:

```python
from langfuse import get_client

langfuse = get_client()

# Tạo score cho một trace
langfuse.score(
    trace_id="trace-abc-123",
    name="relevance",
    value=0.85,
    comment="Câu trả lời đúng nhưng thiếu chi tiết"
)
```

### Human Feedback

Thu thập feedback từ người dùng:

```python
# Từ Dify: user clicks thumbs up/down
langfuse.score(
    trace_id="trace-abc-123",
    name="user-feedback",
    value=1,  # 1 = positive, 0 = negative
    comment="Câu trả lời chính xác và hữu ích"
)
```

## Prompt Management

### Tạo Prompt

1. Vào **Langfuse → Prompts → New Prompt**
2. Đặt tên: e.g., `glpi-system-prompt`
3. Nhập nội dung prompt
4. **Publish** để deploy

### Version Control

| Version | Nội dung | Score TB | Latency TB |
|---|---|---|---|
| v1 | Basic system prompt | 0.65 | 1.2s |
| v2 | Thêm guardrails | 0.75 | 1.3s |
| v3 | Thêm few-shot examples | 0.85 | 1.5s |
| **v3 (active)** | **Production** | **0.85** | **1.5s** |

### Sử Dụng Prompt Từ Langfuse (Python)

```python
from langfuse import Langfuse

langfuse = Langfuse()

# Lấy prompt version mới nhất
prompt = langfuse.get_prompt("glpi-system-prompt")

# Sử dụng prompt
compiled = prompt.compile(
    user_name="Nguyễn Văn A",
    department="Phòng IT"
)
```

### A/B Testing Prompts

1. Tạo 2 versions prompt
2. Deploy cả 2 (tag: `production-a`, `production-b`)
3. So sánh metrics trong Langfuse Dashboard:
   - Latency
   - Token usage
   - User feedback scores
   - Relevance scores

## Analytics & Metrics

### Dashboard Overview

| Metric | Mô Tả | Alert Threshold |
|---|---|---|
| **Total Traces** | Tổng số requests | — |
| **Avg Latency** | Thời gian trung bình | > 5s |
| **P95 Latency** | 95th percentile latency | > 10s |
| **Total Tokens** | Tổng tokens consumed | Budget-based |
| **Total Cost** | Tổng chi phí inference | Budget-based |
| **Error Rate** | Tỷ lệ lỗi | > 5% |
| **Avg Score** | Điểm đánh giá trung bình | < 0.7 |

### Cost Analysis

Langfuse tự động tính cost dựa trên:
- Model sử dụng (Qwen3-14B vs BGE-M3)
- Input tokens + Output tokens
- Pricing configuration

### User Analytics

- **Active Users**: Số users sử dụng AI features
- **Sessions**: Số phiên hội thoại
- **Messages per Session**: Trung bình số messages
- **Popular Queries**: Câu hỏi thường gặp

## Dataset Management

### Tạo Dataset Từ Production Traces

1. Chọn traces chất lượng cao từ Trace Explorer
2. **Add to Dataset** → Chọn dataset
3. Sử dụng dataset cho regression testing

### Regression Testing

```python
from langfuse import get_client

langfuse = get_client()

# Lấy dataset items
dataset = langfuse.get_dataset("production-qa-pairs")

for item in dataset.items:
    # Chạy lại với prompt/model mới
    result = run_pipeline(item.input)
    
    # So sánh với expected output
    langfuse.score(
        trace_id=result.trace_id,
        name="regression-match",
        value=compare(result.output, item.expected_output)
    )
```

## Tích Hợp Với OpenObserve (Hanas L7)

| Khía cạnh | OpenObserve | Langfuse |
|---|---|---|
| **Focus** | Infrastructure monitoring | AI quality monitoring |
| **Metrics** | CPU, RAM, network, logs | Tokens, latency, cost, scores |
| **Alerts** | Service down, high CPU | Low quality, high cost, errors |
| **Data** | Logs, metrics, traces (infra) | LLM traces, evaluations, prompts |

Cả hai bổ sung cho nhau: OpenObserve giám sát infrastructure (vLLM server health, Dify container metrics), Langfuse giám sát AI application quality.
