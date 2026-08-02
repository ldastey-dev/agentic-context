# PR #23 Refactoring Coordinator — Executive Summary

**Role:** Refactor Coordinator & Principal Architect  
**Repository:** https://github.com/ldastey-dev/agentic-context  
**PR:** #23 "Add skills for setting up local otel stack"  
**Branch:** feature/otel-skills (by djpnicholls)  
**Date:** 2026-08-02  
**Status:** ✅ DISCOVERY PHASE COMPLETE — Ready for Phase 1

---

## What You Need To Know

PR #23 adds 4 OpenTelemetry playbooks (779 lines + 1100+ lines of scripts). To make these universally applicable and avoid duplicating standards, we're refactoring into **three separate contributions**:

| # | Contribution | Type | Status | Effort | Owner |
|---|---|---|---|---|---|
| 1 | OTel Stack Infrastructure | Playbooks | Keep as-is | 1-2 hrs | SRE |
| 2 | .NET OTel Standard | Standard | Migrate from playbook | 2-3 hrs | Principal Eng |
| 3 | Language-Agnostic OTel | Standard | Create new | 3-4 hrs | Architect |

**All work can happen in parallel.** No sequencing constraints.

---

## Three Contributions Explained

### Contribution 1: OTel Stack Infrastructure Playbooks ✅

**What:** Keep the 3 operational playbooks + all scripts  
**Files:**
- `playbooks/setup/create-local-otel-stack.md` (start stack)
- `playbooks/setup/discover-local-otel-stack.md` (check health)
- `playbooks/setup/use-local-otel-stack.md` (configure endpoints)
- Plus: Bash/PowerShell scripts, Docker Compose, Podman configs, collectors

**Changes:**
- Add backend-agnostic note (VictoriaMetrics is one option; others exist)
- Update cross-references to new standards

**Why:** Operational playbooks are already correctly structured. They belong together.

---

### Contribution 2: .NET OpenTelemetry Standard 📝

**What:** Migrate SDK patterns from playbook into a canonical standard  
**Source:** `playbooks/setup/instrument-dotnet-otel.md`  
**Target:** `standards/opentelemetry-dotnet.md`

**What Gets Migrated:**
- NuGet package selection → Section 1
- Startup.cs canonical pattern → Section 2
- Environment variables & configuration → Section 3
- Testing patterns (InMemory exporter) → Section 4
- 3 known pitfalls + fixes → Section 5 + Non-Negotiables
- Related playbooks → Related Standards

**Structure:**
```
## 1 · SDK Selection and Installation
## 2 · Instrumentation Patterns
## 3 · Exporter Configuration
## 4 · Testing Patterns
## 5 · Pitfalls and Solutions
## Non-Negotiables
## Decision Checklist
```

**Why:** SDK patterns are prescriptive rules that belong in a standard, not a how-to playbook.

---

### Contribution 3: Language-Agnostic OpenTelemetry Standard 🎯

**What:** Create a new cross-language OTel standard  
**Target:** `standards/opentelemetry.md`

**What Gets Covered:**
- OTel principles (Semantic Conventions, instrumentation types)
- SDK patterns (Resource, Traces, Metrics, Logs) for all languages
- OTLP protocol (gRPC port 4317 vs HTTP/protobuf port 4318, signal paths)
- Backends (Jaeger, Tempo, Honeycomb, Datadog, AWS X-Ray)
- Integration patterns (direct, sidecar, gateway networking)
- Cross-language pitfalls (port reachability, trace context propagation)

**Structure:**
```
## 1 · OTel Principles
## 2 · Core SDK Patterns
## 3 · OTLP Protocol
## 4 · Backends and Exporters
## 5 · Integration Patterns
## 6 · Pitfalls (Cross-Language)
## Non-Negotiables
## Decision Checklist
```

**Why:** OTel SDK principles are identical across languages. This standard enables Go, Python, Java, Rust, Node.js, .NET, etc. to reference one canonical source.

---

## Why This Refactoring?

**Framework Principle:** One copy of every standard.

Instead of:
```
❌ playbook/instrument-dotnet-otel.md (SDK patterns)
❌ standards/opentelemetry.md (generic SDK patterns)
❌ standards/opentelemetry-go.md (Go SDK patterns) [future]
❌ standards/opentelemetry-python.md (Python SDK patterns) [future]
→ 4 copies of the same rule scattered across the repo
```

We're doing:
```
✅ standards/opentelemetry.md (canonical OTel principles for all languages)
✅ standards/opentelemetry-dotnet.md (language-specific details for .NET)
✅ standards/opentelemetry-go.md (language-specific details for Go) [future]
✅ standards/opentelemetry-python.md (language-specific details for Python) [future]
✅ playbooks/setup/{create,discover,use}-local-otel-stack.md (operational procedures)
→ 1 canonical source per concern
```

