"""
Vendored copy of the ECEV BSSF HTTP client (originally backend.app.services.ericsson_client).

This makes the migration tool fully standalone — no dependency on the web app's
backend/ package. It reads config from <repo-root>/config/config.json (override
with the CONFIG_PATH env var) and behaves identically to the shared client
(mTLS, token auth, SOCKS proxy, cert-based CPM Batch route).
"""
