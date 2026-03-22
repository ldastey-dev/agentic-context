---
name: assess-api-design
description: "Run API design and developer experience assessment covering OpenAPI compliance, REST semantics, error handling, pagination, versioning, and contract consistency"
keywords: [assess API, API audit, API design assessment]
---

# API Design & Developer Experience Assessment

## Role

You are a **Principal API Engineer** conducting a comprehensive assessment of an organisation's APIs as both internal integration contracts and external products. You evaluate APIs against REST best practices, the organisation's own API design guidelines, and the standards expected of an API-as-product company. You assess not just whether APIs function correctly, but whether they are consistent, discoverable, well-documented, and a pleasure to consume. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Assess every API surface for consistency, correctness, developer experience, and adherence to organisational standards. Evaluate documentation quality, contract completeness, versioning discipline, error handling, pagination, discoverability, and consumer experience. Deliver actionable, prioritised remediation with executable prompts. APIs are products -- they must be held to a product-quality bar.

---

## Organisational API Standards

The following are the organisation's established API design guidelines. **All APIs must be assessed for compliance with these standards.** Deviations must be flagged as findings.

### Resource Naming

- Nouns, not verbs for resource paths: `/users` not `/getUsers`
- Plural nouns for collections: `/customers`, `/orders`, `/products`
- Singular for specific resources: `/customers/123`, `/orders/456/invoice`
- Lowercase with hyphens for multi-word resources: `/customer-profile`, `/order-items`

### HTTP Methods

Strict REST semantics, consistent across all services:

- `GET` for retrieval (safe, idempotent)
- `POST` for creation or non-idempotent operations
- `PUT` for full resource updates (idempotent)
- `PATCH` for partial updates
- `DELETE` for removal (idempotent)

### Query Parameters

- `camelCase`: `?sortOrder=desc&pageSize=50`
- Boolean parameters as strings: `?includeInactive=true`
- Consistent pagination: `page`/`size` (not `limit`/`offset`)

### URL Structure (Microservices + Micro-Frontends)

- API resources: `v1/{resource}/api/`
- Micro-frontend resources: `v1/{resource}/mfe/`
- Reasoning: clear resource separation, simplified routing (MFEs via CDN), independent security policies (CORS, auth), independent deployment, different caching strategies.

### Response Field Naming

- `camelCase` consistently
- Descriptive but concise: `customerId` not `id`, `createdAt` not `timestamp`
- ISO 8601 for all dates: `"2025-08-13T10:30:00Z"`

### Response Envelope

All responses follow a consistent envelope pattern:

```json
{
  "status": "success",
  "message": "Data retrieved successfully",
  "data": { ... },
  "pagination": {
    "currentPage": 1,
    "pageSize": 10,
    "totalPages": 5,
    "totalItems": 50,
    "hasNextPage": true,
    "hasPreviousPage": false
  },
  "links": [
    { "href": "/v1/customers?page=1", "rel": "self", "method": "GET" },
    { "href": "/v1/customers?page=2", "rel": "next", "method": "GET" },
    { "href": "/v1/customers?page=5", "rel": "last", "method": "GET" }
  ]
}
```

- `pagination` included only when applicable
- `links` for HATEOAS discoverability (for agents and UI consumers)

### Versioning

- Path-based major versioning: `/v1/`, `/v2/`
- Support N and N-1 major versions simultaneously
- Minimum 3-month deprecation notice for version retirement
- `API-Version` response header for minor versions within a major (e.g., `API-Version: 2.1`)
- Breaking changes require new major version (removing fields/endpoints, changing field types/formats, modifying required fields, changing auth schemes, altering error response structures)
- Non-breaking changes are minor/patch (adding optional fields, new endpoints, expanding enums, improving error messages, performance optimisations)

### Documentation

- OpenAPI Specification 3+ is **mandatory** for all APIs
- Must include: detailed descriptions, examples, constraints, purpose and scope, authentication requirements and examples, rate limiting policies, deprecation timelines, error scenarios with example responses, SDK and code samples

### Operational

- `/health` endpoint with operational visibility (Grafana metrics, dependency health)
- `/readiness` endpoint for load balancer traffic decisions (e.g., after scale-out events)
- OpenTelemetry adopted for distributed tracing across services
- ALB for routing, caching, authentication, and SSL termination

