# kopia-backup images

[![server](https://img.shields.io/docker/v/mreil/kopia-server?sort=semver&logo=docker&label=server)](https://hub.docker.com/r/mreil/kopia-server) [![agent](https://img.shields.io/docker/v/mreil/kopia-agent?sort=semver&logo=docker&label=agent)](https://hub.docker.com/r/mreil/kopia-agent)

Two Docker images that work as a pair for kopia-based volume backups:
a central server holding the repository, and a per-cluster agent that
snapshots labeled volumes to it on a schedule.

- `server/` — extended `kopia/kopia` image (entrypoint only). Creates the
  repository, provisions the client user, and serves it over TLS. Built as
  `mreil/kopia-server:<VERSION>`.
- `agent/` — merged docker-gen + kopia agent. Discovers labeled volumes
  from the local Docker daemon and snapshots each one to the server.
  Built as `mreil/kopia-agent:<VERSION>`.

## Usage

### Server

```sh
docker run -d --name kopia-server \
  -p 51515:51515 \
  -v kopia-repo:/repo \
  -e KOPIA_REPOSITORY_PASSWORD=secret-repo-password \
  -e KOPIA_CLIENT_USER=root \
  -e KOPIA_CLIENT_HOST=my-cluster \
  -e KOPIA_CLIENT_PASSWORD=secret-client-password \
  -e KOPIA_SERVER_USER=admin \
  -e KOPIA_SERVER_PASSWORD=secret-admin-password \
  mreil/kopia-server:<VERSION>
# Print the cert fingerprint clients must pin:
docker exec kopia-server cat /repo/certs/fingerprint
```

Server env vars (all required unless noted):

- `KOPIA_REPOSITORY_PASSWORD` — password for the filesystem repository in `/repo`.
- `KOPIA_CLIENT_USER` / `KOPIA_CLIENT_HOST` — conduit user provisioned as `<user>@<host>` (e.g. `root@my-cluster`).
- `KOPIA_CLIENT_PASSWORD` — password for the conduit user.
- `KOPIA_SERVER_USER` / `KOPIA_SERVER_PASSWORD` — UI and server-control credentials.
- `KOPIA_DISABLE_BASIC_AUTH` (optional, default `false`) — set to `true` to run without a password (logs a warning; anyone reaching :51515 has full access).

### Agent

```sh
docker run -d --name kopia-agent \
  --hostname my-cluster \
  -v /var/run/docker.sock:/tmp/docker.sock:rw \
  -v agent-state:/state \
  -v my-data:/mnt/my-data:ro \
  -e DOCKER_HOST=unix:///tmp/docker.sock \
  -e KOPIA_SERVER_URL=https://kopia-server:51515 \
  -e KOPIA_SERVER_FINGERPRINT=<fingerprint-from-server> \
  -e KOPIA_CLIENT_PASSWORD=secret-client-password \
  mreil/kopia-agent:<VERSION>
```

Label a container to opt a volume in (see `test/cluster/docker-compose.yml`):

```yaml
labels:
  backup.data.enabled: "true"
  backup.data.schedule: "@daily"       # optional, default $AGENT_SCHEDULE else @daily
  backup.data.keep-daily: "7"         # optional, keep-latest/hourly/daily/weekly/monthly/annual or inherit
```

Agent env vars (all required unless noted):

- `KOPIA_SERVER_URL` — e.g. `https://server:51515` on the backup network.
- `KOPIA_SERVER_FINGERPRINT` — from the server's `/repo/certs/fingerprint`.
- `KOPIA_CLIENT_PASSWORD` — this cluster's conduit user password.
- `AGENT_SCHEDULE` (optional, default `@daily`) — default schedule for volumes with no `backup.<id>.schedule` label.
- `DOCKER_HOST` — local socket path, e.g. `unix:///tmp/docker.sock` (must match where the socket is mounted).

## Versions

- `VERSION` — this repo's own release version (SemVer, independent of the
  kopia release). `build.sh` tags both images with it; bump it and add a
  `CHANGELOG.md` entry on release.
- `versions.env` — pinned upstream build args (`KOPIA_VERSION`, docker-gen,
  yq, supercronic). Bump there and rebuild.

## Build and push

```sh
./build.sh            # local builds
./build.sh --push     # build + push both images to Docker Hub
./build.sh --push --tag latest  # override tag (default: VERSION)
```

Requires `docker login` before `--push`.

## Release

Releases are cut from this repo with its own SemVer (`VERSION`), independent
of the kopia release:

```sh
# 1. Bump the version and describe it.
#    VERSION: e.g. 0.1.0 -> 0.2.0
#    CHANGELOG.md: move entries from [Unreleased] under a new
#    `## [0.2.0] - YYYY-MM-DD` header.
# 2. Prove it.
./test.sh
# 3. Publish both images under the new tag.
./build.sh --push
# 4. Optionally float the `latest` tag.
./build.sh --push --tag latest
```

`KOPIA_VERSION` in `versions.env` (the upstream base) can change without a
repo release — it just becomes part of the next one. A repo release without
upstream changes gets a patch/minor bump per SemVer.

## Deploy

Publishing is the deploy: clusters consume images by tag, so pointing a
cluster at the new release means setting its image to
`mreil/kopia-server:<VERSION>` / `mreil/kopia-agent:<VERSION>` and
recreating (`docker compose up -d`).

## Tests

Robot Framework end-to-end suite proving the full path against
`test/cluster/` (demo + agent): snapshot visibility on the server plus
a byte-identical restore. The suite runs the locally built images via
`test/server-image.yml`, and generates `test/cluster/.env` itself
(fingerprint injection) — never hand-edit it. Build the images first,
prove them with the suite, then push:

```sh
./test.sh                       # build images + run suite
./build.sh --push               # push after green suite
```

`test.sh` builds both images under test-local names
(`kopia-server-under-test:local`, `kopia-agent-under-test:local`), so the
suite never touches the official Hub tags, then computes the repo locations
and passes them to the suite via `--variable`, so the robot file holds no
absolute paths.
