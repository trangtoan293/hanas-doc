# Cấu Hình vLLM

## Entrypoint Script (`start.sh`)

Mọi cấu hình vLLM được truyền qua environment variables, script `start.sh` chuyển thành CLI arguments:

```bash
#!/bin/bash

# Mặc định nếu không có tham số được truyền vào
DEFAULT_MODEL=${MODEL:-"meta-llama/Meta-Llama-3-8B"}
DEFAULT_TP_SIZE=${TENSOR_PARALLEL_SIZE:-1}
DEFAULT_MAX_MODEL_LEN=${MAX_MODEL_LEN:-8192}
DEFAULT_QUANTIZATION=${QUANTIZATION:-""}
DEFAULT_GPU_MEM_UTIL=${GPU_MEMORY_UTILIZATION:-0.9}
DEFAULT_MAX_NUM_SEQS=${MAX_NUM_SEQS:-32}
DEFAULT_BLOCK_SIZE=${BLOCK_SIZE:-16}
DEFAULT_TOOL_CALL_PARSER=${TOOL_CALL_PARSER:-"hermes"}

exec vllm serve \
    "$DEFAULT_MODEL" \
    --tensor-parallel-size "$DEFAULT_TP_SIZE" \
    --max-model-len "$DEFAULT_MAX_MODEL_LEN" \
    --gpu-memory-utilization "$DEFAULT_GPU_MEM_UTIL" \
    --block-size "$DEFAULT_BLOCK_SIZE" \
    --max-num-seqs "$DEFAULT_MAX_NUM_SEQS" \
    --enable-auto-tool-choice \
    --tool-call-parser "$DEFAULT_TOOL_CALL_PARSER" \
    $QUANT_CMD \
    --host 0.0.0.0 \
    --port 8000 \
    --trust-remote-code \
    "$@"
```

## Environment Variables

### Core Variables

| Biến | Mô Tả | Mặc Định | Ví Dụ |
|---|---|---|---|
| `MODEL` | HuggingFace model ID | `meta-llama/Meta-Llama-3-8B` | `Qwen/Qwen3-14B-AWQ` |
| `TENSOR_PARALLEL_SIZE` | Số GPU parallel | `1` | `2` (cho multi-GPU) |
| `MAX_MODEL_LEN` | Context length tối đa (tokens) | `8192` | `32786` |
| `MAX_NUM_SEQS` | Số sequences concurrent tối đa | `32` | `16` |
| `GPU_MEMORY_UTILIZATION` | Tỷ lệ sử dụng VRAM (0.0-1.0) | `0.9` | `0.6` |
| `QUANTIZATION` | Phương pháp quantization | (trống) | `awq`, `gptq` |
| `TRUST_REMOTE_CODE` | Cho phép chạy code từ model repo | `False` | `True` |

### Task-specific Variables

| Biến | Mô Tả | Giá Trị |
|---|---|---|
| `TASK` | Loại task cho model | `embeddings` (embedding), `score` (reranking) |
| `TOOL_CALL_PARSER` | Parser cho function calling | `hermes` (mặc định cho Qwen3) |
| `VLLM_ENABLE_V1_MULTIPROCESSING` | Multi-process mode | `0` (tắt cho embedding/reranker) |
| `BLOCK_SIZE` | KV cache block size | `16` |

### GGUF Model Variables

| Biến | Mô Tả | Ví Dụ |
|---|---|---|
| `GGUF_FILE` | Tên file GGUF trong repo | `Qwen3-Coder-Next-Q4_K_M-00001-of-00003.gguf` |
| `TOKENIZER` | Tokenizer từ base model | `Qwen/Qwen3-Coder-Next` |
| `FLASHINFER_DISABLE_VERSION_CHECK` | Tắt kiểm tra version FlashInfer | `1` |

## Profiles Cấu Hình

### Profile: LLM (Text Generation)

```yaml
environment:
  - MODEL=Qwen/Qwen3-14B-AWQ
  - TENSOR_PARALLEL_SIZE=1
  - MAX_MODEL_LEN=32786
  - MAX_NUM_SEQS=16
  - GPU_MEMORY_UTILIZATION=0.6
  - TRUST_REMOTE_CODE=True
```

- **Port**: 8010
- **GPU Memory**: ~60% VRAM
- **Context**: 32K tokens
- **Concurrent**: 16 sequences

