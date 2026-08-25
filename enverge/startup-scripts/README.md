# startup scripts

Paste into the create/queue panel.

- [warm-up.sh](./warm-up.sh) — offline GPU check, ~2 min
- [download-model.sh](./download-model.sh) — Qwen3-8B into `~/.cache/huggingface`, doesn’t serve

```bash
tail -f /var/log/enverge/startup.log
sudo systemctl stop enverge-startup
```

No tokens in the script. Doesn’t re-run on restart.
