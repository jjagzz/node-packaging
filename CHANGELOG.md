# Changelog

All notable changes to this project are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/),
and this project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]


## [1.0.0] - 2026-11-06
### Added
- Express app with `/` and `/health` endpoints.
- Environment-specific configuration (development, staging) kept outside the package.
- Packaging with `npm pack` and a release bundle.
- Security audit with `npm audit`.

### Added
- SHA256 checksum generation and verification (`scripts/checksum.sh`).
- This changelog.

### Added
- Dockerfile and .dockerignore for containerizing the app.
- Jenkins stages: Docker Build, Docker Push (Docker Hub), container-based Deploy.

### Changed
- Deploy stage runs the image as a Docker container instead of a nohup node process.
