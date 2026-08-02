# PR #23 Refactoring Coordination Document

**Status:** Discovery Phase Complete  
**Repository:** https://github.com/ldastey-dev/agentic-context  
**Branch:** `feature/otel-skills` (by djpnicholls)  
**PR:** #23 "Add skills for setting up local otel stack"  
**Date Created:** 2026-08-02  

---

## Executive Summary

PR #23 adds four new playbooks for OpenTelemetry setup and instrumentation. To make these universally applicable and non-duplicative, we are refactoring into **three separate contributions**:

1. **Contribution 1 (Playbooks):** Infrastructure setup playbooks — `create-local-otel-stack`, `discover-local-otel-stack`, `use-local-otel-stack`
2. **Contribution 2 (Standard):** .NET-specific OpenTelemetry standard — extracted from `instrument-dotnet-otel` playbook
3. **Contribution 3 (Standard):** Language-agnostic OpenTelemetry standard — canonical patterns for all languages/runtimes

This ensures:
- No duplication of standards across the repository
- Language-specific guidance lives in language-specific standards
- Generic OTel principles live in a cross-cutting standard
- Playbooks remain focused on operational procedures

---

## Current State Analysis

### Files in PR #23

| File | Type | Lines | Status |
|------|------|-------|--------|
| `playbooks/setup/create-local-otel-stack.md` | Playbook | 320 | Keep as-is (Contrib 1) |
| `playbooks/setup/discover-local-otel-stack.md` | Playbook | 91 | Keep as-is (Contrib 1) |
| `playbooks/setup/use-local-otel-stack.md` | Playbook | 147 | Keep as-is (Contrib 1) |
| `playbooks/setup/instrument-dotnet-otel.md` | Playbook → Standard | 221 | Migrate to standard (Contrib 2) |
| `playbooks/setup/create-local-otel-stack/` | Directory | — | Keep as-is (Contrib 1) |
| Supporting scripts | — | 1100+ | Keep as-is (Contrib 1) |
| `core/.context/index.md` | Index | — | Update keywords (Contrib 2, 3) |
| `deploy.sh`, `deploy.ps1` | Scripts | — | Update for skill wrappers (Contrib 2) |

**Total changes:** 779 lines of playbook content + 1100+ lines of shell/PS scripts

### Existing Baseline

| Artifact | Current State |
|----------|---------------|
| `standards/observability.md` | High-level OTEL principles (logging, tracing, metrics) |
| `standards/dotnet.md` | .NET architecture, SOLID, async patterns, ASP.NET Core, EF Core |
| `core/.context/index.md` | Keyword router for standards and playbooks |
| Deploy scripts | Generate skill wrappers from playbook frontmatter (Claude/Copilot) |

**Key Insight:** The existing `standards/observability.md` is a high-level reference. Contribution 3 will be a more granular, SDK-focused standard.

---

## Three Contributions Mapped

### Contribution 1: OTel Stack Infrastructure Playbooks

**Status:** ✅ Already correctly structured  
**Files:**
- `playbooks/setup/create-local-otel-stack.md`
- `playbooks/setup/discover-local-otel-stack.md`
- `playbooks/setup/use-local-otel-stack.md`
- `playbooks/setup/create-local-otel-stack/` directory (scripts, configs, versions)

**Changes:**
1. ✅ Add backend-agnostic note: "VictoriaMetrics is one recommended option; other OTEL-compatible backends (Grafana Tempo, Jaeger, DataDog) also work."
2. ✅ Update cross-references in `## Related Skills` sections to point to new standards
3. ✅ Ensure all keyword routes are in `core/.context/index.md` ← Already present in PR

**Owner:** Senior Engineer 1 (SRE focus)

---

### Contribution 2: .NET OpenTelemetry Standard

**Status:** 🔄 Needs creation from playbook content  
**Source:** `playbooks/setup/instrument-dotnet-otel.md` (221 lines)

**Target File:** `standards/opentelemetry-dotnet.md`

