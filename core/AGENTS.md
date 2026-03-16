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

## Workflow Orchestration

### Plan Mode Default

- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions).
- If something goes sideways, STOP and re-plan immediately — don't keep pushing.
- Use plan mode for verification steps, not just building.
- Write detailed specs upfront to reduce ambiguity.

### Subagent Strategy

- Use subagents liberally to keep main context window clean.
- Offload research, exploration, and parallel analysis to subagents.
- For complex problems, throw more compute at it via subagents.
- One task per subagent for focused execution.

### Self-Improvement Loop

- After ANY correction from the user: update `tasks/lessons.md` with the pattern.
- Write rules for yourself that prevent the same mistake.
- Ruthlessly iterate until mistake rate drops.
- Review lessons at session start for the relevant project.

### Verification Before Done

- Never mark a task complete without proving it works.
- Diff behaviour between main and your changes when relevant.
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness.

### Demand Elegance (Balanced)

- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution."
- Skip this for simple, obvious fixes — don't over-engineer.
- Challenge your own work before presenting it.

### Autonomous Bug Fixing

- When given a bug report: just fix it. Don't ask for hand-holding.
- Point at logs, errors, failing tests — then resolve them.
- Zero context switching required from the user.
- Fix failing CI tests without being told how.

### Autonomous Improvement During Review

- When reviewing code or conducting an assessment, if you identify issues: fix them. Do not ask for permission to improve code health.
- Prioritise coverage and pipeline excellence first — a strong safety net enables all other improvements.
- Delegate fixes to subagents: construct a focused prompt for each fix, starting with test coverage, then pipeline quality, then the fix itself.
- Small, focused improvements compound. A review that also adds missing tests and fixes a lint warning leaves the codebase better than it was found.

---

## Task Management

1. **Plan First:** Write plan to `tasks/todo.md` with checkable items.
2. **Verify Plan:** Check in before starting implementation.
3. **Track Progress:** Mark items complete as you go.
4. **Explain Changes:** High-level summary at each step.
5. **Document Results:** Add review section to `tasks/todo.md`.
6. **Capture Lessons:** Update `tasks/lessons.md` after corrections.

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

## Mandated Standards

The following standards are non-negotiable. Do not weaken them. Detailed guidance is in `standards/` and auto-loads as Claude skills when relevant.

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

## Project-Specific Rules [CONFIGURE]

<!-- PROJECT: Rules unique to this project that don't fit the categories above. -->
