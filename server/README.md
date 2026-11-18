# kopia

## Build

`FROM kopia/kopia:${KOPIA_VERSION}` plus `openssl` for the first-boot
self-signed cert. `BASE_IMAGE` records the upstream image; `BUILD_DATE` is
stamped at build time. Upstream entrypoint is overridden with our own.

## Contents (`docker/`)

- `entrypoint.sh` — creates the repo, connects locally, provisions the
  conduit user (add-or-keep), generates/persists the TLS cert, writes the
  fingerprint file, then `exec`s `kopia server start`.

## Behaviour

First start creates the filesystem repository in `/repo`, a self-signed
4096-bit TLS cert (valid 10 years, persisted in `/repo/certs/`), and the
client conduit user; restarts reuse all three. The cert fingerprint is
written to `/repo/certs/fingerprint` — clients pin it via
`KOPIA_SERVER_FINGERPRINT`. Everything stateful lives in `/repo`, so
that path must be a persisted volume.

## Env vars (all required unless noted)

- `KOPIA_REPOSITORY_PASSWORD` — password for the filesystem repository.
- `KOPIA_CLIENT_USER` / `KOPIA_CLIENT_HOST` — conduit user provisioned
  as `<user>@<host>` (e.g. `root@my-cluster`).
- `KOPIA_CLIENT_PASSWORD` — password for the conduit user.
- `KOPIA_SERVER_USER` / `KOPIA_SERVER_PASSWORD` — UI and server-control
  credentials.
- `KOPIA_DISABLE_BASIC_AUTH` (optional, default `false`) — set to `true`
  to run without a password (logs a warning; anyone reaching :51515 has
  full access).
