#!/bin/bash

# Qwen3-14B-AWQ Memory Optimization Script
# This script tests different configurations to find optimal VRAM usage

echo "🔍 Testing Qwen3-14B-AWQ Memory Optimization..."

# Test 1: Conservative (8K context, high throughput)
echo "📊 Test 1: Conservative Configuration"
docker-compose -f docker-compose-qwen3-optimized.yml up -d
sleep 30
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits
docker-compose -f docker-compose-qwen3-optimized.yml down

# Test 2: Balanced (16K context, medium throughput)
echo "📊 Test 2: Balanced Configuration"
docker run --rm --gpus all \
  -e MODEL=Qwen/Qwen3-14B-AWQ \
  -e MAX_MODEL_LEN=16384 \
  -e MAX_NUM_SEQS=24 \
  -e GPU_MEMORY_UTILIZATION=0.65 \
  -e KV_CACHE_DTYPE=fp16 \
  -p 8012:8000 \
  --name qwen3-test \
  ktl-vllm:latest &
sleep 30
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits
docker stop qwen3-test

# Test 3: Performance (32K context, lower throughput)
echo "📊 Test 3: Performance Configuration"
docker run --rm --gpus all \
  -e MODEL=Qwen/Qwen3-14B-AWQ \
  -e MAX_MODEL_LEN=32768 \
  -e MAX_NUM_SEQS=8 \
  -e GPU_MEMORY_UTILIZATION=0.5 \
  -e KV_CACHE_DTYPE=fp8 \
  -p 8013:8000 \
  --name qwen3-test \
  ktl-vllm:latest &
sleep 30
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits
docker stop qwen3-test

echo "✅ Memory optimization tests completed!"
echo "📈 Check results above to choose optimal configuration"