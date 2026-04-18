# API Design Standards — REST, Contracts & Reliability

## Core Principle

Every API is a public contract. Changing it breaks consumers. Design every endpoint
as if it will be consumed by a team you will never speak to, documented only by
its OpenAPI specification and the response it returns.

---

## REST Conventions

### Resource Naming
Resource paths use **plural nouns**, never verbs.

- `/v1/customers` — collection of customers.
- `/v1/customers/{customerId}` — single customer resource.
- `/v1/customers/{customerId}/orders` — nested sub-collection.
- Never `/v1/getCustomers`, `/v1/createOrder`, or `/v1/deleteUser` — HTTP methods
  already express the action.

### URL Structure

- Path segments are **kebab-case**: `/v1/line-items`, not `/v1/lineItems` or
  `/v1/line_items`.
- Resource identifiers are path parameters: `/v1/orders/{orderId}`, not
  `/v1/orders?id=123`.
- Query parameters are **camelCase**: `?pageSize=20&sortBy=createdAt`.
- Trailing slashes are **not** significant — the API must behave identically with
  or without a trailing slash, or explicitly redirect one to the other.

### HTTP Method Semantics
Each HTTP method has a precise contract. Do not deviate.

| Method | Semantics | Idempotent | Safe | Typical Status |
|--------|-----------|------------|------|----------------|
| `GET` | Read resource(s) | Yes | Yes | `200` |
| `POST` | Create a resource or trigger an action | No | No | `201` / `202` |
| `PUT` | Full replacement of a resource | Yes | No | `200` / `204` |
| `PATCH` | Partial update of a resource | No | No | `200` |
| `DELETE` | Remove a resource | Yes | No | `204` |

- **GET must never produce side effects** — no writes, no state changes, no
  triggering background jobs. If a read operation has consequences, use POST.
- **PUT replaces the entire resource.** Omitted fields are set to their defaults
  or null — it is not a partial update. Clients must send the full representation.
- **PATCH applies a partial update.** Only the fields included in the request body
  are modified. Use JSON Merge Patch (RFC 7396) or JSON Patch (RFC 6902) and
  declare which in the `Content-Type` header.
- **DELETE is idempotent.** Deleting an already-deleted resource returns `204`,
  not `404`. The second call is a no-op.

