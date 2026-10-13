# CBEV Migration tool — container image
# Build online, then `docker save` -> transfer -> `docker load` on the air-gap host.
FROM python:3.11-slim

# No bytecode, unbuffered logs
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    CONFIG_PATH=/app/config/config.json

WORKDIR /app

# 1) deps first (better layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 2) app code (config/certs are MOUNTED at runtime, not baked in — see .dockerignore)
COPY migration/ ./migration/
COPY e2e_migrate_one.py ./

# The vendored client reads CONFIG_PATH (set above) -> /app/config/config.json
# Entrypoint is the migration CLI; args are passed through.
ENTRYPOINT ["python", "-m", "migration.cli"]
CMD ["--help"]
