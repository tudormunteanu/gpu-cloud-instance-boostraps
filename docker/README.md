# docker

RunPod/Vast: you *are* the container → see those folders.

Enverge: docker-inside-the-box. Use `NVIDIA_VISIBLE_DEVICES`, not `--gpus all`.

## download (no gpu)

```bash
MODEL=${MODEL:-Qwen/Qwen3-8B}
IMAGE=${IMAGE:-vllm/vllm-openai:latest}
CACHE="$HOME/.cache/huggingface"
mkdir -p "$CACHE"

docker run --rm \
  -v "${CACHE}:/root/.cache/huggingface" \
  -e "HF_TOKEN=${HF_TOKEN:-}" \
  --entrypoint bash \
  "$IMAGE" -lc "
    set -euo pipefail
    run_hf() {
      if command -v hf >/dev/null 2>&1; then hf "$@";
      elif command -v uvx >/dev/null 2>&1; then uvx hf "$@";
      else
        curl -LsSf https://hf.co/cli/install.sh | bash -s -- --exclude-skill
        export PATH="${HOME}/.local/bin:${PATH}"
        hf "$@"
      fi
    }
    run_hf download '$MODEL'
  "
```

## serve

Image entrypoint is already `vllm serve` — don’t double it.

```bash
docker run -d --name enverge-serve --ipc=host -p 8000:8000 \
  -v "$HOME/.cache/huggingface":/root/.cache/huggingface \
  -e NVIDIA_VISIBLE_DEVICES=all \
  vllm/vllm-openai:latest \
  Qwen/Qwen3-8B --gpu-memory-utilization 0.85 --max-num-seqs 4
```

Or: [serve-vllm.sh](./serve-vllm.sh)

GB10: keep `gpu_memory_utilization` around 0.85, not 0.9+.
