# Context Index

Before starting any task, scan this index for matching keywords.
Load the referenced files into your context before proceeding.
Combine multiple matches when a task spans domains.

---

## Standards (reference — load when working in the domain)

| Keywords | File | Summary |
|----------|------|---------|
| code quality, SOLID, DRY, clean code, complexity, naming | `.context/standards/code-quality.md` | SOLID, DRY, cyclomatic complexity < 10 |
| security, OWASP, vulnerability, injection, auth, secrets | `.context/standards/security.md` | OWASP Top 10 compliance |
| testing, test, coverage, TDD, unit test, integration test | `.context/standards/testing.md` | Test Trophy Model, >= 90% coverage |
| CI, CD, pipeline, quality gate, deployment, build | `.context/standards/ci-cd.md` | 7-stage pipeline, < 10 min full CI |
| observability, logging, tracing, metrics, monitoring | `.context/standards/observability.md` | OpenTelemetry, structured JSON logging |
| resilience, fault tolerance, circuit breaker, retry, timeout | `.context/standards/resilience.md` | Circuit breakers, retries with backoff |
| performance, scalability, N+1, caching, pagination | `.context/standards/performance.md` | No N+1, pagination, resource disposal |
| cost, FinOps, optimisation, right-sizing | `.context/standards/cost-optimisation.md` | Cache before network, FinOps principles |
| operations, IaC, infrastructure, runbook, config | `.context/standards/operational-excellence.md` | IaC, env vars, small focused PRs |
| API, REST, endpoint, OpenAPI, error response | `.context/standards/api-design.md` | OpenAPI 3+, REST, RFC 7807 errors |
| AWS, well-architected, cloud, pillar | `.context/standards/aws-well-architected.md` | 6 pillars: OpEx, Security, Reliability, Perf, Cost, Sustainability |
| Azure, well-architected, cloud, pillar, AKS, Cosmos DB, Entra ID, Key Vault | `.context/standards/azure-well-architected.md` | 5 pillars: Reliability, Security, Cost, OpEx, Performance |
| GDPR, data protection, privacy, consent, subject rights | `.context/standards/gdpr.md` | Lawful basis, data minimisation, subject rights |
| PCI, DSS, payment, cardholder, card data | `.context/standards/pci-dss.md` | CDE scoping, AES-256, TLS 1.2+ |
| accessibility, a11y, WCAG, ARIA, screen reader, keyboard | `.context/standards/accessibility.md` | WCAG 2.2 AA, keyboard, ARIA, contrast |
| architecture, clean architecture, layers, dependency direction, domain | `.context/standards/architecture.md` | Clean Architecture, layer boundaries, dependency inversion |
| IaC, infrastructure as code, Terraform, state, drift, containers | `.context/standards/iac.md` | IaC coverage, state management, containerisation, policy-as-code |
| tech debt, technical debt, code health, refactoring priority | `.context/standards/tech-debt.md` | Debt taxonomy, impact scoring, paydown strategy |
| .NET, C#, ASP.NET, Entity Framework, EF Core | `.context/standards/dotnet.md` | C#, ASP.NET Core, EF Core, async patterns |
| React, hooks, components, JSX, state management | `.context/standards/react.md` | Component architecture, hooks, Testing Library |
| SQL, MSSQL, database, schema, migration, stored proc | `.context/standards/mssql.md` | Schema design, migrations, Azure SQL |
| PowerShell, PS, script, Az module, Pester | `.context/standards/powershell.md` | Verb-Noun, parameters, Pester, Az module |
| Terraform, HCL, tfstate, module, provider | `.context/standards/terraform.md` | File layout, modules, tflint, Terratest |
| ADO, Azure DevOps, pipeline, YAML pipeline | `.context/standards/ado-pipelines.md` | Triggers, templates, environments, approvals |
| Docker, Dockerfile, container, image, compose | `.context/standards/docker.md` | Multi-stage builds, layer optimisation, scanning |

---

## Playbooks — Assessments (structured codebase-level evaluation)