### Actions That Don't Map to CRUD
For operations that are not simple CRUD (e.g., "cancel an order", "resend an
invitation"), use a **sub-resource verb** as a last resort:

```
POST /v1/orders/{orderId}/cancellation
POST /v1/invitations/{invitationId}/resend
```

Prefer creating a new sub-resource (a noun) over a verb. `cancellation` is a noun
representing the state change.

---

## Response Structure

### Envelope Pattern
All responses use a consistent envelope. Do not return a bare array or bare
primitive.

```json
{
  "status": "success",
  "message": "Orders retrieved successfully",
  "data": [ ... ],
  "pagination": {
    "page": 2,
    "pageSize": 20,
    "totalItems": 148,
    "totalPages": 8
  },
  "links": {
    "self":  { "href": "/v1/orders?page=2&pageSize=20", "method": "GET" },
    "next":  { "href": "/v1/orders?page=3&pageSize=20", "method": "GET" },
    "prev":  { "href": "/v1/orders?page=1&pageSize=20", "method": "GET" }
  }
}
```

- **`status`** — `"success"` or `"error"`. Machine-readable.
- **`message`** — human-readable summary. Never leak internal details.
- **`data`** — the payload. Always an object or array, never null on success.
- **`pagination`** — present only on collection endpoints.
- **`links`** — HATEOAS navigation. Present on every response.
- Single-resource responses omit `pagination` and wrap the resource in `data`.

### Field Naming

- All field names are **camelCase**: `customerId`, `createdAt`, `lineItems`.
- Use descriptive, context-qualified names: `customerId` not `id`, `orderTotal`
  not `total`, `createdAt` not `date`.
- Boolean fields are `is*` or `has*`: `isActive`, `hasShipped`.
- Dates and timestamps are **ISO 8601** with timezone: `"2024-01-15T09:30:00Z"`.
  Never use epoch integers or locale-specific formats in response bodies.
- Monetary values include the amount and the currency code as separate fields:
  `"amount": 49.99, "currency": "USD"`.
- Empty collections return `[]`, not `null`.

---

## Error Handling

### Error Response Format
Error responses follow **RFC 7807 Problem Details** (or a documented equivalent
that carries the same information). Every error response includes these fields:

```json
{
  "status": "error",
  "error": {
    "type": "https://api.example.com/errors/validation-failed",
    "title": "Validation Failed",
    "status": 422,
    "detail": "The request body contains 2 validation errors.",
    "instance": "/v1/customers",
    "correlationId": "req-8f3a-4b2c-9d1e",
    "errors": [
      {
        "field": "email",
        "code": "INVALID_FORMAT",
        "message": "Must be a valid email address."
      },
      {
        "field": "dateOfBirth",
        "code": "FUTURE_DATE",
        "message": "Date of birth must be in the past."
      }
    ]
  }
}
```

### Error Rules

- **`type`** — a stable URI identifying the error category. Machine-readable.
  Clients switch on this, not on status codes alone.
- **`code`** on field errors — a machine-readable constant (`INVALID_FORMAT`,
  `REQUIRED_FIELD`, `DUPLICATE_VALUE`). Never change these once published.
- **`message`** and **`detail`** — human-readable. Safe to display to end users.
- **`correlationId`** — present on every error response. Ties the error to a
  specific request for log correlation.
- **All validation errors in a single response.** Never return one validation
  error at a time forcing the client to fix-and-retry in a loop.
- **Never leak stack traces, internal file paths, database table names, SQL
  statements, or framework error pages** in any environment, including development.
- **Never expose infrastructure details** — no server software versions, no
  internal hostnames, no dependency names.

---

## HTTP Status Codes

### Correct Usage
Use the most specific appropriate status code. The following are the minimum
required set — every API must handle all of these consistently.

| Code | Meaning | When to Use |
|------|---------|-------------|
| `200` | OK | Successful GET, PUT, PATCH that returns a body |
| `201` | Created | Successful POST that creates a resource. Include `Location` header |
| `204` | No Content | Successful DELETE or PUT/PATCH with no response body |
| `400` | Bad Request | Malformed syntax, unparseable JSON, missing required header |
| `401` | Unauthorized | Missing or invalid authentication credentials |
| `403` | Forbidden | Authenticated but insufficient permissions |
| `404` | Not Found | Resource does not exist (or caller lacks permission to know it exists) |
| `409` | Conflict | State conflict — duplicate creation, concurrent modification |
| `422` | Unprocessable Entity | Syntactically valid but semantically invalid (validation errors) |
| `429` | Too Many Requests | Rate limit exceeded. Include `Retry-After` header |
| `500` | Internal Server Error | Unhandled server failure. Log the full error server-side |

### Status Code Rules

- **Distinguish 400 from 422.** `400` means the request is malformed (bad JSON,
  wrong content type). `422` means the JSON is valid but the values fail business
  validation.
- **Distinguish 401 from 403.** `401` means "I don't know who you are."
  `403` means "I know who you are and you can't do this."
- **201 must include a `Location` header** pointing to the newly created resource.
- **204 must have an empty body.** Do not return `{"status": "success"}` with 204.
- **5xx errors never expose implementation details.** Return a generic message
  with a `correlationId` and log the real error server-side.
- **Never return 200 with an error in the body.** If the operation failed, use an
  error-level status code.

---

## Pagination, Filtering & Sorting

### Pagination
All collection endpoints must paginate. No exceptions.

- **Offset-based pagination** uses `page` and `pageSize` query parameters.
- **Cursor-based pagination** uses `cursor` and `pageSize`. Prefer cursor-based
  for high-volume or real-time datasets where offset is unreliable.
- Default `pageSize` must be documented and sensible (e.g., 20).
- Maximum `pageSize` must be enforced server-side (e.g., 100). Requests exceeding
  the maximum are clamped or rejected with 422 — never silently honoured.
- Responses include a `pagination` object with `page` (or `cursor`), `pageSize`,
  `totalItems` (when affordable to compute), and `totalPages` (offset only).
- The response `links` object includes `next` and `prev` (null when at bounds).

### Filtering

- Filter by resource fields using query parameters: `?status=active&region=eu`.
- Complex filters use a documented syntax. Document operator support explicitly
  (e.g., `?createdAfter=2024-01-01&createdBefore=2024-12-31`).
- Unknown filter parameters must be rejected with `400`, not silently ignored.

### Sorting

- Use `sortBy` and `sortOrder` query parameters: `?sortBy=createdAt&sortOrder=desc`.
- Default sort order must be documented.
- Only allow sorting on indexed / performant fields. Reject unsupported sort fields
  with `400`.

---

## Versioning

### Version Strategy
Use **path-based major versioning**: `/v1/`, `/v2/`.

- The version segment is the first path component after the base URL.
- Increment the major version only for **breaking changes**.
- Non-breaking changes (new optional fields, new endpoints) are added to the
  current version without incrementing.

### Breaking vs Non-Breaking Changes
| Change Type | Breaking? | Action |
|-------------|-----------|--------|
| Remove a field from a response | Yes | New major version |
| Rename a field | Yes | New major version |
| Change a field's type | Yes | New major version |
| Remove an endpoint | Yes | New major version |
| Add a new required request field | Yes | New major version |
| Add a new optional request field | No | Add to current version |
| Add a new response field | No | Add to current version |
| Add a new endpoint | No | Add to current version |
| Add a new enum value | Possibly | Depends on consumer contracts |

### Deprecation Policy

- Support a minimum of **two concurrent versions**: current (N) and previous (N-1).
- Deprecated versions must include `Deprecation` and `Sunset` headers in every
  response:
  ```
  Deprecation: true
  Sunset: Sat, 01 Mar 2025 00:00:00 GMT
  ```
- Minimum deprecation notice period: **6 months** from the first `Deprecation`
  header to the `Sunset` date.
- Publish a migration guide for every major version increment.

---

## HATEOAS & Discoverability

### Link Format
Every response includes a `links` object with discoverable navigation and actions.

```json
{
  "data": { "orderId": "ord-123", "status": "pending" },
  "links": {
    "self":   { "href": "/v1/orders/ord-123", "method": "GET" },
    "cancel": { "href": "/v1/orders/ord-123/cancellation", "method": "POST" },
    "items":  { "href": "/v1/orders/ord-123/items", "method": "GET" },
    "customer": { "href": "/v1/customers/cust-456", "method": "GET" }
  }
}
```

### Link Rules

- **`self`** — present on every resource response. Points to the canonical URL.
- **`next`** / **`prev`** — present on paginated collections. Null at boundaries.
- **Action links** — only include actions the caller is authorised to perform.
  Do not expose a `cancel` link if the caller lacks permission or the order is
  already cancelled.
- **Consistent shape** — every link is an object with `href` (string, relative
  path), `rel` (implicit from the key name), and `method` (HTTP method string).
- Clients should be able to navigate the API entirely through links without
  constructing URLs manually.

---

## Idempotency & Reliability

### Idempotency Guarantees

- **GET** — always idempotent and safe. No side effects.
- **PUT** — truly idempotent. Sending the same PUT request twice produces the same
  resource state. The second call does not create a duplicate or fail.
- **DELETE** — truly idempotent. Deleting an already-deleted resource returns `204`.
- **PATCH** — not required to be idempotent, but document the behaviour.
- **POST** — not idempotent by default. Use idempotency keys (see below).

### Idempotency Keys for POST
Non-idempotent operations (POST) must support an `Idempotency-Key` header.

- Clients send `Idempotency-Key: <unique-uuid>` with the request.
- The server stores the key and the response. If the same key is received again,
  the server returns the stored response without re-executing the operation.
- Keys expire after a documented TTL (e.g., 24 hours).
- Reject requests with a previously-used key but a different request body with `422`.

### Optimistic Concurrency

- Use `ETag` headers on resource responses.
- Update operations (PUT, PATCH) require `If-Match` with the current ETag.
- Return `412 Precondition Failed` if the ETag does not match.
- This prevents lost-update problems in concurrent environments.

### Retry Safety

- Document which endpoints are safe to retry.
- Idempotent methods (GET, PUT, DELETE) are always safe to retry.
- POST with an `Idempotency-Key` is safe to retry.
- POST without an `Idempotency-Key` is not safe to retry — document this.

---

## Rate Limiting

### Rate Limit Headers
Every response includes rate limit headers:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 42
X-RateLimit-Reset: 1705312800
```

- **`X-RateLimit-Limit`** — maximum requests allowed in the current window.
- **`X-RateLimit-Remaining`** — requests remaining in the current window.
- **`X-RateLimit-Reset`** — Unix epoch timestamp when the window resets.

### Rate Limit Rules

- When the limit is exceeded, return `429 Too Many Requests` with a `Retry-After`
  header (seconds until the client may retry).
- Rate limits are documented per-endpoint in the OpenAPI specification.
- Different tiers or authentication levels may have different limits — document
  these clearly.
- Never silently drop or queue requests that exceed the limit — always return `429`.

---

## API Contract

### OpenAPI Specification

- Every API must have an **OpenAPI 3.0+** specification file.
- The specification is the **source of truth**. If the code and the spec disagree,
  it is a bug.
- Every endpoint, request body, response body, query parameter, header, and error
  response is documented in the spec.
- The spec includes examples for every request and response schema.

### Schema Validation

- All incoming request bodies are validated against the OpenAPI schema before
  reaching business logic.
- Unknown / additional properties in request bodies are rejected with `400`, not
  silently ignored — unless the endpoint explicitly documents open content.
- Response bodies are validated against the spec in test environments to catch
  drift.

### Contract Testing

- **Contract tests run in CI** and gate merges. A PR that breaks the API contract
  does not merge.
- Contract tests verify:
  - Every endpoint returns the documented status codes.
  - Response bodies match the schema (required fields present, correct types).
  - Error responses follow the standard error format.
  - Pagination, filtering, and sorting parameters work as documented.
- Use consumer-driven contract testing (e.g., Pact) when the API has known
  consumers with their own test suites.

---

## OpenAPI Specification Structure

### Spec Metadata

- `info.title` must be descriptive and identify the product or service — not
  just "API".
- `info.version` must reflect the API version, not the spec document version.
- `info.description` must provide a meaningful overview of the API's purpose
  and intended audience.
- `info.contact` must include a team name or email for API consumers to raise
  issues.
- `info.license` must be populated for externally exposed APIs.

### Servers

- The `servers` array must be populated with all applicable base URLs
  (development, staging, production).
- Server URLs must not include trailing slashes.
- Server descriptions must clarify the environment.
- Server variables must be used where the URL contains environment-specific
  components.

### Tags

- Tags must be defined at the top level (`tags:`) with descriptions.
- All operations must be tagged.
- Tags must group operations by resource or capability, not by HTTP method.
- Tag names must be consistent with resource naming used in paths and schemas.

### Operation IDs

- Every operation must have an `operationId`.
- `operationId` values must be unique across the entire spec.
- `operationId` must follow a consistent naming convention (e.g., `GetOrder`,
  `CreateOrder`, `DeleteOrder`).
- Auto-generated operation IDs (e.g., `OrdersGet_1`) are never acceptable —
  always provide meaningful names.

---

## Schema Constraints

### Type Precision

- All schema properties must have an explicit `type` defined.
- `nullable` must be explicit: use `nullable: true` (OAS 3.0) or
  `type: ['string', 'null']` (OAS 3.1).
- `format` must be specified where applicable: `int32`, `int64`, `date`,
  `date-time`, `uuid`, `email`, `uri`.
- `string` fields with a fixed set of values must use `enum`.
- Monetary values must be `string` or `number` with precision documented —
  never `float` or `double`.

### Constraints and Validation

- `minLength` and `maxLength` must be set on string properties where applicable.
- `minimum` and `maximum` must be set on numeric properties where applicable.
- `pattern` must be used for structured strings not covered by built-in formats.
- The `required` array must be present on objects where properties must be
  provided.

### Read/Write Direction

- `readOnly: true` must be set on server-generated properties (`id`,
  `createdAt`, `updatedAt`).
- `writeOnly: true` must be set on request-only properties (e.g., `password`,
  `secret`).
- Clients must not send `readOnly` properties; servers must not return
  `writeOnly` properties.

### Request Body Schemas

- Request body schemas must use `$ref` to a component schema — avoid defining
  schemas inline.
- `PATCH` operations must define a partial schema where all properties are
  optional — never reuse the `PUT` schema.
- `required: true` must be set on request bodies that are mandatory.
- Content type must be specified explicitly (`application/json`).

---

## Component Reusability

- Schemas used in more than one place must be defined in `components/schemas`
  and referenced via `$ref`.
- Common parameters (pagination, tenant ID, correlation ID) must be in
  `components/parameters`.
- Common responses (Problem Details, paginated response wrapper) must be in
  `components/responses`.
- Common headers must be in `components/headers`.
- Inline schemas are only acceptable for one-off definitions with no reuse
  potential.
- Circular `$ref` references must be avoided unless the toolchain explicitly
  supports them.
- All `$ref` references must resolve without errors.

---

## API Tooling

### Linting

- The OpenAPI spec must pass a Spectral (or equivalent) linter with no errors.
- The Spectral ruleset must be configured and committed to the repository.
- Linting must run in CI on pull requests and fail the build on errors.

### Code-First Generation

When using code-first generation (Swashbuckle, NSwag, or equivalent):

- XML documentation must be enabled and surfaced in the generated spec.
- Response type attributes (e.g., `[ProducesResponseType]`) must be complete on
  all actions.
- The generated spec must be reviewed as a first-class artefact — never treated
  as disposable auto-output.
- Schema filters must handle Problem Details, enums, and nullable types
  correctly.

### Breaking Change Detection

- An API diff tool (`oasdiff`, `openapi-diff`, or equivalent) must run in CI.
- Breaking change detection must fail the build unless the API version has been
  incremented.
- Breaking changes must be explicitly acknowledged and communicated to API
  consumers.

---

## Decision Checklist

Before merging any PR that adds or modifies an API endpoint, confirm:

- [ ] Resource paths use plural nouns, not verbs
- [ ] HTTP methods match their documented semantics (GET is safe, PUT is idempotent)
- [ ] Response follows the standard envelope (status, message, data, links)
- [ ] All field names are camelCase with descriptive, context-qualified names
- [ ] Dates are ISO 8601 with timezone
- [ ] Error responses follow RFC 7807 format with correlationId
- [ ] All validation errors returned in a single response
- [ ] No stack traces, internal paths, or infrastructure details leaked in errors
- [ ] Correct HTTP status codes used (400 vs 422, 401 vs 403)
- [ ] 201 responses include a `Location` header
- [ ] Collection endpoint is paginated with enforced maximum page size
- [ ] OpenAPI spec is updated and matches the implementation
- [ ] Contract tests cover the new or changed endpoint
- [ ] Rate limit headers present on the endpoint
- [ ] Versioning and deprecation headers applied if modifying an existing contract
- [ ] Idempotency key supported for any new POST endpoint
- [ ] ETag and If-Match supported for update operations
- [ ] HATEOAS links present in the response (self, related, actions)
- [ ] `operationId` set on every operation with unique, meaningful names
- [ ] Schema constraints complete (`readOnly`, `writeOnly`, `minLength`, `maxLength`, `required`)
- [ ] `nullable` handling correct for the OAS version (3.0 vs 3.1)
- [ ] Reusable schemas extracted to `components/` — no inline duplication
- [ ] `PATCH` schemas define all properties as optional (separate from `PUT`)
- [ ] Spectral linter passes with no errors
- [ ] API diff tool run for breaking change detection

---

## Non-Negotiables

- **No verbs in resource paths.** Endpoints like `/getUsers` or `/createOrder` are
  rejected outright. HTTP methods express the action.
- **No side effects on GET.** A GET request must never write data, trigger jobs,
  send emails, or mutate state. No exceptions.
- **No bare arrays or primitives as top-level responses.** Every response uses the
  standard envelope.
- **No stack traces in any environment.** Error responses never contain stack traces,
  internal file paths, SQL, or framework debug output — not even in development.
- **All validation errors in one response.** Returning validation errors one at a
  time is a client-hostile pattern and is not acceptable.
- **OpenAPI spec is mandatory and must match.** No undocumented endpoints. No
  endpoints that return shapes not described in the spec. Spec drift is a bug.
- **Collection endpoints paginate.** Unbounded collection responses are a
  denial-of-service vector and a performance liability. No exceptions.
- **Rate limiting on every endpoint.** Unprotected endpoints are a production
  incident waiting to happen.
- **Breaking changes require a major version increment.** Removing fields, renaming
  fields, or changing types in an existing version is never acceptable.
- **`operationId` on every operation.** Auto-generated names like `OrdersGet_1`
  are never acceptable. Every operation must have a meaningful, unique identifier.
- **Spectral linting must pass in CI.** No OpenAPI specification merges without
  a clean linter run. The ruleset is committed to the repository.
