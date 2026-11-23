[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/rustrak-2?utm_medium=integration&utm_source=button&utm_campaign=rustrak)

# Deploy and Host Rustrak on Railway

Rustrak is an open-source, self-hosted error tracker written in Rust. It speaks the Sentry protocol, so any Sentry SDK (JavaScript, Python, Go, Rust, Java and more) reports to it by changing only the DSN. Besides errors, it collects logs, transactions, release health, cron check-ins and AI-agent traces, in one small process.

## About Hosting Rustrak

This template deploys Rustrak v0.31.0, built from the official `rustrak/rustrak-server` PostgreSQL image (pinned by version and digest), next to a Railway PostgreSQL database on the private network. One public service answers the dashboard, the API and the Sentry ingest endpoints on your Railway domain, with a health check on `/health/ready`. Session keys and the admin password are generated at deploy time; the only prompt is the admin email. Rustrak creates that admin on first boot, so no setup wizard is ever open to the public. Uploaded source maps and the ingest spool live on a Railway volume, and everything else lives in PostgreSQL, so data survives redeploys and restarts.

## Common Use Cases

* Track errors and crashes from web, mobile and backend apps with the Sentry SDKs you already use, without a per-event bill
* Watch logs, slow transactions and crash-free sessions per release, with alerts to email, Slack, Discord or webhooks
* Keep error data on your own infrastructure for privacy or compliance

## Dependencies for Rustrak Hosting

* PostgreSQL (Railway's PostgreSQL service, included)
* A Railway volume for source maps and the ingest spool (included)

### Deployment Dependencies

* Rustrak documentation: https://rustrak.dev/
* Rustrak v0.31.0 release: https://github.com/rustrak/rustrak/releases/tag/v0.31.0
* Template source: https://github.com/aalfath/rustrak-railway-template

### Implementation Details

Services in this template:

| Service | What it does |
|---|---|
| `Rustrak` (public) | Dashboard, REST API and Sentry ingest on port 8080. Health check `/health/ready`. Volume at `/data` holds uploaded source maps and accepted events waiting to be stored. |
| `Postgres` | Railway PostgreSQL with its own volume. Holds projects, issues, events, users and settings. |

**After deploy:**

1. Open the `Rustrak` service's **Variables** tab and copy `ADMIN_PASSWORD` (generated).
2. Sign in at `https://YOUR-DOMAIN` with the `ADMIN_EMAIL` you entered and that password, then change the password under your account settings.
3. Create a project. Rustrak shows its DSN, already pointing at your Railway domain. Paste it into your Sentry SDK, for example `Sentry.init({ dsn: "https://KEY@YOUR-DOMAIN/1" })`.

**Variables:**

| Variable | Default | Notes |
|---|---|---|
| `ADMIN_EMAIL` | prompt | Email of the first admin, created on first boot only |
| `ADMIN_PASSWORD` | `${{secret(24)}}` | First admin's password; read it in the Variables tab, change it after signing in |
| `SESSION_SECRET_KEY` | `${{secret(64)}}` | Signs and encrypts login cookies (64+ characters). Changing it signs everyone out |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | Private-network PostgreSQL connection |
| `PUBLIC_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Address written into DSNs and alert links; change it if you add a custom domain |
| `PORT` | `8080` | Port Railway routes to |

The image sets `SSL_PROXY=true` (secure cookies behind Railway's HTTPS), `HOST=::` (reachable over the IPv6 private network too), `INGEST_DIR=/data/ingest` (so accepted events survive a restart) and `RUSTRAK_TELEMETRY=off`. Optional features are off until you add their variables to the `Rustrak` service: SMTP for email alerts (`SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_FROM`), OpenID Connect SSO (`OIDC_*`), Prometheus metrics (`RUSTRAK_METRICS=on`, unauthenticated) and the anonymous usage report (`RUSTRAK_TELEMETRY=on`). See https://rustrak.dev/configuration/environment.

**Resources:** Rustrak idles under 100 MB of RAM. The whole template runs on Railway's smallest plan (tested with every service capped at 0.5 GB RAM and 1 vCPU).

**Updates:** the `Rustrak` service builds from this GitHub repo. When a new Rustrak release is tested here, the pin in the `Dockerfile` is bumped and `CHANGELOG.md` says what changed, breaking changes first. Railway then shows an "update available" notice on your project, and you choose when to apply it. Rustrak runs its database migrations on start. Back up PostgreSQL before a big jump.

## Why Deploy Rustrak on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Rustrak on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
