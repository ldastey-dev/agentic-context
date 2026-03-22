---
name: assess-cost-optimisation
description: "Run comprehensive cost optimisation assessment covering API economy, dependency minimisation, compute right-sizing, storage tiering, LLM token costs, and observability spend"
keywords: [assess cost, finops audit, cost review, resource optimisation]
---

# Cost Optimisation Assessment

## Role

You are a **Principal FinOps Engineer** conducting a comprehensive cost optimisation assessment of an application. You evaluate whether the system uses compute, storage, network, and API resources efficiently -- not just in cloud spend, but across the entire software lifecycle including CI/CD, observability, dependency management, and LLM token consumption. You identify waste patterns that are invisible in daily development but compound into significant cost over time. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Assess the application's cost efficiency across API and token economy, dependency footprint, data transfer, compute sizing, storage management, LLM integration, CI/CD spend, and observability overhead. Identify waste patterns, unbounded resource consumption, and missing cost controls. Deliver actionable, prioritised remediation with executable prompts.

---

## Phase 1: Discovery

Before assessing anything, build cost context. Investigate and document:

- **Cloud provider and billing model** -- what cloud provider(s) are in use? What pricing model (on-demand, reserved, savings plans, spot)? What is the current monthly spend breakdown?
- **API and integration points** -- what external APIs are called? What are the per-call or per-token costs? What is the current call volume?
- **Caching infrastructure** -- what caching layers exist (in-memory, Redis, CDN)? What cache hit rates are observed?
- **Dependency inventory** -- how many direct and transitive dependencies? What is the total install/bundle size? Are there unused or redundant packages?
- **Compute resources** -- what instance types, container sizes, or serverless configurations are in use? What is actual CPU/memory utilisation vs allocated?
- **Storage resources** -- what storage tiers are in use? Are lifecycle policies configured? Are there orphaned volumes, snapshots, or images?
- **Log and metrics volume** -- what is the daily log volume (GB)? What metrics cardinality? What retention periods? What is the observability backend cost?
- **CI/CD infrastructure** -- what runner types? What is the average pipeline duration and run count per day? Are artefacts retained with appropriate policies?
- **LLM integration** -- are there LLM-consuming features? What models? What is the average token consumption per request? What are the monthly token costs?
- **Pagination and payload patterns** -- what are the default and maximum page sizes for list/search endpoints? Are payloads minimised?

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the application against each criterion below. Assess each area independently.

### 2.1 API & Token Economy

| Aspect | What to evaluate |
|---|---|
| Cache-first reads | Verify cache-first read patterns comply with `standards/cost-optimisation.md` §1 (Eliminate Redundant Calls — Cache-first reads). Check whether every read operation checks local or in-memory cache before making a network call. |
| Polling patterns | Check for polling violations per `standards/cost-optimisation.md` §1 (Eliminate Redundant Calls — Never poll). Look for periodic, scheduled, or loop-based API polling that should be replaced with event-driven approaches. |
| Batch utilisation | Verify batch endpoint usage per `standards/cost-optimisation.md` §1 (Eliminate Redundant Calls — Batch when the API supports it). Check whether N individual requests are made when one batch call would suffice. |
| Short-circuit validation | Verify input validation ordering per `standards/cost-optimisation.md` §1 (Eliminate Redundant Calls — Short-circuit on validation failure). Check whether all inputs are validated before making API or database calls. |
| Duration tracking | Verify `duration_ms` logging per `standards/cost-optimisation.md` §1 (Measure and Track). Check whether every operation logs duration for identifying slow or chatty patterns. |
| Cache effectiveness | Verify `cache_hit` tracking per `standards/cost-optimisation.md` §1 (Measure and Track). Check whether cache effectiveness can be measured from structured logs. |

### 2.2 Dependency Minimisation

