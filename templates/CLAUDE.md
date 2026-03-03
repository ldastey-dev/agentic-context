# CLAUDE.md

<!-- TEMPLATE: Copy to your repository root as `CLAUDE.md`.
     Sections marked [CONFIGURE] require project-specific values.
     All coding standards are defined in AGENTS.md — do not duplicate them here.
     Delete this comment block and all <!-- PROJECT: ... --> placeholders after populating. -->

## Project Overview [CONFIGURE]

<!-- PROJECT: One paragraph describing what this application does, who uses it,
     and what business value it delivers. -->

## Tech Stack [CONFIGURE]

<!-- PROJECT: List actual technologies so Claude does not assume availability. -->

- **Language(s):**
- **Framework(s):**
- **Database(s):**
- **Testing:**
- **Linting / formatting:**
- **Package manager:**

## Commands [CONFIGURE]

<!-- PROJECT: Commands Claude should use when working in this project. -->

```bash
# Install dependencies
# <package manager install command>

# Run tests
# <test command>

# Run tests with coverage
# <test command with coverage gate>

# Lint
# <lint command>

# Format
# <format command>

# Type check
# <type check command>

# Build
# <build command>
```

## Architecture [CONFIGURE]

<!-- PROJECT: Describe the actual architecture and key design decisions.
     Reference ADRs if they exist. -->

- **Style:**
- **Deployment model:**
- **Service boundaries:**

## Repository Structure [CONFIGURE]

<!-- PROJECT: Map the directory layout so Claude navigates without guessing. -->

```
<!-- PROJECT: Replace with actual layout. -->
```

---

## Coding Standards

Read and apply all coding standards defined in `AGENTS.md` in this repository root. That file is the single source of truth for:

- Clean Code, Clean Architecture, and design principles (Single Responsibility, Open-Closed, Liskov Substitution, Interface Segregation, Dependency Inversion)
- DRY — single authoritative representation of every piece of knowledge
- OWASP Top 10 security standards and security path analysis (trace code paths, think like an attacker, identify trust boundaries and privilege transitions)
- Memory leak vigilance (event listeners, subscriptions, timers, closures, disposal patterns)
- Testing (Test Trophy Model, 90% coverage gate)
- CI/CD quality gates (Conventional Commits, branch protection)
- Fast flow and fast feedback (pipeline speed, parallelisation, caching, DORA metrics, trunk-based development, feature flags)
- Observability (OpenTelemetry, Golden Signals, structured logging)
- Resilience and fault tolerance (circuit breakers, retry, timeouts)
- Performance and scalability
- Cost optimisation
- Operational excellence
- API design standards
- Infrastructure as Code
- GDPR compliance (data minimisation, lawful basis, data subject rights, retention, pseudonymisation, privacy by design)
- PCI DSS compliance (CDE scope minimisation, cardholder data protection, audit logging, vulnerability scanning, MFA)
- Autonomous improvement during review (fix coverage gaps and pipeline issues proactively, delegate to subagents)

Do not weaken or override these standards.

---

## Claude-Specific Workflow

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

- **PR-level:** Apply the standards from `.github/instructions/*.instructions.md` relevant to the change.

---

## Project-Specific Rules [CONFIGURE]

<!-- PROJECT: Rules unique to this project that are not covered by AGENTS.md.
     Examples: domain-specific naming conventions, required approval workflows,
     integration constraints, deployment procedures. -->
