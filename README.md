# AI Agent Prompts & Playbooks for Context Engineering

A template library of coding standards, assessment playbooks, PR review playbooks, reusable skills, and agent configuration files. Import into any repository to get consistent AI-assisted development across all major coding agents.

## Context-Optimised Architecture

Content is organised into three tiers that control when files load into agent context:

| Tier | Directory | When loaded | Purpose |
| ---- | --------- | ----------- | ------- |
| **1 — Always in context** | `core/` | Session start | Lean project config, workflow rules, standards reference table |
| **2 — Auto-matched on demand** | `skills/` | When task matches skill description | Playbooks, runbooks, and standards as Claude Code skills |
| **3 — Reference** | `standards/` | When explicitly read | Detailed per-concern standards accessible to all agents |

**Result:** ~85% reduction in startup context. Agents get the minimum context needed for any task, with detailed guidance available on demand.

## Supported Agents

| Agent | File(s) read | How |
| ----- | ------------ | --- |
| **Devin** | `AGENTS.md`, `.devin/devin.json` | Native — reads `AGENTS.md` (always-on) + `.devin/devin.json` for DeepWiki and knowledge config |
| **Cursor** | `.cursor/rules/standards.mdc` → `AGENTS.md` | Redirect with `alwaysApply: true` |
| **Windsurf** | `.windsurfrules` → `AGENTS.md` | Redirect |
| **Claude Code** | `CLAUDE.md` → `AGENTS.md` + `.claude/skills/` | Delegation + on-demand skill loading |
| **GitHub Copilot** | `.github/copilot-instructions.md` | Native auto-load; references `standards/` |
| **Cline / Roo Code** | `.clinerules` → `AGENTS.md` | Redirect |

`AGENTS.md` is the **single source of truth** for project conventions and workflow rules. Agent config files delegate to it.

## Quick Start

```bash
./deploy.sh /path/to/target-repo
```

Then fill in all `[CONFIGURE]` sections in:

- `AGENTS.md` — project overview, tech stack, architecture, conventions
- `CLAUDE.md` — project-specific rules
- `.github/copilot-instructions.md` — project context, tech stack, architecture

## Repository Structure

```text
core/                                   Tier 1 — always in context (→ target repo root)
  CLAUDE.md                             Claude Code config (lean, ~30 lines)
  AGENTS.md                             Canonical conventions hub (lean, ~265 lines)
  .clinerules                           Cline/Roo redirect → AGENTS.md
  .windsurfrules                        Windsurf redirect → AGENTS.md
  .cursor/rules/standards.mdc           Cursor redirect → AGENTS.md
  .devin/devin.json                     Devin config + AGENTS.md pointer
  .github/copilot-instructions.md       GitHub Copilot project instructions
  .claude/settings.json                 Claude Code permissions + hooks template

standards/                              Tier 3 — reference (→ target standards/)
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

skills/                                 Tier 2 — on demand (→ target .claude/skills/)
  assess-*/SKILL.md                     Assessment playbooks (11 skills)
  review-*/SKILL.md                     PR review playbooks (9 skills)
  plan-*/SKILL.md                       Planning playbooks (4 skills)
  safe-refactor/SKILL.md                Behaviour-preserving refactoring runbook
  extract-module/SKILL.md               Module/service extraction runbook
  dependency-upgrade/SKILL.md           Major dependency upgrade runbook
  ref-*/SKILL.md                        Standards as model-invocable skills (13 skills)
```

## How Skills Work

Skills are Claude Code's mechanism for on-demand context loading. Each skill has:

- A **description** (~100 bytes) loaded at session start — used for automatic matching
- **Full content** loaded only when the skill fires (user invocation or model match)

| Category | Prefix | Invocation | Model-invocable |
| -------- | ------ | ---------- | --------------- |
| Assessment playbooks | `assess-` | `/assess-security`, `/assess-architecture`, etc. | Yes |
| Review playbooks | `review-` | `/review-security`, `/review-code-quality`, etc. | Yes |
| Planning playbooks | `plan-` | `/plan-design-doc`, `/plan-adr`, etc. | Yes |
| Runbooks | (none) | `/safe-refactor`, `/extract-module`, `/dependency-upgrade` | Yes |
| Standards | `ref-` | Hidden from menu | Yes (auto-loads when domain matches) |

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
| Standards as skills (Claude) | `skills/ref-{concern}/SKILL.md` |
| Copilot project scaffold | `core/.github/copilot-instructions.md` |

When updating a detailed standard, update both `standards/{concern}.md` and `skills/ref-{concern}/SKILL.md` to keep them in sync.

## Editing Guidelines

- Do not modify templates unless explicitly asked.
- Keep standards prescriptive — "must", "never", "always" — not advisory.
- Every instruction file ends with `## Non-Negotiables` and `## Decision Checklist`.
- When updating a standard, update it in the canonical source and its skill wrapper.
