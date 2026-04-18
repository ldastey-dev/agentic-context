# Docker Standards — Containers, Images & Build Optimisation

Every container image must be minimal, secure, and reproducible. Production images must run as non-root, use multi-stage builds to exclude build tooling, pin base images to specific versions, and pass vulnerability scanning with no unresolved critical or high CVEs.

> **Cross-reference:** For generic container security principles (minimal images, non-root, scanning), see `standards/iac.md` S3.

---

## 1 · Dockerfile Structure

### 1.1 · General

- The Dockerfile must be in the repository root or a clearly identified location.
- A `.dockerignore` file must exist and must exclude unnecessary files (`.git`, `node_modules`, `bin`, `obj`, test output).
- Instructions must be ordered from least to most frequently changing to maximise layer cache reuse.
- Each `RUN` instruction must have a clear, single purpose.
- `WORKDIR` must always be set explicitly — never rely on the default working directory.
- `COPY` paths must be explicit and minimal — copy only what the build step needs.

### 1.2 · Instruction Best Practices

- `RUN` commands that install packages must combine update and install in one layer (`apt-get update && apt-get install -y ...`) with `--no-install-recommends`.
- Package manager caches must be cleaned in the same `RUN` layer (`rm -rf /var/lib/apt/lists/*`).
- `CMD` must be used for the default command; `ENTRYPOINT` must be used when the container always runs a specific executable.
- `ENTRYPOINT` must use exec form (`["executable", "arg"]`), never shell form, to handle signals correctly.
- `CMD` must use exec form unless shell processing is required.
- The `SHELL` instruction must be used if non-default shell behaviour is needed (e.g., bash features).

---

## 2 · Base Images

### 2.1 · Selection

- Base images must be from official or verified publishers (Microsoft, Canonical, etc.).
- The smallest appropriate base image must be used (`alpine`, `slim`, `distroless`, `-nanoserver`) unless a specific capability requires a larger image.
- `distroless` or similar minimal images must be used for final production stages.
- Debug or development base images (`-sdk`, `-full`) must only be used in build stages, never in final images.
- The base image must be appropriate for the workload (e.g., `mcr.microsoft.com/dotnet/aspnet` for ASP.NET Core runtime).

### 2.2 · Pinning

- Base images must always be pinned to a specific version tag — never use `latest`.
- Images must optionally be pinned to digest (`image@sha256:...`) for maximum reproducibility in production.
- Pinned versions must be reviewed and updated on a regular cadence (dependency update process).
- Known vulnerable base image versions must never be used (scanner must pass — see CI/CD section).

---

## 3 · Layer Optimisation

### 3.1 · Cache Efficiency

- `COPY` of dependency manifests (`*.csproj`, `package.json`, `packages.lock.json`) must happen before application code `COPY`.
- `dotnet restore` or `npm ci` must run immediately after copying manifests, before copying source.
- Application source code must be copied in a separate `COPY` instruction after dependency restore.
- Files that change frequently must always be copied last.

### 3.2 · Image Size

- The final image must contain only what is needed to run — never include build tools, test dependencies, or source code.
- Multi-stage builds must be used to separate build artefacts from the runtime image.
- Temporary files created during build must be cleaned up in the same `RUN` layer.
- `npm prune --production` or equivalent must be run before copying `node_modules` to the runtime stage.
- Image size must be reasonable and must not grow unexpectedly (tracked in CI).

---

## 4 · Security

### 4.1 · Non-Root User

- Containers must always run as a non-root user in the final stage.
- The `USER` instruction must set a non-root user before `CMD`/`ENTRYPOINT`.
- The user must be created in the Dockerfile if not present in the base image (`adduser` / `useradd`).
- File permissions must be set correctly for the non-root user to read the application files.

### 4.2 · Secrets

- Secrets, API keys, passwords, and connection strings must never appear in the Dockerfile or image layers.
- Build-time secrets must use `--secret` mount (BuildKit) — never use `ARG` or `ENV` for sensitive values.
- `ARG` values must never be used for secrets (they are visible in image history via `docker history`).
- Runtime secrets must be injected via environment variables, Key Vault references, or mounted secret volumes — never baked into the image.

