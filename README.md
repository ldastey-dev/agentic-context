# AI Agent Prompts & Playbooks for Context Engineering

A template library of coding standards, assessment playbooks, PR review playbooks, and agent configuration files. Import into any repository to get consistent AI-assisted development across all major coding agents.

## Context-Optimised Architecture

Content is organised to minimise always-in-context footprint and load detail on demand:

| Tier | Directory | When loaded | Purpose |
| ---- | --------- | ----------- | ------- |
| **1 — Always in context** | `core/` | Session start | Lean project config (~60 lines), context index, conventions |
| **2 — On demand** | `playbooks/` | When task matches keywords | Assessment, review, planning, and refactoring procedures |
| **3 — Reference** | `standards/` | When domain matches keywords | Detailed per-concern standards (security, testing, etc.) |

**Result:** Always-in-context is ~60 lines of AGENTS.md plus a routing table. All detail loads on demand via keyword matching in `.context/index.md`.

## How Context Loading Works

The `.context/index.md` file is a keyword-to-file routing table. Every agent — Claude Code, Cursor, Copilot, Devin, Windsurf — is instructed to read this index before starting a task and load files matching the current domain.

This is the cross-agent mechanism: any LLM-based agent can read a markdown table and match keywords. No proprietary skill system required.

For **Claude Code** specifically, `deploy.sh` generates thin `.claude/skills/` wrappers that provide native auto-matching. The playbook is the single source of truth; the skill wrapper is a disposable adapter.

### Example

User says: "refactor the authentication module"

1. Agent reads `.context/index.md`
2. Matches keyword "refactor" → `.context/playbooks/refactor/safe-refactor.md`
3. Matches keyword "auth" + "security" → `.context/standards/security.md`
4. Loads both files and follows the playbook

## Supported Agents

| Agent | File(s) read | How |
| ----- | ------------ | --- |
| **Devin** | `AGENTS.md`, `.devin/devin.json` | Native — reads `AGENTS.md` + `.context/index.md` via instructions |
| **Cursor** | `.cursor/rules/standards.mdc` → `AGENTS.md` | Redirect with `alwaysApply: true` |
| **Windsurf** | `.windsurfrules` → `AGENTS.md` | Redirect |
| **Claude Code** | `CLAUDE.md` → `AGENTS.md` + `.claude/skills/` | Delegation + generated skill wrappers |
| **GitHub Copilot** | `.github/copilot-instructions.md` → `AGENTS.md` | Redirect |

`AGENTS.md` is the **single source of truth** for project conventions. All agent config files redirect to it and to `.context/index.md`.

## Quick Start

```bash
./deploy.sh /path/to/target-repo
```

Then fill in all `[CONFIGURE]` sections in `AGENTS.md` and `CLAUDE.md`.

## Repository Structure

```text
core/                                   Tier 1 — always in context (→ target repo root)
  AGENTS.md                             Lean project config (~60 lines)
  CLAUDE.md                             Claude Code config (→ AGENTS.md + index)
  .context/
    index.md                            Keyword → file routing table
    conventions/
      code.md                           Naming, patterns, imports, core principles
      workflow.md                       Workflow orchestration, task management
      communication.md                  Writing standards, communication style
  .clinerules                           Cline/Roo redirect → AGENTS.md
  .windsurfrules                        Windsurf redirect → AGENTS.md
  .cursor/rules/standards.mdc           Cursor redirect → AGENTS.md + index
  .devin/devin.json                     Devin config + index pointer
  .github/copilot-instructions.md       Copilot redirect → AGENTS.md
  .claude/settings.json                 Claude Code permissions + hooks template

standards/                              Tier 3 — reference (→ target .context/standards/)
  code-quality.md                       SOLID, DRY, Clean Code, Clean Architecture
  security.md                           OWASP Top 10 security checklist
  testing.md                            Test Trophy Model, coverage, fixtures
  ci-cd.md                              CI/CD pipeline and quality gates
  observability.md                      OpenTelemetry, Golden Signals, 3 pillars
  resilience.md                         Circuit breakers, retries, bulkheads
  performance.md                        Performance and scalability patterns
  cost-optimisation.md                  FinOps and cost-aware engineering
  operational-excellence.md             Runbooks, config, change management
  api-design.md                         REST/GraphQL API design standards
  aws-well-architected.md               AWS Well-Architected Framework (6 pillars)
  gdpr.md                               GDPR data protection standards
  pci-dss.md                            PCI DSS payment card data standards
  accessibility.md                      WCAG 2.2 Level AA accessibility standards

playbooks/                              Tier 2 — on demand (→ target .context/playbooks/)
  assess/                               Structured codebase-level assessments (12)
    accessibility.md, api-design.md, architecture.md, code-quality.md,
    compliance.md, full.md, iac.md, observability.md, performance.md,
    security.md, tech-debt.md, test-coverage.md
  review/                               PR-level and change-level reviews (10)
    accessibility.md, api-design.md, architecture.md, code-quality.md,
    compliance.md, iac.md, observability.md, performance.md,
    security.md, test-coverage.md
  plan/                                 Design and decision documents (4)
    adr.md, design-doc.md, risk-assessment.md, spike.md
  refactor/                             Structured code change procedures (3)
    safe-refactor.md, extract-module.md, dependency-upgrade.md
```

## Playbook Format

Playbooks use a universal markdown format with YAML frontmatter:

```yaml
---
name: assess-security
description: "Run comprehensive OWASP Top 10 security assessment..."
keywords: [assess security, security audit, threat model]
---

# Security Assessment

## Phase 1: Discovery
...
```

The `keywords` field feeds the context index. The `description` field is used by `deploy.sh` to generate Claude Code skill wrappers. The content is plain markdown that any agent can read and follow.

## Conventions

- **British English** throughout (optimisation, behaviour, colour)
- **Kebab-case** file names
- In `standards/`, use **`## N · Section Title`** heading style (middle dot separator)
- **`[CONFIGURE]`** in headings marks project-specific sections
- **`<!-- PROJECT: ... -->`** HTML comments mark inline customisation points
- SOLID principles always use **full names** (never SRP, OCP, etc.)
- All instructions prescriptive: "must", "never", "always"

## Updating Standards

Standards are maintained in **one place only**:

| What | Where |
| ---- | ----- |
| Project conventions and workflow | `core/AGENTS.md` |
| Per-concern detail | `standards/{concern}.md` |
| On-demand context routing | `core/.context/index.md` |
| Playbook procedures | `playbooks/{category}/{concern}.md` |
| Claude Code skill wrappers | Generated by `deploy.sh` — do not edit directly |

## Editing Guidelines

- Do not modify templates unless explicitly asked.
- Keep standards prescriptive — "must", "never", "always" — not advisory.
- Every instruction file ends with `## Non-Negotiables` and `## Decision Checklist`.
- When adding a new standard, add it to `standards/`, create playbooks in `playbooks/`, and add entries to `core/.context/index.md`.