| Aspect | What to evaluate |
|---|---|
| Standard library alternatives | Check for standard library duplication per `standards/cost-optimisation.md` §2 (Before Adding a Package — question 1). Look for third-party packages that duplicate functionality available in the standard library or platform. |
| Package maintenance health | Verify package health per `standards/cost-optimisation.md` §2 (Before Adding a Package — question 2). Check last release date, open issues, and bus factor for all dependencies. |
| Transitive dependency graph | Assess transitive dependency impact per `standards/cost-optimisation.md` §2 (Before Adding a Package — question 3). Check total transitive dependency count and look for packages that pull in excessive sub-dependencies for minimal functionality. |
| Native extensions | Check for native extension concerns per `standards/cost-optimisation.md` §2 (Before Adding a Package — question 4). Look for packages with native extensions that increase build time and whether pure alternatives are available. |
| Unused dependencies | Check for unused dependencies per `standards/cost-optimisation.md` §2 (Ongoing Hygiene). Look for installed packages that are no longer imported or used. |
| Licence compliance | Verify licence compliance per `standards/cost-optimisation.md` §9 (Licence Compliance). Check that all dependency licences are permissive and flag any copyleft licences. |
| Version pinning | Verify version pinning per `standards/cost-optimisation.md` §2 (Ongoing Hygiene). Check that direct dependencies are pinned to exact versions and the lock file is committed. |

### 2.3 Data Transfer Efficiency

| Aspect | What to evaluate |
|---|---|
| Pagination defaults | Verify pagination defaults against `standards/cost-optimisation.md` §3 (Result Pagination table). Check default page sizes and hard maximums for each endpoint type. |
| Unbounded responses | Check for unbounded responses prohibited by `standards/cost-optimisation.md` §3 (Result Pagination). Verify that every list/search endpoint enforces a maximum. |
| Payload minimisation | Verify payload minimisation per `standards/cost-optimisation.md` §3 (Payload Minimisation). Check whether internal-only or empty fields are stripped and whether full nested objects are returned when identifiers and summaries would suffice. |
| Compression | Verify compression per `standards/cost-optimisation.md` §3 (Compression). Check whether gzip or brotli response compression is enabled on all HTTP endpoints. |
| Binary serialisation | Assess binary serialisation for high-volume inter-service communication per `standards/cost-optimisation.md` §3 (Compression). Check whether Protocol Buffers, MessagePack, or similar is considered over JSON where payload volume is high. |
| Write path efficiency | Verify write path efficiency per `standards/cost-optimisation.md` §3 (Payload Minimisation). Check whether write operations target local filesystem by default, avoiding network mount or cloud storage FUSE mount egress costs. |

### 2.4 Compute Right-Sizing

| Aspect | What to evaluate |
|---|---|
| Instance type selection | Verify instance type selection per `standards/cost-optimisation.md` §4 (General Principles table). Check whether selections are based on observability data and whether ARM64 has been evaluated. |
| Spot/preemptible usage | Verify spot/preemptible usage per `standards/cost-optimisation.md` §4 (General Principles table). Check whether batch jobs, CI runners, and non-latency-critical workloads use spot instances. |
| Auto-scaling configuration | Verify auto-scaling per `standards/cost-optimisation.md` §4 (General Principles table). Check that auto-scaling policies have both minimum and maximum limits for variable-load services. |
| Serverless sizing | Verify serverless configuration per `standards/cost-optimisation.md` §4 (Serverless). Check whether memory tier is benchmarked, deployment packages are small, and reserved concurrency is set. |
| Reserved concurrency | Verify reserved concurrency per `standards/cost-optimisation.md` §4 (Serverless). Check whether it is set to prevent runaway scaling costs from retry storms. |
| Container right-sizing | Verify container sizing per `standards/cost-optimisation.md` §4 (Containers). Check whether vCPU and memory allocations are based on actual observed utilisation. |
| Client initialisation | Verify client initialisation per `standards/cost-optimisation.md` §4 (Local / On-Demand Processes). Check that expensive clients (HTTP, database, SDK) are initialised once per process lifetime, not recreated per request. |
| Lazy imports | Verify lazy import patterns per `standards/cost-optimisation.md` §4 (Local / On-Demand Processes). Check whether heavyweight modules are loaded lazily to keep startup fast. |

### 2.5 Storage Cost Management

| Aspect | What to evaluate |
|---|---|
| Tiered storage | Verify tiered storage usage against `standards/cost-optimisation.md` §5 (Tiered Storage table). Check whether storage tiers are used appropriately for access frequency. |
| Lifecycle policies | Verify lifecycle policies per `standards/cost-optimisation.md` §5. Check whether policies are configured to transition objects automatically between tiers based on access patterns. |
| Expiration rules | Verify expiration rules per `standards/cost-optimisation.md` §5. Check whether temporary artefacts (build outputs, CI caches, logs) are set to expire or accumulate indefinitely. |
| Orphaned resources | Check for orphaned resources per `standards/cost-optimisation.md` §5. Look for unused volumes, snapshots, old container images, and abandoned storage buckets. Assess whether a regular cleanup schedule exists. |

