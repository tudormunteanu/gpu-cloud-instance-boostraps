#!/usr/bin/env bash
# Vast on-start: warm the HF cache under /workspace (SSH/Jupyter launch modes).
# Put HF_TOKEN in account env vars, not in a public template.
set -euo pipefail

# Make template/account env visible to later shells / processes.
env >> /etc/environment || true

MODEL=${MODEL:-Qwen/Qwen3-8B}
HF_HOME=${HF_HOME:-/workspace/huggingface}
mkdir -p "$HF_HOME"
export HF_HOME HUGGINGFACE_HUB_CACHE="$HF_HOME"

echo "== vast onstart: download ${MODEL} → ${HF_HOME} =="
if command -v hf >/dev/null 2>&1; then
  hf download "$MODEL"
elif command -v huggingface-cli >/dev/null 2>&1; then
  huggingface-cli download "$MODEL"
else
  pip install -q -U "huggingface_hub[cli]"
  hf download "$MODEL"
fi

echo "Download done. SSH/Jupyter stay up; start serve yourself or swap on-start to onstart-serve-vllm.sh."
