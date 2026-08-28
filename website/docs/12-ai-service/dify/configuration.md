# Cấu Hình Dify

## Model Provider — Tích Hợp vLLM

Dify kết nối đến vLLM thông qua giao thức **OpenAI-compatible API**. Cần cấu hình 3 model providers cho 3 loại model.

### Cấu Hình LLM (Text Generation)

Truy cập **Settings → Model Providers → OpenAI-API-compatible**:

| Thuộc tính | Giá trị |
|---|---|
| **Provider Name** | `vllm-llm` |
| **Model Name** | `Qwen/Qwen3-14B-AWQ` |
| **API Base URL** | `http://<vllm-host>:8010/v1` |
| **API Key** | `<VLLM_API_KEY_FROM_SECRET>` (vLLM có thể không bắt buộc; vẫn dùng credential riêng nếu endpoint được bảo vệ) |
| **Model Type** | LLM |
| **Context Size** | `32768` |

### Cấu Hình Embedding Model

| Thuộc tính | Giá trị |
|---|---|
| **Provider Name** | `vllm-embeddings` |
| **Model Name** | `BAAI/bge-m3` |
| **API Base URL** | `http://<vllm-host>:8017/v1` |
| **Model Type** | Text Embedding |
| **Max Tokens** | `1024` |

### Cấu Hình Reranker Model

| Thuộc tính | Giá trị |
|---|---|
| **Provider Name** | `vllm-reranker` |
| **Model Name** | `BAAI/bge-reranker-v2-m3` |
| **API Base URL** | `http://<vllm-host>:8018/v1` |
| **Model Type** | Rerank |
| **Max Tokens** | `1024` |

### Xác Nhận Kết Nối

```bash
# Test LLM
curl http://<vllm-host>:8010/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "Qwen/Qwen3-14B-AWQ", "messages": [{"role": "user", "content": "Hello"}]}'

# Test Embeddings
curl http://<vllm-host>:8017/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{"model": "BAAI/bge-m3", "input": "Hello world"}'

# Test Reranker
curl http://<vllm-host>:8018/v1/rerank \
  -H "Content-Type: application/json" \
  -d '{"model": "BAAI/bge-reranker-v2-m3", "query": "test", "documents": ["doc1", "doc2"]}'
```

## Langfuse Integration

Dify tích hợp sẵn Langfuse từ version 0.6.12+, chỉ cần cấu hình environment variables:

```bash
# === Langfuse Tracing ===
LANGFUSE_PUBLIC_KEY=<LANGFUSE_PUBLIC_KEY>
LANGFUSE_SECRET_KEY=<LANGFUSE_SECRET_KEY_FROM_SECRET>
LANGFUSE_HOST=http://langfuse.your-domain.com
```

Sau khi cấu hình, truy cập **Settings → Monitoring → Langfuse** để kích hoạt.

> [!TIP]
> Xem chi tiết tại [Langfuse Configuration](../langfuse/configuration.md).

## Knowledge Base Configuration

### Indexing Strategy

```yaml
# Cấu hình Knowledge Base mặc định
indexing:
  # Embedding model
  embedding_model:
    provider: vllm-embeddings
    model: BAAI/bge-m3
  
  # Chunking strategy
  chunk_size: 500          # Kích thước chunk (tokens)
  chunk_overlap: 50        # Overlap giữa các chunks
  
  # Indexing mode
  indexing_mode: high_quality  # economy | high_quality
```

### Retrieval Strategy

| Strategy | Mô Tả | Khi Nào Dùng |
|---|---|---|
| **Vector Search** | Tìm kiếm theo semantic similarity | Câu hỏi ngữ nghĩa |
| **Keyword Search** | Tìm kiếm BM25 theo từ khóa | Tìm tên, mã số cụ thể |
| **Hybrid Search** | Kết hợp vector + keyword | Khuyến nghị cho production |

```yaml
retrieval:
  search_method: hybrid_search
  reranking_enable: true
  reranking_model:
    provider: vllm-reranker
    model: BAAI/bge-reranker-v2-m3
  top_k: 5
  score_threshold: 0.5
```

## Environment Variables

### Core

| Biến | Mô Tả | Giá trị mặc định |
|---|---|---|
| `SECRET_KEY` | Encryption key cho sessions | Bắt buộc |
| `CONSOLE_WEB_URL` | URL giao diện console | `http://localhost` |
| `APP_WEB_URL` | URL ứng dụng end-user | `http://localhost` |
| `MIGRATION_ENABLED` | Tự động chạy DB migration | `true` |

### Database

| Biến | Mô Tả | Giá trị mặc định |
|---|---|---|
| `DB_HOST` | PostgreSQL host | `db` |
| `DB_PORT` | PostgreSQL port | `5432` |
| `DB_USERNAME` | Database user | `postgres` |
| `DB_PASSWORD` | Database password | Bắt buộc |
| `DB_DATABASE` | Database name | `dify` |

### Storage

| Biến | Mô Tả | Giá trị mặc định |
|---|---|---|
| `STORAGE_TYPE` | Loại storage (`local`, `s3`, `azure`) | `local` |
| `S3_ENDPOINT` | MinIO/S3 endpoint | — |
| `S3_BUCKET_NAME` | Bucket name | `dify-storage` |
| `S3_ACCESS_KEY` | Access key | — |
| `S3_SECRET_KEY` | Secret key | — |

### Vector Database

| Biến | Mô Tả | Giá trị mặc định |
|---|---|---|
| `VECTOR_STORE` | Vector DB type | `weaviate` |
| `WEAVIATE_ENDPOINT` | Weaviate endpoint | — |
| `QDRANT_URL` | Qdrant URL (nếu dùng Qdrant) | — |

## Plugin Configuration

### Cài Đặt Plugin Từ Marketplace

Dify hỗ trợ marketplace với 500+ plugins. Các loại plugin:

| Loại | Mô Tả | Ví Dụ |
|---|---|---|
| **Model** | Thêm model providers | `openai_api_compatible`, `vllm` |
| **Tool** | Công cụ cho Agent | GLPI, OCR, web search |
| **Agent Strategy** | Chiến lược điều phối Agent | ReAct, Function Calling |
| **Extension** | Mở rộng tính năng | External data source |

### Plugin vLLM

```yaml
# Plugin: yangyaofei/vllm:0.1.3
# Cung cấp kết nối trực tiếp đến vLLM server
dependencies:
  - type: package
    value:
      plugin_unique_identifier: yangyaofei/vllm:0.1.3
```

### Plugin OpenAI-compatible

```yaml
# Plugin: langgenius/openai_api_compatible:0.0.16
# Kết nối Generic OpenAI API (dùng cho vLLM)
dependencies:
  - type: marketplace
    value:
      marketplace_plugin_unique_identifier: langgenius/openai_api_compatible:0.0.16
```