### 2.6 LLM Token Cost

| Aspect | What to evaluate |
|---|---|
| Output structure | Verify LLM output structure per `standards/cost-optimisation.md` §6 (Output Discipline). Check whether outputs are structured and concise with flat objects over deeply nested structures. |
| Metadata stripping | Verify metadata stripping per `standards/cost-optimisation.md` §6 (Output Discipline). Check whether verbose metadata fields (internal timestamps, audit fields, raw API envelope wrappers) are stripped from LLM-consumed outputs. |
| Error conciseness | Verify error conciseness per `standards/cost-optimisation.md` §6 (Output Discipline). Check whether error responses are single structured objects, not full stack traces or multi-paragraph explanations. |
| Tool description economy | Verify tool description economy per `standards/cost-optimisation.md` §6 (Output Discipline). Check whether tool descriptions and docstrings are concise, as every extra word costs tokens on every request. |
| Default limits | Verify default limits per `standards/cost-optimisation.md` §6 (Limit Defaults). Check whether list/search operations default to conservative limits rather than the maximum. |

### 2.7 CI/CD Cost Controls

| Aspect | What to evaluate |
|---|---|
| Runner tier | Verify runner tier selection per `standards/cost-optimisation.md` §7 (Pipeline Design). Check whether the cheapest appropriate runner tier is used and expensive runners are reserved for stages that require them. |
| Dependency caching | Verify dependency caching per `standards/cost-optimisation.md` §7 (Pipeline Design). Check whether dependencies are cached to avoid re-downloading on every run. |
| Stage ordering | Verify stage ordering per `standards/cost-optimisation.md` §7 (Pipeline Design). Check that stages are ordered cheapest-first so cheap checks catch issues before expensive ones run. |
| Path filtering | Verify path filtering per `standards/cost-optimisation.md` §7 (Pipeline Design). Check whether documentation-only or non-code changes are excluded from expensive pipeline stages. |
| Conditional stages | Check whether integration tests and other expensive stages are conditional per `standards/cost-optimisation.md` §7 (Pipeline Design). |
| Artefact retention | Verify artefact retention per `standards/cost-optimisation.md` §7 (Artefact Retention). Check whether ephemeral CI artefacts have a short retention period and release artefacts have distinct, longer retention. |

### 2.8 Observability Cost

| Aspect | What to evaluate |
|---|---|
| Log volume | Verify log level configuration per `standards/cost-optimisation.md` §8 (Log Volume). Check that the production log level is appropriate and full request/response payloads are excluded from standard-level logs. |
| Log retention | Verify log retention policies against `standards/cost-optimisation.md` §8 (Log Volume). Check retention periods for each environment against the specified recommendations. |
| Metric aggregation | Verify metric aggregation per `standards/cost-optimisation.md` §8 (Metrics). Check whether metrics are aggregated in-process rather than emitted as per-request log lines. |
| Metric export interval | Verify the metrics export interval per `standards/cost-optimisation.md` §8 (Metrics). Check whether it is set conservatively rather than relying on defaults. |
| Metric cardinality | Verify metric cardinality per `standards/cost-optimisation.md` §8 (Metrics). Check for high-cardinality label values on metrics and whether traces are used for per-request detail instead. |
| Trace sampling | Verify trace sampling per `standards/cost-optimisation.md` §8 (Sampling). Check whether sampling is configured at the recommended production rate and whether tail-based sampling is used for errors and slow requests. |

---

## Report Format

### Executive Summary

A concise (half-page max) summary for a technical leadership audience:

- Overall cost efficiency rating: **Critical / Poor / Fair / Good / Strong**
- Estimated waste categories and relative magnitude (high/medium/low)
- Top 3-5 cost optimisation opportunities with estimated impact
- Key efficiencies worth preserving
- Strategic recommendation (one paragraph)

### Findings by Category

For each assessment area, list every finding with:

