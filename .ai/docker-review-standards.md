# Dockerfile and Containerisation Review Standards

This document provides code review standards for Dockerfiles, Docker Compose files, and container configuration. Targeted at .NET and Node/React workloads deploying to Azure Container Apps, AKS, or Azure App Service containers.

## Table of Contents

- [Dockerfile Structure](#dockerfile-structure)
- [Base Images](#base-images)
- [Layer Optimisation](#layer-optimisation)
- [Security](#security)
- [Build Arguments and Environment Variables](#build-arguments-and-environment-variables)
- [Multi-Stage Builds](#multi-stage-builds)
- [Networking and Ports](#networking-and-ports)
- [Health Checks](#health-checks)
- [Docker Compose](#docker-compose)
- [CI/CD Integration](#cicd-integration)
- [Documentation](#documentation)

---

## Dockerfile Structure

### General

- [ ] Dockerfile is in the repository root or a clearly identified location
- [ ] `.dockerignore` file exists and excludes unnecessary files (`.git`, `node_modules`, `bin`, `obj`, test output)
- [ ] Instructions are ordered from least to most frequently changing to maximise layer cache reuse
- [ ] Each `RUN` instruction has a clear, single purpose
- [ ] `WORKDIR` is set explicitly — no relying on default working directory
- [ ] `COPY` paths are explicit and minimal (copy only what the build step needs)

### Instruction Best Practices

- [ ] `RUN` commands that install packages combine update and install in one layer (`apt-get update && apt-get install -y ...`) with `--no-install-recommends`
- [ ] Package manager caches are cleaned in the same `RUN` layer (`rm -rf /var/lib/apt/lists/*`)
- [ ] `CMD` is used for the default command; `ENTRYPOINT` is used when the container is always a specific executable
- [ ] `ENTRYPOINT` uses exec form (`["executable", "arg"]`), not shell form, to handle signals correctly
- [ ] `CMD` uses exec form unless shell processing is required
- [ ] `SHELL` instruction is used if non-default shell behaviour is needed (e.g., bash features)

---

## Base Images

### Selection

- [ ] Base images are from official or verified publishers (Microsoft, Canonical, etc.)
- [ ] The smallest appropriate base image is used (`alpine`, `slim`, `distroless`, `-nanoserver`) unless a specific capability requires a larger image
- [ ] `distroless` or similar minimal images are used for final production stages
- [ ] Debug or development base images (`-sdk`, `-full`) are only used in build stages, not final images
- [ ] Base image is appropriate for the workload (e.g., `mcr.microsoft.com/dotnet/aspnet` for ASP.NET Core runtime)

### Pinning

- [ ] Base images are pinned to a specific version tag — never use `latest`
- [ ] Images are optionally pinned to digest (`image@sha256:...`) for maximum reproducibility in production
- [ ] Pinned versions are reviewed and updated on a regular cadence (dependency update process)
- [ ] Known vulnerable base image versions are not used (scanner must pass — see CI/CD section)

---

## Layer Optimisation

### Cache Efficiency

- [ ] `COPY` of dependency manifests (`*.csproj`, `package.json`, `packages.lock.json`) happens before application code `COPY`
- [ ] `dotnet restore` or `npm ci` runs immediately after copying manifests, before copying source
- [ ] Application source code is copied in a separate `COPY` instruction after dependency restore
- [ ] Files that change frequently are copied last

### Image Size

- [ ] Final image contains only what is needed to run (no build tools, test dependencies, or source code)
- [ ] Multi-stage builds are used to separate build artefacts from the runtime image
- [ ] Temporary files created during build are cleaned up in the same `RUN` layer
- [ ] `npm prune --production` or equivalent is run before copying `node_modules` to the runtime stage
- [ ] Image size is reasonable and has not grown unexpectedly (tracked in CI)

---

## Security

### Non-Root User

- [ ] Container runs as a non-root user in the final stage
- [ ] `USER` instruction sets a non-root user before `CMD`/`ENTRYPOINT`
- [ ] User is created in the Dockerfile if not present in the base image (`adduser` / `useradd`)
- [ ] File permissions are set correctly for the non-root user to read the application files

### Secrets

- [ ] No secrets, API keys, passwords, or connection strings in the Dockerfile or image layers
- [ ] Build-time secrets use `--secret` mount (BuildKit) — not `ARG` or `ENV` for sensitive values
- [ ] `ARG` values are not used for secrets (they are visible in image history via `docker history`)
- [ ] Runtime secrets are injected via environment variables, Key Vault references, or mounted secret volumes — not baked into the image

### Attack Surface

- [ ] Only required packages are installed in the final image
- [ ] Package managers (`apt`, `apk`) are removed or not available in the final stage where possible
- [ ] Shell access (`bash`, `sh`) is not available in production runtime images where distroless is used
- [ ] Read-only root filesystem is supported where possible (test with `docker run --read-only`)
- [ ] Capabilities are dropped in orchestration config (`--cap-drop ALL`) unless specific capabilities are needed

### Vulnerability Scanning

- [ ] Image is scanned with Trivy, Grype, or equivalent in CI
- [ ] No `CRITICAL` or `HIGH` CVEs in the final image without documented exception
- [ ] Base image updates are automated or reviewed on a fixed cadence
- [ ] Scanner results are published as pipeline artefacts for audit

---

## Build Arguments and Environment Variables

### ARG vs ENV

- [ ] `ARG` is used for build-time variables only (not available at runtime)
- [ ] `ENV` is used for runtime environment variables
- [ ] Sensitive values are never passed via `ARG` or `ENV` (use BuildKit secrets or runtime injection)
- [ ] `ARG` has a sensible default where appropriate; mandatory args are validated early in the build
- [ ] `ENV` variables that configure the application are documented

### Environment Configuration

- [ ] Environment-specific configuration is not baked into the image (12-factor app: config from environment)
- [ ] `ASPNETCORE_ENVIRONMENT`, `NODE_ENV`, and similar are set at runtime, not in the Dockerfile
- [ ] Default `ENV` values are safe for production (no `DEBUG=true` defaults)

---

## Multi-Stage Builds

### Stage Design

- [ ] Multi-stage builds are used for all production images
- [ ] Stages are named with `AS` for readability (e.g., `FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build`)
- [ ] Build stage contains all SDK, build tools, and test execution
- [ ] Final runtime stage copies only published output from the build stage
- [ ] Intermediate stages are used for dependency restore and build separation to maximise cache

### .NET Specifics

- [ ] `dotnet restore` is run with `--locked-mode` to enforce lock file use
- [ ] `dotnet publish` uses `-c Release` and appropriate runtime identifier if self-contained
- [ ] Published output is copied from `build` stage to final `runtime` stage with minimal `COPY`
- [ ] `mcr.microsoft.com/dotnet/aspnet` (runtime only) is used as the final base — not the SDK image

### Node/React Specifics

- [ ] `npm ci` is used over `npm install` for reproducible installs
- [ ] Build output (`/dist`, `/build`) is copied to the runtime stage, not the whole project
- [ ] `node_modules` are not copied to the runtime stage unless serving via Node (for static sites use nginx/caddy)
- [ ] Node version matches the project's `.nvmrc` or `engines` field in `package.json`

---

## Networking and Ports

- [ ] `EXPOSE` documents the port(s) the container listens on (even though it does not publish them)
- [ ] Only required ports are exposed
- [ ] Application listens on `0.0.0.0`, not `127.0.0.1`, within the container
- [ ] Port is configurable via environment variable for flexibility (`PORT`, `ASPNETCORE_URLS`)
- [ ] HTTP and HTTPS port behaviour is documented — TLS termination is handled at the load balancer/ingress in most Azure scenarios

---

## Health Checks

- [ ] `HEALTHCHECK` instruction is defined in the Dockerfile (or in orchestration config)
- [ ] Health check command is lightweight (does not add significant CPU/memory overhead)
- [ ] `--interval`, `--timeout`, `--start-period`, and `--retries` are set explicitly
- [ ] Start period accounts for application startup time (especially for .NET apps with warm-up)
- [ ] Health check endpoint returns a meaningful response (e.g., `GET /health` → 200)
- [ ] Health check distinguishes liveness from readiness where the orchestrator supports it (Kubernetes)

---

## Docker Compose

### Development Use

- [ ] `docker-compose.yml` is for local development only — production uses orchestration manifests
- [ ] Sensitive values in `docker-compose.yml` use `.env` file references — `.env` is in `.gitignore`
- [ ] `docker-compose.override.yml` is used for developer-specific overrides
- [ ] Service dependencies use `depends_on` with `condition: service_healthy` (not just `service_started`)
- [ ] Named volumes are used for persistent data rather than bind mounts in shared dev environments
- [ ] Port mappings do not conflict with common local service ports

### Compose File Quality

- [ ] `version:` is specified and appropriate (or omitted for Compose v2)
- [ ] Service names are lowercase and descriptive
- [ ] Resource limits (`mem_limit`, `cpus`) are set to prevent a single runaway service consuming all dev machine resources
- [ ] Networks are defined explicitly where service isolation is needed
- [ ] Health checks are defined on services that others depend on

---

## CI/CD Integration

### Build

- [ ] Docker image is built in CI using BuildKit (`DOCKER_BUILDKIT=1` or `docker buildx build`)
- [ ] Build cache is configured (e.g., `--cache-from` pointing to the registry)
- [ ] Image is tagged with the build number/git SHA and a mutable tag (e.g., `latest`, `main`)
- [ ] Image is pushed to Azure Container Registry (ACR) — not Docker Hub for production images
- [ ] ACR uses Geo-replication if deployed to multiple regions

### Scanning

- [ ] Trivy or Prisma/Aqua scan runs before push and fails the pipeline on critical/high CVEs
- [ ] Scan results are published as pipeline artefacts
- [ ] SBOM (Software Bill of Materials) is generated and attached to the image via attestation

### Signing and Trust

- [ ] Images are signed (Notation/Cosign) for production deployments where supply chain control is required
- [ ] ACR Content Trust is enabled for production registries where supported
- [ ] Image digest (not just tag) is used in deployment manifests for immutable references

---

## Documentation

### Inline

- [ ] Non-obvious `RUN` instructions have a comment explaining the reason
- [ ] Build argument purposes are documented inline
- [ ] Any workaround for a known base image issue references the upstream issue

### README / Wiki

- [ ] Repository documents how to build and run the container locally
- [ ] Required environment variables are listed with descriptions and example values
- [ ] Health check endpoint is documented
- [ ] Image tagging and versioning strategy is documented

---

## Review Checklist Summary

Before approving a PR, ensure:

1. **Base Image**: Pinned to specific version; smallest appropriate image; not `latest`
2. **Multi-Stage**: SDK/build tools not in final image; published output only
3. **Non-Root**: `USER` set to non-root in final stage
4. **Secrets**: No secrets in layers or `ARG`/`ENV`; BuildKit secrets or runtime injection used
5. **Layer Order**: Dependencies copied and restored before source code
6. **Scanning**: Trivy scan passes; no critical/high CVEs
7. **Health Check**: `HEALTHCHECK` defined with appropriate timing parameters
8. **`.dockerignore`**: Present and excludes build artifacts and secrets
9. **Environment Config**: Not baked in; injected at runtime
10. **Documentation**: Build instructions and environment variables documented

---

## Customisation Notes

- Add your ACR registry URL and naming convention
- Reference your approved base image versions and update schedule
- Add your Trivy/scanner threshold configuration
- Reference your image signing setup (Notation/Cosign)
- Add your Azure Container Apps or AKS deployment manifest standards