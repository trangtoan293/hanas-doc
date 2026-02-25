# AGENTS.md

This file contains guidelines and commands for agentic coding agents working in this vLLM Docker hosting repository.

## Project Overview

This is a Docker-based vLLM (Virtual Large Language Model) hosting project that provides OpenAI-compatible API endpoints for various AI models including text generation, embeddings, and reranking models.

## Build and Development Commands

### Docker Commands
```bash
# Build the custom vLLM image
docker build -t ktl-vllm:latest .

# Start all services (main configuration)
docker-compose up -d

# Start specific service
docker-compose up -d vllm-qwen3-14b-awq

# Stop all services
docker-compose down

# View logs for specific service
docker-compose logs -f vllm-qwen3-14b-awq

# Restart a service
docker-compose restart vllm-qwen3-14b-awq
```

### Alternative Configurations
```bash
# Vision model configuration
docker-compose -f docker-compose-qwen3-vl.yml up -d

# Other model configurations available in backup/ directory
docker-compose -f backup/docker-compose-qwen3-4b-awq.yml up -d
docker-compose -f backup/docker-compose-embeddings.yml up -d
docker-compose -f backup/docker-compose-rerank.yml up -d
```

### Health Checks
```bash
# Check if service is healthy
curl http://localhost:8010/v1/models

# Check embeddings service
curl http://localhost:8017/v1/models

# Check reranker service
curl http://localhost:8018/v1/models
```

## Code Style Guidelines

### Docker Compose Files
- Use YAML with 2-space indentation
- Service names should follow pattern: `vllm-{model-type}-{model-name}`
- Port mapping: external port should be unique (8010-8099 range), internal always 8000
- Environment variables should be UPPER_SNAKE_CASE
- Include health checks for all services
- Use `restart: always` for production services

### Shell Scripts (start.sh)
- Use Bash shebang: `#!/bin/bash`
- Variable names should be UPPER_SNAKE_CASE with descriptive prefixes
- Use parameter expansion with defaults: `${VAR:-"default"}`
- Quote all variable expansions: `"$DEFAULT_MODEL"`
- Use exec for final command to replace shell process
- Comments should be in Vietnamese (matching existing codebase)

### Dockerfile
- Start with `FROM vllm/vllm-openai:latest`
- Use LABEL directives for metadata
- RUN commands should be chained with `&&` where possible
- Use `--no-cache-dir` for pip installs
- Set WORKDIR to `/app`
- COPY files after installing dependencies
- EXPOSE port 8000 (standard vLLM port)

## Configuration Patterns

### Environment Variables
Standard variables for all services:
- `MODEL`: HuggingFace model identifier
- `TENSOR_PARALLEL_SIZE`: GPU parallelism (default: 1)
- `MAX_MODEL_LEN`: Context length (varies by model)
- `MAX_NUM_SEQS`: Concurrent sequences (default: 32)
- `GPU_MEMORY_UTILIZATION`: Memory usage 0.0-1.0 (default: 0.9)
- `QUANTIZATION`: Quantization method (optional)
- `TRUST_REMOTE_CODE`: Required for many models (True/False)

### Service-Specific Variables
- Embedding models: `TASK=embeddings`
- Reranker models: `TASK=score`
- Vision models: `TOOL_CALL_PARSER=hermes`

### Resource Allocation
- Text generation: 0.4-0.9 GPU memory
- Embedding models: 0.15 GPU memory
- Reranker models: 0.15 GPU memory
- Vision models: 0.7 GPU memory

## File Organization

### Root Files
- `docker-compose.yml`: Main configuration (Qwen3-14B-AWQ + embeddings + reranker)
- `docker-compose-qwen3-vl.yml`: Vision model configuration
- `Dockerfile`: Custom vLLM image build
- `start.sh`: Container entrypoint script
- `AGENTS.md`: This file

### Backup Directory
Contains alternative model configurations:
- `docker-compose-qwen3-*.yml`: Various Qwen3 model sizes
- `docker-compose-embeddings*.yml`: Embedding model configs
- `docker-compose-rerank*.yml`: Reranker model configs

## Testing and Validation

### Manual Testing
```bash
# Test text generation
curl -X POST http://localhost:8010/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "Qwen/Qwen3-14B-AWQ", "messages": [{"role": "user", "content": "Hello"}]}'

# Test embeddings
curl -X POST http://localhost:8017/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{"model": "BAAI/bge-m3", "input": "Hello world"}'

# Test reranker
curl -X POST http://localhost:8018/v1/rerank \
  -H "Content-Type: application/json" \
  -d '{"model": "BAAI/bge-reranker-v2-m3", "query": "test", "documents": ["doc1", "doc2"]}'
```

### Health Monitoring
- All services include health checks using `/v1/models` endpoint
- Health check interval: 30s
- Timeout: 10s
- Retries: 3
- Start period: 60-240s depending on model size

## Error Handling

### Common Issues
- GPU memory: Adjust `GPU_MEMORY_UTILIZATION` if OOM occurs
- Model loading: Increase `start_period` for large models
- Port conflicts: Use unique external ports (8010-8099)
- Cache issues: Mount HuggingFace cache volume

### Debugging
```bash
# Check container logs
docker logs <container-name>

# Enter container for debugging
docker exec -it <container-name> bash

# Check GPU usage
nvidia-smi

# Check model availability
curl http://localhost:8010/v1/models
```

## Security Guidelines

- Never expose internal ports directly to internet
- Use reverse proxy for production deployments
- Keep HuggingFace cache volumes secure
- Monitor container resource usage
- Regular base image updates for security patches