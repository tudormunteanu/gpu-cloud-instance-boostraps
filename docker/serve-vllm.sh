#!/usr/bin/env bash
# Serve a Hub model with the official vLLM OpenAI image.
# Nested Docker: NVIDIA_VISIBLE_DEVICES, not --gpus all.
set -euo pipefail

MODEL=${MODEL:-Qwen/Qwen3-8B}
IMAGE=${IMAGE:-vllm/vllm-openai:latest}
CACHE="${CACHE:-$HOME/.cache/huggingface}"
NAME=${NAME:-enverge-serve}
PORT=${PORT:-8000}

mkdir -p "$CACHE"

docker run -d --name "$NAME" --ipc=host -p "${PORT}:8000" \
  -v "${CACHE}:/root/.cache/huggingface" \
  -e NVIDIA_VISIBLE_DEVICES=all \
  "$IMAGE" \
  "$MODEL" --gpu-memory-utilization 0.85 --max-num-seqs 4

echo "Serving ${MODEL} on :${PORT} (container ${NAME})."
echo "  curl -s http://127.0.0.1:${PORT}/v1/models"
