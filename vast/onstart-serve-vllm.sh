#!/usr/bin/env bash
# Vast on-start: serve with vLLM (SSH/Jupyter modes replace image ENTRYPOINT).
# Secrets via account env. Image should provide the `vllm` CLI (e.g. vllm/vllm-openai).
set -euo pipefail

env >> /etc/environment || true

MODEL=${MODEL:-Qwen/Qwen3-8B}
HF_HOME=${HF_HOME:-/workspace/huggingface}
PORT=${PORT:-8000}
export HF_HOME HUGGINGFACE_HUB_CACHE="$HF_HOME"
mkdir -p "$HF_HOME"

echo "== vast onstart: serve ${MODEL} on :${PORT} =="

# If the image entrypoint was ["vllm","serve"], SSH mode skipped it — call serve here.
# Background if you also need the on-start script to "finish"; foreground is fine when
# Vast keeps the process supervised. Adjust to taste.
if command -v vllm >/dev/null 2>&1; then
  vllm serve "$MODEL" \
    --host 0.0.0.0 --port "$PORT" \
    --gpu-memory-utilization "${GPU_MEMORY_UTILIZATION:-0.90}" \
    --max-num-seqs "${MAX_NUM_SEQS:-256}" &
else
  # Fallback when PATH only has the image entrypoint binaries under /usr/local
  python -m vllm.entrypoints.openai.api_server \
    --model "$MODEL" --host 0.0.0.0 --port "$PORT" &
fi

wait -n || true
