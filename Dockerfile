# =============================================================================
# Stage 1: Build the patroni_exporter binary from source
# =============================================================================
FROM golang:1.22-alpine AS builder

RUN apk add --no-cache git ca-certificates

ARG PATRONI_EXPORTER_VERSION=v0.2.1

WORKDIR /build

RUN git clone --depth 1 --branch "${PATRONI_EXPORTER_VERSION}" \
      https://github.com/gopaytech/patroni_exporter.git .

RUN CGO_ENABLED=0 GOOS=linux go build \
      -ldflags="-s -w" \
      -trimpath \
      -o /patroni_exporter \
      ./cmd/main.go

# =============================================================================
# Stage 2: Minimal hardened runtime image
# =============================================================================
FROM alpine:3.20 AS runtime

RUN apk add --no-cache ca-certificates tini \
    && addgroup -S exporter \
    && adduser -S -G exporter -H -D exporter

COPY --from=builder /patroni_exporter /usr/local/bin/patroni_exporter
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/patroni_exporter

USER exporter

EXPOSE 9933

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:9933/ || exit 1

ENTRYPOINT ["tini", "--", "docker-entrypoint.sh"]
