
FROM vllm/vllm-openai:latest

LABEL maintainer="dev@katalyst.vn"
LABEL description="Custom vLLM image for AI model hosting"
LABEL version="1.0"

# Cài đặt git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Cài đặt vLLM nightly và Transformers từ source để hỗ trợ model architecture mới (glm4_moe_lite)
RUN pip install --no-cache-dir -U vllm --pre --index-url https://pypi.org/simple --extra-index-url https://wheels.vllm.ai/nightly
RUN pip install --no-cache-dir git+https://github.com/huggingface/transformers.git

# Cài đặt thêm các thư viện nếu cần
RUN pip install --no-cache-dir -U tqdm rich qwen-agent
RUN which python3 && ln -sf $(which python3) /usr/local/bin/python || echo "Python not found"

WORKDIR /app

COPY start.sh /app/
RUN chmod +x /app/start.sh

# Mở port mặc định
EXPOSE 8000

# Điểm vào khi container chạy
ENTRYPOINT ["/app/start.sh"]
