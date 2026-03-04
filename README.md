# AI Agent Prompts & Playbooks

A template library of coding standards, review playbooks, and agent configuration files.
Import into any repository to get consistent AI-assisted development across all major coding agents.

## Supported Agents

| Agent | File(s) read | How |
| ----- | ------------ | --- |
| **Devin** | `AGENTS.md` | Native (always-on) |
| **Cursor** | `.cursor/rules/standards.mdc` → `AGENTS.md` | Redirect with `alwaysApply: true` |
| **Windsurf** | `.windsurfrules` → `AGENTS.md` | Redirect |
| **Claude Code** | `CLAUDE.md` → `AGENTS.md` | Delegation (reads `AGENTS.md` when instructed) |
| **GitHub Copilot** | `.github/copilot-instructions.md` + `.github/instructions/*.instructions.md` | Native auto-load with `applyTo` globs |
| **Cline / Roo Code** | `.clinerules` → `AGENTS.md` | Redirect |

`AGENTS.md` is the **single source of truth** for all coding standards. Every other agent file either reads it natively or redirects to it.

## Quick Start

```bash
cp -a templates/. <target-repo>/
```

Then fill in all `[CONFIGURE]` sections in:

- `AGENTS.md` — project overview, tech stack, architecture, conventions
- `CLAUDE.md` — project overview, tech stack, commands
- `.github/copilot-instructions.md` — project context, tech stack, architecture

## Repository Structure

```text
templates/                              Importable agent config
  AGENTS.md                             Canonical coding standards (Devin, Cursor, Windsurf)
  CLAUDE.md                             Claude Code instructions (delegates to AGENTS.md)
  .github/
    copilot-instructions.md             GitHub Copilot global instructions
    instructions/                       Per-concern review playbooks (Copilot auto-loads)
      api-design.instructions.md        REST/GraphQL API design standards
      aws-well-architected.instructions.md  AWS Well-Architected Framework (6 pillars)
      ci-cd.instructions.md             CI/CD pipeline and quality gates
      code-quality.instructions.md      SOLID, Clean Code, Clean Architecture
      cost-optimisation.instructions.md FinOps and cost-aware engineering
      observability.instructions.md     OpenTelemetry, Golden Signals, 3 pillars
      operational-excellence.instructions.md  Runbooks, config, change management
      performance.instructions.md       Performance and scalability patterns
      resilience.instructions.md        Circuit breakers, retries, bulkheads
      security.instructions.md          OWASP Top 10 security checklist
      testing.instructions.md           Test Trophy Model, coverage, fixtures
  .cursor/rules/standards.mdc          Cursor redirect → AGENTS.md
  .windsurfrules                        Windsurf redirect → AGENTS.md
  .clinerules                           Cline/Roo redirect → AGENTS.md

playbooks/                              Standalone prompts (paste into any agent chat)
  repository-review/                    Codebase assessment playbooks
    00-full-assessment.md               Combined single-pass assessment
    01-architectural-assessment.md      Principal Architect review
    02-security-assessment.md           Security Engineer review
    03-test-coverage-assessment.md      Testing strategy review
    04-solid-clean-code-assessment.md   SOLID and Clean Code review
    05-iac-maturity-assessment.md       Infrastructure as Code review
    06-performance-resilience-assessment.md  Performance and resilience review
    07-observability-assessment.md      Observability maturity review
    08-api-assessment.md                API design and DX review
  planning/                             Upfront design work
    01-technical-design-doc.md          Technical Design Document template
    02-architecture-decision-record.md  ADR template (Michael Nygard format)
    03-risk-assessment.md               Technical risk register and mitigation
    04-spike-research.md                Timeboxed spike / research investigation
  refactoring/                          Behaviour-preserving code improvement
    01-safe-refactoring-runbook.md      General-purpose refactoring runbook
    02-extract-module.md                Extract module / service from monolith
    03-dependency-upgrade.md            Major dependency version upgrade
    04-technical-debt-reduction.md      Systematic debt identification and paydown
```

## Conventions

- **British English** throughout (optimisation, behaviour, colour)
- **Kebab-case** file names
- **`.instructions.md`** suffix for Copilot instruction files
- **`## N · Section Title`** heading style (middle dot separator)
- **`[CONFIGURE]`** in headings marks project-specific sections
- **`<!-- PROJECT: ... -->`** HTML comments mark inline customisation points
- SOLID principles always use **full names** (never SRP, OCP, etc.)

## Updating Standards

Standards are maintained in **one place only**:

| What | Where |
| ---- | ----- |
| Core coding standards | `templates/AGENTS.md` |
| Per-concern detail | `templates/.github/instructions/{concern}.instructions.md` |
| Copilot project scaffold | `templates/.github/copilot-instructions.md` |

`templates/CLAUDE.md`, `.windsurfrules`, `.cursor/rules/standards.mdc`, and `.clinerules` all delegate to `AGENTS.md` — do not duplicate standards in these files.
