# PR #23 Refactoring Status Tracker

## Overview
- **Repository:** https://github.com/ldastey-dev/agentic-context
- **PR:** #23 "Add skills for setting up local otel stack"
- **Branch:** feature/otel-skills
- **Current Phase:** Phase 1 (Senior Engineers) — About to start
- **Last Updated:** 2026-08-02 15:15 UTC

---

## Phase 1: Senior Engineers (Main Work)

### Contribution 1: OTel Stack Infrastructure Playbooks
**Owner:** Senior Engineer 1 (SRE)  
**Status:** 🔲 NOT STARTED  
**Target Completion:** —

**Tasks:**
- [ ] Review and verify `playbooks/setup/create-local-otel-stack.md`
  - Add backend-agnostic note about VictoriaMetrics vs. other options
  - Verify all container configs are correct
  - Check version management (versions.env)
- [ ] Update `playbooks/setup/discover-local-otel-stack.md`
  - Verify health check endpoints
  - Update cross-references to new standards
- [ ] Update `playbooks/setup/use-local-otel-stack.md`
  - Verify endpoint configuration patterns
  - Add link to new opentelemetry.md standard
  - Update cross-references
- [ ] Review supporting scripts
  - `create-local-otel-stack/start-local-otel-stack.sh` ✓
  - `create-local-otel-stack/Start-LocalOtelStack.ps1` ✓
  - `create-local-otel-stack/validate-config.sh` ✓
  - `create-local-otel-stack/test-local-otel-stack.sh` ✓
  - `create-local-otel-stack/docker-compose.yaml` ✓
  - `create-local-otel-stack/otel-collector-*.yaml` ✓
  - `create-local-otel-stack/versions.env` ✓
- [ ] Run validation: `validate-config.sh`
- [ ] Run smoke tests: `test-local-otel-stack.sh` (requires Podman)
- [ ] Push to feature/otel-skills
- [ ] Notify Coordinator when complete

**Deliverable:** Ready-to-merge Contribution 1 files with all scripts validated

---

### Contribution 2: .NET OpenTelemetry Standard
**Owner:** Senior Engineer 2 (Principal Engineer)  
**Status:** 🔲 NOT STARTED  
**Target Completion:** —

**Tasks:**
- [ ] Create `standards/opentelemetry-dotnet.md` from `playbooks/setup/instrument-dotnet-otel.md`
- [ ] Structure with `## N · Section Title` heading style (match `standards/dotnet.md`)
  - [ ] Section 1: SDK Selection and Installation
  - [ ] Section 2: Instrumentation Patterns
  - [ ] Section 3: Exporter Configuration
  - [ ] Section 4: Testing Patterns
  - [ ] Section 5: Pitfalls and Solutions
  - [ ] Section 6: Non-Negotiables
  - [ ] Section 7: Decision Checklist
- [ ] Review against `standards/dotnet.md` for duplication
  - Ensure no duplicate content (link instead if cross-cutting)
- [ ] Migrate all content from playbook:
  - [ ] NuGet packages → Section 1
  - [ ] Startup.cs canonical pattern → Section 2
  - [ ] Environment variables → Section 3
  - [ ] InMemory exporter test pattern → Section 4
  - [ ] Pitfalls 1, 2, 3 → Section 5 + Non-Negotiables
  - [ ] Related Skills → Related Standards (with links to playbooks)
- [ ] Add YAML frontmatter (for skill wrapper generation if deploying Copilot/Claude)
  ```yaml
  ---
  name: standard-opentelemetry-dotnet
  description: "OpenTelemetry SDK instrumentation patterns and anti-patterns for .NET applications"
  keywords: [opentelemetry dotnet, dotnet otel, .NET instrumentation, traces metrics logs]
  ---
  ```
- [ ] Verify all links work (playbooks, related standards)
- [ ] Use British English throughout
- [ ] Push to feature/otel-skills
- [ ] Notify Coordinator when complete

**Deliverable:** standards/opentelemetry-dotnet.md, properly structured and linked

---

### Contribution 3: Language-Agnostic OpenTelemetry Standard
**Owner:** Senior Engineer 3 (Architect)  
**Status:** 🔲 NOT STARTED  
**Target Completion:** —

