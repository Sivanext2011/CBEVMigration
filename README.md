# ECEV Migration Tool (standalone)

Standalone EC/SDP → CBEV subscriber **migration** tool. Fully self-contained:
it vendors its own copy of the ECEV BSSF HTTP client
(`migration/vendor/ericsson_client.py`), so it has **no dependency on the web
provisioning app's `backend/` package**.

## Layout
```
ECEV_Migration_standalone/
  migration/              # the migration package (CLI, UCIP client, mapping, reports)
    vendor/
      ericsson_client.py  # vendored BSSF client (mTLS/token/SOCKS/CPM-Batch)
    cli.py                # entry point: python -m migration.cli ...
    config/               # mapping workbook, RMCA recipes, migration_config.template.json
  config/
    config.json           # BSSF environment/auth/tls/apis/defaults (gitignored; create from template)
    config.template.json  # template (no secrets)
  requirements.txt
```

## Setup
```bash
cd ECEV_Migration_standalone
python3.11 -m venv .venv && . .venv/bin/activate      # optional
pip install -r requirements.txt

# BSSF (target CBEV) connection + spec defaults:
cp config/config.template.json config/config.json
#   edit config/config.json -> environment URLs, auth username/password,
#   tls cert paths, network.socks5_*, and defaults (party/customer/contract/
#   billingAccount spec externalIds, partitionId, msisdn/imsi resource specs).
#   Override location with the CONFIG_PATH env var if needed.

# Source (EC/SDP via UCIP) connection:
cp migration/config/migration_config.template.json migration/config/migration_config.json
#   edit UCIP endpoint/credentials + options.
```

## Run
```bash
python -m migration.cli --help
#   subcommands: init-template | migrate | batch | report

# Offline (no BSSF/config needed): generate the Excel mapping workbook
python -m migration.cli init-template --out mapping.xlsx

# Migrate a single subscriber (add --dry-run via config/options to avoid writes)
python -m migration.cli --config migration/config/migration_config.json migrate <msisdn>

# Migrate many (file of msisdns or comma list)
python -m migration.cli --config migration/config/migration_config.json batch --file subscribers.txt

# Reconciliation report
python -m migration.cli --config migration/config/migration_config.json report
```
Run `python -m migration.cli <subcommand> --help` for exact flags.

## Tests
```bash
python -m pytest migration/tests -q
```
Unit tests run without any config (the BSSF client is imported lazily).

## Notes
- `config/config.json`, `config/certs/`, `migration/config/migration_config.json`
  and logs are gitignored — they contain environment URLs, credentials and certs.
- The vendored `ericsson_client` reads `config/config.json` relative to the repo
  root (two levels up from `migration/vendor/`), or `$CONFIG_PATH` if set.
- Behaviour (token refresh, partition header, mTLS, SOCKS proxy, cert-based CPM
  Batch route) is identical to the main provisioning tool, since the client is a
  direct copy.