### 4.3 · Attack Surface

- Only required packages must be installed in the final image.
- Package managers (`apt`, `apk`) must be removed or unavailable in the final stage where possible.
- Shell access (`bash`, `sh`) must not be available in production runtime images where distroless is used.
- Read-only root filesystem must be supported where possible (test with `docker run --read-only`).
- Capabilities must be dropped in orchestration configuration (`--cap-drop ALL`) unless specific capabilities are needed.

### 4.4 · Vulnerability Scanning

- Every image must be scanned with Trivy, Grype, or equivalent in CI.
- No `CRITICAL` or `HIGH` CVEs must remain in the final image without a documented exception.
- Base image updates must be automated or reviewed on a fixed cadence.
- Scanner results must be published as pipeline artefacts for audit.

---

## 5 · Build Arguments and Environment Variables

### 5.1 · ARG vs ENV

- `ARG` must be used for build-time variables only (not available at runtime).
- `ENV` must be used for runtime environment variables.
- Sensitive values must never be passed via `ARG` or `ENV` — always use BuildKit secrets or runtime injection.
- `ARG` must have a sensible default where appropriate; mandatory args must be validated early in the build.
- `ENV` variables that configure the application must always be documented.

### 5.2 · Environment Configuration

- Environment-specific configuration must never be baked into the image (12-factor app: configuration from the environment).
- `ASPNETCORE_ENVIRONMENT`, `NODE_ENV`, and similar must be set at runtime, never in the Dockerfile.
- Default `ENV` values must always be safe for production — never set `DEBUG=true` as a default.

---

## 6 · Multi-Stage Builds

### 6.1 · Stage Design

- Multi-stage builds must be used for all production images.
- Stages must be named with `AS` for readability (e.g., `FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build`).
- The build stage must contain all SDK, build tools, and test execution.
- The final runtime stage must copy only published output from the build stage.
- Intermediate stages must be used for dependency restore and build separation to maximise cache.

### 6.2 · .NET Specifics

- `dotnet restore` must be run with `--locked-mode` to enforce lock file use.
- `dotnet publish` must use `-c Release` and an appropriate runtime identifier if self-contained.
- Published output must be copied from the `build` stage to the final `runtime` stage with minimal `COPY`.
- `mcr.microsoft.com/dotnet/aspnet` (runtime only) must be used as the final base — never the SDK image.

### 6.3 · Node/React Specifics

- `npm ci` must always be used over `npm install` for reproducible installs.
- Build output (`/dist`, `/build`) must be copied to the runtime stage, never the whole project.
- `node_modules` must not be copied to the runtime stage unless serving via Node (for static sites, use nginx or caddy).
- The Node version must match the project's `.nvmrc` or `engines` field in `package.json`.

---

## 7 · Networking and Ports

- `EXPOSE` must document the port(s) the container listens on (even though it does not publish them).
- Only required ports must be exposed.
- The application must listen on `0.0.0.0`, never `127.0.0.1`, within the container.
- The port must be configurable via environment variable for flexibility (`PORT`, `ASPNETCORE_URLS`).
- HTTP and HTTPS port behaviour must be documented — TLS termination is handled at the load balancer or ingress in most Azure scenarios.

---

## 8 · Health Checks

- A `HEALTHCHECK` instruction must be defined in the Dockerfile (or in orchestration configuration).
- The health check command must be lightweight and must not add significant CPU or memory overhead.
- `--interval`, `--timeout`, `--start-period`, and `--retries` must always be set explicitly.
- Start period must account for application startup time (especially for .NET apps with warm-up).
- The health check endpoint must return a meaningful response (e.g., `GET /health` returning 200).
- Health checks must distinguish liveness from readiness where the orchestrator supports it (Kubernetes).

---

## 9 · Docker Compose

### 9.1 · Development Use