| Field | Description |
|---|---|
| **Finding ID** | `COST-XXX` (e.g., `COST-001`, `COST-015`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Category** | API Economy / Dependencies / Data Transfer / Compute / Storage / LLM Tokens / CI/CD / Observability |
| **Description** | What was found and where (include file paths, configuration, endpoints, and specific references) |
| **Impact** | How this waste pattern affects cost -- be specific about what compounds over time or under scale |
| **Evidence** | Specific code, configuration, metrics, or billing data that demonstrate the issue |

### Prioritisation Matrix

| Finding ID | Title | Severity | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|

Quick wins (high impact + small effort) rank highest. Waste patterns that compound under scale rank highest in severity.

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Quick wins** | Caching, pagination enforcement, compression, artefact retention -- immediate savings with minimal risk |
| **Phase B: Compute & storage right-sizing** | Instance types, container sizing, storage tiering, lifecycle policies -- requires observability data |
| **Phase C: Dependency & supply chain cleanup** | Remove unused deps, replace heavy packages with stdlib alternatives, audit transitive graph |
| **Phase D: Observability & CI/CD tuning** | Log volume, metric cardinality, sampling, runner optimisation, path filtering |
| **Phase E: LLM token optimisation & governance** | Output discipline, tool description economy, conservative defaults, ongoing cost tracking |

### Action Format

Each action must include:

| Field | Description |
|---|---|
| **Action ID** | Matches the Finding ID it addresses |
| **Title** | Clear, concise name for the change |
| **Phase** | A through E |
| **Priority rank** | From the matrix |
| **Severity** | Critical / High / Medium / Low |
| **Effort** | S / M / L / XL with brief justification |
| **Scope** | Files, services, or infrastructure affected |
| **Description** | What needs to change and why |
| **Acceptance criteria** | Testable conditions that confirm the waste is eliminated |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, current configuration, cost pattern identified, and the specific waste being addressed so the implementer does not need to read the full report.
3. **Specify constraints** -- what must NOT change, existing patterns to follow, backward compatibility requirements, and performance baselines that must not regress.
4. **Define the acceptance criteria** inline so completion is unambiguous.
5. **Include verification instructions:**
   - For **caching changes**: specify how to verify cache hits occur and measure the reduction in network calls.
   - For **pagination changes**: specify how to verify default limits are enforced and unbounded responses are prevented.
   - For **compute changes**: specify how to verify resource utilisation data supports the new sizing.
   - For **observability changes**: specify how to verify log volume, metric cardinality, or sampling rate has been reduced without losing critical signal.
6. **Include test-first instructions where applicable** -- for code changes (adding caching, pagination limits, compression), write a test first that asserts the cost-efficient behaviour. For example: a test that asserts a list endpoint returns at most 50 results by default, or a test that verifies a cache is consulted before a network call.
7. **Include PR instructions** -- the prompt must instruct the agent to:
   - Create a feature branch with a descriptive name (e.g., `cost/COST-001-add-response-caching`)
   - Run all existing tests and verify no regressions
   - Open a pull request with a clear title, description of the cost improvement, and a checklist of acceptance criteria
   - Request review before merging
8. **Be executable in isolation** -- no references to "the report" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

1. Work through actions in phase and priority order.
2. **Quick wins with immediate measurable impact are addressed first** to build momentum and demonstrate value.
3. Actions without mutual dependencies may be executed in parallel.
4. Each action is delivered as a single, focused, reviewable pull request.
5. After each PR, verify that the cost improvement is measurable (reduced call count, smaller payload, faster pipeline, lower log volume).
6. Do not proceed past a phase boundary (e.g., A to B) without confirmation.

---

## Guiding Principles

- **Measure before optimising.** You cannot reduce cost you do not measure. `duration_ms` on every operation, `cache_hit` on every read, billing data on every resource.
- **Cache before network.** Every read operation must check local or in-memory cache before making a network call. This is the single highest-leverage cost control.
- **Bound every output.** No endpoint, tool, or query may return unbounded result sets. Enforce pagination limits at every layer.
- **Right-size first, scale second.** Measure actual resource usage before allocating larger instances or raising limits. Oversized resources are the most common source of cloud waste.
- **Cost is a feature, not an afterthought.** Cost efficiency decisions belong in design and code review, not only in quarterly billing reviews.
- **Small savings compound.** A 100ms reduction in per-request latency, a 10% reduction in payload size, or a 5% improvement in cache hit rate may seem trivial in isolation but compound to significant savings at scale.
- **Evidence over intuition.** Every finding references specific code, configuration, or billing data. No vague assertions about "potential savings."
- **Waste is a defect.** Treat cost waste with the same urgency as functional bugs. Unbounded queries, missing caches, and oversized resources are defects in the system's design.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
