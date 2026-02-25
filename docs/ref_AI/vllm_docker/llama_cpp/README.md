# llama.cpp Server - Qwen3-Coder-Next

Docker setup cho llama.cpp server với Qwen3-Coder-Next GGUF.

## 📖 References

- [llama.cpp GitHub](https://github.com/ggml-org/llama.cpp)
- [llama.cpp Docker Docs](https://github.com/ggml-org/llama.cpp/blob/master/docs/docker.md)
- [llama-server Docs](https://github.com/ggml-org/llama.cpp/blob/master/tools/server)
- [Qwen3-Coder-Next GGUF](https://huggingface.co/Qwen/Qwen3-Coder-Next-GGUF)

## 🚀 Quick Start

```bash
cd /home/useradmin/de-team/llama_cpp

# Start server (sẽ tự pull image và download model)
docker compose up -d

# Xem logs
docker compose logs -f
```

> **Note:** Lần đầu chạy sẽ:
> 1. Pull Docker image `ghcr.io/ggml-org/llama.cpp:server-cuda` (~3GB)
> 2. Download model từ HuggingFace (~40GB cho Q4_K_M)
> 3. Load model vào GPU

## 📡 API Endpoints

llama.cpp server cung cấp OpenAI-compatible API (Port **8011**):

| Endpoint | Mô tả |
|----------|-------|
| `GET /health` | Health check |
| `GET /v1/models` | Danh sách models |
| `POST /v1/chat/completions` | Chat completion (OpenAI format) |
| `POST /v1/completions` | Text completion |
| `GET /metrics` | Prometheus metrics |

## 💬 Test API

```bash
# Health check
curl http://localhost:8011/health

# List models
curl http://localhost:8011/v1/models

# Chat completion (OpenAI format)
curl http://localhost:8011/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3-coder-next",
    "messages": [
      {"role": "user", "content": "Write a Python function to calculate fibonacci"}
    ],
    "temperature": 0.7,
    "max_tokens": 1000
  }'
```

## ⚙️ Configuration

### Command Line Options (trong docker-compose.yml)

| Option | Default | Mô tả |
|--------|---------|-------|
| `--hf-repo` | - | HuggingFace model repository |
| `--hf-file` | - | File GGUF trong repo |
| `-c` | 32768 | Context length (max 262144) |
| `-ngl` | 99 | GPU layers (-1 hoặc 99 = all on GPU) |
| `-b` | 2048 | Batch size |
| `--parallel` | 4 | Concurrent requests |
| `-fa` | - | Enable Flash Attention |
| `--jinja` | - | Enable chat templates |

### Thay đổi Context Length

Để tăng context lên 131072 tokens:
```yaml
command: >
  ...
  -c 131072
  ...
```

> ⚠️ Context length lớn hơn sẽ cần nhiều VRAM hơn

## 📊 VRAM Usage

| Quantization | File | VRAM (~) | Quality |
|--------------|------|----------|---------|
| Q8_0 | `*-Q8_0-00001-of-00005.gguf` | ~80GB | ⭐⭐⭐⭐⭐ |
| Q5_K_M | `*-Q5_K_M-00001-of-00004.gguf` | ~50GB | ⭐⭐⭐⭐ |
| **Q4_K_M** | `*-Q4_K_M-00001-of-00003.gguf` | ~40GB | ⭐⭐⭐ **(Recommended)** |
| Q3_K_M | `*-Q3_K_M-00001-of-00002.gguf` | ~30GB | ⭐⭐ |

## 🔧 Troubleshooting

### Model download chậm
- Model được download từ HuggingFace (~40GB)
- Được cache tại `/ephemeral/data/.cache/huggingface`
- Các lần chạy sau sẽ dùng cache

### Out of memory
1. Giảm context length: `-c 16384`
2. Giảm concurrent requests: `--parallel 2`
3. Dùng quantization thấp hơn (Q3_K_M)

### Check logs
```bash
docker compose logs -f llama-qwen3-coder
```

### Check GPU usage
```bash
nvidia-smi
```

## 🔄 Build Custom Image (Optional)

Nếu cần custom build với CUDA version khác:

```bash
# Clone llama.cpp
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp

# Build với CUDA
docker build -t local/llama.cpp:server-cuda \
  --target server \
  -f .devops/cuda.Dockerfile .
```

Sau đó thay đổi image trong docker-compose.yml:
```yaml
image: local/llama.cpp:server-cuda
```