| Keywords | File | Summary |
|----------|------|---------|
| assess accessibility, WCAG audit, a11y assessment | `.context/playbooks/assess/accessibility.md` | Full WCAG 2.2 Level AA assessment |
| assess API, API audit, API design assessment | `.context/playbooks/assess/api-design.md` | API design and developer experience assessment |
| assess architecture, architecture review, well-architected | `.context/playbooks/assess/architecture.md` | Well-Architected Framework assessment |
| assess AWS, AWS well-architected, AWS cloud review | `.context/playbooks/assess/aws-well-architected.md` | AWS Well-Architected Framework assessment (6 pillars) |
| assess Azure, Azure well-architected, Azure cloud review | `.context/playbooks/assess/azure-well-architected.md` | Azure Well-Architected Framework assessment (5 pillars) |
| assess code quality, SOLID assessment, clean code audit | `.context/playbooks/assess/code-quality.md` | SOLID and Clean Code assessment |
| assess compliance, GDPR audit, PCI audit, regulatory | `.context/playbooks/assess/compliance.md` | GDPR and PCI-DSS compliance assessment |
| full assessment, comprehensive assessment, health check | `.context/playbooks/assess/full.md` | Single-pass assessment across all domains |
| assess IaC, infrastructure assessment, terraform audit | `.context/playbooks/assess/iac.md` | Infrastructure as Code maturity assessment |
| assess observability, monitoring audit, logging assessment | `.context/playbooks/assess/observability.md` | Observability maturity assessment |
| assess performance, performance audit, scalability review | `.context/playbooks/assess/performance.md` | Performance and resilience assessment |
| assess security, security audit, threat model, pen test | `.context/playbooks/assess/security.md` | OWASP Top 10 security assessment |
| assess domain security, DNS audit, subdomain takeover, security headers, HSTS, CSP, WAF, Cloudflare | `.context/playbooks/assess/domain-security.md` | External domain and attack-surface security assessment |
| assess tech debt, debt inventory, code health | `.context/playbooks/assess/tech-debt.md` | Technical debt identification and prioritisation |
| assess test coverage, test audit, testing assessment | `.context/playbooks/assess/test-coverage.md` | Testing strategy and coverage assessment |

---

## Playbooks — Reviews (PR-level or change-level evaluation)

| Keywords | File | Summary |
|----------|------|---------|
| review accessibility, a11y review | `.context/playbooks/review/accessibility.md` | WCAG 2.2 PR accessibility checklist |
| review API, API review | `.context/playbooks/review/api-design.md` | API contract and DX review |
| review architecture, architecture review | `.context/playbooks/review/architecture.md` | Layer boundaries, dependency direction |
| review code quality, code review | `.context/playbooks/review/code-quality.md` | SOLID, Clean Code, naming, complexity |
| review compliance, compliance review | `.context/playbooks/review/compliance.md` | Data handling, encryption, audit compliance |
| review IaC, infrastructure review | `.context/playbooks/review/iac.md` | Infrastructure code patterns and security |
| review observability, observability review | `.context/playbooks/review/observability.md` | Logging, tracing, metrics instrumentation |
| review performance, performance review | `.context/playbooks/review/performance.md` | Query efficiency, caching, resource disposal |
| review security, security review | `.context/playbooks/review/security.md` | OWASP, secrets, injection vectors |
| review test coverage, test review | `.context/playbooks/review/test-coverage.md` | Test quality, coverage gaps, coupling |

---

## Playbooks — Planning (design and decision documents)

| Keywords | File | Summary |
|----------|------|---------|
| ADR, architecture decision, decision record | `.context/playbooks/plan/adr.md` | Architecture Decision Record |
| design doc, technical design, design document | `.context/playbooks/plan/design-doc.md` | Technical Design Document |
| risk assessment, risk register, risk analysis | `.context/playbooks/plan/risk-assessment.md` | Risk identification and mitigation |
| spike, investigation, proof of concept, PoC | `.context/playbooks/plan/spike.md` | Timeboxed technical investigation |

---

## Playbooks — Refactoring (structured code change procedures)

| Keywords | File | Summary |
|----------|------|---------|
| refactor, refactoring, restructure, clean up, code smell | `.context/playbooks/refactor/safe-refactor.md` | Phased behaviour-preserving refactoring |
| extract, extract module, decompose, modularise | `.context/playbooks/refactor/extract-module.md` | Module or service extraction |
| upgrade, dependency upgrade, major version, migration | `.context/playbooks/refactor/dependency-upgrade.md` | Major dependency version upgrade |

---

## Conventions (style and workflow guidance)

| Keywords | File | Summary |
|----------|------|---------|
| naming, conventions, patterns, imports, file handling | `.context/conventions/code.md` | Naming, patterns, imports, core principles |
| workflow, planning, tasks, plan mode, verification | `.context/conventions/workflow.md` | Plan-first, task management, verification |
| writing, communication, style, tone, British English | `.context/conventions/communication.md` | Research, writing, and communication standards |
