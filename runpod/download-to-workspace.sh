#!/usr/bin/env bash
# RunPod container start command helper: download a Hub model into the volume.
# Mount a Network Volume at /workspace so the next Pod reuses the cache.
# Secrets: set HF_TOKEN via {{ RUNPOD_SECRET_… }} in the template env — not here.
set -euo pipefail

run_hf() {
  if command -v hf >/dev/null 2>&1; then
    hf "$@"
  elif command -v uvx >/dev/null 2>&1; then
    uvx hf "$@"
  else
    curl -LsSf https://hf.co/cli/install.sh | bash -s -- --exclude-skill
    export PATH="${HOME}/.local/bin:${PATH}"
    hf "$@"
  fi
}

MODEL=${MODEL:-Qwen/Qwen3-8B}
HF_HOME=${HF_HOME:-/workspace/huggingface}
mkdir -p "$HF_HOME"
export HF_HOME HUGGINGFACE_HUB_CACHE="$HF_HOME"

echo "== download ${MODEL} → ${HF_HOME} =="
run_hf download "$MODEL"

echo "Done. Cache is on the volume; stop the Pod or switch the start command to serve."
# Keep the container alive if you want to SSH in and inspect:
# exec sleep infinity
