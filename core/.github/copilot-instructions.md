---
applyTo: "**"
---

# Project Instructions

<!-- TEMPLATE: Copy to your repository at `.github/copilot-instructions.md`.
     Sections marked [CONFIGURE] require project-specific values.
     All other sections are mandated standards — do not weaken them.
     Delete this comment block and all <!-- PROJECT: ... --> placeholders
     after populating. -->

---

## Project Context [CONFIGURE]

<!-- PROJECT: Fill in your application details. This context frames every decision. -->

- **Purpose:**
- **Users:**
- **Business criticality:** <!-- revenue-generating / internal tooling / experimental -->

---

## Tech Stack [CONFIGURE]

<!-- PROJECT: List actual technologies. Agents must verify against this list and
     the dependency manifest before assuming any library is available. -->

- **Language(s):**
- **Framework(s):**
- **Database(s):**
- **ORM / data access:**
- **Testing:**
- **Linting / formatting:**
- **CI/CD:**
- **Infrastructure:**
- **Package manager:**
- **Observability:**

---

## Architecture [CONFIGURE]

<!-- PROJECT: Describe the actual architecture, not the aspirational one. -->

- **Style:** <!-- monolith / modular monolith / microservices / serverless / event-driven -->
- **Deployment model:**
- **Service boundaries:**
- **Communication:** <!-- REST / gRPC / events / direct calls -->

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

<!-- PROJECT: Replace with your actual layer names if they differ. -->

### Key Design Decisions

<!-- PROJECT: List architectural decisions agents must respect. Reference ADRs. -->

---

## Repository Structure [CONFIGURE]

<!-- PROJECT: Map the directory layout. -->

```text
<!-- PROJECT: Replace with your actual layout. -->
```

---

## Code Conventions [CONFIGURE]

### Naming

<!-- PROJECT: Define naming conventions for files, classes, functions, constants,
     database tables, API routes. -->

### Patterns in Use

<!-- PROJECT: "When you add X, follow the pattern in Y." -->

### Import Rules

<!-- PROJECT: Define which layers may import from which. -->

---

## Mandated Standards

The following standards are non-negotiable. Do not weaken them. Detailed guidance is in `standards/`. Refer to the relevant standards file when working in that domain.

### Core Principles

- **Simplicity First:** Make every change as simple as possible. Impact minimal code.
- **No Laziness:** Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact:** Changes should only touch what's necessary. Avoid introducing bugs.
- **Security is Non-Negotiable:** Never log secrets, commit credentials, or introduce injection vectors.
- **Test What You Change:** If you modify behaviour, prove it works. If you refactor, prove nothing broke.
- **Evidence Over Opinion:** Reference specific code, config, or behaviour. No vague assertions.

### Standards Reference

| Standard | Key Rule | Detail |
| --- | --- | --- |
| Code Quality | SOLID, DRY, cyclomatic complexity < 10 | `standards/code-quality.md` |
| Security | OWASP Top 10 compliance | `standards/security.md` |
| Testing | >= 90% coverage, Test Trophy Model | `standards/testing.md` |
| CI/CD | 7-stage pipeline, < 10 min full CI | `standards/ci-cd.md` |
| Observability | OpenTelemetry, structured JSON logging | `standards/observability.md` |
| Resilience | Circuit breakers, retries with backoff | `standards/resilience.md` |
| Performance | No N+1, pagination, resource disposal | `standards/performance.md` |
| Cost | Cache before network, FinOps principles | `standards/cost-optimisation.md` |
| Operations | IaC, env vars, small focused PRs | `standards/operational-excellence.md` |
| API Design | OpenAPI 3+, REST, RFC 7807 errors | `standards/api-design.md` |
| AWS | 6 pillars: OpEx, Security, Reliability, Perf, Cost, Sustainability | `standards/aws-well-architected.md` |
| GDPR | Lawful basis, data minimisation, subject rights | `standards/gdpr.md` |
| PCI DSS | CDE scoping, AES-256, TLS 1.2+ | `standards/pci-dss.md` |

---

## Agent Behaviour

### Research and Analysis

- Establish scope and constraints before diving in.
- Identify primary sources over secondary commentary.
- Cross-reference claims across multiple sources when possible.
- Distinguish between facts, consensus, and speculation.
- Note confidence level: certain, likely, uncertain.
- Flag when information may be outdated relative to your knowledge cutoff.
- Define problems clearly before proposing solutions. Consider at least two alternatives.

### Writing Standards

- **Concise over verbose.** Say it in fewer words.
- **Active voice.** "The team decided" not "It was decided by the team."
- **Specific over general.** "Latency increased 3x" not "Performance degraded significantly."
- **British English** unless the context requires otherwise.
- **No filler.** Cut "In order to" (use "To"), "It should be noted that" (just state it).
- **Tables over prose** for comparisons, options, and structured data.
- Lead with the conclusion or recommendation. Detail follows.

### Communication Style

- Direct and to the point. No preamble or postamble.
- Match the register of the request — technical for technical, plain for plain.
- If a one-word answer is sufficient, give a one-word answer.
- Do not repeat the question back. Do not summarise what you are about to do. Just do it.
- When disagreeing, lead with the evidence.

### Working With Files

- Read before writing — understand existing content and conventions.
- Follow existing conventions in the target directory (naming, format, structure).
- No emoji unless explicitly requested.
- Use markdown with consistent heading hierarchy.
- Prefer editing existing files over creating new ones.
- Batch independent operations for efficiency.

### Assessment and Review Workflows

When asked to assess or review an application, codebase, or system:

- **PR-level:** Apply the relevant `standards/*.md` for the change.

Standards file inventory:

| Concern | File |
| --- | --- |
| SOLID, DRY, Clean Code, Clean Architecture | `standards/code-quality.md` |
| Security — OWASP Top 10 | `standards/security.md` |
| Testing — Test Trophy Model | `standards/testing.md` |
| CI/CD — Quality Gates & Fast Flow | `standards/ci-cd.md` |
| Observability — OpenTelemetry | `standards/observability.md` |
| Resilience & Fault Tolerance | `standards/resilience.md` |
| Performance & Scalability | `standards/performance.md` |
| Cost Optimisation | `standards/cost-optimisation.md` |
| Operational Excellence & IaC | `standards/operational-excellence.md` |
| API Design | `standards/api-design.md` |
| AWS Well-Architected (6 pillars) | `standards/aws-well-architected.md` |
| GDPR Compliance | `standards/gdpr.md` |
| PCI DSS Compliance | `standards/pci-dss.md` |

---

## Project-Specific Rules [CONFIGURE]

<!-- PROJECT: Rules unique to this project that don't fit the categories above. -->
