# Changelog

Each entry is one version of this template. Breaking changes come first.

## 0.31.0 (2026-11-23)

- First release of the template: Rustrak v0.31.0 (`rustrak/rustrak-server:v0.31.0-postgres@sha256:d6983b66…`) with Railway PostgreSQL.
- Rustrak exits 0 after a graceful stop, which Railway's ON_FAILURE policy never restarts; the start script supervises it and exits non-zero, so Railway brings it back.
- `/bin/sh` (busybox) is available, so `railway ssh` works.
- Start script: waits for PostgreSQL, prepares the `/data` volume, creates the first admin from `ADMIN_EMAIL` and the generated `ADMIN_PASSWORD`, and keeps the ingest spool on the volume (`INGEST_DIR=/data/ingest`).
- Upstream release notes: https://github.com/rustrak/rustrak/releases/tag/v0.31.0