**Tasks:**
- [ ] Create `standards/opentelemetry.md` from first principles
- [ ] Structure with `## N · Section Title` heading style
  - [ ] Section 1: OTel Principles (Semantic Conventions, SDK patterns)
  - [ ] Section 2: Core SDK Patterns (Resource, Traces, Metrics, Logs)
  - [ ] Section 3: OTLP Protocol (gRPC vs HTTP, signal paths, protobuf)
  - [ ] Section 4: Backends and Exporters (Jaeger, Tempo, Honeycomb, Datadog, X-Ray)
  - [ ] Section 5: Integration Patterns (networking, sidecar, context propagation)
  - [ ] Section 6: Pitfalls (cross-language)
  - [ ] Section 7: Non-Negotiables
  - [ ] Section 8: Decision Checklist
- [ ] Cover all languages/runtimes where applicable:
  - Go, Python, Java, Rust, Node.js, .NET, PHP, Ruby
- [ ] Link to language-specific standards (e.g., opentelemetry-dotnet.md for .NET details)
- [ ] Link to playbooks (create-local-otel-stack, use-local-otel-stack, discover-local-otel-stack)
- [ ] Include rationale for gRPC vs HTTP/protobuf (not just rules)
- [ ] Explain when to use automatic instrumentation vs. manual
- [ ] Add YAML frontmatter (for skill wrapper generation)
  ```yaml
  ---
  name: standard-opentelemetry
  description: "Language-agnostic OpenTelemetry SDK principles, patterns, OTLP protocol, and backends"
  keywords: [opentelemetry, otel, observability sdk, instrumentation, traces metrics logs, otlp]
  ---
  ```
- [ ] Verify all links work (playbooks, related standards)
- [ ] Use British English throughout
- [ ] Push to feature/otel-skills
- [ ] Notify Coordinator when complete

**Deliverable:** standards/opentelemetry.md, properly structured and linked

---

## Phase 2: Coordinator (Integration & Index Updates)

**Owner:** Coordinator  
**Status:** 🔲 NOT STARTED  
**Target Completion:** After Phase 1 complete

**Tasks:**
- [ ] Verify all 3 contributions pushed to feature/otel-skills
- [ ] Update `core/.context/index.md`
  - [ ] Add `opentelemetry-dotnet` to Standards table
  - [ ] Add `opentelemetry` to Standards table
  - [ ] Update or remove `instrument-dotnet-otel` from Setup Playbooks table
  - [ ] Verify keyword routes are correct
- [ ] Update `deploy.sh`
  - [ ] Add skill wrapper generation from `standards/opentelemetry-dotnet.md` (if Copilot/Claude)
  - [ ] Add skill wrapper generation from `standards/opentelemetry.md` (if Copilot/Claude)
  - [ ] Remove skill wrapper generation from `playbooks/setup/instrument-dotnet-otel.md`
- [ ] Update `deploy.ps1` (mirror changes from deploy.sh)
- [ ] Update `README.md` if needed
  - [ ] Note new standards in Repository Structure section
- [ ] Run link checker (e.g., `grep -r "instrument-dotnet-otel.md" .` to find stale references)
- [ ] Create comprehensive validation checklist
- [ ] Prepare for review team handoff

**Deliverable:** Validated, link-checked index and deploy scripts; ready for review team

---

## Phase 3: Review Team (Iteration)

**Participants:**
- SRE (Contribution 1)
- Principal Engineer (Contributions 2, 3)
- Architect (Contributions 2, 3)
- QA (All contributions)
- Security Engineer (All contributions)
- Observability Specialist (All contributions)
- Senior Technical Writer (All contributions)

**Status:** 🔲 NOT STARTED  
**Target Completion:** —

**Review Checklist (Per Speciality):**

#### SRE
- [ ] Container runtime compatibility (Podman, Docker, Rancher, WSL2)
- [ ] Networking patterns correct (localhost, host.containers.internal)
- [ ] Health checks comprehensive and reliable
- [ ] Port mappings non-conflicting
- [ ] Version pinning and image registries secure
- [ ] Cleanup scripts idempotent
- [ ] Smoke tests pass in CI environments

#### Principal Engineer
- [ ] Contribution 2 aligns with `standards/dotnet.md`
- [ ] No duplication with existing .NET standard
- [ ] Startup.cs pattern matches team conventions
- [ ] OTEL SDK API usage correct (no deprecated patterns)
- [ ] Framework alignment (ASP.NET Core 6+, latest OTel packages)

#### Architect
- [ ] Contribution 3 covers all languages/runtimes
- [ ] SDK patterns are truly language-agnostic
- [ ] Extensibility clear (how to add new language standards)
- [ ] Backend-agnostic guidance sound
- [ ] Integration patterns (sidecar, direct, gateway) complete

#### QA
- [ ] All markdown links valid (no stale references)
- [ ] Keyword routes complete and correct
- [ ] Index.md table formatting consistent
- [ ] Deploy scripts handle new standards correctly
- [ ] No circular references
- [ ] Frontmatter YAML valid

