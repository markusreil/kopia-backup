# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0/).

## [Unreleased]

### Added

- Server and agent docker build contexts, extracted from `../docker-backup`.
- `build.sh`: builds `mreil/kopia-server` and `mreil/kopia-agent`, tagged
  with the repo `VERSION` by default (`--tag`, `--server-image`,
  `--agent-image` overrides, `--push` to publish).
- `versions.env`: pinned upstream versions (`KOPIA_VERSION`, docker-gen,
  yq, supercronic) used as build args.
- `test.sh`: builds test-local images, then runs the robot suites in one
  call — `test/image.robot` (structural image checks) plus
  `test/kopia.robot` (snapshot + byte-identical restore against the
  `docker-backup` server stack).

### Changed

- `BUILD_DATE` stamp (`ARG` + `ENV`) moved after all build layers in both
  Dockerfiles, so a new day reuses the layer cache.