**Migration:**
1. Extract canonical patterns from playbook
2. Adopt `standards/dotnet.md` heading style (`## N · Section Title`)
3. Combine with existing .NET standard guidance
4. Add sections:
   - Instrumentation patterns (traces, metrics, logs)
   - NuGet package selection
   - Configuration patterns (Startup.cs, appsettings.json)
   - Integration testing patterns (InMemory exporter)
   - Known pitfalls → Non-Negotiables
   - Decision checklist

**Structure:**
```
# OpenTelemetry Standard for .NET

## 1 · SDK Selection and Installation
   - NuGet packages (when to use which)
   - Version compatibility

## 2 · Instrumentation Patterns
   - Resource configuration (service name, version, environment)
   - Traces (OTEL Trace conventions)
   - Metrics (OTEL Metrics conventions)
   - Logs (structured JSON, OTEL Log conventions)

## 3 · Exporter Configuration
   - OTLP (gRPC vs HTTP/protobuf)
   - Environment variable pattern
   - Code-based configuration (when, when not)

## 4 · Testing
   - Unit tests with InMemory exporter
   - Integration tests with local stack
   - Assertions on telemetry payload

## 5 · Pitfalls and Solutions
   - Explicit endpoint breaks signal path appending (Pitfall 1 from playbook)
   - gRPC vs HTTP/protobuf (Pitfall 2 from playbook)
   - ActivityListener pollution in test suites (Pitfall 3 from playbook)

## Non-Negotiables
   [Derived from pitfalls]

## Decision Checklist
   [For SDK setup tasks]
```

**Content Harvest:**
- Startup.cs canonical pattern → Section 2
- NuGet packages → Section 1
- Environment variables → Section 3
- Pitfalls 1, 2, 3 → Section 5 + Non-Negotiables
- InMemory exporter test pattern → Section 4

**Playbook Post-Migration:**
- `playbooks/setup/instrument-dotnet-otel.md` is removed or repurposed as a thin playbook that links to the new standard

**Owner:** Senior Engineer 2 (Principal Engineer focus)

---

### Contribution 3: Language-Agnostic OpenTelemetry Standard

**Status:** 🔄 Needs creation (no existing playbook content)  
**Target File:** `standards/opentelemetry.md`

**Audience:** Platform engineers, SREs, observability specialists deploying OTel SDKs in any language.

**Sections:**
```
# OpenTelemetry Standard (Cross-Language)

## 1 · OTel Principles
   - Semantic Conventions (logs, traces, metrics)
   - Instrumentation vs. automatic instrumentation
   - Exporters and backends (OTLP, Jaeger, Tempo, Datadog, etc.)
   - Sampling strategies

## 2 · SDK Patterns (Language-Agnostic)
   - Resource setup (service name, version, environment, attributes)
   - Traces (span context, attributes, status)
   - Metrics (instruments: counters, histograms, gauges)
   - Logs (structured JSON, severity, correlation)

## 3 · OTLP Protocol
   - Receiver types: gRPC (:4317), HTTP (:4318)
   - Signal paths (/v1/traces, /v1/metrics, /v1/logs)
   - Protobuf vs. JSON encoding

## 4 · Backends
   - Backend-agnostic principles
   - Common backends: Jaeger, Grafana Tempo, Honeycomb, Datadog, AWS X-Ray
   - Local development: VictoriaMetrics stack (link to playbook)
   - Production concerns: retention, sampling, cost

## 5 · Integration Patterns
   - Service-to-collector networking (localhost, host.containers.internal, remote)
   - Sidecar pattern (collectors in containers)
   - Multi-service tracing (trace ID propagation)
   - Testing with local stack (link to playbooks)

## 6 · Pitfalls (Cross-Language)
   - Port reachability (4317 gRPC vs 4318 HTTP via host.containers.internal)
   - Sampling configuration (head-based vs. tail-based)
   - Trace context propagation (W3C TraceContext, Jaeger headers)
   - Library instrumentation conflicts

## Non-Negotiables
   [Minimum SDK requirements across languages]

## Decision Checklist
   [For OTel SDK adoption decisions]
```

