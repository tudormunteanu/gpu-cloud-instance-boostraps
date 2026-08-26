#!/usr/bin/env bash
# RunPod container start command helper: download a Hub model into the volume.
# Mount a Network Volume at /workspace so the next Pod reuses the cache.
# Secrets: set HF_TOKEN via {{ RUNPOD_SECRET_… }} in the template env — not here.
set -euo pipefail

MODEL=${MODEL:-Qwen/Qwen3-8B}
HF_HOME=${HF_HOME:-/workspace/huggingface}
mkdir -p "$HF_HOME"
export HF_HOME HUGGINGFACE_HUB_CACHE="$HF_HOME"

echo "== download ${MODEL} → ${HF_HOME} =="
if command -v hf >/dev/null 2>&1; then
  hf download "$MODEL"
elif command -v huggingface-cli >/dev/null 2>&1; then
  huggingface-cli download "$MODEL"
else
  pip install -q -U "huggingface_hub[cli]"
  hf download "$MODEL"
fi

echo "Done. Cache is on the volume; stop the Pod or switch the start command to serve."
# Keep the container alive if you want to SSH in and inspect:
# exec sleep infinity
