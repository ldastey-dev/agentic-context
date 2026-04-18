# .NET Standards — C#, ASP.NET Core & Entity Framework

Every .NET service must follow established architectural patterns, use modern C# idioms, and treat performance, security, and testability as first-class concerns. Code must be readable, maintainable, and aligned with the team's conventions at all times.

---

## 1 · Architecture and Design

### 1.1 · SOLID Principles

- Every class must adhere to the Single Responsibility Principle: one class, one reason to change.
- Types must be open for extension and closed for modification (Open-Closed Principle).
- Derived classes must always be substitutable for their base classes (Liskov Substitution Principle).
- Interfaces must be segregated so that clients never depend on methods they do not use (Interface Segregation Principle).
- High-level modules must never depend on low-level modules; both must depend on abstractions (Dependency Inversion Principle).

### 1.2 · Project Structure

- Solution structure must be logical and follow team conventions.
- Projects must have clear responsibilities and boundaries.
- Circular dependencies between projects must never exist.
- Shared code must be properly abstracted in common libraries.
- Feature folders or vertical slices must be used consistently where adopted.

### 1.3 · Design Patterns

- Patterns must be used appropriately — never over-engineered.
- The repository pattern must be used consistently for data access where adopted.
- Factory patterns must be used for complex object creation.
- The strategy pattern must be used for interchangeable algorithms.
- The options pattern must always be used for configuration.

---

## 2 · C# Best Practices

### 2.1 · Naming Conventions

- Public members, types, and namespaces must use PascalCase.
- Private fields must use camelCase (with or without `_` prefix per team convention).
- Interfaces must always be prefixed with `I` (e.g., `IUserService`).
- Async methods must always be suffixed with `Async`.
- Boolean properties and methods must use `Is`, `Has`, `Can`, or `Should` prefixes.

### 2.2 · Type Usage

- `var` must only be used when the type is obvious from context.
- Nullable reference types must be enabled and respected.
- `record` types must be used for immutable data transfer objects.
- Value types and reference types must be chosen appropriately for each use case.
- Generic constraints must be used to enforce type safety.

### 2.3 · Modern C# Features

- Pattern matching must be used for cleaner conditionals.
- Null-coalescing operators (`??`, `??=`) must be used where appropriate.
- Expression-bodied members must be used for simple methods and properties.
- Collection expressions and primary constructors must be used where supported.
- The `required` modifier must be used for mandatory initialisation.

### 2.4 · Code Quality

- Empty catch blocks must never exist.
- Compiler warnings must never be suppressed without documented justification.
- Magic numbers must always be extracted to named constants.
- String interpolation must always be preferred over concatenation.
- `nameof` must always be used instead of hardcoded member names.

---

## 3 · ASP.NET Core

### 3.1 · Controllers

- Controllers must be thin — business logic must always reside in services.
- Action methods must return appropriate `IActionResult` types.
- Route attributes must be clear and RESTful.
- Model validation must be performed using DataAnnotations or FluentValidation.
- API versioning must be implemented where applicable.

### 3.2 · Minimal APIs

- Endpoints must be organised logically.
- Request and response types must be well-defined.
- Endpoint filters must be used for cross-cutting concerns.
- Route groups must be used to reduce duplication.
- OpenAPI metadata must be properly configured.

### 3.3 · Middleware

- Middleware order must be correct in the pipeline.
- Custom middleware must be properly implemented and documented.
- Middleware must never be used for request-specific logic.
- Exception handling middleware must always be configured.
- CORS, authentication, and authorisation must be properly ordered.

### 3.4 · Model Binding and Validation

- DTOs must always be used for API contracts — never domain entities.
- Validation attributes must be appropriate and complete.
- Complex validation must use `IValidatableObject` or FluentValidation.
- Model state must always be checked before processing.
- Custom model binders must be documented.

---

## 4 · Entity Framework and Data Access

### 4.1 · DbContext

- DbContext lifetime must be correctly scoped.
- Connection strings must never be hardcoded.
- Migrations must always be used for schema changes.
- Seed data must be appropriately managed.
- Multiple DbContexts must be justified when present.

### 4.2 · Query Performance

- N+1 queries must always be avoided (use `Include`/`ThenInclude`).
- Projections must be used to select only needed columns.
- `AsNoTracking` must be used for read-only queries.
- Pagination must be implemented for large result sets.
- Indexes must be considered for frequently queried columns.

### 4.3 · Best Practices

- The repository pattern must abstract EF where adopted by the team.
- The Unit of Work pattern must be used for transactions where applicable.
- Raw SQL must be avoided unless necessary, and must always be parameterised.
- Lazy loading must be disabled or used intentionally — never left as a default.
- Concurrency must be handled where needed using `RowVersion` or equivalent.

