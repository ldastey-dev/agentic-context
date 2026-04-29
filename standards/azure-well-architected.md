# Azure Well-Architected Framework Guidelines

Every design decision in this repository must be evaluated against the Azure
Well-Architected Framework's five pillars. Whether the application runs locally
today or is already cloud-deployed, these principles apply — retrofitting
architectural quality is significantly costlier than building it in from day one.

---

## 1 · Reliability

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
| **Availability zones** | Deploy stateless workloads across availability zones where supported. Use zone-redundant configurations for Azure services (AKS, Cosmos DB, Blob Storage). |

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

## 2 · Security

**Goal:** Protect data, systems, and assets through defence in depth.

| Practice | Expectation |
|---|---|
| **Identity & least privilege** | Use Azure Managed Identity for service-to-service authentication. Azure RBAC role assignments must grant only the minimum permissions required. Never assign `Owner` or `Contributor` at a broad scope without justification. Use Entra ID for identity governance. |
| **Protect data in transit** | All network communication must use TLS 1.2+. Never downgrade to plain HTTP. Enforce HTTPS at the ingress controller and application level. |
| **Protect data at rest** | Secrets, tokens, and credentials must never be committed to source control or written to disk unencrypted. Use Azure Key Vault for all secret management. Enable encryption at rest on all Azure data stores. |
| **Audit trail** | Log all mutating operations with timestamps, actor identity, and resource affected. Ship audit logs to a tamper-evident store. Enable Azure Activity Log and Diagnostic Settings for all resources. |
| **Dependency scanning** | Run a software composition analysis tool (e.g., `npm audit`, `pip-audit`, Dependabot, Snyk) in CI. Block merges on high/critical CVEs. Patch within 30 days. |
| **Static analysis** | Integrate SAST tooling into the CI pipeline. Address findings before merge — do not accumulate a backlog of suppressed warnings. |
| **Network segmentation** | Deploy workloads in private virtual networks where possible. Use NSGs with deny-by-default rules, Azure Firewall for centralised egress control, and Private Endpoints for PaaS services. Expose only what is explicitly required. |

<!-- PROJECT: Link to your project's security-specific instructions if they exist, e.g.:
- See `standards/security.md` for OWASP-specific controls.
- See your Entra ID tenant documentation for conditional access policies.
-->

---

## 3 · Cost Optimisation

**Goal:** Deliver business value at the lowest price point.

| Practice | Expectation |
|---|---|
| **Avoid unnecessary calls** | Cache upstream responses and check local state before making network requests. Never call external APIs in polling loops without backoff and caps. |
| **Minimise dependencies** | Each added dependency increases supply-chain risk, build time, and potential licensing cost. Evaluate necessity before adding packages; prefer standard-library equivalents where they exist. |
| **Right-size compute** | Start with the smallest SKU or node pool configuration that meets p99 latency targets. Measure, then scale — do not over-provision speculatively. Use AKS node auto-scaling. |
| **Data transfer awareness** | Understand data-transfer costs across regions and availability zones. Colocate compute and storage. Avoid cross-region calls where same-region alternatives exist. |
| **Lifecycle policies** | Apply Blob Storage lifecycle management rules, Log Analytics retention policies, and database TTLs. Do not store data indefinitely without a business justification. |
| **Reserved & spot capacity** | For predictable workloads, use Azure Reserved Instances or Azure Savings Plans. For fault-tolerant batch work, consider Spot VMs. |
| **Tagging** | Tag all cloud resources with at minimum: `project`, `environment`, `owner`, and `cost-centre`. Use Azure Cost Management and Azure Advisor to monitor spend. |

---

## 4 · Operational Excellence

**Goal:** Run and monitor systems to deliver business value and continually improve.

| Practice | Expectation |
|---|---|
| **Infrastructure as Code** | All cloud resources (compute, storage, networking, RBAC) must be defined in code — Terraform (AzureRM or AzAPI provider) or Bicep; ARM templates are acceptable for parity with existing modules. No ClickOps. |
| **Observability** | Emit structured JSON logs with consistent fields: `request_id`, `operation`, `duration_ms`, `status`. Integrate with Azure Monitor, Application Insights, Log Analytics, and OpenTelemetry. |
| **Runbooks** | Document every operational procedure (deployment, rollback, credential rotation, incident response) in the repo so any operator can execute without tribal knowledge. |
| **Small, frequent changes** | PRs should be focused and atomic. Deployment pipelines must support automated rollback. Feature flags over long-lived branches. |
| **Failure anticipation** | Handle upstream service failures gracefully — return structured error responses, never unhandled exceptions. Run game days or chaos experiments where appropriate. |
| **Post-incident learning** | Conduct blameless post-mortems for every production incident; track action items to completion. |
| **Azure Policy** | Enforce organisational guardrails through Azure Policy definitions and initiatives. Assign policies at the management group or subscription scope to prevent non-compliant resources from being created (e.g. deny public IP on subnets, require tags, enforce allowed SKUs). Use audit-mode policies to surface drift without blocking. Combine with Defender for Cloud regulatory compliance dashboards to track posture continuously. |

