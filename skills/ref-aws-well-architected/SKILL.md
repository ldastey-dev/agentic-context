---
name: ref-aws-well-architected
description: "AWS Well-Architected Framework standards across all six pillars: Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimisation, and Sustainability"
user-invocable: false
---

# AWS Well-Architected Framework Guidelines

Every design decision in this repository must be evaluated against the AWS
Well-Architected Framework's six pillars. Whether the application runs locally
today or is already cloud-deployed, these principles apply — retrofitting
architectural quality is significantly costlier than building it in from day one.

---

## 1 · Operational Excellence

**Goal:** Run and monitor systems to deliver business value and continually improve.

| Practice | Expectation |
|---|---|
| **Infrastructure as Code** | All cloud resources (compute, storage, networking, IAM) must be defined in code — AWS CDK preferred, CloudFormation or Terraform acceptable. No ClickOps. |
| **Observability** | Emit structured JSON logs with consistent fields: `request_id`, `operation`, `duration_ms`, `status`. Integrate with CloudWatch Logs, X-Ray, or an equivalent observability stack. |
| **Runbooks** | Document every operational procedure (deployment, rollback, credential rotation, incident response) in the repo so any operator can execute without tribal knowledge. |
| **Small, frequent changes** | PRs should be focused and atomic. Deployment pipelines must support automated rollback. Feature flags over long-lived branches. |
| **Failure anticipation** | Handle upstream service failures gracefully — return structured error responses, never unhandled exceptions. Run game days or chaos experiments where appropriate. |
| **Post-incident learning** | Conduct blameless post-mortems for every production incident; track action items to completion. |

---

## 2 · Security

**Goal:** Protect data, systems, and assets through defence in depth.

| Practice | Expectation |
|---|---|
| **Identity & least privilege** | Execution roles and service accounts must have only the minimum IAM permissions required. Never use wildcard (`*`) actions or resources in production policies. |
| **Protect data in transit** | All network communication must use TLS 1.2+. Never downgrade to plain HTTP. Enforce HTTPS at the load-balancer and application level. |
| **Protect data at rest** | Secrets, tokens, and credentials must never be committed to source control or written to disk unencrypted. Use AWS Secrets Manager, Parameter Store (SecureString), or an equivalent vault. |
| **Audit trail** | Log all mutating operations with timestamps, actor identity, and resource affected. Ship audit logs to a tamper-evident store (e.g., CloudTrail, S3 with Object Lock). |
| **Dependency scanning** | Run a software composition analysis tool (e.g., `npm audit`, `pip-audit`, Dependabot, Snyk) in CI. Block merges on high/critical CVEs. Patch within 30 days. |
| **Static analysis** | Integrate SAST tooling into the CI pipeline. Address findings before merge — do not accumulate a backlog of suppressed warnings. |
| **Network segmentation** | Deploy workloads in private subnets where possible. Use security groups and NACLs with deny-by-default rules. Expose only what is explicitly required. |

<!-- PROJECT: Link to your project's security-specific instructions if they exist, e.g.:
- See `standards/security.md` for OWASP-specific controls.
-->

---

## 3 · Reliability

**Goal:** Perform intended functions correctly and consistently, recovering quickly from failure.

| Practice | Expectation |
|---|---|
| **Graceful degradation** | When an upstream dependency is unreachable or returns an error, the application must return a structured error — never crash the process or leave the caller hanging. |
| **Retry with backoff** | For transient failures (5xx, network timeouts), implement exponential backoff with jitter. See pseudocode below. |
| **Health checks** | Expose a health/readiness endpoint or startup probe. Application initialisation must not block on network I/O — use lazy or deferred initialisation for external clients. |
| **Idempotency** | Mutating operations (writes, deletes, state changes) must be idempotent. Use deduplication keys, conditional writes, or compare-and-swap where applicable. |
| **Timeouts** | Set explicit timeouts on all outbound calls (HTTP, database, queue). Never allow unbounded waits. |
| **Circuit breakers** | When an upstream dependency fails repeatedly, stop calling it temporarily to allow recovery. Use a circuit-breaker pattern or equivalent library. |
| **Data durability** | Critical data must be backed up with tested restore procedures. Define RPO and RTO for each data store and validate them periodically. |

**Retry pseudocode:**

```
function retry(operation, max_attempts = 3, base_delay = 1.0):
    for attempt in 0 .. max_attempts - 1:
        try:
            return operation()
        catch TransientError:
            if attempt == max_attempts - 1: raise
            sleep(base_delay * 2^attempt + random(0, 0.5))
```

<!-- PROJECT: Add language-specific retry implementation for your stack -->

---

## 4 · Performance Efficiency

**Goal:** Use resources efficiently to meet requirements and maintain efficiency as demand evolves.

| Practice | Expectation |
|---|---|
| **Pagination & result limits** | API responses and internal queries must be paginated or capped. Never return unbounded result sets — define a sensible `MAX_RESULTS` constant and enforce it. |
| **Connection reuse** | Initialise HTTP/database clients once and reuse across requests. Never create a new connection per operation. Use connection pooling where applicable. |
| **Async & concurrency** | Use asynchronous I/O or concurrent execution for I/O-bound workloads (network calls, file operations). Avoid blocking the main thread/event loop. |
| **Caching strategy** | Cache read-heavy, infrequently-changing data close to the consumer (in-memory, local file, ElastiCache, CloudFront). Define TTLs and invalidation rules explicitly. |
| **Minimise data movement** | Request only the fields needed. Avoid fetching full records when a subset suffices. Compress payloads in transit where beneficial. |
| **Benchmarking** | Establish baseline latency metrics (p50, p95, p99) for critical paths. Alert on regressions. Profile before optimising — measure, don't guess. |

