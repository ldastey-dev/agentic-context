# OpenAPI / Swagger Specification Review Standards

This document provides code review standards for OpenAPI 3.x specifications. Applies whether specs are code-generated (Swashbuckle/NSwag) or design-first (YAML/JSON authored directly).

## Table of Contents

- [Spec Structure and Metadata](#spec-structure-and-metadata)
- [Paths and Operations](#paths-and-operations)
- [Request Design](#request-design)
- [Response Design](#response-design)
- [Schemas and Data Types](#schemas-and-data-types)
- [Security](#security)
- [Versioning](#versioning)
- [Reusability and Components](#reusability-and-components)
- [Documentation Quality](#documentation-quality)
- [Tooling and Validation](#tooling-and-validation)

---

## Spec Structure and Metadata

### Info Object

- [ ] `info.title` is descriptive and identifies the product/service (not just "API")
- [ ] `info.version` reflects the API version (not the spec document version — see [Versioning](#versioning))
- [ ] `info.description` provides a meaningful overview of what the API does and who it is for
- [ ] `info.contact` includes a team name or email for API consumers to raise issues
- [ ] `info.license` is populated if the API is externally exposed

### Servers

- [ ] `servers` array is populated with all applicable base URLs (dev, staging, production)
- [ ] Server URLs do not include trailing slashes
- [ ] Server descriptions clarify the environment
- [ ] Server variables are used where the URL contains environment-specific components

### Tags

- [ ] Tags are defined at the top level (`tags:`) with descriptions
- [ ] All operations are tagged
- [ ] Tags group operations by resource or capability (not by HTTP method)
- [ ] Tag names are consistent with the resource naming used in paths and schemas

---

## Paths and Operations

### Path Design

- [ ] Paths are lowercase and use hyphens for word separation (`/order-items`, not `/orderItems` or `/order_items`)
- [ ] Paths represent resources (nouns), not actions (`/orders/{id}`, not `/getOrder`)
- [ ] Path parameters are used for resource identifiers (`/orders/{orderId}`)
- [ ] Query parameters are used for filtering, sorting, and pagination (not path segments)
- [ ] Paths do not include the API version prefix (versioning is via URL prefix on the server or header — consistent per API)
- [ ] Trailing slash variants are not defined as separate paths

### HTTP Method Usage

- [ ] `GET` is side-effect free and idempotent
- [ ] `POST` is used for creation and non-idempotent actions
- [ ] `PUT` is used for full replacement (idempotent)
- [ ] `PATCH` is used for partial updates
- [ ] `DELETE` is idempotent
- [ ] `GET` operations do not have a request body

### Operation IDs

- [ ] `operationId` is set on every operation
- [ ] `operationId` is unique across the entire spec
- [ ] `operationId` follows a consistent naming convention (e.g., `GetOrder`, `CreateOrder`, `DeleteOrder`)
- [ ] `operationId` is meaningful — not auto-generated noise like `OrdersGet_1`

---

## Request Design

### Parameters

- [ ] Path parameters are marked `required: true`
- [ ] Query parameters have a `description` explaining their purpose and behaviour
- [ ] Sorting parameters follow a consistent pattern (e.g., `sortBy` + `sortOrder`)
- [ ] Pagination parameters are consistent across all paginated endpoints (e.g., `page`+`pageSize` or cursor-based)
- [ ] Parameter names are `camelCase`

### Request Body

- [ ] `requestBody` has a `description`
- [ ] `required: true` is set on request bodies that are mandatory
- [ ] Content type is specified (`application/json`)
- [ ] Request body schema is a `$ref` to a component (not all inline)
- [ ] `PATCH` operations define a partial schema (all properties optional) — not the same schema as `PUT`

---

## Response Design

### Status Codes

- [ ] Every operation defines at least a success response and a default error response
- [ ] `200 OK` for successful `GET`, `PUT`, `PATCH`
- [ ] `201 Created` for `POST` that creates a resource; `Location` header documented
- [ ] `204 No Content` for successful `DELETE` or no-body responses
- [ ] `400 Bad Request` for validation failures
- [ ] `401 Unauthorized` for unauthenticated requests on secured endpoints
- [ ] `403 Forbidden` for authorisation failures
- [ ] `404 Not Found` for operations on a specific resource
- [ ] `409 Conflict` where concurrent modification or duplicate creation is possible
- [ ] `422 Unprocessable Entity` for semantic validation failures
- [ ] `429 Too Many Requests` if rate limiting is applied
- [ ] `500` covered via `default` or explicit entry

### Error Response Format

- [ ] All error responses use a consistent schema (RFC 7807 Problem Details recommended)
- [ ] Error schema includes at minimum: `type`, `title`, `status`, `detail`
- [ ] `400`/`422` responses include field-level validation errors (e.g., `errors` array with `field` and `message`)
- [ ] Error responses do not include internal stack traces
- [ ] `traceId` or `correlationId` is included

### Response Bodies

- [ ] Success responses have a defined schema (not empty or `{}` unless `204`)
- [ ] `GET` list responses return a wrapper object (not a bare array) to allow future pagination metadata
- [ ] Paginated responses include pagination metadata (`totalCount`, `pageSize`, `page`, etc.)
- [ ] `Location` header is documented on `201 Created` responses

---

## Schemas and Data Types

### Type Definitions

- [ ] All schema properties have a `type` defined
- [ ] `nullable: true` (OAS 3.0) or `type: ['string', 'null']` (OAS 3.1) is explicit for nullable properties
- [ ] `format` is specified where applicable (`int32`, `int64`, `date`, `date-time`, `uuid`, `email`, `uri`)
- [ ] `string` fields with a fixed set of values use `enum`
- [ ] Monetary values are `string` or `number` with precision documented — never `float`/`double`
- [ ] Dates use `format: date`; timestamps use `format: date-time` (ISO 8601 with timezone)

### Schema Constraints

- [ ] `minLength` / `maxLength` set on strings where applicable
- [ ] `minimum` / `maximum` set on numeric types where applicable
- [ ] `pattern` used for structured strings not covered by built-in formats
- [ ] `required` array is present on objects where properties must be provided
- [ ] `readOnly: true` set on server-generated properties (`id`, `createdAt`)
- [ ] `writeOnly: true` set on request-only properties (e.g., `password`)

### Naming

- [ ] Schema names are `PascalCase` and singular (`Order`, `OrderItem`)
- [ ] Request schemas suffixed with `Request` where distinct (`CreateOrderRequest`)
- [ ] Response schemas suffixed with `Response` where distinct (`OrderSummaryResponse`)
- [ ] Property names are `camelCase`
- [ ] Boolean properties use `is`, `has`, or `can` prefix

---

## Security

### Scheme Definition

- [ ] Security schemes are defined in `components/securitySchemes`
- [ ] JWT bearer auth uses `type: http`, `scheme: bearer`, `bearerFormat: JWT`
- [ ] OAuth2 flows define correct scopes
- [ ] API key schemes define the parameter name and location

### Operation-Level Security

- [ ] Security is applied globally and overridden per-operation where needed
- [ ] Public endpoints explicitly declare `security: []` to override global security
- [ ] Required scopes are specified per operation in OAuth2 schemes

### Sensitive Data

- [ ] Spec does not include example values with real credentials or PII
- [ ] Sensitive response fields are marked `writeOnly: true` or excluded from responses

---

## Versioning

### Version Strategy

- [ ] Version strategy is documented (URL path `/v1/`, header, or `Accept` header) and consistent
- [ ] Breaking changes increment the major version
- [ ] Non-breaking additions (new optional fields, new endpoints) do not require a version bump
- [ ] Deprecated API versions document a sunset date

### Deprecation

- [ ] Deprecated operations are marked with `deprecated: true`
- [ ] Deprecated operations include replacement and removal timeline in description
- [ ] Deprecated schema properties are marked `deprecated: true` with migration guidance

---

## Reusability and Components

- [ ] Schemas used in more than one place are in `components/schemas` and referenced via `$ref`
- [ ] Common parameters (e.g., pagination, tenant ID) are in `components/parameters`
- [ ] Common responses (e.g., `ProblemDetails`, `PagedResponse`) are in `components/responses`
- [ ] Common headers are in `components/headers`
- [ ] Inline schemas are only used for one-off definitions with no reuse potential
- [ ] Circular `$ref` references are avoided unless the toolchain handles them correctly
- [ ] All `$ref` references resolve without errors

---

## Documentation Quality

### Descriptions

- [ ] Every operation has a `summary` (short) and `description` (detail including edge cases)
- [ ] Every parameter has a `description`
- [ ] Every schema property has a `description`
- [ ] Descriptions explain consumer-facing behaviour — not implementation details

### Examples

- [ ] Operations include `examples` on request and response bodies
- [ ] Examples are realistic — not `string`, `0`, `true` placeholders
- [ ] Examples do not contain real customer data or valid credentials
- [ ] Multiple named examples for endpoints with varied response shapes

---

## Tooling and Validation

### Linting

- [ ] Spec passes Spectral or equivalent linter with no errors
- [ ] Spectral ruleset is configured and committed to the repository
- [ ] Linting runs in CI on PR and fails the build on errors

### Code-First Generation (Swashbuckle/NSwag)

- [ ] XML documentation is enabled and surfaced in the spec
- [ ] `[ProducesResponseType]` attributes are complete on all controller actions
- [ ] Spec is reviewed as a first-class artefact — not treated as disposable auto-output
- [ ] Schema filters handle `ProblemDetails`, enums, and nullable types correctly

### Breaking Change Detection

- [ ] API diff tool (`oasdiff`, `openapi-diff`) runs in CI
- [ ] Breaking change detection fails the build without a version increment
- [ ] Breaking changes are explicitly acknowledged and communicated to API consumers

---

## Review Checklist Summary

Before approving a PR, ensure:

1. **Validation**: Spectral linter passes with no errors
2. **Operation IDs**: Unique and meaningfully named
3. **Responses**: All status codes covered; consistent Problem Details error schema
4. **Schemas**: Types, formats, constraints, and `required` complete; no bare `{}`
5. **Security**: Schemes defined; all operations secured; public endpoints opt out explicitly
6. **Breaking Changes**: API diff run; version incremented if needed
7. **Deprecation**: `deprecated: true` set with description and sunset timeline
8. **Examples**: Realistic examples on requests and responses
9. **Descriptions**: Summary and description on all operations, parameters, and properties
10. **Components**: Reusable schemas and parameters extracted to `components/`

---

## Customisation Notes

- Add your Spectral ruleset file reference
- Document your versioning strategy decision (URL vs header)
- Add your Problem Details schema component definition
- Reference your API gateway and how specs are published
- Add your consumer-driven contract testing setup
- Reference your auth scheme names and scope definitions