### 4.4 · Data Integrity

- Foreign keys and constraints must be properly defined.
- Cascade deletes must be intentional and documented.
- Soft delete must be implemented consistently where used.
- Audit fields must always be populated (`CreatedAt`, `ModifiedAt`, etc.).
- Data annotations and Fluent API configurations must be complete.

---

## 5 · Dependency Injection

### 5.1 · Registration

- Services must be registered with appropriate lifetimes.
- Scoped services must never be injected into singletons.
- Interfaces must always be used for service contracts.
- Registration must be organised using extension methods or modules.
- Factory registrations must be used for complex scenarios.

### 5.2 · Design

- Constructor injection must always be preferred.
- The service locator pattern must never be used.
- Dependencies must be kept minimal per class.
- Circular dependencies must never exist.
- `IOptions<T>` must be used for configuration injection.

### 5.3 · Testing Support

- Services must be easily mockable via interfaces.
- Static dependencies must be minimised.
- Time-dependent code must use `IDateTimeProvider` or similar abstraction.
- File system access must be abstracted where applicable.
- HTTP calls must be abstracted via typed clients.

---

## 6 · Async Programming

### 6.1 · Async/Await

- `async` methods must be truly asynchronous — never wrapping synchronous code.
- `await` must not be used unnecessarily on the final return.
- `ConfigureAwait(false)` must be used in library code.
- `Task.Run` must never be used to fake async behaviour.
- `async void` must only be used for event handlers.

### 6.2 · Cancellation

- `CancellationToken` must be accepted by all async methods.
- Cancellation tokens must always be passed through call chains.
- Cancellation must be checked in long-running operations.
- `OperationCanceledException` must be handled appropriately.
- HTTP request cancellation tokens must always be used.

### 6.3 · Thread Safety

- Shared state must always be properly synchronised.
- `ConcurrentDictionary` and similar types must be used where appropriate.
- `lock` statements must always be kept short.
- Deadlocks must be avoided in all synchronisation logic.
- `Interlocked` operations must be used for simple counters.

---

## 7 · Error Handling

### 7.1 · Exception Handling

- Exceptions must be caught at appropriate levels.
- Specific exception types must always be caught — never bare `Exception`.
- Exceptions must never be used for control flow.
- Inner exceptions must always be preserved when re-throwing.
- Custom exceptions must inherit from appropriate base types.

### 7.2 · Result Pattern

- Where adopted, result types must be used consistently for expected failures.
- Validation errors must return a Result, never throw exceptions.
- Business rule failures must return Result types.
- Infrastructure failures may still throw exceptions where appropriate.
- Result handling must never be ignored.

### 7.3 · API Error Responses

- Problem Details format must be used for error responses.
- Error messages must be user-friendly — never expose stack traces.
- Appropriate HTTP status codes must always be returned.
- Validation errors must include field-level details.
- Error correlation IDs must always be included.

---

## 8 · Testing

### 8.1 · Unit Tests

- Tests must follow the Arrange-Act-Assert pattern.
- Test names must describe the scenario and expected outcome.
- Tests must be independent and isolated.
- Mocking must be appropriate and never excessive.
- Edge cases and boundaries must always be tested.

### 8.2 · Integration Tests

- `WebApplicationFactory` must be used for API tests.
- The test database must be properly isolated.
- External dependencies must be appropriately mocked or stubbed.
- Tests must always clean up after themselves.
- Configuration must be appropriate for the test environment.

### 8.3 · Test Quality

- Tests must verify behaviour, not implementation.
- Assertions must be meaningful and specific.
- Test data builders and factories must be used to reduce duplication.
- Flaky tests must be identified and fixed immediately.
- Code coverage must be meaningful — never optimised for percentage alone.

### 8.4 · Mocking Best Practices

- Only external dependencies must be mocked.
- Mocks must verify important interactions.
- Mock setup must be clear and minimal.
- In-memory implementations must be preferred where practical.
- Test doubles must be appropriate for the scenario (mock vs stub vs fake).

---

## 9 · Security

### 9.1 · Authentication and Authorisation

- Authentication must be properly configured on every endpoint.
- Authorisation policies must be used appropriately.
- JWT validation must be complete (issuer, audience, expiry).
- Secrets must never be hardcoded.
- Sensitive endpoints must always require authentication.

### 9.2 · Input Validation

- All user input must be validated.
- SQL injection must be prevented via parameterised queries.
- XSS must be prevented via proper encoding.
- Path traversal must always be prevented.
- File upload validation must be thorough.

### 9.3 · Data Protection

- Sensitive data must be encrypted at rest.
- Sensitive data must never be logged.
- PII must be handled according to applicable regulations.
- The Data Protection API must be used for encryption.
- Connection strings must use managed identities where possible.