<!-- PROJECT: Document your caching strategy, e.g.:
| Cache layer | Technology | TTL | Invalidation |
|---|---|---|---|
| [CACHE_STRATEGY] | [TECHNOLOGY] | [TTL] | [TRIGGER] |
-->

---

## 5 · Cost Optimisation

**Goal:** Deliver business value at the lowest price point.

| Practice | Expectation |
|---|---|
| **Avoid unnecessary calls** | Cache upstream responses and check local state before making network requests. Never call external APIs in polling loops without backoff and caps. |
| **Minimise dependencies** | Each added dependency increases supply-chain risk, build time, and potential licensing cost. Evaluate necessity before adding packages; prefer standard-library equivalents where they exist. |
| **Right-size compute** | Start with the smallest instance/memory configuration that meets p99 latency targets. Measure, then scale — do not over-provision speculatively. |
| **Data transfer awareness** | Understand data-transfer costs across regions and AZs. Colocate compute and storage. Avoid cross-region calls where same-region alternatives exist. |
| **Lifecycle policies** | Apply S3 lifecycle rules, log retention policies, and database TTLs. Do not store data indefinitely without a business justification. |
| **Reserved & spot capacity** | For predictable workloads, use Reserved Instances or Savings Plans. For fault-tolerant batch work, consider Spot Instances. |
| **Tagging** | Tag all cloud resources with at minimum: `project`, `environment`, `owner`, and `cost-centre`. Use AWS Cost Explorer and budgets to monitor spend. |

---

## 6 · Sustainability

**Goal:** Minimise the environmental impact of workloads.

| Practice | Expectation |
|---|---|
| **Efficient resource use** | Scale down or shut off resources when not in use (e.g., dev/staging environments outside business hours). Use auto-scaling rather than static over-provisioning. |
| **Efficient data retrieval** | Fetch only the fields and records required for a given operation. Avoid full-table scans and over-fetching from APIs. |
| **Avoid polling** | Prefer event-driven architectures (webhooks, SNS/SQS, EventBridge) over periodic polling. If polling is unavoidable, use adaptive intervals. |
| **Lean dependencies** | Prefer lightweight libraries over heavyweight frameworks where equivalent functionality exists. Smaller artefacts = faster cold starts and less compute. |
| **ARM-based compute** | Where supported, use Graviton (ARM) instances for approximately 20% better price-performance and lower energy consumption. |
| **Efficient CI/CD** | Cache build artefacts, use incremental builds, and avoid redundant test runs. Green builds should be the norm, not the exception. |

---

## Non-Negotiables

These ten rules are non-negotiable regardless of project phase, deadline pressure,
or scope:

| # | Rule |
|---|---|
| 1 | **No secrets in source control.** Credentials, tokens, and keys must live in a secrets manager or environment variables — never committed to the repo. |
| 2 | **No ClickOps.** All infrastructure is defined in code and deployed through a pipeline. Manual console changes are forbidden in production. |
| 3 | **No wildcard IAM permissions in production.** Every role follows least-privilege. `Action: "*"` or `Resource: "*"` on production policies is a blocking finding. |
| 4 | **No unhandled exceptions in production paths.** Every external call is wrapped in error handling that returns a structured response. |
| 5 | **No unbounded queries or API responses.** All data retrieval must have explicit limits, pagination, or timeouts. |
| 6 | **No HTTP in production.** All data in transit is encrypted with TLS 1.2+. No exceptions. |
| 7 | **No merges with critical/high CVEs.** Dependency scanning runs in CI; unresolved critical or high vulnerabilities block the merge. |
| 8 | **No deployment without rollback capability.** Every deployment mechanism must support automated rollback within minutes. |
| 9 | **No data stores without backup and retention policies.** Every persistent store has defined RPO/RTO, automated backups, and tested restore procedures. |
| 10 | **No cloud resources without tags.** All resources are tagged for cost allocation, ownership, and lifecycle management. |

---

## Decision Checklist

Before merging any significant change, verify:

**Operational Excellence**
- [ ] Change is deployable and rollback-able via the CI/CD pipeline
- [ ] Structured logging is present for new operations
- [ ] Runbooks and documentation are updated if operational procedures changed

**Security**
- [ ] No secrets, tokens, or credentials are hardcoded or committed
- [ ] New IAM permissions follow least-privilege
- [ ] Dependency scan passes with no critical/high findings
- [ ] Input validation is applied to all external inputs

**Reliability**
- [ ] External calls have explicit timeouts and retry logic
- [ ] Failures return structured errors — no unhandled crashes
- [ ] Mutating operations are idempotent
- [ ] Health checks and readiness probes are in place

**Performance Efficiency**
- [ ] API responses are paginated or capped
- [ ] Connections and clients are reused, not recreated per request
- [ ] Caching is applied where reads significantly outnumber writes
- [ ] No N+1 query patterns or unbounded loops over external calls

**Cost Optimisation**
- [ ] Local cache is consulted before making network requests
- [ ] Compute is right-sized based on measured requirements
- [ ] Data retention and lifecycle policies are defined
- [ ] New cloud resources are tagged appropriately

**Sustainability**
- [ ] Only necessary data is fetched — no over-fetching
- [ ] Event-driven patterns are preferred over polling
- [ ] Build and test pipelines are efficient (caching, incremental builds)
- [ ] ARM-compatible where applicable