- `docker-compose.yml` must be for local development only — production must use orchestration manifests.
- Sensitive values in `docker-compose.yml` must use `.env` file references — `.env` must be in `.gitignore`.
- `docker-compose.override.yml` must be used for developer-specific overrides.
- Service dependencies must use `depends_on` with `condition: service_healthy`, never just `service_started`.
- Named volumes must be used for persistent data rather than bind mounts in shared development environments.
- Port mappings must not conflict with common local service ports.

### 9.2 · Compose File Quality

- `version:` must be specified and appropriate (or omitted for Compose v2).
- Service names must be lowercase and descriptive.
- Resource limits (`mem_limit`, `cpus`) must be set to prevent a single runaway service from consuming all development machine resources.
- Networks must be defined explicitly where service isolation is needed.
- Health checks must be defined on services that others depend on.

---

## 10 · CI/CD Integration

### 10.1 · Build

- Docker images must be built in CI using BuildKit (`DOCKER_BUILDKIT=1` or `docker buildx build`).
- Build cache must be configured (e.g., `--cache-from` pointing to the registry).
- Images must be tagged with the build number or git SHA and a mutable tag (e.g., `latest`, `main`).
- Images must be pushed to Azure Container Registry (ACR) — never use Docker Hub for production images.
- ACR must use geo-replication if deployed to multiple regions.

### 10.2 · Scanning

- Trivy or Prisma/Aqua scan must run before push and must fail the pipeline on critical or high CVEs.
- Scan results must be published as pipeline artefacts.
- An SBOM (Software Bill of Materials) must be generated and attached to the image via attestation.

### 10.3 · Signing and Trust

- Images must be signed (Notation/Cosign) for production deployments where supply chain control is required.
- ACR Content Trust must be enabled for production registries where supported.
- Image digest (not just tag) must be used in deployment manifests for immutable references.

---

## 11 · Documentation

### 11.1 · Inline

- Non-obvious `RUN` instructions must always have a comment explaining the reason.
- Build argument purposes must be documented inline.
- Any workaround for a known base image issue must reference the upstream issue.

### 11.2 · README / Wiki

- The repository must document how to build and run the container locally.
- Required environment variables must be listed with descriptions and example values.
- The health check endpoint must be documented.
- The image tagging and versioning strategy must be documented.

---

## Non-Negotiables

- Base images must always be pinned to a specific version tag — never use `latest`.
- Containers must always run as a non-root user in the final stage.
- Secrets must never appear in the Dockerfile, `ARG`, `ENV`, or any image layer.
- Multi-stage builds must be used for all production images — SDK and build tools must never be in the final image.
- Every image must pass vulnerability scanning with no unresolved `CRITICAL` or `HIGH` CVEs.
- A `.dockerignore` file must always exist and must exclude `.git`, `node_modules`, build artefacts, and secrets.
- Environment-specific configuration must never be baked into the image — always inject at runtime.

---

## Decision Checklist

- [ ] Base image is from an official or verified publisher and pinned to a specific version
- [ ] Multi-stage build separates SDK/build tools from the final runtime image
- [ ] `USER` instruction sets a non-root user before `CMD`/`ENTRYPOINT`
- [ ] No secrets, API keys, or connection strings appear in the Dockerfile or image layers
- [ ] Dependency manifests are copied and restored before application source code
- [ ] Trivy or equivalent scan passes with no critical or high CVEs
- [ ] `HEALTHCHECK` is defined with appropriate `--interval`, `--timeout`, `--start-period`, and `--retries`
- [ ] `.dockerignore` is present and excludes build artefacts, `.git`, and secrets
- [ ] Environment configuration is injected at runtime, never baked into the image
- [ ] `ENTRYPOINT` and `CMD` use exec form for correct signal handling
- [ ] Build uses BuildKit with cache configured for the registry
- [ ] Images are pushed to ACR and tagged with build number or git SHA
- [ ] Image signing is configured for production deployments where required
- [ ] Required environment variables are documented with descriptions and examples
- [ ] Docker Compose files use `service_healthy` conditions and resource limits
