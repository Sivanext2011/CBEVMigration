# Air-gapped installation

Install the CBEV Migration tool on a server with **no internet access**.
You download dependencies on an online machine, carry one tarball across, and
install offline from bundled wheels.

> Requires **Python 3.11+** on the target. Dependencies: `httpx`,
> `httpx-socks`, `openpyxl` (+ their transitive deps) — all bundled offline.

---

## 1. On an INTERNET-connected machine

Use a machine that **matches the air-gap target's OS, CPU arch and Python
version** (easiest: an identical box or a matching container). Then:

```bash
git clone https://github.com/Sivanext2011/CBEVMigration.git
cd CBEVMigration
./make_offline_bundle.sh
# -> produces cbevmigration_offline.tgz (repo + wheelhouse/)
```

If the target differs from your build box, cross-download matching wheels:
```bash
TARGET_PYVER=3.11 TARGET_PLATFORM=manylinux2014_x86_64 ./make_offline_bundle.sh
```
(Common platforms: `manylinux2014_x86_64`, `manylinux_2_28_x86_64`,
`win_amd64`, `macosx_11_0_arm64`.)

---

## 2. Transfer

Copy `cbevmigration_offline.tgz` to the air-gapped server (USB / approved
transfer channel).

---

## 3. On the AIR-GAPPED server

```bash
tar xzf cbevmigration_offline.tgz
cd CBEVMigration
chmod +x *.sh                   # if the exec bit didn't survive transfer
./install_offline.sh            # creates .venv and installs from wheelhouse (no internet)
```
Options:
- `NO_VENV=1 ./install_offline.sh` — install into the system Python (`--user`), no venv.
- `PYTHON=/path/to/python3.11 ./install_offline.sh` — pick a specific interpreter.

**If you see `ensurepip is not available` / `python3-venv` missing** (common on
air-gapped Debian/Ubuntu): the installer now **auto-falls back to a `--user`
install** into the system Python — no venv, no root, no internet needed. You can
also force it explicitly:
```bash
NO_VENV=1 ./install_offline.sh
```
(Or install `python3.12-venv` offline if you prefer a venv.)

The installer verifies the imports at the end.

---

## 4. Configure for the air-gapped environment

The repo ships with lab configs; edit them for this server:

- **`config/config.json`** — CBEV `environment` URLs, `auth`, and **`tls` cert
  paths that exist on THIS server** (copy the client certs over and update the
  paths), plus `network.socks5_*` if you reach CBEV via a tunnel.
- **`migration/config/migration_config.json`** — AIR `ucip.endpoint` and
  credentials, and `ucip.socks5_enabled`/`socks5_proxy` if AIR is reached via a
  jump host.

> "Air-gapped" here means no **internet** — the server still needs network
> routes to the **AIR** and **CBEV** endpoints (direct or via SOCKS tunnel).

---

## 5. Run

```bash
source .venv/bin/activate          # unless you used NO_VENV=1
./run.sh --help

# dry-run one subscriber (fetch + map + plan, no writes)
./run.sh migrate 886970007050 --dry-run

# full E2E (provision into CBEV + verify; EC not deleted per config)
./run.sh migrate 886970007050

# batch + reconciliation report
./run.sh batch msisdns.txt
./run.sh report

# single E2E with HTML report
python e2e_migrate_one.py 886970007050 --report migration_report.html
```

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `No matching distribution found` during offline install | Wheels don't match the target. Re-run `make_offline_bundle.sh` with `TARGET_PYVER`/`TARGET_PLATFORM`, or build on a matching box/container. |
| `ensurepip`/`venv` fails | Install the OS `python3.11-venv` package offline, or use `NO_VENV=1`. |
| `httpx_socks` import error | Proxy support needs `httpx-socks` + `python-socks` wheels — confirm both are in `wheelhouse/`. |
| Can't reach AIR/CBEV | Set `socks5_enabled: true` + `socks5_proxy` in the two config files; confirm routes/firewall. |
| Wrong Python | Target needs **3.11+**; carry the Python runtime offline if absent. |
