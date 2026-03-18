# Cấu Hình Langfuse

## Tích Hợp Dify (Native)

Dify tích hợp sẵn Langfuse từ version 0.6.12+. Chỉ cần cấu hình environment variables trong Dify:

### Bước 1: Lấy API Keys Từ Langfuse

1. Truy cập Langfuse Dashboard → **Project Settings → API Keys**
2. Tạo API key pair mới
3. Ghi lại:
   - **Public Key**: `pk-lf-xxxxxxxx`
   - **Secret Key**: `sk-lf-xxxxxxxx`

### Bước 2: Cấu Hình Trong Dify

Thêm vào `.env` của Dify:

```bash
# === Langfuse Integration ===
LANGFUSE_PUBLIC_KEY=pk-lf-your-public-key
LANGFUSE_SECRET_KEY=sk-lf-your-secret-key
LANGFUSE_HOST=http://langfuse.your-domain.com
```

### Bước 3: Kích Hoạt Trong Dify UI

1. Truy cập Dify Console → **Settings → Monitoring**
2. Chọn **Langfuse**
3. Nhập Public Key, Secret Key, Host
4. Click **Save** và **Enable**

### Xác Nhận

Sau khi enable, gửi một tin nhắn test trong bất kỳ ứng dụng Dify nào. Trace sẽ xuất hiện trong Langfuse Dashboard trong vài giây.

## Tích Hợp Custom Application (Python SDK)

### Cài Đặt SDK

```bash
pip install langfuse
```

### Cấu Hình Environment

```bash
export LANGFUSE_PUBLIC_KEY=pk-lf-your-public-key
export LANGFUSE_SECRET_KEY=sk-lf-your-secret-key
export LANGFUSE_HOST=http://langfuse.your-domain.com
```

### Sử Dụng `@observe()` Decorator

```python
from langfuse import observe, get_client
from openai import OpenAI

langfuse = get_client()
client = OpenAI(
    base_url="http://vllm-host:8010/v1",
    api_key="token-abc123"
)

@observe()
def process_query(query: str) -> str:
    """Auto-traced: inputs, outputs, latency"""
    response = client.chat.completions.create(
        model="Qwen/Qwen3-14B-AWQ",
        messages=[
            {"role": "system", "content": "Bạn là trợ lý AI."},
            {"role": "user", "content": query}
        ]
    )
    return response.choices[0].message.content

@observe()
def rag_pipeline(question: str) -> dict:
    """Traced RAG pipeline with nested spans"""
    # Embedding
    with langfuse.start_as_current_observation(
        as_type="retriever", name="embed_query", input=question
    ) as span:
        # Call embedding API
        embed_result = embed(question)
        span.update(output=embed_result)
    
    # Retrieval
    with langfuse.start_as_current_observation(
        as_type="retriever", name="retrieve_docs", input=question
    ) as span:
        docs = retrieve(embed_result)
        span.update(output=docs)
    
    # Generate
    answer = process_query(f"Context: {docs}\n\nQuestion: {question}")
    
    return {"answer": answer, "docs": docs}
```

### OpenAI SDK Auto-Instrumentation

```python
from langfuse.openai import OpenAI  # Drop-in replacement

client = OpenAI(
    base_url="http://vllm-host:8010/v1",
    api_key="token-abc123"
)

# Tự động trace tất cả OpenAI calls
response = client.chat.completions.create(
    model="Qwen/Qwen3-14B-AWQ",
    messages=[{"role": "user", "content": "Hello"}]
)
```

## Environment Variables — Langfuse Server

### Core

| Biến | Mô Tả | Bắt buộc |
|---|---|---|
| `DATABASE_URL` | PostgreSQL connection string | ✅ |
| `NEXTAUTH_SECRET` | Session encryption key | ✅ |
| `NEXTAUTH_URL` | Public URL của Langfuse | ✅ |
| `SALT` | Salt cho API key hashing | ✅ |

### Authentication

| Biến | Mô Tả | Mặc định |
|---|---|---|
| `AUTH_DISABLE_SIGNUP` | Tắt đăng ký tài khoản mới | `false` |
| `AUTH_DISABLE_USERNAME_PASSWORD` | Tắt đăng nhập username/password | `false` |
| `AUTH_GOOGLE_CLIENT_ID` | Google OAuth client ID | — |
| `AUTH_GOOGLE_CLIENT_SECRET` | Google OAuth secret | — |

### Performance

| Biến | Mô Tả | Mặc định |
|---|---|---|
| `TELEMETRY_ENABLED` | Gửi anonymous telemetry | `true` |
| `LANGFUSE_LOG_LEVEL` | Log level | `info` |
| `LANGFUSE_ASYNC_INGESTION_PROCESSING` | Async trace processing | `true` |

## Project Configuration

### Tạo Project

1. Login Langfuse → **New Project**
2. Đặt tên: e.g., "Hanas AI Production"
3. Tạo API Keys cho project

### Multi-Environment Setup

| Environment | Project Name | Mục đích |
|---|---|---|
| **Development** | `hanas-ai-dev` | Testing và debugging |
| **Staging** | `hanas-ai-staging` | Pre-production validation |
| **Production** | `hanas-ai-prod` | Production monitoring |

> [!TIP]
> Dùng separate projects cho mỗi environment, mỗi project có API keys riêng.