#### Security Engineer
- [ ] No credentials in examples or defaults
- [ ] Container image versions pinned (no `latest`)
- [ ] Registries (ghcr.io, docker.io) verified
- [ ] No secrets exposed in logs
- [ ] Network isolation correct (Podman pod, Docker network)
- [ ] Secrets management guidance present (if applicable)

#### Observability Specialist
- [ ] SDK instrumentation patterns match OTEL Semantic Conventions
- [ ] All three signal types covered (traces, metrics, logs)
- [ ] Correlation IDs and trace context correct
- [ ] Sampling strategies explained (if relevant)
- [ ] Resource attributes complete
- [ ] Backend query examples work

#### Senior Technical Writer
- [ ] British English throughout (no "color", use "colour")
- [ ] Kebab-case file names
- [ ] Consistent heading style (`## N · Title`)
- [ ] Examples clear and runnable
- [ ] Tone matches repository conventions
- [ ] No emoji
- [ ] Related sections properly linked

**Deliverable:** Feedback comments on PR #23

---

## Phase 4: Integration & Final QA

**Owner:** Coordinator + Senior Engineers  
**Status:** 🔲 NOT STARTED  
**Target Completion:** —

**Tasks:**
- [ ] Address all review team feedback
- [ ] Coordinate iterations with senior engineers
- [ ] Run deploy.sh against scratch directory
  ```bash
  mkdir /tmp/agentic-context-test
  ./deploy.sh /tmp/agentic-context-test --agents claude-code,copilot
  ```
- [ ] Run deploy.ps1 against scratch directory (Windows)
- [ ] Verify all skill wrappers generate correctly
- [ ] Test keyword routing in `.context/index.md`
- [ ] Verify no broken links
- [ ] Run all validation scripts
  ```bash
  playbooks/setup/create-local-otel-stack/validate-config.sh
  ```
- [ ] Run smoke tests (if Podman available)
  ```bash
  timeout 120 playbooks/setup/create-local-otel-stack/test-local-otel-stack.sh
  ```
- [ ] Final PR review sweep
- [ ] Mark PR as ready to merge

**Deliverable:** Merge-ready PR #23 with all feedback addressed

---

## File Status Checklist

### PR #23 Currently Has:

#### ✅ Already Correct (Contribution 1)
- [ ] `playbooks/setup/create-local-otel-stack.md`
- [ ] `playbooks/setup/discover-local-otel-stack.md`
- [ ] `playbooks/setup/use-local-otel-stack.md`
- [ ] `playbooks/setup/create-local-otel-stack/start-local-otel-stack.sh`
- [ ] `playbooks/setup/create-local-otel-stack/Start-LocalOtelStack.ps1`
- [ ] `playbooks/setup/create-local-otel-stack/validate-config.sh`
- [ ] `playbooks/setup/create-local-otel-stack/test-local-otel-stack.sh`
- [ ] `playbooks/setup/create-local-otel-stack/docker-compose.yaml`
- [ ] `playbooks/setup/create-local-otel-stack/otel-collector-config.yaml`
- [ ] `playbooks/setup/create-local-otel-stack/otel-collector-config-compose.yaml`
- [ ] `playbooks/setup/create-local-otel-stack/otel-collector-sidecar-config.yaml`
- [ ] `playbooks/setup/create-local-otel-stack/versions.env`

#### 🔄 Needs Migration (Contribution 2)
- [ ] `playbooks/setup/instrument-dotnet-otel.md` → `standards/opentelemetry-dotnet.md`

#### 🆕 Needs Creation (Contribution 3)
- [ ] CREATE `standards/opentelemetry.md`

#### 🔄 Needs Updates (Coordinator)
- [ ] `core/.context/index.md` — Add standards, update playbook entries
- [ ] `deploy.sh` — Add skill wrappers for new standards
- [ ] `deploy.ps1` — Add skill wrappers for new standards
- [ ] `README.md` — Update Repository Structure if applicable

---

## Notes & Blockers

- **No blockers identified** — all work is independent and can proceed in parallel
- **Validation requires Podman** — smoke tests need container runtime; can skip in pure CI
- **Deploy script testing requires scratch directory** — never run against this repo
- **All changes are additive** — no breaking changes to existing standards or playbooks

---

## Communication

- **Coordinator:** Posts updates in PR #23 comments
- **Senior Engineers:** Push to feature/otel-skills when tasks complete; notify Coordinator
- **Review Team:** Posts domain-specific feedback in PR #23
- **Final Merge:** Coordinator confirms all feedback addressed, PR is merged

---

