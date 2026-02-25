# Best Practices — vLLM

## GPU Memory Optimization

### Multi-model Trên Cùng GPU

Nguyên tắc phân bổ VRAM khi chạy 3 models song song:

| Model | VRAM | `GPU_MEMORY_UTILIZATION` | Lý Do |
|---|---|---|---|
| LLM (14B AWQ) | 60% | `0.6` | Model lớn, cần context window |
| Embedding | 15% | `0.15` | Model nhỏ, throughput cao |
| Reranker | 15% | `0.15` | Model nhỏ, batch processing |
| **Reserved** | **10%** | — | OS overhead, safety margin |

> [!CAUTION]
> Tổng `GPU_MEMORY_UTILIZATION` của tất cả services **không được vượt quá 0.90** để tránh OOM.

### Khi Gặp OOM (Out of Memory)

1. **Giảm `MAX_MODEL_LEN`**: 32K → 16K → 8K
2. **Giảm `MAX_NUM_SEQS`**: 16 → 8 → 4
3. **Giảm `GPU_MEMORY_UTILIZATION`**: 0.6 → 0.5 → 0.4
4. **Dùng quantization**: AWQ hoặc GPTQ giảm ~50% VRAM

### Quantization Strategy

| Method | VRAM Giảm | Chất Lượng | Khi Nào Dùng |
|---|---|---|---|
| **AWQ** | ~50% | Tốt | Production — khuyến nghị |
| **GPTQ** | ~50% | Tốt | Alternative cho AWQ |
| **FP8** | ~25% | Rất tốt | GPU hỗ trợ FP8 (H100) |
| **GGUF** | Tuỳ chọn | Tuỳ mức nén | Experimental trong vLLM |

## Model Selection

### Chọn LLM

| Tiêu chí | Khuyến Nghị |
|---|---|
| **Production (banking)** | Qwen3-14B-AWQ — cân bằng chất lượng & hiệu suất |
| **VRAM giới hạn (< 16 GB)** | Qwen3-4B-AWQ — model nhỏ vẫn đủ tốt |
| **Cần code generation** | Qwen3-Coder-Next — chuyên biệt cho code |
| **Multi-modal (image)** | Qwen3-VL-4B-Instruct — xử lý ảnh + text |
| **Large context (> 32K)** | Xem xét nâng GPU hoặc giảm batch size |

### Chọn Embedding Model

| Model | Dimensions | Hỗ trợ | Ghi chú |
|---|---|---|---|
| **BAAI/bge-m3** | 1024 | Multilingual (100+ languages) | Khuyến nghị — hỗ trợ tiếng Việt tốt |
| **Qwen/Qwen3-Embedding-0.6B** | 1024 | Multilingual | Alternative |

### Chọn Reranker Model

| Model | Hỗ trợ | Ghi chú |
|---|---|---|
| **BAAI/bge-reranker-v2-m3** | Multilingual | Khuyến nghị — chính xác, nhỏ gọn |
| **Qwen/Qwen3-Reranker-0.6B** | Multilingual | Alternative — Qwen3 series |

## Performance Tuning

### Throughput vs Latency

| Tối ưu cho | Cấu Hình |
|---|---|
| **Low Latency** (chatbot) | `MAX_NUM_SEQS=4`, `MAX_MODEL_LEN=8192`, `GPU_MEMORY_UTILIZATION=0.7` |
| **High Throughput** (batch) | `MAX_NUM_SEQS=32`, `MAX_MODEL_LEN=4096`, `GPU_MEMORY_UTILIZATION=0.9` |
| **Balanced** (production) | `MAX_NUM_SEQS=16`, `MAX_MODEL_LEN=32768`, `GPU_MEMORY_UTILIZATION=0.6` |

### Embedding Throughput

```yaml
# Tối ưu embedding cho high throughput
environment:
  - MAX_NUM_SEQS=64            # Nhiều sequences → high throughput
  - MAX_MODEL_LEN=1024         # Ngắn context → ít VRAM
  - GPU_MEMORY_UTILIZATION=0.15 # Nhỏ memory → chia sẻ GPU
```

## Security

### Network

- **Không expose ports ra internet** — chỉ internal network
- Sử dụng **reverse proxy** (NGINX/Traefik) với TLS cho external access
- Firewall: chỉ cho phép Dify server kết nối đến vLLM ports

### Model Cache

```bash
# Đảm bảo permissions đúng cho model cache
chmod 700 /ephemeral/data/.cache/huggingface
# Không share cache directory giữa các user
```

### API Key

```python
# Mặc dù vLLM không bắt buộc API key,
# nên set trong production để tránh unauthorized access
# Sử dụng --api-key flag khi start vLLM server
```

## High Availability

### Health Check Configuration

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8000/v1/models"]
  interval: 30s       # Kiểm tra mỗi 30 giây
  timeout: 10s        # Timeout mỗi lần check
  retries: 3          # Retry 3 lần trước khi đánh dấu unhealthy
  start_period: 240s  # Chờ 4 phút khi khởi động (model loading)
```

### Auto-restart

```yaml
restart: always       # Docker tự restart nếu container crash
```

### Scaling Recommendations

| Kịch bản | Giải pháp |
|---|---|
| **1 GPU, 3 models** | Chia sẻ VRAM (hiện tại) |
| **Tăng throughput LLM** | Thêm GPU, `TENSOR_PARALLEL_SIZE=2` |
| **HA (đảm bảo uptime)** | 2 GPU servers + load balancer |
| **Multi-tenant** | Separate vLLM instances per tenant |

## Vận Hành

### Container Lifecycle

```bash
# Restart service sau khi thay đổi config
docker compose restart vllm-qwen3-14b-awq

# Stop tất cả
docker compose down

# Start lại
docker compose up -d

# Rebuild image (khi update Dockerfile)
docker compose build --no-cache
docker compose up -d
```

### Common Issues

| Vấn đề | Nguyên nhân | Giải pháp |
|---|---|---|
| OOM Killed | VRAM không đủ | Giảm `GPU_MEMORY_UTILIZATION` hoặc `MAX_MODEL_LEN` |
| Slow startup | Model download lần đầu | Pre-download models vào cache |
| Port conflict | Port đã được sử dụng | Đổi external port trong docker-compose |
| CUDA error | Driver không tương thích | Update NVIDIA driver ≥ 535 |
| Tokenizer error | Model mới chưa support | Update nightly vLLM + Transformers |