**Content Sources:**
- OTEL documentation and semantic conventions
- Playbook patterns from `use-local-otel-stack.md` (endpoint config, host.containers.internal patterns)
- Playbook patterns from `create-local-otel-stack.md` (collector configuration, backends)
- Playbook patterns from `discover-local-otel-stack.md` (health checks, validation)
- Cross-reference to `standards/opentelemetry-dotnet.md` for .NET-specific details

**Key Distinguishers:**
- Explains *why* (semantics, principles)
- Covers *all* languages (Go, Python, Java, Rust, Node, .NET, etc.)
- Shows when to use gRPC vs HTTP/protobuf (technology-agnostic rationale)
- Links to language-specific standards for implementation details

**Owner:** Senior Engineer 3 (Architect focus)

---

## Index Updates Required

### `core/.context/index.md` Changes

**Current (in PR):**
```markdown
| instrument dotnet, dotnet otel, opentelemetry dotnet, dotnet sdk otel | `.context/playbooks/setup/instrument-dotnet-otel.md` | Instrument a .NET service with OpenTelemetry SDK |
```

**After Contribution 2:**
- Remove or update `instrument-dotnet-otel.md` entry
- Add to Standards table: `| opentelemetry dotnet, dotnet otel, .NET instrumentation | `.context/standards/opentelemetry-dotnet.md` | OpenTelemetry SDK patterns for .NET |`

**After Contribution 3:**
- Add to Standards table: `| opentelemetry, otel, observability sdk, instrumentation, traces metrics logs | `.context/standards/opentelemetry.md` | Language-agnostic OpenTelemetry SDK principles and patterns |`

---

## Deploy Script Updates

### `deploy.sh` and `deploy.ps1`

**Current (in PR):**
- Skill wrappers are generated from `playbooks/setup/instrument-dotnet-otel.md` frontmatter

**After Contributions 2 & 3:**
- Remove `instrument-dotnet-otel.md` skill wrapper generation (it becomes a standard)
- Add skill wrapper generation from `standards/opentelemetry-dotnet.md` frontmatter (if deploying Claude/Copilot agents)
- Add skill wrapper generation from `standards/opentelemetry.md` frontmatter (if deploying Claude/Copilot agents)

**Note:** Standards can have optional frontmatter for skill generation; the choice is per-agent. Devin and Cursor do not generate skills from standards, only from playbooks.

---

## Content Mapping: Current → Target

### Playbook `instrument-dotnet-otel.md` → Standard `opentelemetry-dotnet.md`

| Current Section | Target Section | Notes |
|-----------------|-----------------|-------|
| Frontmatter (name, description, keywords) | Frontmatter (converted to standard format) | Update for skill wrapper generation |
| `## NuGet packages` | `## 1 · SDK Selection → NuGet Packages` | Expand selection rationale |
| `## Startup.cs — canonical pattern` | `## 2 · Instrumentation Patterns → Resource & Startup` | Add explanations |
| `## Environment variables` | `## 3 · Exporter Configuration` | Add OTLP protocol rationale |
| `## Known pitfalls` (1, 2, 3) | `## 5 · Pitfalls and Solutions` + `## Non-Negotiables` | Each pitfall → checklist item |
| `## Related Skills` | `## Related Standards` + links to playbooks | Update for new structure |

---

## Review Team Assignments

| Speciality | Focus | Contribution(s) |
|-----------|-------|-----------------|
| **SRE** | Container orchestration, networking, health checks | Contrib 1 |
| **Principal Engineer** | Architecture consistency, framework alignment, .NET patterns | Contrib 2, 3 |
| **Architect** | System design, extensibility for other languages, SDK patterns | Contrib 2, 3 |
| **QA** | Markdown links, keyword routing, deploy script integration | All |
| **Security Engineer** | Secrets in logs, container defaults, version pinning, registries | Contrib 1, 2, 3 |
| **Observability Specialist** | SDK best practices, instrumentation completeness, OTel conventions | All |
| **Senior Technical Writer** | Documentation clarity, conventions compliance, examples | All |