---

## Phase 1: Discovery

Before assessing anything, build API context. Investigate and document:

- **API inventory** -- list every API endpoint across all services. Group by service/domain.
- **Consumer landscape** -- who consumes these APIs? Internal services, micro-frontends, external partners, third-party integrations, mobile apps?
- **API gateway/routing** -- how are APIs exposed? ALB configuration, API gateway, reverse proxy, service mesh?
- **Documentation state** -- do OpenAPI specs exist for all APIs? Are they generated from code or hand-written? Are they published and discoverable?
- **Authentication model** -- how do APIs authenticate consumers? OAuth2, API keys, JWT, mTLS? Is it consistent across services?
- **Existing API standards adoption** -- how well do current APIs conform to the organisational guidelines above? Is there variance between teams or services?
- **SDK/client generation** -- are clients generated from OpenAPI specs? Are there official SDKs?
- **Rate limiting** -- is rate limiting in place? Per consumer? Per endpoint? How is it communicated?
- **Monitoring** -- how are APIs monitored? Error rates, latency percentiles, usage patterns per consumer?
- **Change management** -- how are API changes proposed, reviewed, and communicated to consumers?

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate every API against each criterion below. Assess each area independently.

### 2.1 Organisational Standards Compliance

For every API endpoint, check compliance with the organisational standards defined above:

| Aspect | What to evaluate |
|---|---|
| Resource naming | Verify resource paths comply with `standards/api-design.md` REST Conventions — Resource Naming. Check for verbs in paths, singular collection names, and non-kebab-case multi-word segments. Flag every violation. |
| HTTP method usage | Verify method semantics comply with `standards/api-design.md` REST Conventions — HTTP Method Semantics. Check for misuse (e.g., POST for retrieval, GET with side effects, PUT for partial updates). |
| Query parameter conventions | Verify query parameters comply with `standards/api-design.md` REST Conventions — URL Structure. Check for camelCase naming, consistent `page`/`size` pagination, and naming consistency across APIs. |
| URL structure | Verify URL patterns comply with the organisational URL structure (Microservices + Micro-Frontends section above). Check that API and MFE paths follow the specified patterns. Flag deviations. |
| Response field naming | Verify field names comply with `standards/api-design.md` Response Structure — Field Naming. Check for camelCase consistency, descriptive context-qualified names, and ISO 8601 date format across every response schema. |
| Response envelope | Verify response structure complies with `standards/api-design.md` Response Structure — Envelope Pattern. Check for consistent `status`, `message`, `data`, `pagination` (where applicable), and `links` (HATEOAS) fields. Flag missing or inconsistent envelopes. |
| Versioning | Verify versioning complies with `standards/api-design.md` Versioning. Check for path-based major versioning, N and N-1 support, deprecation headers, and `Sunset` header usage per the specified deprecation policy. |
| Documentation | Verify documentation complies with `standards/api-design.md` API Contract — OpenAPI Specification. Check that an OpenAPI 3+ spec exists, is complete (descriptions, examples, constraints, auth, rate limits, errors), and is published. |
| Health/readiness | Verify operational endpoints comply with the organisational Operational standards above. Check that `/health` and `/readiness` endpoints are present and functional. |

### 2.2 API Contract Quality

| Aspect | What to evaluate |
|---|---|
| OpenAPI spec completeness | Verify spec completeness against `standards/api-design.md` API Contract — OpenAPI Specification. Check that all endpoints are documented with complete request/response schemas, types, constraints, descriptions, and examples. |
| Spec accuracy | Compare the OpenAPI spec against actual API behaviour. Check for undocumented endpoints, fields, or response codes that indicate spec drift. |
| Spec-first vs code-first | Determine whether the spec is the source of truth per `standards/api-design.md` API Contract — OpenAPI Specification. Identify any drift between spec and implementation. |
| Contract testing | Verify contract testing practices comply with `standards/api-design.md` API Contract — Contract Testing. Check whether contract tests exist, verify implementation against the spec, and gate merges in CI. |
| Schema validation | Verify request validation complies with `standards/api-design.md` API Contract — Schema Validation. Check that request bodies are validated against the schema and invalid requests are rejected with clear error messages. |
| Response codes | Verify status code usage complies with `standards/api-design.md` HTTP Status Codes. Check for correct and consistent usage across all endpoints against the specified status code table. |

