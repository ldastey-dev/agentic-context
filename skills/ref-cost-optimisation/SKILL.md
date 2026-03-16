---
name: ref-cost-optimisation
description: "FinOps and cost-aware engineering standards covering caching strategy, dependency minimisation, CI ordering, log retention, and resource right-sizing"
user-invocable: false
---

# Cost Optimisation Standards — AWS Well-Architected Pillar 5

All design and implementation decisions must account for cost efficiency. These
principles apply to local resource consumption (CPU, memory, network, API quota)
and become critical when services are deployed to cloud environments.

---

## 1 · API & Token Economy

### Eliminate Redundant Calls

- **Cache-first reads.** Always check local or in-memory caches before making
  network requests. Use `[CACHE_STRATEGY]` (e.g., in-memory LRU, on-disk cache,
  Redis) appropriate to the data's freshness requirements.
- **Never poll.** Do not implement periodic, scheduled, or loop-based API polling
  unless the architecture explicitly requires it. Prefer event-driven patterns
  (webhooks, pub/sub, server-sent events) over polling.
- **Batch when the API supports it.** Where an API accepts multiple identifiers
  in a single call, always use the batch endpoint rather than issuing N individual
  requests.
- **Short-circuit on validation failure.** Validate all inputs *before* making any
  API or database call. Reject invalid requests immediately rather than consuming
  a network round-trip.

### Measure and Track

- Log `duration_ms` on every operation so slow or chatty patterns can be
  identified via log analysis.
- Consider adding a `cache_hit` boolean attribute to structured logs so cache
  effectiveness can be measured without code changes.

---

## 2 · Dependency Minimisation

### Before Adding a Package
Answer **all** of the following:

1. **Is there a stdlib or platform alternative?** Prefer built-in modules and
   platform APIs over third-party equivalents.
2. **Is the package actively maintained?** Check the last release date, open
   issue count, and bus factor (single-maintainer packages are risky).
3. **What is the transitive dependency graph?** A single install can pull dozens
   of packages. Use `[PACKAGE_MANAGER]` tree/list commands to audit before
   committing.
4. **Does it have native extensions?** Native extensions increase build time,
   platform-specific failures, and container image size. Prefer pure
   implementations where performance is equivalent.
5. **What is the licence?** Only permissive licences (MIT, Apache-2.0, BSD) are
   acceptable. Copyleft (GPL, AGPL) requires legal review.

### Ongoing Hygiene

- Pin exact versions for direct dependencies to prevent unexpected cost from
  debugging non-reproducible builds.
- Run `[PACKAGE_MANAGER]` outdated/audit commands periodically and evaluate
  upgrades for cost-relevant bug fixes (memory leaks, performance regressions).
- Remove unused dependencies promptly — dead imports still contribute to cold
  start time and bundle/image size.

---

## 3 · Data Transfer Efficiency

### Result Pagination

- Enforce a sensible default page size and a hard maximum. Large unbounded
  responses waste bandwidth, memory, and (for LLM consumers) tokens.
- When consumers need more results, prefer refined queries or cursor-based
  pagination over raising the cap.

| Scenario               | Recommended default | Hard maximum |
|------------------------|--------------------:|-------------:|
| List / search APIs     |                  50 |          200 |
| Autocomplete / suggest |                  10 |           25 |
| Export / bulk           |                 500 |        5 000 |

### Payload Minimisation

- Strip internal-only or empty fields from API responses before returning them.
  Centralise this in a shared utility rather than per-endpoint ad-hoc trimming.
- Prefer returning identifiers and summaries over full nested objects. Consumers
  can request details on specific items if needed.
- For download or write operations, target local filesystem — never a network
  mount or cloud storage FUSE mount unless explicitly required, as this incurs
  egress costs and latency.

### Compression

- Enable gzip or brotli response compression on all HTTP endpoints. Even small
  JSON payloads benefit from 60–80% compression ratios.
- For inter-service communication, consider binary serialisation (Protocol
  Buffers, MessagePack) over JSON when payload volume is high.

---

## 4 · Compute Right-Sizing

### General Principles

| Strategy               | When to use                                    |
|------------------------|------------------------------------------------|
| Spot / preemptible     | Batch jobs, CI runners, non-latency-critical   |
| ARM64 (Graviton, etc.) | Always evaluate — typically 20–30% cheaper      |
| Auto-scaling           | Variable load; set both min and max limits      |
| Reserved / savings     | Stable baseline; commit only after measurement  |

### Serverless (Lambda, Cloud Functions)

- Start with the smallest memory tier and benchmark. Use power-tuning tools to
  find the cost-optimal setting.
- Keep deployment packages small. Exclude test files, docs, and dev dependencies
  from production bundles.
- Set reserved concurrency to prevent runaway scaling costs from retry storms.

### Containers (ECS, Kubernetes, Cloud Run)

- Right-size vCPU and memory using observability data — do not guess.
- Use Spot/preemptible instances for non-latency-sensitive workloads.
- Implement graceful shutdown to avoid wasted compute during scale-down.

### Local / On-Demand Processes

- Prefer on-demand subprocesses over persistent daemons for infrequent tasks.
- Initialise expensive clients once per process lifetime (singleton / lazy init).
  Do not recreate clients per request.