---

## Files NOT Changing

- `standards/observability.md` — Remains high-level, cross-cutting (logging, tracing, metrics principles)
- `standards/dotnet.md` — Remains focused on C#, ASP.NET Core, EF Core (not OTel-specific)
- `README.md` — Already updated in PR; no further changes needed
- All test fixtures and validation scripts — Remain as-is

---

## Next Steps

### Phase 1: Senior Engineers (Main Work)

**Senior Engineer 1 (Playbooks / SRE):**
1. Review `playbooks/setup/create-local-otel-stack.md` for backend-agnostic note
2. Update cross-references in all three playbooks to new standards
3. Verify all scripts, configs, versions are correct
4. Run `validate-config.sh` and smoke tests
5. Commit and push to `feature/otel-skills`

**Senior Engineer 2 (.NET Standard / Principal Engineer):**
1. Create `standards/opentelemetry-dotnet.md` from `instrument-dotnet-otel.md` content
2. Match `standards/dotnet.md` heading style and structure
3. Ensure no duplication with existing `standards/dotnet.md`
4. Add Decision Checklist and Non-Negotiables sections
5. Update frontmatter for skill wrapper generation (if applicable)
6. Commit and push to `feature/otel-skills`

**Senior Engineer 3 (OTel Standard / Architect):**
1. Create `standards/opentelemetry.md` from first principles
2. Cover language-agnostic SDK patterns, protocols, backends
3. Link to language-specific standards (opentelemetry-dotnet.md, future opentelemetry-go.md, etc.)
4. Add Decision Checklist and Non-Negotiables sections
5. Update frontmatter for skill wrapper generation (if applicable)
6. Commit and push to `feature/otel-skills`

### Phase 2: Coordinator (Integration & Index)

1. Collect all outputs from senior engineers
2. Update `core/.context/index.md` with new standard keyword routes
3. Update `deploy.sh` and `deploy.ps1` for new skill wrappers
4. Verify no broken links across all files
5. Prepare for review team

### Phase 3: Review Team (Iteration)

1. Each speciality reviews their domain
2. Post comments on PR #23
3. Coordinator collects feedback
4. Senior engineers iterate on their contributions
5. Repeat until all feedback addressed

### Phase 4: Integration & QA

1. Test deploy scripts against scratch directory
2. Run all validation scripts
3. Verify skill wrappers generate correctly
4. Confirm keyword routing works
5. Final PR review and merge

---

## Success Criteria

- ✅ All 3 contributions properly structured
- ✅ No duplicated content across files
- ✅ All cross-references intact and working
- ✅ Deploy scripts updated and tested
- ✅ All review team feedback addressed
- ✅ Merge-ready state with no open comments on PR #23

---

## Known Constraints

1. **This repo is a template library**, not a target repo — do not run `deploy.sh` against this directory
2. **Standards are singular** — one canonical home per rule (no language-specific copies in per-agent files)
3. **Playbooks stay operational** — they remain procedures, not principles
4. **Deploy scripts must stay equivalent** — any change to bash must be mirrored in PowerShell
5. **Skill wrappers are regenerated** — hand-edited wrappers will be overwritten by `deploy.sh`

---

## References

- **Template Standards:** `standards/dotnet.md`, `standards/react.md`
- **Existing OTel Reference:** `standards/observability.md`
- **Playbook Structure:** `playbooks/setup/`, `playbooks/assess/`, `playbooks/review/`
- **Core Configuration:** `core/AGENTS.md`, `core/CLAUDE.md`, `core/.context/index.md`
- **Deploy Scripts:** `deploy.sh`, `deploy.ps1`

