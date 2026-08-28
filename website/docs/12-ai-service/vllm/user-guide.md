# Hướng Dẫn Sử Dụng vLLM

## OpenAI-compatible API

vLLM cung cấp API tương thích hoàn toàn với OpenAI, cho phép sử dụng OpenAI client libraries hoặc bất kỳ HTTP client nào.

### API Endpoints

| Endpoint | Method | Mô Tả | Service |
|---|---|---|---|
| `/v1/models` | GET | Liệt kê models đang serve | Tất cả |
| `/v1/chat/completions` | POST | Chat completion (streaming/non-streaming) | LLM |
| `/v1/completions` | POST | Text completion | LLM |
| `/v1/embeddings` | POST | Text embedding | Embedding |
| `/v1/rerank` | POST | Document reranking | Reranker |
| `/health` | GET | Health check | Tất cả |

## Text Generation (Chat/Completions)

### Sử Dụng cURL

```bash
curl -X POST http://localhost:8010/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-14B-AWQ",
    "messages": [
      {"role": "system", "content": "Bạn là trợ lý AI thông minh."},
      {"role": "user", "content": "Hanas Data Platform là gì?"}
    ],
    "temperature": 0.7,
    "max_tokens": 1024,
    "stream": true
  }'
```

### Sử Dụng Python (OpenAI SDK)

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8010/v1",
    api_key="<VLLM_API_KEY_FROM_SECRET>"  # vLLM không bắt buộc API key
)

response = client.chat.completions.create(
    model="Qwen/Qwen3-14B-AWQ",
    messages=[
        {"role": "system", "content": "Bạn là trợ lý AI thông minh."},
        {"role": "user", "content": "Giải thích kiến trúc Data Lakehouse"}
    ],
    temperature=0.7,
    max_tokens=1024
)

print(response.choices[0].message.content)
```

### Tool Calling (Function Calling)

```python
response = client.chat.completions.create(
    model="Qwen/Qwen3-14B-AWQ",
    messages=[
        {"role": "user", "content": "Tạo phiếu đề xuất mới với tiêu đề 'Yêu cầu cấp thiết bị'"}
    ],
    tools=[{
        "type": "function",
        "function": {
            "name": "create_ticket",
            "description": "Tạo phiếu đề xuất mới trong hệ thống GLPI",
            "parameters": {
                "type": "object",
                "properties": {
                    "name": {"type": "string", "description": "Tiêu đề phiếu"},
                    "content": {"type": "string", "description": "Nội dung mô tả"},
                    "priority": {"type": "integer", "description": "Độ ưu tiên (1-6)"}
                },
                "required": ["name"]
            }
        }
    }],
    tool_choice="auto"
)
```

## Embeddings

### Sử Dụng cURL

```bash
curl -X POST http://localhost:8017/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{
    "model": "BAAI/bge-m3",
    "input": "Hanas Data Platform là nền tảng dữ liệu hợp nhất"
  }'
```

### Sử Dụng Python

```python
client_embed = OpenAI(
    base_url="http://localhost:8017/v1",
    api_key="<VLLM_API_KEY_FROM_SECRET>"
)

response = client_embed.embeddings.create(
    model="BAAI/bge-m3",
    input=["Câu hỏi cần embedding", "Tài liệu cần tìm kiếm"]
)

# Vector embeddings
for i, embedding in enumerate(response.data):
    print(f"Input {i}: {len(embedding.embedding)} dimensions")
```

## Reranking

### Sử Dụng cURL

```bash
curl -X POST http://localhost:8018/v1/rerank \
  -H "Content-Type: application/json" \
  -d '{
    "model": "BAAI/bge-reranker-v2-m3",
    "query": "Cách cấu hình Airflow DAG",
    "documents": [
      "Apache Airflow là công cụ orchestration mã nguồn mở",
      "DAG trong Airflow định nghĩa workflow xử lý dữ liệu",
      "MinIO cung cấp object storage tương thích S3"
    ]
  }'
```

### Response

```json
{
  "results": [
    {"index": 1, "relevance_score": 0.92},
    {"index": 0, "relevance_score": 0.78},
    {"index": 2, "relevance_score": 0.15}
  ]
}
```

## Tích Hợp Với Dify

### Kết Nối Model Provider

Trong Dify, cấu hình 3 model providers:

| Model | Dify Provider Type | API Base URL |
|---|---|---|
| Qwen3-14B-AWQ | LLM | `http://<vllm-host>:8010/v1` |
| BGE-M3 | Text Embedding | `http://<vllm-host>:8017/v1` |
| BGE-Reranker-v2-M3 | Rerank | `http://<vllm-host>:8018/v1` |

> Chi tiết tại [Dify Configuration](../dify/configuration.md).

## Monitoring

### Health Check

```bash
# Kiểm tra tất cả services
for port in 8010 8017 8018; do
  echo "Port $port: $(curl -sf http://localhost:$port/v1/models | jq -r '.data[0].id')"
done
```

### GPU Monitoring

```bash
# Kiểm tra VRAM usage
nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu \
  --format=csv,noheader

# Watch real-time
watch -n 2 nvidia-smi
```

### Container Logs

```bash
# Xem logs LLM service
docker logs -f vllm-qwen3-14b-awq

# Xem logs tất cả services
docker compose logs -f
```

### Debugging

```bash
# Enter container
docker exec -it vllm-qwen3-14b-awq bash

# Kiểm tra model loaded
curl -s http://localhost:8000/v1/models | jq '.'

# Kiểm tra metrics
curl http://localhost:8000/metrics
```

## Benchmark Testing

### Test Context Sizes

```bash
# Script sẵn có để test VRAM usage với các context lengths khác nhau
./test-context-sizes.sh

# Kết quả tham khảo:
# • 16K: ~20GB VRAM - Good for most large prompts
# • 24K: ~26GB VRAM - Very large prompts
# • 32K: ~34GB VRAM - Maximum context
```

### Test Memory Optimization

```bash
# Script test các cấu hình memory khác nhau
./optimize-memory.sh

# Test 1: Conservative (8K context, high throughput)
# Test 2: Balanced (16K context, medium throughput)
# Test 3: Performance (32K context, lower throughput)
```

### Latency Testing

```bash
# Simple latency test
time curl -s -X POST http://localhost:8010/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "Qwen/Qwen3-14B-AWQ", "messages": [{"role": "user", "content": "Hello"}], "max_tokens": 100}' \
  > /dev/null
```
