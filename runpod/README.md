# RunPod

You’re inside the container. Template = image + start cmd + env + volume.

Docs: https://docs.runpod.io/pods/templates/manage-templates

Typical setup:
- image: `vllm/vllm-openai:latest`
- volume at `/workspace`
- `HF_HOME=/workspace/huggingface`
- secrets: `HF_TOKEN={{ RUNPOD_SECRET_hf_token }}` (not plaintext)

Scripts (use as container start command):
- [download-to-workspace.sh](./download-to-workspace.sh) — pull weights onto the volume
- [serve-vllm.sh](./serve-vllm.sh) — serve `$MODEL`

Network volumes are region-locked. Attach at create.
