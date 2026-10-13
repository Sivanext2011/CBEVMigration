# Running the CBEV Migration tool as a Docker container (air-gapped)

Containerizing avoids host pip/venv/PEP-668 issues entirely. You build the image
on an online machine, `docker save` it to a tar, carry it to the air-gapped
host, `docker load`, and run with the live config/certs **mounted** at runtime
(nothing secret is baked into the image).

Requires **Docker** on both machines.

---

## 1. On an INTERNET-connected machine
```bash
git clone https://github.com/Sivanext2011/CBEVMigration.git
cd CBEVMigration
./build_image.sh
# -> builds cbevmigration:1.0 and writes cbevmigration_image.tar.gz
#    (the python:3.11-slim base is baked in, so no registry needed offline)
```

## 2. Transfer to the air-gap host
Copy **both**:
- `cbevmigration_image.tar.gz`  (the image)
- the **repo** (for `config/`, `migration/config/`, certs, and `run_container.sh`)

## 3. On the AIR-GAPPED host
```bash
cd CBEVMigration
# load happens automatically on first run, or manually:
gunzip -c cbevmigration_image.tar.gz | docker load

# edit the live configs for this environment:
#   config/config.json                      (CBEV env/auth/tls cert paths)
#   migration/config/migration_config.json  (AIR UCIP endpoint/creds)
# put the CBEV client certs under config/certs/ (or set CERTS_DIR)

./run_container.sh --help
./run_container.sh migrate 886970007050 --dry-run
./run_container.sh migrate 886970007050
./run_container.sh report
```

### Batch / files / reports
Host `./data/` is mounted at `/app/data` in the container:
```bash
cp msisdns.txt data/
./run_container.sh batch /app/data/msisdns.txt
# e2e HTML report:
docker run --rm -it --network host \
  -v "$PWD/config/config.json:/app/config/config.json:ro" \
  -v "$PWD/migration/config/migration_config.json:/app/migration/config/migration_config.json:ro" \
  -v "$PWD/config/certs:$PWD/config/certs:ro" \
  -v "$PWD/data:/app/data" \
  --entrypoint python cbevmigration:1.0 e2e_migrate_one.py 886970007050 --report /app/data/report.html
```

---

## How it's wired
- **Config:** container env `CONFIG_PATH=/app/config/config.json`; the vendored
  client reads it. Mounted read-only from the host.
- **Certs:** `config/config.json` `tls.*_path` must point at paths that exist
  **inside the container**. `run_container.sh` mounts the host `config/certs`
  dir at the *same path* so absolute paths resolve. If your cert paths differ,
  set `CERTS_DIR=/host/cert/dir` and make `config.json` reference that path.
- **Network:** `--network host` so the container reaches AIR + CBEV (and any
  SOCKS proxy) exactly like the host. Set `ucip.socks5_enabled`/`network.socks5_*`
  in the configs if a tunnel is required.

## Env overrides for run_container.sh
| Var | Default | Purpose |
|---|---|---|
| `IMAGE` | `cbevmigration:1.0` | image tag |
| `IMAGE_TAR` | `cbevmigration_image.tar.gz` | tar to load if image missing |
| `CERTS_DIR` | `./config/certs` | host cert dir, mounted at same path |
| `DATA_DIR` | `./data` | host I/O dir -> `/app/data` |

## Troubleshooting
| Symptom | Fix |
|---|---|
| `docker load` fails | ensure you transferred the `.tar.gz` fully; `gunzip -t` to test. |
| TLS cert "file not found" in container | cert paths in `config.json` must match the mount; use `CERTS_DIR` + absolute paths. |
| Can't reach AIR/CBEV | `--network host` is already set; check host routes/SOCKS and set `socks5_enabled` in configs. |
| Rebuild after code change | re-run `build_image.sh` online, re-ship the tar. |
