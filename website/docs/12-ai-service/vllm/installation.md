# Cài Đặt & Triển Khai vLLM

## Prerequisites

| Thành phần | Yêu cầu tối thiểu | Khuyến nghị |
|---|---|---|
| **GPU** | NVIDIA GPU, CUDA 12.1+ | A100 / H100 / RTX 4090 |
| **VRAM** | 24 GB (cho 14B AWQ model) | 48+ GB |
| **RAM** | 32 GB | 64+ GB |
| **Disk** | 100 GB SSD | 200+ GB NVMe |
| **Docker** | 20.10+ | Theo baseline/manifest đã phê duyệt |
| **NVIDIA Driver** | 535+ | Theo ma trận GPU/driver đã kiểm thử |
| **NVIDIA Container Toolkit** | Installed | — |

> [!IMPORTANT]
> Cần cài đặt **NVIDIA Container Toolkit** để Docker sử dụng được GPU.

### Cài Đặt NVIDIA Container Toolkit

```bash
# Ubuntu/Debian
distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

## Build Custom Image

### Dockerfile

```dockerfile
FROM vllm/vllm-openai:<PINNED_TAG>

LABEL maintainer="<PLATFORM_TEAM_CONTACT>"
LABEL description="Custom vLLM image for AI model hosting"
LABEL version="1.0"

# Cài đặt git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Cài đặt vLLM nightly (hỗ trợ model architecture mới)
RUN pip install --no-cache-dir -U vllm --pre \
    --index-url https://pypi.org/simple \
    --extra-index-url https://wheels.vllm.ai/nightly

# Cài đặt Transformers từ source (model mới nhất)
RUN pip install --no-cache-dir git+https://github.com/huggingface/transformers.git

# Cài đặt thư viện bổ sung
RUN pip install --no-cache-dir -U tqdm rich qwen-agent
RUN which python3 && ln -sf $(which python3) /usr/local/bin/python || echo "Python not found"

WORKDIR /app
COPY start.sh /app/
RUN chmod +x /app/start.sh

EXPOSE 8000
ENTRYPOINT ["/app/start.sh"]
```

### Build Image

```bash
cd vllm_docker/
docker build -t ktl-vllm:<PINNED_TAG> .
```

> [!NOTE]
> Image được build với nightly vLLM và Transformers từ source để hỗ trợ các model architecture mới nhất (GLM4, Qwen3, v.v.).

## Triển Khai Bằng Docker Compose

### Main Configuration (Production)

3 services chạy song song trên cùng GPU:

```yaml
# docker-compose.yml
version: '3.8'

services:
  # === LLM — Text Generation ===
  vllm-qwen3-14b-awq:
    image: ktl-vllm:<PINNED_TAG>
    container_name: vllm-qwen3-14b-awq
    runtime: nvidia
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    ports:
      - "8010:8000"
    volumes:
      - /ephemeral/data/.cache/huggingface:/root/.cache/huggingface
    environment:
      - MODEL=Qwen/Qwen3-14B-AWQ
      - TENSOR_PARALLEL_SIZE=1
      - MAX_MODEL_LEN=32786
      - MAX_NUM_SEQS=16
      - GPU_MEMORY_UTILIZATION=0.6
      - TRUST_REMOTE_CODE=True
    ipc: host
    ulimits:
      memlock: -1
      stack: 67108864
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/v1/models"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 240s

  # === Embedding Model ===
  vllm-embeddings-bge-m3:
    image: ktl-vllm:<PINNED_TAG>
    container_name: vllm-embeddings-bge-m3
    runtime: nvidia
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    ports:
      - "8017:8000"
    volumes:
      - /ephemeral/data/.cache/huggingface:/root/.cache/huggingface
    environment:
      - VLLM_ENABLE_V1_MULTIPROCESSING=0
      - MODEL=BAAI/bge-m3
      - TASK=embeddings          # Quan trọng: task embeddings
      - TENSOR_PARALLEL_SIZE=1
      - MAX_MODEL_LEN=1024
      - MAX_NUM_SEQS=64
      - GPU_MEMORY_UTILIZATION=0.15
    ipc: host
    ulimits:
      memlock: -1
      stack: 67108864
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/v1/models"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 240s

  # === Reranker Model ===
  vllm-reranker-bge-m3:
    image: ktl-vllm:<PINNED_TAG>
    container_name: vllm-reranker-bge-m3
    runtime: nvidia
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    ports:
      - "8018:8000"
    volumes:
      - /ephemeral/data/.cache/huggingface:/root/.cache/huggingface
    environment:
      - VLLM_ENABLE_V1_MULTIPROCESSING=0
      - MODEL=BAAI/bge-reranker-v2-m3
      - TASK=score               # Quan trọng: task score cho reranking
      - MAX_MODEL_LEN=1024
      - MAX_NUM_SEQS=64
      - GPU_MEMORY_UTILIZATION=0.15
    ipc: host
    ulimits:
      memlock: -1
      stack: 67108864
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/v1/models"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 240s
```

### Khởi Động

```bash
# Build image (nếu chưa có)
docker build -t ktl-vllm:<PINNED_TAG> .

# Khởi động tất cả services
docker compose up -d

# Kiểm tra status
docker compose ps

# Xem logs
docker compose logs -f vllm-qwen3-14b-awq
```

### Alternative Configurations

```bash
# Vision model (Qwen3-VL multimodal)
docker compose -f docker-compose-qwen3-vl.yml up -d

# Code generation (GGUF quantized)
docker compose -f docker-compose-qwen3-coder.yml up -d
```

## Download Models Trước

Để giảm thời gian khởi động, pre-download models vào cache:

```bash
# Tạo thư mục cache
mkdir -p /ephemeral/data/.cache/huggingface

# Download models
pip install huggingface_hub
huggingface-cli download Qwen/Qwen3-14B-AWQ --local-dir /ephemeral/data/.cache/huggingface
huggingface-cli download BAAI/bge-m3
huggingface-cli download BAAI/bge-reranker-v2-m3
```

## Health Check

```bash
# Kiểm tra LLM service
curl http://localhost:8010/v1/models

# Kiểm tra Embedding service
curl http://localhost:8017/v1/models

# Kiểm tra Reranker service
curl http://localhost:8018/v1/models

# Kiểm tra GPU usage
nvidia-smi
```

## Tiếp Theo

- [Cấu hình chi tiết](configuration.md) — Environment variables, memory tuning
- [Hướng dẫn sử dụng](user-guide.md) — API endpoints, testing