### 2.3 Error Handling

| Aspect | What to evaluate |
|---|---|
| Error response structure | Verify error responses comply with `standards/api-design.md` Error Handling — Error Response Format. Check for RFC 7807 Problem Details compliance (or documented equivalent) and consistency across all APIs. |
| Error detail quality | Verify error detail fields comply with `standards/api-design.md` Error Handling — Error Rules. Check for machine-readable error codes, human-readable messages, field-level validation detail, and correlation IDs. |
| Error consistency | Check whether the same type of error produces the same response structure across different endpoints and services. |
| Internal leakage | Verify error responses comply with the information leakage rules in `standards/api-design.md` Error Handling — Error Rules and HTTP Status Codes — Status Code Rules. Check for stack traces, internal paths, database details, or implementation specifics in any error response. |
| Validation errors | Verify validation error reporting complies with `standards/api-design.md` Error Handling — Error Rules. Check that errors are field-specific, descriptive, and all invalid fields are reported in a single response. |
| Error documentation | Check whether error scenarios are documented in the OpenAPI spec with example responses, enabling consumers to anticipate and handle errors without trial and error. |

### 2.4 Pagination, Filtering & Sorting

| Aspect | What to evaluate |
|---|---|
| Pagination implementation | Verify pagination complies with `standards/api-design.md` Pagination, Filtering & Sorting — Pagination. Check for consistent `page`/`pageSize` parameters and required pagination response fields. |
| Default and maximum page size | Verify page size handling complies with `standards/api-design.md` Pagination, Filtering & Sorting — Pagination. Check that sensible defaults are set, a maximum page size is enforced server-side, and these are documented. |
| Unbounded responses | Check for collection endpoints that can return unbounded results. Per `standards/api-design.md` Non-Negotiables, every collection endpoint must paginate. |
| Filtering | Verify filtering complies with `standards/api-design.md` Pagination, Filtering & Sorting — Filtering. Check that filter parameters are consistent in naming and behaviour, and unknown parameters are rejected. |
| Sorting | Verify sorting complies with `standards/api-design.md` Pagination, Filtering & Sorting — Sorting. Check for consistent `sortBy`/`sortOrder` parameter format and documented default sort order. |
| Search | For resources requiring search, assess whether a consistent search mechanism exists (full-text, field-specific, or query language). |
| Cursor-based pagination | For high-volume or real-time data, check whether cursor-based pagination is available as per `standards/api-design.md` Pagination, Filtering & Sorting — Pagination. |

### 2.5 HATEOAS & Discoverability

| Aspect | What to evaluate |
|---|---|
| Link presence | Verify HATEOAS links comply with `standards/api-design.md` HATEOAS & Discoverability — Link Format and Link Rules. Check for `self`, `next`, `prev` links on paginated responses. |
| Action links | Verify that resource responses include action links per `standards/api-design.md` HATEOAS & Discoverability — Link Rules. Check that available actions (edit, delete, related resources) are represented and respect authorisation state. |
| Link consistency | Verify link format consistency against `standards/api-design.md` HATEOAS & Discoverability — Link Rules. Check that every link is an object with `href`, `rel` (implicit from key), and `method`. |
| Root resource | Check whether an API root/index endpoint exists that lists available resources and their URLs. |
| Discoverability | Assess whether a consumer can navigate the entire API starting from a single entry point, using only the links provided in responses. |
| Documentation links | Check whether responses or error messages include links to relevant documentation. |

### 2.6 Idempotency & Reliability

| Aspect | What to evaluate |
|---|---|
| Idempotent operations | Verify idempotency guarantees comply with `standards/api-design.md` Idempotency & Reliability — Idempotency Guarantees. Check that PUT and DELETE are truly idempotent. |
| Idempotency keys | Verify POST idempotency complies with `standards/api-design.md` Idempotency & Reliability — Idempotency Keys for POST. Check for `Idempotency-Key` header support on creation, payment, and critical write operations. |
| Retry safety | Verify retry documentation complies with `standards/api-design.md` Idempotency & Reliability — Retry Safety. Check that it is documented which operations are safe to retry. |
| Eventual consistency | For eventually consistent operations, check whether consistency behaviour is communicated to consumers and mechanisms exist to check completion status. |
| Concurrency control | Verify optimistic concurrency complies with `standards/api-design.md` Idempotency & Reliability — Optimistic Concurrency. Check for ETag headers, `If-Match` requirements on updates, and 412 responses on conflicts. |