- Avoid loading heavyweight modules at import time. Use lazy imports to keep
  startup fast.

---

## 5 · Storage Cost Management

### Tiered Storage

| Tier         | Use case                 | Typical cost ratio |
|--------------|--------------------------|-----------:|
| Hot          | Frequently accessed data |         1× |
| Warm / IA    | Accessed < 1×/month      |       0.4× |
| Cold/Archive | Compliance, audit, DR    |      0.05× |

- Implement lifecycle policies to transition objects automatically between tiers.
- Set expiration rules for temporary artefacts (build outputs, CI caches, logs).
- Delete orphaned resources (unused volumes, snapshots, old container images) on
  a regular schedule.

---

## 6 · LLM Token Cost Awareness

When output is consumed by LLMs, every token has a direct monetary cost.

### Output Discipline

- Return **structured, concise** data. Prefer flat objects over deeply nested
  structures.
- Strip verbose metadata fields the LLM is unlikely to use (internal timestamps,
  audit fields, raw API envelope wrappers).
- For errors, return a single structured error object — not a full stack trace or
  multi-paragraph explanation.
- Tool descriptions and docstrings are sent as schemas. Keep them informative but
  concise — every extra word costs tokens on every request.

### Limit Defaults

- All list/search operations should default to a conservative limit (e.g., 50),
  not the maximum. This balances usefulness with token economy.
- Consumers can explicitly request higher limits when needed.

---

## 7 · CI/CD Cost Controls

### Pipeline Design

- Use the cheapest runner tier (e.g., `ubuntu-latest`) unless a specific OS is
  required.
- Enable dependency caching via `[PACKAGE_MANAGER]` cache support to avoid
  re-downloading packages on every run.
- Fail fast: order stages from fastest to slowest (lint → format → type check
  → audit → test → security scan) so cheap checks catch issues before expensive
  ones run.
- Use path filters to skip unnecessary work:
  ```yaml
  paths-ignore:
    - '**.md'
    - 'docs/**'
  ```
- Use conditional stages to skip integration tests on documentation-only changes.

### Artefact Retention

- Set short retention periods (e.g., 7 days) on ephemeral CI artefacts. Default
  retention (often 90 days) wastes storage.
- Keep release artefacts longer than CI artefacts — apply distinct policies.

---

## 8 · Observability Cost Efficiency

### Log Volume

- Default log level is `INFO`. Never set `DEBUG` in production — it generates
  10–100× more volume with minimal operational value.
- Do not log full request/response payloads at INFO level. Log only metadata
  (`operation`, `duration_ms`, `status`, `request_id`).
- Set log retention policies appropriate to the environment:
  - Development: 7 days
  - Production: 30 days (or 90 days if regulatory requirements exist)

### Metrics

- Use in-process aggregation (histograms, counters). Do not emit per-request
  metric log lines — this duplicates cost between logs and metrics backends.
- Set the metrics export interval conservatively (e.g.,
  `OTEL_METRICS_EXPORT_INTERVAL=60000`) rather than the default to reduce
  exporter network costs.
- Control metric cardinality: avoid high-cardinality label values (user IDs,
  request IDs) on metrics — use traces for per-request detail instead.

### Sampling

- Apply trace sampling (e.g., 10–25% in production) to control observability
  backend costs while maintaining statistical significance.
- Use head-based sampling for general traffic; tail-based sampling to capture
  errors and slow requests.

---

## 9 · Supply Chain Cost

### Licence Compliance

- Every dependency must have a permissive licence (MIT, Apache-2.0, BSD-2/3).
- Audit licences using `[PACKAGE_MANAGER]` licence commands before adding new
  packages. A copyleft dependency in a commercial deployment creates legal and
  financial risk.

### Vulnerability Response

- Fix HIGH/CRITICAL CVEs within 7 days. Delayed patching increases incident
  response cost.
- Run dependency audits in CI — do not suppress findings without a documented
  exception and expiry date.

---

## Non-Negotiables

- **Cache before network.** Every read operation must check local/in-memory cache
  before making a network call.
- **No unintentional polling.** Services should be event-driven or request-driven
  — zero background network activity unless architecturally justified.
- **Bounded outputs.** No endpoint or tool may return unbounded result sets.
  Enforce pagination limits at every layer.
- **Pin dependencies.** Direct dependencies use exact versions; transitive deps
  are locked in `[LOCK_FILE]`.
- **Measure everything.** `duration_ms` on every operation. You cannot optimise
  what you do not measure.
- **Right-size first, scale second.** Measure actual resource usage before
  allocating larger instances or raising limits.

---

## Decision Checklist

Before merging any PR, confirm:

- [ ] No new polling loops or scheduled calls introduced without justification
- [ ] No unnecessary dependencies added (stdlib/platform alternative checked)
- [ ] Result payloads are bounded (pagination limits enforced)
- [ ] API/tool descriptions are concise (no unnecessary token cost)
- [ ] Error responses are structured and compact (not verbose tracebacks)
- [ ] CI stages still ordered cheapest-first
- [ ] Log level is appropriate (INFO for operations, DEBUG gated behind config)
- [ ] No high-cardinality labels added to metrics
- [ ] Licence compliance verified for new dependencies
- [ ] Artefact retention periods set appropriately
