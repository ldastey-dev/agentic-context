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

<!-- agentic-context:begin 1.0.0 -->
<!-- Everything between these markers is managed by agentic-context and is REPLACED
     WHOLESALE on update. Do not edit inside this block — your changes will be lost.
     To change framework rules, add an override under .context/overrides/.
     Everything outside these markers is yours and is never touched. -->

## Context System

This repository uses on-demand context loading. Before starting any task, read `.context/index.md` and load files matching the current task's domain.

Available context types:

- **Standards** in `.context/standards/` — detailed reference for a specific concern (security, testing, performance, etc.)
- **Playbooks** in `.context/playbooks/` — step-by-step procedures for assessments, reviews, plans, and refactoring
- **Conventions** in `.context/conventions/` — workflow, communication, and coding style guidance

### Override Resolution

Before loading any `.context/**` file, check whether `.context/overrides/<same relative path>` exists. If it does, that override takes precedence:

- `mode: replace` (or no `mode`) — load **only** the override; ignore the base file.
- `mode: extend` — load the base file first, then apply the override on top. Where they conflict, the override wins.

Base files under `.context/standards/`, `.context/playbooks/` and `.context/conventions/` are framework-managed and are replaced on update. Never edit them; put changes in `.context/overrides/`. See `.context/overrides/README.md`.

### Framework Updates

Check frequency: **weekly**  <!-- daily | weekly | monthly | never -->

At session start, if `.context/.last-update-check` is missing or older than the frequency above, run `.context/bin/update.sh --check` once. Report at most one line. **Never block the session.** If the check fails for any reason, continue silently.

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
| GDPR | Lawful basis, data minimisation, subject rights, cookies & tracking declaration | `.context/standards/gdpr.md` |
| PCI DSS | CDE scoping, AES-256, TLS 1.2+ | `.context/standards/pci-dss.md` |
| Accessibility | WCAG 2.2 AA, keyboard, ARIA, contrast | `.context/standards/accessibility.md` |
| Architecture | Clean Architecture, dependency direction, layer boundaries | `.context/standards/architecture.md` |
| Debugging | Scientific method: reproduce, locate, fix, verify, search | `.context/standards/debugging.md` |
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
| Playwright | Page Object Model, semantic locators, auto-waiting, fixtures | `.context/standards/playwright.md` |
| OpenTelemetry | Cross-language SDK patterns, OTLP protocol, backends | `.context/standards/opentelemetry.md` |
| OpenTelemetry .NET | .NET instrumentation, pitfalls, testing patterns | `.context/standards/opentelemetry-dotnet.md` |

<!-- agentic-context:end -->

---

## Project-Specific Rules [CONFIGURE]

<!-- PROJECT: Rules unique to this project that don't fit the categories above. -->

---

## Additional Context [CONFIGURE]

<!-- PROJECT: Keyword routes for any standards or playbooks you have added under
     .context/overrides/ that the framework does not ship. Agents scan this table
     the same way they scan .context/index.md.

| Keywords | File | Summary |
|----------|------|---------|
| billing, invoice, dunning | `.context/overrides/standards/billing-domain.md` | Billing domain rules |
-->

