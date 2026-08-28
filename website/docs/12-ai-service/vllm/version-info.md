# Thông Tin Version — vLLM

## Version Hiện Tại

| Thành phần | Version | Ghi chú |
|---|---|---|
| **vLLM** | Nightly (pre-release) | Build từ `wheels.vllm.ai/nightly` |
| **Base Image** | `<CẦN CHỐT TAG/DIGEST>` | Official Docker image, không dùng mutable tag |
| **Custom Image** | `<CẦN CHỐT TAG/DIGEST>` | Katalyst custom build |
| **Transformers** | `<CẦN CHỐT COMMIT/VERSION>` | Build từ source đã lock |
| **CUDA** | 12.1+ | Bundled trong base image |

> [!NOTE]
> Nếu sử dụng nightly/pre-release để hỗ trợ model mới, phải ghi commit/image digest, kết quả benchmark và kế hoạch rollback trong release register.

## Model Version Matrix

### Production Models

| Model | Version/Variant | Params | VRAM | Hỗ Trợ Tiếng Việt |
|---|---|---|---|---|
| **Qwen/Qwen3-14B-AWQ** | AWQ quantized | 14B | ~10 GB | Tốt |
| **BAAI/bge-m3** | v1 | 568M | ~2 GB | Multilingual |
| **BAAI/bge-reranker-v2-m3** | v2 | 568M | ~2 GB | Multilingual |

### Backup / Alternative Models

| Model | Params | VRAM | Ghi chú |
|---|---|---|---|
| Qwen/Qwen3-4B-AWQ | 4B | ~4 GB | Low VRAM alternative |
| Qwen/Qwen3-32B-AWQ | 32B | ~22 GB | Higher quality |
| Qwen/Qwen3-VL-4B-Instruct | 4B | ~8 GB | Vision-language |
| Qwen/Qwen3-Coder-Next-GGUF | Q4_K_M | ~12 GB | Code generation |
| GLMHF/glm-4-7b-flash | 7B | ~8 GB | GLM4 alternative |
| Qwen/Qwen3-Embedding-0.6B | 0.6B | ~1.5 GB | Qwen3 embedding |
| Qwen/Qwen3-Reranker-0.6B | 0.6B | ~1.5 GB | Qwen3 reranker |

## Hardware Compatibility

| GPU | VRAM | Hỗ trợ | Models khuyến nghị |
|---|---|---|---|
| **NVIDIA A100** | 40/80 GB | Tốt nhất | 32B AWQ, multi-model |
| **NVIDIA H100** | 80 GB | Tốt nhất | FP8 quantization |
| **NVIDIA RTX 4090** | 24 GB | Có | 14B AWQ + embed + rerank |
| **NVIDIA RTX 3090** | 24 GB | Có | 14B AWQ solo |
| **NVIDIA V100** | 16/32 GB | Giới hạn | 4B models only |

## vLLM Feature Compatibility

| Feature | Supported | Ghi chú |
|---|---|---|
| **PagedAttention** | Có | Core feature |
| **Continuous Batching** | Có | Auto-enabled |
| **AWQ Quantization** | Có | Production-ready |
| **GPTQ Quantization** | Có | Production-ready |
| **FP8 Quantization** | Có | H100 recommended |
| **GGUF Format** | Experimental | Single file only |
| **Tool Calling** | Có | Hermes parser |
| **Prefix Caching** | Có | Auto-enabled |
| **Speculative Decoding** | Có | Needs draft model |
| **Tensor Parallelism** | Có | Multi-GPU |
| **Embedding Task** | Có | `TASK=embeddings` |
| **Reranking Task** | Có | `TASK=score` |
| **Vision Models** | Có | `limit-mm-per-prompt` |

## Upgrade Notes

### Update vLLM Nightly

```bash
# Rebuild image từ version/commit đã phê duyệt
docker build --no-cache -t <REGISTRY>/<VLLM_IMAGE>:<PINNED_TAG> .
docker compose down
docker compose up -d
```

### Đổi Model

```bash
# 1. Edit environment variable trong docker-compose.yml
environment:
  - MODEL=Qwen/Qwen3-32B-AWQ  # Model mới

# 2. Restart service
docker compose restart vllm-qwen3-14b-awq

# 3. Verify
curl http://localhost:8010/v1/models
```

### Upgrade GPU

Khi upgrade từ 1 GPU → multi-GPU:

```yaml
# 1. Tăng TENSOR_PARALLEL_SIZE
environment:
  - TENSOR_PARALLEL_SIZE=2

# 2. Allocate nhiều GPU
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 2
          capabilities: [gpu]
```

## Tài Nguyên

| Tài Nguyên | Link |
|---|---|
| **GitHub** | [vllm-project/vllm](https://github.com/vllm-project/vllm) |
| **Documentation** | [docs.vllm.ai](https://docs.vllm.ai) |
| **Qwen3 Models** | [HuggingFace/Qwen](https://huggingface.co/Qwen) |
| **BGE Models** | [HuggingFace/BAAI](https://huggingface.co/BAAI) |