---

## 5 · Performance Efficiency

**Goal:** Use resources efficiently to meet requirements and maintain efficiency as demand evolves.

| Practice | Expectation |
|---|---|
| **Pagination & result limits** | API responses and internal queries must be paginated or capped. Never return unbounded result sets — define a sensible `MAX_RESULTS` constant and enforce it. |
| **Connection reuse** | Initialise HTTP/database clients once and reuse across requests. Never create a new connection per operation. Use connection pooling where applicable. |
| **Async & concurrency** | Use asynchronous I/O or concurrent execution for I/O-bound workloads (network calls, file operations). Avoid blocking the main thread/event loop. |
| **Caching strategy** | Cache read-heavy, infrequently-changing data close to the consumer (in-memory, local file, Azure Cache for Redis, Azure Front Door). Define TTLs and invalidation rules explicitly. |
| **Minimise data movement** | Request only the fields needed. Avoid fetching full records when a subset suffices. Compress payloads in transit where beneficial. |
| **Benchmarking** | Establish baseline latency metrics (p50, p95, p99) for critical paths. Alert on regressions. Profile before optimising — measure, don't guess. |
| **Auto-scaling** | Configure AKS cluster autoscaler to add and remove nodes based on pending pod demand. Enable Horizontal Pod Autoscaler (HPA) for each workload deployment, targeting CPU and memory utilisation or custom KEDA metrics. Set resource `requests` and `limits` on every container — HPA cannot function without them. Define minimum and maximum replica counts to bound cost and ensure baseline availability. |

<!-- PROJECT: Document your caching strategy, e.g.:
| Cache layer | Technology | TTL | Invalidation |
|---|---|---|---|
| [CACHE_STRATEGY] | [TECHNOLOGY] | [TTL] | [TRIGGER] |
-->

---

## Non-Negotiables

These ten rules are non-negotiable regardless of project phase, deadline pressure,
or scope:

| # | Rule |
|---|---|
| 1 | **No secrets in source control.** Credentials, tokens, and keys must live in Azure Key Vault or environment variables — never committed to the repo. |
| 2 | **No ClickOps.** All infrastructure is defined in Terraform (AzureRM or AzAPI), Bicep, or ARM templates and deployed through a pipeline. Manual portal changes are forbidden in production. |
| 3 | **No overly broad Azure RBAC role assignments in production.** Every identity follows least-privilege. `Owner` or `Contributor` at subscription scope on production resources is a blocking finding. |
| 4 | **No unhandled exceptions in production paths.** Every external call is wrapped in error handling that returns a structured response. |
| 5 | **No unbounded queries or API responses.** All data retrieval must have explicit limits, pagination, or timeouts. |
| 6 | **No HTTP in production.** All data in transit is encrypted with TLS 1.2+. No exceptions. |
| 7 | **No merges with critical/high CVEs.** Dependency scanning runs in CI; unresolved critical or high vulnerabilities block the merge. |
| 8 | **No deployment without rollback capability.** Every deployment mechanism must support automated rollback within minutes. |
| 9 | **No data stores without backup and retention policies.** Every persistent store has defined RPO/RTO, automated backups, and tested restore procedures. |
| 10 | **No cloud resources without tags.** All resources are tagged for cost allocation, ownership, and lifecycle management. Use Azure Cost Management to verify. |

---

## Decision Checklist

Before merging any significant change, verify:

**Reliability**
- [ ] External calls have explicit timeouts and retry logic
- [ ] Failures return structured errors — no unhandled crashes
- [ ] Mutating operations are idempotent
- [ ] Health checks and readiness probes are in place
- [ ] Stateless workloads are deployed across availability zones where supported

**Security**
- [ ] No secrets, tokens, or credentials are hardcoded or committed
- [ ] New RBAC role assignments and Managed Identity permissions follow least-privilege
- [ ] Dependency scan passes with no critical/high findings
- [ ] Input validation is applied to all external inputs

**Cost Optimisation**
- [ ] Local cache is consulted before making network requests
- [ ] Compute is right-sized based on measured requirements
- [ ] Data retention and lifecycle policies are defined
- [ ] New cloud resources are tagged appropriately

**Operational Excellence**
- [ ] Change is deployable and rollback-able via the CI/CD pipeline
- [ ] Structured logging is present for new operations
- [ ] Runbooks and documentation are updated if operational procedures changed

**Performance Efficiency**
- [ ] API responses are paginated or capped
- [ ] Connections and clients are reused, not recreated per request
- [ ] Caching is applied where reads significantly outnumber writes
- [ ] No N+1 query patterns or unbounded loops over external calls