---

## Documentation Provided

You have **3 complete coordination documents**:

1. **REFACTORING_COORDINATION.md** (15 KB, 369 lines)
   - Complete breakdown of each contribution
   - File mappings (current → target)
   - Content migration plans
   - Review team assignments per speciality

2. **REFACTORING_STATUS.md** (12 KB, 314 lines)
   - Phase-by-phase task breakdown
   - Checklists for each phase (32 tasks total)
   - File status matrix
   - Per-speciality review checklists

3. **PR_23_DISCOVERY_REPORT.md** (8.3 KB, 235 lines)
   - Current state analysis
   - Framework alignment verification
   - Dependencies & blockers
   - Merge-ready checklist
   - Timeline estimate (7-11 hours total)

---

## Timeline

| Phase | Owner | Duration | What Happens |
|-------|-------|----------|---|
| **Phase 1** | 3 Senior Engineers (parallel) | 3-4 hours | Create Contributions 1, 2, 3 |
| **Phase 2** | Coordinator | 1-2 hours | Update index.md, deploy scripts |
| **Phase 3** | 7 Review Specialists (parallel) | 2-3 hours | SRE, Principal Eng, Architect, QA, Security, Observability, Tech Writer review |
| **Phase 4** | Coordinator + Engineers | 1-2 hours | Iterate on feedback, test, merge |
| **TOTAL** | — | **7-11 hours** | — |

**Critical Path:** Phase 1 → 2 → 3 → 4 (sequential, but phases 1, 3 can have parallel work within)

---

## Immediate Next Steps

### For You (Coordinator)

1. ✅ **Done:** Discovery phase complete
2. ✅ **Done:** All 3 contributions clearly defined
3. ✅ **Done:** Senior engineers have detailed handoff docs
4. **Next:** Distribute these 3 documents to your team:
   - Senior Engineer 1 (SRE) → REFACTORING_COORDINATION.md + REFACTORING_STATUS.md
   - Senior Engineer 2 (Principal Eng) → REFACTORING_COORDINATION.md + REFACTORING_STATUS.md
   - Senior Engineer 3 (Architect) → REFACTORING_COORDINATION.md + REFACTORING_STATUS.md
5. **Then:** Monitor Phase 1 progress (all 3 engineers work in parallel)

### For Senior Engineer 1 (SRE)

Contribution 1 work is in REFACTORING_STATUS.md under "Phase 1 → Contribution 1":
- Review and validate the 3 playbooks
- Verify all scripts (Bash, PowerShell)
- Run smoke tests if Podman available
- Add backend-agnostic note
- Update cross-references
- Push to feature/otel-skills

### For Senior Engineer 2 (Principal Engineer)

Contribution 2 work is in REFACTORING_COORDINATION.md under "Contribution 2":
- Create `standards/opentelemetry-dotnet.md`
- Migrate content from `instrument-dotnet-otel.md`
- Match `standards/dotnet.md` structure
- Add Non-Negotiables & Decision Checklist
- Push to feature/otel-skills

### For Senior Engineer 3 (Architect)

Contribution 3 work is in REFACTORING_COORDINATION.md under "Contribution 3":
- Create `standards/opentelemetry.md`
- Cover all languages/runtimes
- Link to language-specific standards
- Add Non-Negotiables & Decision Checklist
- Push to feature/otel-skills

---

## Success Criteria

All of the following must be true before merge:

- ✅ All 3 contributions properly structured
- ✅ No duplicated content across files
- ✅ All cross-references intact and working
- ✅ Deploy scripts updated and tested
- ✅ All review team feedback addressed
- ✅ Merge-ready state with no open comments on PR #23

---

## Key Constraints

1. **Template library, not target repo** — Never run `deploy.sh` against this directory (test in scratch directory only)
2. **One copy per standard** — No language-specific copies in per-agent files
3. **Playbooks stay operational** — They remain procedures, not principles
4. **Deploy scripts must be equivalent** — Any bash change must mirror to PowerShell
5. **Skill wrappers regenerate** — Hand-edited wrappers will be overwritten

---

## Questions?

Refer to:
- **"How do I do this task?"** → REFACTORING_STATUS.md (per-phase checklists)
- **"Why is it structured this way?"** → REFACTORING_COORDINATION.md (rationale & mapping)
- **"What's the current state?"** → PR_23_DISCOVERY_REPORT.md (analysis & readiness)

---

## Current Branch State

```
Branch: feature/otel-skills
Files:  4 playbooks + supporting scripts (already in PR)
Index:  Already updated with new keyword routes
Status: Ready for Phase 1
```

You're on the correct branch. Senior engineers can start work immediately.

---

**Discovery Phase:** ✅ Complete  
**Status:** Ready to proceed to Phase 1  
**Date:** 2026-08-02  

