# AGENTS.md

<!-- TEMPLATE: Copy to your repository root as `AGENTS.md`.
     Read by Devin, Cursor, Windsurf, and other coding agents.
     Sections marked [CONFIGURE] require project-specific values.
     All other sections are mandated standards — do not weaken them.
     Delete <!-- PROJECT: ... --> comments after populating. -->

## Project Overview [CONFIGURE]

<!-- PROJECT: One paragraph — what this application does, who uses it,
     and what business value it delivers. -->

---

## Tech Stack [CONFIGURE]

<!-- PROJECT: List actual technologies. Agents must verify against this list
     and the dependency manifest before assuming any library is available. -->

- **Language(s):**
- **Framework(s):**
- **Database(s):**
- **Testing:**
- **Linting / Formatting:**
- **Package Manager:**

---

## Commands [CONFIGURE]

```bash
<install dependencies>
<run tests>
<run tests with coverage>
<lint>
<format>
<type check>
<security audit>
<build>
```

---

## Architecture [CONFIGURE]

<!-- PROJECT: Describe the actual architecture. -->

- **Style:**
- **Deployment model:**
- **Service boundaries:**

### Dependency Direction

Dependencies point inward. This is non-negotiable.

```text
Presentation (Controllers / API)
    ↓
Application (Use Cases / Handlers)
    ↓
Domain (Entities / Value Objects / Interfaces)
    ↓
Infrastructure (Database / External APIs / Messaging)
```

<!-- PROJECT: Replace with your actual layer names. -->

### Key Design Decisions

<!-- PROJECT: List decisions agents must respect. Reference ADRs if they exist. -->

---

## Repository Structure [CONFIGURE]

<!-- PROJECT: Map the directory layout. -->

```text
<project directory layout>
```

---

## Code Conventions [CONFIGURE]

### Naming

<!-- PROJECT: Files, classes, functions, constants, database tables, API routes. -->

### Patterns

<!-- PROJECT: "When you add X, follow the pattern in Y." -->

### Import Rules

<!-- PROJECT: Which layers may import from which. -->

---

## Context System

This repository uses on-demand context loading. Before starting any task, read `.context/index.md` and load files matching the current task's domain.

Available context types:

- **Standards** in `.context/standards/` — detailed reference for a specific concern (security, testing, performance, etc.)
- **Playbooks** in `.context/playbooks/` — step-by-step procedures for assessments, reviews, plans, and refactoring
- **Conventions** in `.context/conventions/` — workflow, communication, and coding style guidance

---

## Mandated Standards

The following standards are non-negotiable. Do not weaken them. Detailed guidance is in `.context/standards/`.

### Core Principles

- **Simplicity First:** Make every change as simple as possible. Impact minimal code.
- **No Laziness:** Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact:** Changes should only touch what's necessary. Avoid introducing bugs.
- **Security is Non-Negotiable:** Never log secrets, commit credentials, or introduce injection vectors.
- **Test What You Change:** If you modify behaviour, prove it works. If you refactor, prove nothing broke.
- **Evidence Over Opinion:** Reference specific code, config, or behaviour. No vague assertions.

### Domain Standards

| Standard | Key Rule | Detail |
| --- | --- | --- |
| Code Quality | SOLID, DRY, cyclomatic complexity < 10 | `.context/standards/code-quality.md` |
| Security | OWASP Top 10 compliance | `.context/standards/security.md` |
| Testing | >= 90% coverage, Test Trophy Model | `.context/standards/testing.md` |
| CI/CD | 7-stage pipeline, < 10 min full CI | `.context/standards/ci-cd.md` |
| Observability | OpenTelemetry, structured JSON logging | `.context/standards/observability.md` |
| Resilience | Circuit breakers, retries with backoff | `.context/standards/resilience.md` |
| Performance | No N+1, pagination, resource disposal | `.context/standards/performance.md` |
| Cost | Cache before network, FinOps principles | `.context/standards/cost-optimisation.md` |
| Operations | IaC, env vars, small focused PRs | `.context/standards/operational-excellence.md` |
| API Design | OpenAPI 3+, REST, RFC 7807 errors | `.context/standards/api-design.md` |
| AWS | 6 pillars: OpEx, Security, Reliability, Perf, Cost, Sustainability | `.context/standards/aws-well-architected.md` |
| Azure | 5 pillars: Reliability, Security, Cost, OpEx, Performance | `.context/standards/azure-well-architected.md` |
| GDPR | Lawful basis, data minimisation, subject rights | `.context/standards/gdpr.md` |
| PCI DSS | CDE scoping, AES-256, TLS 1.2+ | `.context/standards/pci-dss.md` |
| Accessibility | WCAG 2.2 AA, keyboard, ARIA, contrast | `.context/standards/accessibility.md` |
| Architecture | Clean Architecture, dependency direction, layer boundaries | `.context/standards/architecture.md` |
| IaC | State management, drift detection, container security | `.context/standards/iac.md` |
| Tech Debt | Debt taxonomy, impact scoring, paydown strategy | `.context/standards/tech-debt.md` |

### Technology Standards

| Standard | Key Rule | Detail |
| --- | --- | --- |
| .NET | C#, ASP.NET Core, EF Core, async patterns | `.context/standards/dotnet.md` |
| React | Component architecture, hooks, Testing Library | `.context/standards/react.md` |
| SQL Server | Schema design, migrations, Azure SQL | `.context/standards/mssql.md` |
| PowerShell | Verb-Noun, parameters, Pester, Az module | `.context/standards/powershell.md` |
| Terraform | File layout, modules, tflint, Terratest | `.context/standards/terraform.md` |
| ADO Pipelines | Triggers, templates, environments, approvals | `.context/standards/ado-pipelines.md` |
| Docker | Multi-stage builds, layer optimisation, scanning | `.context/standards/docker.md` |

---

## Project-Specific Rules [CONFIGURE]

<!-- PROJECT: Rules unique to this project that don't fit the categories above. -->
