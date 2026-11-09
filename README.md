# Node Packaging Demo

Express app packaged as an npm tarball, with environment config kept outside the package.

## Commands
```bash
npm install                                  # install dependencies
npm test                                     # run tests
npm pack --pack-destination dist             # build the artifact (.tgz)
npm audit                                    # security audit
npm version patch|minor|major                # bump version, commit and tag
npm run checksum            # generate SHA256 checksums for dist/ artifacts
npm run verify-checksum     # verify them
npm publish --registry http://localhost:4873 # publish to local Verdaccio
```

## Versioning Strategy
Semantic Versioning (MAJOR.MINOR.PATCH), managed with `npm version`.
Each release is a git tag (v1.0.0, v1.0.1). Dependencies use caret ranges
(`^4.x`) and exact versions are locked in `package-lock.json`.

## Environment Config
Priority: environment variables > `config/<APP_ENV>.json` > defaults.
`config/` is excluded from the package (`"files": ["src"]`), so one artifact
runs in any environment. Secrets are passed as environment variables only.

| Env | Port | Debug |
|---|---|---|
| development | 3000 | true |
| staging | 3001 | false |

## Dependency Audit Summary
(Result of `npm audit`: ___ vulnerabilities in current dependencies.
Demo with express@4.16.0: found ___ issues, fixed with `npm audit fix`.
Reports are in `docs/`.)

## Challenges


## Screenshots
See `screenshots/`: dev run, staging run, tarball contents, audit output.

## Verifying Artifact Integrity

Each release includes `dist/checksum.sha256` containing SHA256 hashes of the
artifacts. Verify a download before installing it:

```bash
# 1. Download the artifact and checksum.sha256 into the same folder
cd dist

# 2. Verify (expects "OK" for each file)
sha256sum -c checksum.sha256
#   node-packaging-demo-1.0.0.tgz: OK

# 3. Only install if verification passes
npm install ./node-packaging-demo-1.0.0.tgz
```

macOS users can use `shasum -a 256 -c checksum.sha256` instead.

A result of `FAILED` means the file was corrupted or modified. Do not install
it; download it again from a trusted source.

To generate the checksums after building a release:

```bash
npm pack --pack-destination dist
./scripts/checksum.sh generate     # or: npm run checksum
```

Note: a checksum proves the file wasn't changed in transit. It doesn't prove who
published it. For that you would use signing (e.g. GPG or npm provenance).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for the version history.

## CI/CD with Jenkins

Pipeline defined in `Jenkinsfile`:

| Stage | What it does |
|---|---|
| Build | `npm ci` |
| Test | `node --test`, results published as JUnit; pipeline fails on any failed test |
| Security Audit | `npm audit --omit=dev --audit-level=high` |
| Package | `npm pack` + SHA256 checksum, archived in Jenkins |
| Deploy | Installs the `.tgz` into a staging folder and runs it on port 3001 |

### Setup Summary
- Jenkins on Ubuntu EC2 (Java 21, Node 22), port 8080
- Plugins: Git, GitHub, Pipeline, Stage View, Credentials Binding, JUnit
- Trigger: GitHub webhook to `http://<EC2-IP>:8080/github-webhook/`
- Secrets held in Jenkins Credentials (`deploy-token`, `github-pat`), never in code

### Challenges


### Screenshots
![Pipeline green](screenshots/pipeline-green.png)
![Failed test run](screenshots/pipeline-red.png)

## Docker Integration

The app is containerized with a `Dockerfile` (node:22-alpine, non-root user,
HEALTHCHECK on `/health`). Environment config is mounted at runtime, not baked in.

Pipeline stages added:

| Stage | What it does |
|---|---|
| Docker Build | `docker build`, tagged `<build number>` and `latest` |
| Docker Push | Pushes to Docker Hub using the `dockerhub-creds` Jenkins credential |
| Deploy | Pulls the image, runs it as `node-staging` on port 3001, waits for `healthy` |

Run it manually:
```bash
docker build -t node-packaging-demo .
docker run -d -p 3001:3000 -e APP_ENV=staging node-packaging-demo
```

Registry: https://hub.docker.com/r/jjagzz/node-packaging-demo