### 2.7 Rate Limiting & Throttling

| Aspect | What to evaluate |
|---|---|
| Rate limit implementation | Verify rate limiting is in place per `standards/api-design.md` Rate Limiting — Rate Limit Rules and Non-Negotiables. Check scope (per-consumer, per-endpoint, global). |
| Rate limit headers | Verify rate limit headers comply with `standards/api-design.md` Rate Limiting — Rate Limit Headers. Check for `X-RateLimit-Limit`, `X-RateLimit-Remaining`, and `X-RateLimit-Reset` on every response. |
| 429 responses | Verify rate limit exceeded responses comply with `standards/api-design.md` Rate Limiting — Rate Limit Rules. Check for 429 status code with a `Retry-After` header and a clear error message. |
| Rate limit documentation | Check whether rate limits are documented per endpoint in the OpenAPI spec, enabling consumers to plan their usage. |
| Graduated limits | Check whether different rate limit tiers exist for different consumers or subscription levels. |
| Burst handling | Check whether burst allowance exists for legitimate traffic spikes. |

### 2.8 Consumer Experience (Developer Experience)

| Aspect | What to evaluate |
|---|---|
| Onboarding | Assess time-to-first-successful-call for a new consumer. Check for a getting-started guide. |
| Sandbox/testing | Check whether a sandbox environment exists for consumers to test against and whether it behaves like production. |
| SDK availability | Check whether SDKs are generated from OpenAPI specs, published, versioned, and covering major consumer languages. |
| Changelog | Check whether a changelog documents API changes and consumers can subscribe to change notifications. |
| Deprecation communication | Verify deprecation practices comply with `standards/api-design.md` Versioning — Deprecation Policy. Check for `Sunset` and `Deprecation` headers, OpenAPI spec annotations, and communicated timelines. |
| Support channel | Check whether a clear channel exists for API consumers to ask questions, report issues, and request features. |
| Consistency across services | Assess whether all services feel like a single cohesive API or whether each has its own conventions, error formats, and patterns. |

### 2.9 API Security (Consumer-Facing)

| Aspect | What to evaluate |
|---|---|
| Authentication consistency | Check whether the authentication mechanism is consistent across all APIs and documented with examples. |
| Scope/permission model | Check whether API scopes or permissions are granular and well-defined, allowing consumers to request only the access they need. |
| API key management | Check whether consumers can generate, rotate, and revoke API keys self-service and whether keys are scoped appropriately. |
| CORS configuration | Check whether CORS policies are configured correctly for browser-based consumers and are not overly permissive. |
| Input validation | Verify input validation complies with `standards/api-design.md` API Contract — Schema Validation. Check that all inputs are validated and rejected with clear errors before processing. |
| Sensitive data | Check whether sensitive fields are masked or omitted from responses by default and whether consumers can request them with elevated permissions. |

---

## Report Format

### Executive Summary

A concise (half-page max) summary for a technical leadership audience:

- Overall API maturity rating: **Critical / Poor / Fair / Good / Strong**
- API-as-product readiness: **Not Ready / Partial / Ready / Exemplary**
- Organisational standards compliance rate (percentage of endpoints fully compliant)
- Top 3-5 API issues requiring immediate attention
- Key strengths worth preserving
- Strategic recommendation (one paragraph)

### Findings by Category

For each assessment area, list every finding with:

