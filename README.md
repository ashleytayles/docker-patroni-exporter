# docker-patroni-exporter

Dockerised [patroni_exporter](https://github.com/gopaytech/patroni_exporter) — a Prometheus exporter for Patroni cluster metrics.

## Features

- **Multi-stage build** — compiles from source; final image is ~15 MB (Alpine-based).
- **Hardened runtime** — runs as non-root user, uses `tini` as PID 1, includes a health check.
- **Environment-variable configuration** — every CLI flag is settable via env vars.
- **Multi-arch** — `linux/amd64` and `linux/arm64`.
- **Automated updates** — weekly CI rebuilds for base-image patches; daily upstream release checks auto-open PRs when a new version is detected. Fully self-contained in GitHub Actions.

## Image Tags

| Tag | Behaviour |
|---|---|
| `latest` | Always the most recent build |
| `0.2.1` | **Floating** — tracks the upstream version; overwritten on weekly base-image rebuilds |
| `0.2.1-20260323` | **Immutable** — date-stamped, never overwritten; pin this in production for reproducibility |
| `sha-abc1234` | Git commit SHA of this repo |

Version tags mirror the upstream [patroni_exporter releases](https://github.com/gopaytech/patroni_exporter/releases) (without the `v` prefix).
When the base image is rebuilt for security patches, the floating `0.2.1` tag is updated in-place and a new date-stamped tag is created — no version bump needed.

## Quick Start

```bash
docker run -d \
  -e PATRONI_HOST=http://patroni-node:8008 \
  -e PATRONI_PORT=8008 \
  -p 9933:9933 \
  your-dockerhub-user/patroni-exporter:0.2.1
```

## Environment Variables

| Variable | Flag | Default | Description |
|---|---|---|---|
| `PATRONI_HOST` | `--patroni.host` | `http://localhost` | Patroni API URL |
| `PATRONI_PORT` | `--patroni.port` | `8008` | Patroni API port |
| `WEB_LISTEN_ADDRESS` | `--web.listen-address` | `:9933` | Address to listen on |
| `WEB_TELEMETRY_PATH` | `--web.telemetry-path` | `/metrics` | Metrics endpoint path |
| `LOG_LEVEL` | `--log.level` | `info` | Log level (`debug`, `info`, `warn`, `error`) |
| `LOG_FORMAT` | `--log.format` | `logfmt` | Log format (`logfmt`, `json`) |

You can also pass flags directly:

```bash
docker run your-dockerhub-user/patroni-exporter --patroni.host=http://my-host --patroni.port=8008
```

## Building Locally

```bash
docker build -t patroni-exporter .

# Build a specific upstream version:
docker build --build-arg PATRONI_EXPORTER_VERSION=v0.2.1 -t patroni-exporter .
```

## CI/CD

Everything runs via GitHub Actions — no external tooling required.

### Build & Publish (`.github/workflows/docker-publish.yml`)

- **On push to `main` or tag** — builds and pushes `latest`, floating version tag (`0.2.1`), and date-stamped tag (`0.2.1-20260323`) to Docker Hub.
- **Weekly schedule (Monday 04:00 UTC)** — rebuilds to pick up Alpine security patches. The floating version tag is updated; a new date-stamped tag is created.
- **Manual dispatch** — trigger a build for any version via `workflow_dispatch`.

### Upstream Release Check (`.github/workflows/check-upstream.yml`)

- **Daily schedule (06:00 UTC)** — queries the upstream repo for new releases.
- If a new version is found, automatically creates a PR bumping the `ARG PATRONI_EXPORTER_VERSION` in the Dockerfile.
- Merging the PR triggers the build workflow, publishing the updated image.
- Skips if a bump PR/branch already exists for that version.
- Can also be triggered manually via `workflow_dispatch`.

**Required repository configuration:**

| Type | Name | Value |
|---|---|---|
| Variable | `DOCKERHUB_USERNAME` | Your Docker Hub username |
| Secret | `DOCKERHUB_TOKEN` | Docker Hub access token |

## License

Apache License 2.0 — same as the upstream patroni_exporter project.
# docker-patroni-exporter
