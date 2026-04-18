# React Code Review Standards

This document provides generic code review standards for React applications. Customize these guidelines to fit your team's specific needs and project requirements.

## Table of Contents

- [Component Architecture](#component-architecture)
- [State Management](#state-management)
- [Performance](#performance)
- [TypeScript Usage](#typescript-usage)
- [Testing](#testing)
- [Accessibility](#accessibility)
- [Security](#security)
- [Code Style](#code-style)
- [Error Handling](#error-handling)
- [Documentation](#documentation)

---

## Component Architecture

### Component Structure

- [ ] Components follow single responsibility principle
- [ ] Component files are appropriately sized (consider splitting if > 200-300 lines)
- [ ] Presentational and container components are properly separated
- [ ] Custom hooks extract reusable logic from components
- [ ] Component hierarchy is logical and avoids unnecessary nesting

### Naming Conventions

- [ ] Component names are PascalCase and descriptive
- [ ] Event handlers follow `handle[Event]` naming (e.g., `handleClick`, `handleSubmit`)
- [ ] Props passed to children follow `on[Event]` naming (e.g., `onClick`, `onSubmit`)
- [ ] Boolean props use `is`, `has`, or `should` prefixes (e.g., `isLoading`, `hasError`)
- [ ] Custom hooks start with `use` prefix

### Props

- [ ] Props are properly typed (TypeScript) or documented (PropTypes)
- [ ] Default props are defined where appropriate
- [ ] Props destructuring is used for cleaner code
- [ ] Spread operators on props are used sparingly and intentionally
- [ ] Callback props are memoized when passed to child components

---

## State Management

### Local State

- [ ] State is kept as close to where it's needed as possible
- [ ] `useState` is used appropriately for simple state
- [ ] `useReducer` is used for complex state logic
- [ ] State updates are immutable
- [ ] Derived state is calculated during render, not stored

### Global State

- [ ] Global state contains only truly global data
- [ ] State shape is normalized where appropriate
- [ ] Selectors are used to access state slices
- [ ] State updates follow predictable patterns
- [ ] Async operations are handled consistently

### Side Effects

- [ ] `useEffect` dependencies are correctly specified
- [ ] Cleanup functions are provided where needed
- [ ] Effects are not overused (consider alternatives)
- [ ] Data fetching follows established patterns
- [ ] Race conditions are handled in async effects

---

## Performance

### Rendering Optimization

- [ ] `React.memo` is used appropriately for expensive components
- [ ] `useMemo` is used for expensive calculations
- [ ] `useCallback` is used for callbacks passed to optimized children
- [ ] Lists include stable, unique `key` props
- [ ] Large lists use virtualization when appropriate

### Bundle Size

- [ ] Lazy loading is used for route-level code splitting
- [ ] Dynamic imports are used for heavy dependencies
- [ ] Tree-shaking friendly imports are used (named imports)
- [ ] Image assets are optimized
- [ ] Unnecessary dependencies are avoided

### Network

- [ ] API calls are deduplicated where appropriate
- [ ] Caching strategies are implemented
- [ ] Loading states are handled gracefully
- [ ] Pagination or infinite scroll is used for large data sets
- [ ] Optimistic updates are used where appropriate

---

## TypeScript Usage

### Type Safety

- [ ] `any` type is avoided (use `unknown` if type is truly unknown)
- [ ] Type assertions are minimized and justified
- [ ] Generic types are used for reusable components/functions
- [ ] Union types are preferred over enums where appropriate
- [ ] Nullable types are handled explicitly

### Component Types

- [ ] Props interfaces are defined for all components
- [ ] Event handler types are correctly specified
- [ ] Ref types are properly defined
- [ ] Children types are explicit when needed
- [ ] Generic components have proper type constraints

### Best Practices

- [ ] Types are exported alongside components when needed externally
- [ ] Utility types (`Partial`, `Pick`, `Omit`) are used effectively
- [ ] Type inference is leveraged where types are obvious
- [ ] Discriminated unions are used for complex state
- [ ] Type guards are used for runtime type checking

---

## Testing

### Unit Tests

- [ ] Components have appropriate test coverage
- [ ] Tests focus on behavior, not implementation details
- [ ] Edge cases and error states are tested
- [ ] Mocks are used appropriately and not excessively
- [ ] Tests are readable and serve as documentation

### Testing Library Best Practices

- [ ] Queries follow priority: getByRole > getByLabelText > getByText
- [ ] `userEvent` is preferred over `fireEvent`
- [ ] Async operations use `waitFor` or `findBy` queries
- [ ] Tests avoid querying by test IDs when better options exist
- [ ] Accessibility queries are preferred

### Integration Tests

- [ ] Critical user flows have integration tests
- [ ] API mocking is consistent and realistic
- [ ] Tests are independent and can run in isolation
- [ ] Setup and teardown are handled properly
- [ ] Tests run reliably without flakiness

---

## Accessibility

### Semantic HTML

- [ ] Appropriate HTML elements are used (button, nav, main, etc.)
- [ ] Heading hierarchy is logical (h1 > h2 > h3)
- [ ] Lists use proper ul/ol/li elements
- [ ] Forms have associated labels
- [ ] Tables are used for tabular data only

### ARIA

- [ ] ARIA attributes are used only when semantic HTML is insufficient
- [ ] `aria-label` and `aria-describedby` are used appropriately
- [ ] Live regions announce dynamic content
- [ ] Focus management is handled for modals and dynamic content
- [ ] `aria-hidden` is used correctly

### Keyboard Navigation

- [ ] All interactive elements are keyboard accessible
- [ ] Focus order is logical
- [ ] Focus indicators are visible
- [ ] Keyboard shortcuts don't conflict with assistive technology
- [ ] Skip links are provided for main content

---

## Security

### Input Handling

- [ ] User input is validated on both client and server
- [ ] `dangerouslySetInnerHTML` is avoided or used with sanitized content
- [ ] URL parameters are validated before use
- [ ] File uploads are validated and restricted

### Data Protection

- [ ] Sensitive data is not stored in local storage
- [ ] API keys are not exposed in client-side code
- [ ] Authentication tokens are handled securely
- [ ] CORS is properly configured
- [ ] HTTPS is enforced for all requests

### Dependencies

- [ ] Dependencies are from trusted sources
- [ ] Dependencies are regularly updated
- [ ] Security vulnerabilities are addressed promptly
- [ ] Lock files are committed
- [ ] Unused dependencies are removed

---

## Code Style

### Formatting

- [ ] Code follows consistent formatting (Prettier/ESLint)
- [ ] Import statements are organized (external, internal, relative)
- [ ] No unused imports or variables
- [ ] Consistent use of quotes (single/double)
- [ ] Consistent semicolon usage

### Code Organization

- [ ] Related code is grouped together
- [ ] Magic numbers are extracted to named constants
- [ ] Complex conditions are extracted to named variables
- [ ] Early returns improve readability
- [ ] Functions are kept small and focused

### React-Specific

- [ ] JSX is properly formatted and indented
- [ ] Conditional rendering is clean and readable
- [ ] Fragments are used instead of unnecessary wrapper divs
- [ ] Event handlers are not inline (unless very simple)
- [ ] Component composition is preferred over prop drilling

---

## Error Handling

### Error Boundaries

- [ ] Error boundaries are implemented at appropriate levels
- [ ] Fallback UIs are user-friendly
- [ ] Errors are logged for debugging
- [ ] Error recovery options are provided where possible

### API Errors

- [ ] Error responses are handled gracefully
- [ ] User-friendly error messages are displayed
- [ ] Retry logic is implemented where appropriate
- [ ] Network failures are handled
- [ ] Loading and error states are mutually exclusive

### Form Validation

- [ ] Validation messages are clear and helpful
- [ ] Validation occurs on blur and submit
- [ ] Server-side validation errors are displayed
- [ ] Form state is preserved on validation failure
- [ ] Success feedback is provided

---

## Documentation

### Code Comments

- [ ] Complex logic has explanatory comments
- [ ] TODO comments include context or ticket references
- [ ] JSDoc is used for public APIs and utilities
- [ ] Comments explain "why" not "what"
- [ ] Outdated comments are removed or updated

### Component Documentation

- [ ] Public components have usage examples
- [ ] Props are documented with descriptions
- [ ] Edge cases and limitations are noted
- [ ] Breaking changes are clearly communicated
- [ ] Storybook stories exist for UI components (if applicable)

---

## Review Checklist Summary

Before approving a PR, ensure:

1. **Functionality**: The code works as intended and handles edge cases
2. **Architecture**: Components are well-structured and follow established patterns
3. **Performance**: No obvious performance issues or memory leaks
4. **Types**: TypeScript is used effectively without escape hatches
5. **Tests**: Appropriate test coverage exists
6. **Accessibility**: The UI is accessible to all users
7. **Security**: No security vulnerabilities are introduced
8. **Style**: Code follows team conventions and is readable
9. **Documentation**: Changes are adequately documented

---

## Customization Notes

This template should be customized for your team:

- Add project-specific patterns and conventions
- Remove sections that don't apply to your stack
- Add links to internal documentation and examples
- Include specific linting rules and configurations
- Reference your component library guidelines