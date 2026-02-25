#!/bin/bash

# Qwen3-14B-AWQ Context Length Comparison Script
# Test different configurations for large prompts

echo "🔍 Testing Qwen3-14B-AWQ Configurations for Large Prompts..."

echo "📊 VRAM Status Before:"
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits

# Test 1: 16K Context (Balanced)
echo ""
echo "🧪 Test 1: 16K Context - Balanced Configuration"
docker-compose -f docker-compose-qwen3-16k.yml up -d
sleep 60
echo "📈 VRAM Usage (16K):"
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits
curl -s http://localhost:8012/v1/models | jq '.data[0].id'
docker-compose -f docker-compose-qwen3-16k.yml down

# Test 2: 24K Context (Large Prompt)
echo ""
echo "🧪 Test 2: 24K Context - Large Prompt Configuration"
docker-compose -f docker-compose-qwen3-24k.yml up -d
sleep 90
echo "📈 VRAM Usage (24K):"
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits
curl -s http://localhost:8013/v1/models | jq '.data[0].id'
docker-compose -f docker-compose-qwen3-24k.yml down

# Test 3: Original 32K Context (Maximum)
echo ""
echo "🧪 Test 3: 32K Context - Original Configuration"
docker-compose up -d
sleep 120
echo "📈 VRAM Usage (32K):"
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits
curl -s http://localhost:8010/v1/models | jq '.data[0].id'
docker-compose down

echo ""
echo "✅ Context Length Comparison Completed!"
echo "📋 Choose configuration based on your prompt size needs:"
echo "   • 16K: ~20GB VRAM - Good for most large prompts"
echo "   • 24K: ~26GB VRAM - Very large prompts"  
echo "   • 32K: ~34GB VRAM - Maximum context"