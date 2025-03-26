FROM docker.io/library/golang:1.24 AS build
ARG BUILDKIT_SBOM_SCAN_CONTEXT=true BUILDKIT_SBOM_SCAN_STAGE=true

WORKDIR /app
COPY go.mod go.sum /app/
RUN go mod download

COPY . .
RUN --mount=type=cache,target=/root/.cache \
  VERSION=$(git describe --tags --always --dirty) \
  && go build -o /app/bin/anubis -ldflags="-X github.com/gigirassy/anubis-but-blitzy.Version=${VERSION}" ./cmd/anubis

FROM docker.io/library/debian:bookworm AS runtime
ARG BUILDKIT_SBOM_SCAN_STAGE=true
RUN apt-get update \
  && apt-get -y install ca-certificates

COPY --from=build /app/bin/anubis /app/bin/anubis

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 CMD ["/app/bin/anubis", "--healthcheck"]
CMD ["/app/bin/anubis"]

LABEL org.opencontainers.image.source="https://github.com/gigirassy/anubis-but-blitzy"
