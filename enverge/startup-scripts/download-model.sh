#!/bin/bash
# Download a model, ready to serve later.
#
# Fetches the weights into this instance's Hugging Face cache using vLLM's own
# image, and stops there — nothing is served and no port is opened. A later
# `vllm serve` then starts against a warm cache instead of downloading first.
#
# Qwen3-8B is ~16 GB, so it finishes well inside the startup runner's one-hour
# cap even on a slow home connection. Bigger is not automatically better here:
# a 32B model is ~65 GB, which is fine on a fast link but outlives the cap
# below roughly 150 Mbit — an hour billed for a download that gets killed.
#
# Download time is billed like any other minute, but nothing is waiting on you
# meanwhile — you can SSH in and watch it.
set -euo pipefail

# Any model on the Hub. Smaller variants (Qwen3-4B, Qwen3-1.7B) download
# faster and fit a smaller GPU; larger ones need a proportionally faster link
# to finish inside the cap.
MODEL=${MODEL:-Qwen/Qwen3-8B}
IMAGE=${IMAGE:-vllm/vllm-openai:latest}
CACHE="$HOME/.cache/huggingface"

# Gated models — anything with a licence you have to accept on the Hub first —
# additionally need your own Hugging Face token. Uncomment and paste yours:
#
# HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
#
# Remember this script is stored with your instance, so a token you put here is
# stored with it too. An ungated model needs none of this.

mkdir -p "$CACHE"

# --rm and no -d: this is a one-shot. When the download finishes the container
# is gone, the weights remain in the mounted cache, and the startup script is
# reported as `exited` rather than left running.
#
# No GPU is requested — downloading is pure network and disk, so the GPU stays
# free for whatever you do next.
docker run --rm \
  -v "${CACHE}:/root/.cache/huggingface" \
  -e "HF_TOKEN=${HF_TOKEN:-}" \
  --entrypoint bash \
  "$IMAGE" -lc "
    set -euo pipefail
    run_hf() {
      if command -v hf >/dev/null 2>&1; then hf \"\$@\";
      elif command -v uvx >/dev/null 2>&1; then uvx hf \"\$@\";
      else
        curl -LsSf https://hf.co/cli/install.sh | bash -s -- --exclude-skill
        export PATH=\"\${HOME}/.local/bin:\${PATH}\"
        hf \"\$@\"
      fi
    }
    run_hf download '$MODEL'
  "

echo
echo "Downloaded ${MODEL} into ${CACHE}."
echo "To serve it later, without re-downloading:"
echo
# No 'vllm serve' after the image name: this image's ENTRYPOINT is already
# ["vllm","serve"], so repeating it makes argparse read 'vllm' as the model and
# fail with "unrecognized arguments". (vLLM's own DGX Spark post shows the
# longer form against a different tag, whose entrypoint differs.)
echo "  docker run -d --name enverge-serve --ipc=host -p 8000:8000 \\"
echo "    -v ${CACHE}:/root/.cache/huggingface \\"
echo "    -e NVIDIA_VISIBLE_DEVICES=all ${IMAGE} \\"
echo "    ${MODEL} --gpu-memory-utilization 0.85 --max-num-seqs 4"
echo
echo "Those two flags matter: this GPU shares one memory pool with the CPU and"
echo "the OS, so pushing --gpu-memory-utilization toward 1.0 can hard-lock the"
echo "machine, and more than about four decode streams costs more in bandwidth"
echo "than batching wins back."