| Field | Description |
|---|---|
| **Finding ID** | `API-XXX` (e.g., `API-001`, `API-015`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Category** | Standards Compliance / Contract / Errors / Pagination / HATEOAS / Idempotency / Rate Limiting / DX / Security |
| **Affected Endpoints** | List the specific endpoints or services affected |
| **Description** | What was found and where (include endpoint paths, response examples, and spec references) |
| **Impact** | How this affects API consumers -- broken integrations, poor DX, inconsistency, security risk |
| **Evidence** | Specific request/response examples, OpenAPI spec excerpts, or configuration that demonstrates the issue |

### Prioritisation Matrix

| Finding ID | Title | Severity | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|

Quick wins (high severity + small effort) rank highest. Inconsistencies across services that affect multiple consumers rank higher.

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Contract foundation** | Ensure OpenAPI 3+ specs exist and are accurate for all APIs. Establish contract tests as CI gates. This is prerequisite to all other improvements. |
| **Phase B: Standards alignment** | Fix naming, envelope structure, HTTP method usage, response codes, and versioning to match organisational standards. Consistency first. |
| **Phase C: Error handling & validation** | Standardise error responses, improve validation messages, eliminate internal leakage. |
| **Phase D: Pagination, HATEOAS & reliability** | Fix pagination consistency, add HATEOAS links, implement idempotency keys, add concurrency control. |
| **Phase E: DX & productisation** | Rate limit headers, changelogs, deprecation headers, SDK generation, sandbox environments, developer portal. |

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
| **Scope** | Endpoints, services, or infrastructure affected |
| **Description** | What needs to change and why, referencing the specific organisational standard being addressed |
| **Acceptance criteria** | Testable conditions that confirm the action is complete |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, endpoint paths, controller/handler names, current request/response schemas, and the specific standard or best practice being addressed so the implementer does not need to read the full report.
3. **Include the organisational standard** -- quote the specific guideline the endpoint must conform to (e.g., "Response fields must use camelCase. Dates must be ISO 8601. The response envelope must include status, message, data, and links fields.").
4. **Specify constraints** -- what must NOT change (existing consumer contracts unless a major version bump is planned), backward compatibility requirements, and migration strategy for breaking changes.
5. **Define the acceptance criteria** inline so completion is unambiguous.
6. **Include test-first instructions:**
   - For **standards violations**: write a contract test that asserts the correct response structure per organisational standards. This test fails against the current implementation. Fix the implementation. Test passes.
   - For **missing functionality** (e.g., pagination, HATEOAS links): write a test asserting the expected behaviour. Implement. Test passes.
   - For **bugs** (wrong status codes, leaking internals): write a test asserting correct behaviour. Test fails. Fix. Test passes.
7. **Include PR instructions** -- the prompt must instruct the agent to:
   - Create a feature branch with a descriptive name (e.g., `api/API-001-standardise-order-response-envelope`)
   - Commit the contract test separately from the implementation fix (test-first visible in history)
   - Run all existing tests and verify no regressions
   - Verify the OpenAPI spec is updated to reflect the change
   - Open a pull request with a clear title, description of which standard is being addressed, affected endpoints, and a checklist of acceptance criteria
   - Flag any breaking changes clearly in the PR description with a migration note for consumers
   - Request review before merging
8. **Be executable in isolation** -- no references to "the report" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

1. Work through actions in phase and priority order.
2. **OpenAPI specs and contract tests are established first** as the foundation for all subsequent work.
3. **Breaking changes are batched into major version bumps** with consumer migration guides. Never silently break a contract.
4. Actions without mutual dependencies may be executed in parallel.
5. Each action is delivered as a single, focused, reviewable pull request.
6. After each PR, verify that the OpenAPI spec is updated, contract tests pass, and no existing consumer contracts are broken.
7. Do not proceed past a phase boundary (e.g., A to B) without confirmation.

---

## Guiding Principles

- **APIs are products.** They have consumers, and those consumers' experience matters. Treat every API change as a product decision.
- **Consistency is king.** An API that is consistently mediocre is better than one that is brilliant in places and broken in others. Consumers need predictability.
- **The spec is the contract.** The OpenAPI specification is the source of truth. If the spec and implementation disagree, one of them is wrong. Contract tests prove which.
- **Standards exist for a reason.** The organisational API guidelines are the baseline. Every deviation must be justified, not accidental.
- **Don't break consumers.** Breaking changes require a major version, deprecation notice, migration guide, and minimum 3-month overlap. No exceptions.
- **Test the contract, not the implementation.** API tests assert on the HTTP contract (request in, response out) not on internal method calls or database state.
- **Evidence over opinion.** Every finding references specific endpoints, request/response examples, or spec excerpts. No vague assertions.
- **HATEOAS enables autonomy.** Hypermedia links let consumers (humans, UIs, and AI agents) navigate the API without hardcoding URLs. This is a product differentiator.
- **Think like a consumer.** For every finding, ask: "If I were consuming this API for the first time, would this confuse, frustrate, or break me?"

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
