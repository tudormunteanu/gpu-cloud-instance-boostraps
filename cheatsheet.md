# cheatsheet

| | RunPod | Vast | Nebius | Enverge |
|---|---|---|---|---|
| model | docker template | template + onstart | VM + cloud-init | sandbox + optional shell |
| when | every pod start | onstart (SSH/Jupyter); entrypoint mode = image as-is | first boot | once after create; not on restart; editable in queue |
| secrets | `{{ RUNPOD_SECRET_… }}` | account env | not in user-data | don’t put them in the script |
| pain | cold pulls on the meter | SSH mode eats entrypoint | you’re the sysadmin | nested docker flags; setup minutes bill |

Bake an image or keep a volume. Don’t pay GPU rates for `pip install`.

- RunPod: https://docs.runpod.io/pods/templates/overview
- Vast: https://docs.vast.ai/guides/templates/template-settings
- Nebius: https://docs.nebius.com/compute/virtual-machines/manage
- Enverge: https://enverge.ai/docs#startup-script
