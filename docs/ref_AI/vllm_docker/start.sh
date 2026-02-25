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

# Tạo phần quantization command nếu được cung cấp
QUANT_CMD=""
if [ ! -z "$DEFAULT_QUANTIZATION" ]; then
    QUANT_CMD="--quantization $DEFAULT_QUANTIZATION"
fi


# Chạy vLLM OpenAI server
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