### Profile: Embedding Model

```yaml
environment:
  - VLLM_ENABLE_V1_MULTIPROCESSING=0
  - MODEL=BAAI/bge-m3
  - TASK=embeddings
  - TENSOR_PARALLEL_SIZE=1
  - MAX_MODEL_LEN=1024
  - MAX_NUM_SEQS=64
  - GPU_MEMORY_UTILIZATION=0.15
```

- **Port**: 8017
- **GPU Memory**: ~15% VRAM
- **Context**: 1024 tokens
- **Concurrent**: 64 sequences (high throughput)

### Profile: Reranker Model

```yaml
environment:
  - VLLM_ENABLE_V1_MULTIPROCESSING=0
  - MODEL=BAAI/bge-reranker-v2-m3
  - TASK=score
  - MAX_MODEL_LEN=1024
  - MAX_NUM_SEQS=64
  - GPU_MEMORY_UTILIZATION=0.15
```

- **Port**: 8018
- **GPU Memory**: ~15% VRAM
- **Context**: 1024 tokens
- **Concurrent**: 64 sequences

### Profile: Vision-Language Model

```yaml
environment:
  - MODEL=Qwen/Qwen3-VL-4B-Instruct
  - TENSOR_PARALLEL_SIZE=1
  - MAX_NUM_SEQS=16
  - GPU_MEMORY_UTILIZATION=0.7
  - TOOL_CALL_PARSER=hermes
  - TRUST_REMOTE_CODE=True
command: ["--limit-mm-per-prompt", "{\"image\": 5}"]
```

- **Port**: 8011
- **GPU Memory**: ~70% VRAM
- **Multimodal**: Tối đa 5 ảnh/prompt

## Memory Tuning

### GPU Memory Allocation Strategy

3 services chia sẻ 1 GPU:

```
┌──────────────────────────────┐
│         GPU VRAM (48 GB)     │
├──────────────────────────────┤
│  LLM (60%)      ≈ 28.8 GB   │ → Qwen3-14B-AWQ
│  Embedding (15%) ≈  7.2 GB   │ → BGE-M3
│  Reranker (15%)  ≈  7.2 GB   │ → BGE-Reranker-v2-M3
│  System/Free (10%) ≈ 4.8 GB  │ → OS + overhead
└──────────────────────────────┘
```

### Context Length vs VRAM Trade-off

| Context Length | VRAM Usage | Max Sequences | Ghi chú |
|---|---|---|---|
| 8K | ~20 GB | 32 | Conservative — low VRAM |
| 16K | ~26 GB | 24 | Balanced — most use cases |
| 24K | ~30 GB | 16 | Large prompts |
| 32K | ~34 GB | 8 | Maximum context |

> [!TIP]
> Sử dụng `test-context-sizes.sh` để benchmark các cấu hình trên GPU cụ thể.

### KV Cache Optimization

| Tham số | Mô Tả | Impact |
|---|---|---|
| `GPU_MEMORY_UTILIZATION` giảm | Ít VRAM cho KV cache → ít concurrent requests | Giảm throughput |
| `MAX_MODEL_LEN` giảm | Ít VRAM cho context → thêm concurrent requests | Giảm context window |
| `MAX_NUM_SEQS` giảm | Ít sequences → nhiều context per request | Giảm parallelism |
| `BLOCK_SIZE` thay đổi | Block granularity cho PagedAttention | Trade-off fragmentation vs overhead |

## Docker Configuration

### Port Mapping

| Service | External Port | Internal Port |
|---|---|---|
| LLM (Qwen3-14B-AWQ) | **8010** | 8000 |
| Vision (Qwen3-VL) | **8011** | 8000 |
| Embedding (BGE-M3) | **8017** | 8000 |
| Reranker (BGE-Reranker) | **8018** | 8000 |

### Volumes

| Mount | Mục đích |
|---|---|
| `/ephemeral/data/.cache/huggingface:/root/.cache/huggingface` | HuggingFace model cache — tránh re-download |
| `/ephemeral/data/models:/models` | Local GGUF models (optional) |

### System Settings

```yaml
ipc: host                # Shared memory cho multi-process
ulimits:
  memlock: -1             # Unlimited memory lock
  stack: 67108864         # 64MB stack size
restart: always           # Auto-restart nếu crash
```
