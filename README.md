# kopia-backup images

[![server](https://img.shields.io/docker/v/mreil/kopia-server?sort=semver&logo=docker&label=server)](https://hub.docker.com/r/mreil/kopia-server) [![agent](https://img.shields.io/docker/v/mreil/kopia-agent?sort=semver&logo=docker&label=agent)](https://hub.docker.com/r/mreil/kopia-agent)

Docker build contexts for the kopia backup server and agent, extracted
from `../docker-backup` (which keeps the compose clusters, tests, and docs).
This repo owns the images; `docker-backup` consumes them.

- `server/` — extended `kopia/kopia` image (entrypoint only). Built as
  `mreil/kopia-server:<VERSION>`.
- `agent/` — merged docker-gen + kopia per-cluster agent. Built as
  `mreil/kopia-agent:<VERSION>`.

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
recreating (`docker compose up -d`). The `docker-backup` clusters still
build from source contexts today; when one is switched to the published
tags, its image line is the only change — no build args needed anymore.

## Tests

Robot Framework end-to-end suite (`test/kopia.robot`) proving the full
path against `test/cluster/` (demo + agent): snapshot visibility on the
server plus a byte-identical restore. The agent image is built from this
repo (`../../agent` context); the server stack still runs from
`../docker-backup/server` (tracked `env.test` fixture, isolated
`kopia-server-test` project), overlaid with `test/server-image.yml` so it
runs the local `mreil/kopia-server` image instead of building locally.
The suite generates `test/cluster/.env`
itself (fingerprint injection) — never hand-edit it. Build the images
first, prove them with the suite, then push:

```sh
./test.sh                       # build images + run suite
./build.sh --push               # push after green suite
```

`test.sh` builds both images under test-local names
(`kopia-server-under-test:local`, `kopia-agent-under-test:local`), so the
suite never touches the official Hub tags, then computes the repo locations
and passes them to the suite via `--variable`, so the robot file holds no
absolute paths.