### 9.4 · OWASP Top 10

- Broken access control must always be prevented.
- Cryptographic failures must be avoided.
- Injection attacks must be prevented at every layer.
- Insecure design must be addressed during review.
- Security misconfiguration must never reach production.

---

## 10 · Performance

### 10.1 · Memory Management

- Large objects must be pooled where appropriate.
- `Span<T>` and `Memory<T>` must be used to reduce allocations.
- String building must use `StringBuilder` for concatenation loops.
- `IDisposable` resources must always be properly disposed.
- Memory leaks from event handlers must always be avoided.

### 10.2 · Caching

- Caching must be implemented for expensive operations.
- Cache invalidation must be properly handled.
- Distributed cache must be used in multi-instance scenarios.
- Cache keys must be consistent and collision-free.
- Cache expiration policies must be appropriate.

### 10.3 · Database Performance

- Indexes must support common query patterns.
- Queries must be optimised — `SELECT *` must never be used.
- Connection pooling must be properly configured.
- Batch operations must be used for bulk changes.
- Query execution plans must be reviewed for complex queries.

### 10.4 · HTTP Client

- `IHttpClientFactory` must always be used — never `new HttpClient()`.
- Typed clients must be configured appropriately.
- Timeouts and retry policies must always be configured.
- DNS refresh must be handled properly.
- The circuit breaker pattern must be implemented where appropriate.

---

## 11 · Logging and Observability

### 11.1 · Structured Logging

- Logging must use structured format — never string concatenation.
- Log levels must be appropriate (Debug, Info, Warning, Error).
- Correlation IDs must always enable request tracing.
- Sensitive data must never be logged.
- Performance-sensitive paths must minimise logging.

### 11.2 · Log Content

- Exceptions must include full stack traces at Error level.
- Context must always be included (user, operation, entity IDs).
- Start and completion of operations must be logged.
- External service calls must always be logged.
- Log messages must be actionable.

### 11.3 · Metrics and Tracing

- Health checks must always be implemented.
- Key metrics must be exposed (response times, error rates).
- Distributed tracing must be enabled (OpenTelemetry).
- Performance counters must track critical operations.
- Dashboards must exist for monitoring where applicable.

---

## 12 · Documentation

### 12.1 · Code Documentation

- Public APIs must have XML documentation.
- Complex algorithms must have explanatory comments.
- TODO comments must always include ticket references.
- Outdated comments must be removed.
- Self-documenting code must always be preferred over comments.

### 12.2 · API Documentation

- OpenAPI/Swagger must be properly configured.
- Request and response examples must be provided.
- Error responses must be documented.
- Authentication requirements must be documented.
- Breaking changes must always be communicated.

### 12.3 · Architecture Documentation

- README must explain project setup and structure.
- Architecture decisions must be recorded (ADRs).
- Deployment process must be documented.
- Configuration options must be documented.
- Troubleshooting guides must exist for common issues.

---

## Non-Negotiables

- Scoped services must never be injected into singletons — this causes silent runtime bugs that are extremely difficult to diagnose.
- `async void` must never be used outside of event handlers — unobserved exceptions will crash the process.
- Empty catch blocks must never exist — every exception must be logged or re-thrown.
- `new HttpClient()` must never be used directly — always use `IHttpClientFactory` to prevent socket exhaustion.
- Connection strings and secrets must never be hardcoded — always source from configuration or a secrets manager.
- Raw SQL must never be constructed via string concatenation — always use parameterised queries.
- N+1 queries must never reach production — always use `Include`/`ThenInclude` or projections.
- Controllers must never contain business logic — all domain logic must reside in services.

---

## Decision Checklist

Before merging any change, verify each item:

- [ ] SOLID principles are followed and no circular dependencies exist
- [ ] Naming conventions are consistent (PascalCase public, camelCase private, `I` prefix on interfaces)
- [ ] Nullable reference types are enabled and handled correctly
- [ ] Controllers are thin and delegate to services
- [ ] DTOs are used for API contracts — domain entities are never exposed
- [ ] EF queries are optimised with projections, `AsNoTracking`, and pagination
- [ ] DI lifetimes are correct and no scoped-into-singleton violations exist
- [ ] All async methods accept `CancellationToken` and pass it through the chain
- [ ] Exceptions are caught specifically, logged, and surfaced with Problem Details
- [ ] Unit and integration tests cover the change with meaningful assertions
- [ ] Security controls are in place (auth, input validation, no logged secrets)
- [ ] Structured logging is used with correlation IDs and appropriate log levels
- [ ] `IHttpClientFactory` is used with timeouts and retry policies configured
- [ ] Database migrations are included and indexes support new query patterns
- [ ] No compiler warnings are suppressed without documented justification
