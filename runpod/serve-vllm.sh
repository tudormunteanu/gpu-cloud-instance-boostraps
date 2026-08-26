#!/usr/bin/env bash
# RunPod container start command helper: serve with vLLM against a warm HF_HOME.
# Template env: MODEL, HF_HOME=/workspace/huggingface, optional HF_TOKEN secret.
# Image: vllm/vllm-openai (ENTRYPOINT is already vllm serve) — we exec the CLI directly
# so a custom start command doesn't fight the entrypoint twice.
set -euo pipefail

MODEL=${MODEL:-Qwen/Qwen3-8B}
HF_HOME=${HF_HOME:-/workspace/huggingface}
PORT=${PORT:-8000}
export HF_HOME HUGGINGFACE_HUB_CACHE="$HF_HOME"

mkdir -p "$HF_HOME"
echo "== serve ${MODEL} on :${PORT} (HF_HOME=${HF_HOME}) =="

# Discrete datacenter GPUs: default utilization is fine. Drop toward 0.85 on
# unified-memory / small cards if the host OOMs.
exec vllm serve "$MODEL" \
  --host 0.0.0.0 --port "$PORT" \
  --gpu-memory-utilization "${GPU_MEMORY_UTILIZATION:-0.90}" \
  --max-num-seqs "${MAX_NUM_SEQS:-256}"
