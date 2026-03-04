# AI Agent Prompts & Playbooks

A template library of coding standards, assessment playbooks, PR review playbooks, reusable skills, and agent configuration files.
Import into any repository to get consistent AI-assisted development across all major coding agents.

## Supported Agents

| Agent | File(s) read | How |
| ----- | ------------ | --- |
| **Devin** | `AGENTS.md` | Native (always-on) |
| **Cursor** | `.cursor/rules/standards.mdc` → `AGENTS.md` | Redirect with `alwaysApply: true` |
| **Windsurf** | `.windsurfrules` → `AGENTS.md` | Redirect |
| **Claude Code** | `CLAUDE.md` → `AGENTS.md` | Delegation (reads `AGENTS.md` when instructed) |
| **GitHub Copilot** | `.github/copilot-instructions.md` | Native auto-load; can reference `AGENTS.md` and shared standards |
| **Cline / Roo Code** | `.clinerules` → `AGENTS.md` | Redirect |

`AGENTS.md` is the **single source of truth** for all coding standards. Every other agent file either reads it natively or redirects to it.

## Quick Start

```bash
cp -a templates/. <target-repo>/
```

Then fill in all `[CONFIGURE]` sections in:

- `AGENTS.md` — project overview, tech stack, architecture, conventions
- `.github/copilot-instructions.md` — project context, tech stack, architecture

## Repository Structure

```text
templates/                              Importable agent config
  AGENTS.md                             Canonical coding standards (Devin, Cursor, Windsurf)
  CLAUDE.md                             Claude Code thin delegator → AGENTS.md
  standards/                            Detailed standards (all agents)
    api-design.md                       REST/GraphQL API design standards
    aws-well-architected.md             AWS Well-Architected Framework (6 pillars)
    ci-cd.md                            CI/CD pipeline and quality gates
    code-quality.md                     SOLID, Clean Code, Clean Architecture
    cost-optimisation.md                FinOps and cost-aware engineering
    gdpr.md                             GDPR data protection standards
    observability.md                    OpenTelemetry, Golden Signals, 3 pillars
    operational-excellence.md           Runbooks, config, change management
    pci-dss.md                          PCI DSS payment card data standards
    performance.md                      Performance and scalability patterns
    resilience.md                       Circuit breakers, retries, bulkheads
    security.md                         OWASP Top 10 security checklist
    testing.md                          Test Trophy Model, coverage, fixtures
  .github/
    copilot-instructions.md             GitHub Copilot global instructions
  .cursor/rules/standards.mdc          Cursor redirect → AGENTS.md
  .windsurfrules                        Windsurf redirect → AGENTS.md
  .clinerules                           Cline/Roo redirect → AGENTS.md

playbooks/                              Standalone prompts (paste into any agent chat)
  assessment/                           Whole-codebase evaluations
    full.md                             Combined single-pass assessment
    architecture.md                     Principal Architect review
    security.md                         Security Engineer review
    test-coverage.md                    Testing strategy review
    code-quality.md                     SOLID and Clean Code review
    iac-maturity.md                     Infrastructure as Code review
    performance-resilience.md           Performance and resilience review
    observability.md                    Observability maturity review
    api-design.md                       API design and DX review
    technical-debt.md                   Systematic debt identification and paydown
    compliance.md                       GDPR and PCI DSS regulatory assessment
  review/                               PR / change reviews
    architecture.md                     Architectural alignment review (all 6 Well-Architected pillars)
    security.md                         Security vulnerability review
    test-coverage.md                    Test quality and coverage review
    code-quality.md                     SOLID and Clean Code review
    performance-resilience.md           Performance and resilience review
    observability.md                    Observability completeness review
    api-design.md                       API design and DX review
    iac-maturity.md                     Infrastructure as Code review
    compliance.md                       GDPR and PCI DSS compliance review
  planning/                             Upfront design work
    design-doc.md                       Technical Design Document template
    adr.md                              ADR template (Michael Nygard format)
    risk-assessment.md                  Technical risk register and mitigation
    spike.md                            Timeboxed spike / research investigation

skills/                                 Reusable procedures (invoke as part of tasks)
  safe-refactoring.md                   General-purpose refactoring runbook
  extract-module.md                     Extract module / service from monolith
  dependency-upgrade.md                 Major dependency version upgrade
```

## Conventions

- **British English** throughout (optimisation, behaviour, colour)
- **Kebab-case** file names
- In `templates/standards/*`, use **`## N · Section Title`** heading style (middle dot separator)
- **`[CONFIGURE]`** in headings marks project-specific sections
- **`<!-- PROJECT: ... -->`** HTML comments mark inline customisation points
- SOLID principles always use **full names** (never SRP, OCP, etc.)

## Using Playbooks, Reviews, and Skills

| Type | Purpose | Location |
| ---- | ------- | -------- |
| **Standards** | Rules and criteria agents follow continuously | `templates/standards/` |
| **Playbooks** | Complete standalone prompts producing a defined output | `playbooks/` |
| **Skills** | Reusable procedures applied to specific targets | `skills/` |

Paste playbooks and skills into any agent conversation:

- **Whole-codebase assessment:** `playbooks/assessment/` — deep evaluations producing reports with remediation plans
- **PR / change review:** `playbooks/review/` — focused reviews of individual changes against specific quality aspects
- **Planning:** `playbooks/planning/` — document generation (TDD, ADR, risk assessment, spike research)
- **Skills:** `skills/` — reusable procedures (safe refactoring, module extraction, dependency upgrade)

## Updating Standards

Standards are maintained in **one place only**:

| What | Where |
| ---- | ----- |
| Core coding standards | `templates/AGENTS.md` |
| Per-concern detail | `templates/standards/{concern}.md` |
| Copilot project scaffold | `templates/.github/copilot-instructions.md` |

`templates/CLAUDE.md`, `.windsurfrules`, `.cursor/rules/standards.mdc`, and `.clinerules` all delegate to `AGENTS.md` — do not duplicate standards in these files.

## Editing Guidelines

- Do not modify templates unless explicitly asked.
- Keep standards prescriptive — "must", "never", "always" — not advisory.
- Every instruction file ends with `## Non-Negotiables` and `## Decision Checklist`.
- When updating a standard, update it in ONE place only (the canonical source).
