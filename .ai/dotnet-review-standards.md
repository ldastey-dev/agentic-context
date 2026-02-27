# .NET Code Review Standards

This document provides generic code review standards for .NET applications. Customize these guidelines to fit your team's specific needs and project requirements.

## Table of Contents

- [Architecture and Design](#architecture-and-design)
- [C# Best Practices](#c-best-practices)
- [ASP.NET Core](#aspnet-core)
- [Entity Framework and Data Access](#entity-framework-and-data-access)
- [Dependency Injection](#dependency-injection)
- [Async Programming](#async-programming)
- [Error Handling](#error-handling)
- [Testing](#testing)
- [Security](#security)
- [Performance](#performance)
- [Logging and Observability](#logging-and-observability)
- [Documentation](#documentation)

---

## Architecture and Design

### SOLID Principles

- [ ] **Single Responsibility**: Classes have one reason to change
- [ ] **Open/Closed**: Open for extension, closed for modification
- [ ] **Liskov Substitution**: Derived classes can substitute base classes
- [ ] **Interface Segregation**: Clients aren't forced to depend on unused methods
- [ ] **Dependency Inversion**: High-level modules don't depend on low-level modules

### Project Structure

- [ ] Solution structure is logical and follows team conventions
- [ ] Projects have clear responsibilities and boundaries
- [ ] Circular dependencies between projects are avoided
- [ ] Shared code is properly abstracted in common libraries
- [ ] Feature folders or vertical slices are used consistently (if applicable)

### Design Patterns

- [ ] Patterns are used appropriately, not over-engineered
- [ ] Repository pattern is used consistently for data access (if adopted)
- [ ] Factory patterns are used for complex object creation
- [ ] Strategy pattern is used for interchangeable algorithms
- [ ] Options pattern is used for configuration

---

## C# Best Practices

### Naming Conventions

- [ ] PascalCase for public members, types, namespaces
- [ ] camelCase for private fields (with or without `_` prefix per team convention)
- [ ] Interfaces prefixed with `I` (e.g., `IUserService`)
- [ ] Async methods suffixed with `Async`
- [ ] Boolean properties/methods use `Is`, `Has`, `Can`, `Should` prefixes

### Type Usage

- [ ] `var` is used appropriately (when type is obvious from context)
- [ ] Nullable reference types are enabled and respected
- [ ] `record` types are used for immutable data transfer objects
- [ ] Value types vs reference types are chosen appropriately
- [ ] Generic constraints are used to enforce type safety

### Modern C# Features

- [ ] Pattern matching is used for cleaner conditionals
- [ ] Null-coalescing operators (`??`, `??=`) are used appropriately
- [ ] Expression-bodied members are used for simple methods/properties
- [ ] Collection expressions and primary constructors (where supported)
- [ ] `required` modifier is used for mandatory initialization

### Code Quality

- [ ] No empty catch blocks
- [ ] No suppression of compiler warnings without justification
- [ ] Magic numbers are extracted to named constants
- [ ] String interpolation is preferred over concatenation
- [ ] `nameof` is used instead of hardcoded member names

---

## ASP.NET Core

### Controllers

- [ ] Controllers are thin - business logic is in services
- [ ] Action methods return appropriate `IActionResult` types
- [ ] Route attributes are clear and RESTful
- [ ] Model validation is performed (DataAnnotations or FluentValidation)
- [ ] API versioning is implemented (if applicable)

### Minimal APIs (if applicable)

- [ ] Endpoints are organized logically
- [ ] Request/response types are well-defined
- [ ] Endpoint filters are used for cross-cutting concerns
- [ ] Route groups are used to reduce duplication
- [ ] OpenAPI metadata is properly configured

### Middleware

- [ ] Middleware order is correct in the pipeline
- [ ] Custom middleware is properly implemented
- [ ] Middleware is not used for request-specific logic
- [ ] Exception handling middleware is configured
- [ ] CORS, authentication, authorization are properly ordered

### Model Binding and Validation

- [ ] DTOs are used for API contracts (not domain entities)
- [ ] Validation attributes are appropriate and complete
- [ ] Complex validation uses `IValidatableObject` or FluentValidation
- [ ] Model state is checked before processing
- [ ] Custom model binders are documented

---

## Entity Framework and Data Access

### DbContext

- [ ] DbContext lifetime is correctly scoped
- [ ] Connection strings are not hardcoded
- [ ] Migrations are used for schema changes
- [ ] Seed data is appropriately managed
- [ ] Multiple DbContexts are justified (if present)

### Query Performance

- [ ] N+1 queries are avoided (use `Include`/`ThenInclude`)
- [ ] Projections are used to select only needed columns
- [ ] `AsNoTracking` is used for read-only queries
- [ ] Pagination is implemented for large result sets
- [ ] Indexes are considered for frequently queried columns

### Best Practices

- [ ] Repository pattern abstracts EF (if adopted by team)
- [ ] Unit of Work pattern is used for transactions (if applicable)
- [ ] Raw SQL is avoided unless necessary (and parameterized)
- [ ] Lazy loading is disabled or used intentionally
- [ ] Concurrency is handled where needed (`RowVersion`)

### Data Integrity

- [ ] Foreign keys and constraints are properly defined
- [ ] Cascade deletes are intentional and documented
- [ ] Soft delete is implemented consistently (if used)
- [ ] Audit fields are populated (CreatedAt, ModifiedAt, etc.)
- [ ] Data annotations/Fluent API configurations are complete

---

## Dependency Injection

### Registration

- [ ] Services are registered with appropriate lifetimes
- [ ] Scoped services are not injected into singletons
- [ ] Interfaces are used for service contracts
- [ ] Registration is organized (extension methods or modules)
- [ ] Factory registrations are used for complex scenarios

### Design

- [ ] Constructor injection is preferred
- [ ] Service locator pattern is avoided
- [ ] Dependencies are kept minimal per class
- [ ] Circular dependencies are avoided
- [ ] `IOptions<T>` is used for configuration injection

### Testing Support

- [ ] Services are easily mockable via interfaces
- [ ] Static dependencies are minimized
- [ ] Time-dependent code uses `IDateTimeProvider` or similar
- [ ] File system access is abstracted (if applicable)
- [ ] HTTP calls are abstracted via typed clients

---

## Async Programming

### Async/Await

- [ ] `async` methods are truly asynchronous (not wrapping sync code)
- [ ] `await` is not used unnecessarily on final return
- [ ] `ConfigureAwait(false)` is used in library code
- [ ] `Task.Run` is not used to fake async
- [ ] `async void` is only used for event handlers

### Cancellation

- [ ] `CancellationToken` is accepted by async methods
- [ ] Cancellation tokens are passed through call chains
- [ ] Cancellation is checked in long-running operations
- [ ] `OperationCanceledException` is handled appropriately
- [ ] HTTP request cancellation tokens are used

### Thread Safety

- [ ] Shared state is properly synchronized
- [ ] `ConcurrentDictionary` and similar are used appropriately
- [ ] `lock` statements are kept short
- [ ] Deadlocks are avoided in synchronization
- [ ] `Interlocked` operations are used for simple counters

---

## Error Handling

### Exception Handling

- [ ] Exceptions are caught at appropriate levels
- [ ] Specific exception types are caught (not just `Exception`)
- [ ] Exceptions are not used for control flow
- [ ] Inner exceptions are preserved when re-throwing
- [ ] Custom exceptions inherit from appropriate base types

### Result Pattern (if adopted)

- [ ] Result types are used consistently for expected failures
- [ ] Validation errors return Result, not throw exceptions
- [ ] Business rule failures return Result types
- [ ] Infrastructure failures may still throw exceptions
- [ ] Result handling is not ignored

### API Error Responses

- [ ] Problem Details format is used for error responses
- [ ] Error messages are user-friendly (not stack traces)
- [ ] Appropriate HTTP status codes are returned
- [ ] Validation errors include field-level details
- [ ] Error correlation IDs are included

---

## Testing

### Unit Tests

- [ ] Tests follow Arrange-Act-Assert pattern
- [ ] Test names describe scenario and expected outcome
- [ ] Tests are independent and isolated
- [ ] Mocking is appropriate and not excessive
- [ ] Edge cases and boundaries are tested

### Integration Tests

- [ ] `WebApplicationFactory` is used for API tests
- [ ] Test database is properly isolated
- [ ] External dependencies are appropriately mocked/stubbed
- [ ] Tests clean up after themselves
- [ ] Configuration is appropriate for test environment

### Test Quality

- [ ] Tests verify behavior, not implementation
- [ ] Assertions are meaningful and specific
- [ ] Test data builders/factories reduce duplication
- [ ] Flaky tests are identified and fixed
- [ ] Code coverage is meaningful (not just high percentage)

### Mocking Best Practices

- [ ] Only external dependencies are mocked
- [ ] Mocks verify important interactions
- [ ] Mock setup is clear and minimal
- [ ] In-memory implementations are preferred where practical
- [ ] Test doubles are appropriate (mock vs stub vs fake)

---

## Security

### Authentication and Authorization

- [ ] Authentication is properly configured
- [ ] Authorization policies are used appropriately
- [ ] JWT validation is complete (issuer, audience, expiry)
- [ ] Secrets are not hardcoded
- [ ] Sensitive endpoints require authentication

### Input Validation

- [ ] All user input is validated
- [ ] SQL injection is prevented (parameterized queries)
- [ ] XSS is prevented (proper encoding)
- [ ] Path traversal is prevented
- [ ] File upload validation is thorough

### Data Protection

- [ ] Sensitive data is encrypted at rest
- [ ] Sensitive data is not logged
- [ ] PII is handled according to regulations
- [ ] Data Protection API is used for encryption
- [ ] Connection strings use managed identities where possible

### OWASP Top 10

- [ ] Broken access control is prevented
- [ ] Cryptographic failures are avoided
- [ ] Injection attacks are prevented
- [ ] Insecure design is addressed
- [ ] Security misconfiguration is avoided

---

## Performance

### Memory Management

- [ ] Large objects are pooled where appropriate
- [ ] `Span<T>` and `Memory<T>` reduce allocations
- [ ] String building uses `StringBuilder` for concatenation loops
- [ ] `IDisposable` resources are properly disposed
- [ ] Memory leaks from event handlers are avoided

### Caching

- [ ] Caching is implemented for expensive operations
- [ ] Cache invalidation is properly handled
- [ ] Distributed cache is used in multi-instance scenarios
- [ ] Cache keys are consistent and collision-free
- [ ] Cache expiration policies are appropriate

### Database Performance

- [ ] Indexes support common query patterns
- [ ] Queries are optimized (no SELECT *)
- [ ] Connection pooling is properly configured
- [ ] Batch operations are used for bulk changes
- [ ] Query execution plans are reviewed for complex queries

### HTTP Client

- [ ] `IHttpClientFactory` is used (not `new HttpClient()`)
- [ ] Typed clients are configured appropriately
- [ ] Timeouts and retry policies are configured
- [ ] DNS refresh is handled properly
- [ ] Circuit breaker pattern is implemented (if appropriate)

---

## Logging and Observability

### Structured Logging

- [ ] Logging uses structured format (not string concatenation)
- [ ] Log levels are appropriate (Debug, Info, Warning, Error)
- [ ] Correlation IDs enable request tracing
- [ ] Sensitive data is not logged
- [ ] Performance-sensitive paths minimize logging

### Log Content

- [ ] Exceptions include full stack traces at Error level
- [ ] Context is included (user, operation, entity IDs)
- [ ] Start and completion of operations are logged
- [ ] External service calls are logged
- [ ] Log messages are actionable

### Metrics and Tracing

- [ ] Health checks are implemented
- [ ] Key metrics are exposed (response times, error rates)
- [ ] Distributed tracing is enabled (OpenTelemetry)
- [ ] Performance counters track critical operations
- [ ] Dashboards exist for monitoring (if applicable)

---

## Documentation

### Code Documentation

- [ ] Public APIs have XML documentation
- [ ] Complex algorithms have explanatory comments
- [ ] TODO comments include ticket references
- [ ] Outdated comments are removed
- [ ] Self-documenting code is preferred over comments

### API Documentation

- [ ] OpenAPI/Swagger is properly configured
- [ ] Request/response examples are provided
- [ ] Error responses are documented
- [ ] Authentication requirements are documented
- [ ] Breaking changes are communicated

### Architecture Documentation

- [ ] README explains project setup and structure
- [ ] Architecture decisions are recorded (ADRs)
- [ ] Deployment process is documented
- [ ] Configuration options are documented
- [ ] Troubleshooting guides exist for common issues

---

## Review Checklist Summary

Before approving a PR, ensure:

1. **Functionality**: The code works as intended and handles edge cases
2. **Architecture**: Code follows SOLID principles and established patterns
3. **C# Best Practices**: Modern C# features are used appropriately
4. **Data Access**: Queries are efficient and secure
5. **Async**: Asynchronous code is correct and handles cancellation
6. **Error Handling**: Errors are handled gracefully and logged
7. **Security**: No vulnerabilities are introduced
8. **Testing**: Appropriate test coverage exists
9. **Performance**: No obvious performance issues
10. **Observability**: Changes are properly logged and monitored

---

## Customization Notes

This template should be customized for your team:

- Add project-specific patterns and conventions
- Remove sections that don't apply to your stack (e.g., EF if using Dapper)
- Add links to internal documentation and examples
- Include specific analyzer rules and configurations
- Reference your NuGet package guidelines
- Add cloud-specific guidelines (Azure, AWS) as needed