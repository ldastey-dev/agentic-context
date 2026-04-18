# React Standards — Components, Hooks & Testing

Every React application must follow established component patterns, use hooks correctly, and treat accessibility, performance, and type safety as first-class concerns. Code must be readable, composable, and aligned with the team's conventions at all times.

---

## 1 · Component Architecture

### 1.1 · Component Structure

- Every component must follow the Single Responsibility Principle.
- Component files must be appropriately sized — consider splitting if a file exceeds 200-300 lines.
- Presentational and container components must be properly separated.
- Custom hooks must extract reusable logic from components.
- Component hierarchy must be logical and must never introduce unnecessary nesting.

### 1.2 · Naming Conventions

- Component names must use PascalCase and be descriptive.
- Event handlers must follow `handle[Event]` naming (e.g., `handleClick`, `handleSubmit`).
- Props passed to children must follow `on[Event]` naming (e.g., `onClick`, `onSubmit`).
- Boolean props must use `is`, `has`, or `should` prefixes (e.g., `isLoading`, `hasError`).
- Custom hooks must always start with the `use` prefix.

### 1.3 · Props

- Props must be properly typed with TypeScript interfaces.
- Default props must be defined where appropriate.
- Props destructuring must be used for cleaner code.
- Spread operators on props must be used sparingly and intentionally.
- Callback props must be memoised when passed to child components.

---

## 2 · State Management

### 2.1 · Local State

- State must always be kept as close to where it is needed as possible.
- `useState` must be used for simple state.
- `useReducer` must be used for complex state logic.
- State updates must always be immutable.
- Derived state must be calculated during render — never stored separately.

### 2.2 · Global State

- Global state must contain only truly global data.
- State shape must be normalised where appropriate.
- Selectors must be used to access state slices.
- State updates must follow predictable patterns.
- Async operations must be handled consistently.

### 2.3 · Side Effects

- `useEffect` dependencies must always be correctly specified.
- Cleanup functions must be provided where needed.
- Effects must not be overused — always consider alternatives first.
- Data fetching must follow established patterns.
- Race conditions must always be handled in async effects.

---

## 3 · Performance

### 3.1 · Rendering Optimisation

- `React.memo` must be used for expensive components that re-render with unchanged props.
- `useMemo` must be used for expensive calculations.
- `useCallback` must be used for callbacks passed to optimised children.
- Lists must always include stable, unique `key` props.
- Large lists must use virtualisation when appropriate.

### 3.2 · Bundle Size

- Lazy loading must be used for route-level code splitting.
- Dynamic imports must be used for heavy dependencies.
- Tree-shaking friendly imports must always be used (named imports).
- Image assets must be optimised.
- Unnecessary dependencies must always be avoided.

### 3.3 · Network

- API calls must be deduplicated where appropriate.
- Caching strategies must be implemented.
- Loading states must be handled gracefully.
- Pagination or infinite scroll must be used for large data sets.
- Optimistic updates must be used where appropriate.

---

## 4 · TypeScript Usage

### 4.1 · Type Safety

- The `any` type must never be used — use `unknown` if the type is truly unknown.
- Type assertions must be minimised and justified with a comment.
- Generic types must be used for reusable components and functions.
- Union types must be preferred over enums where appropriate.
- Nullable types must always be handled explicitly.

### 4.2 · Component Types

- Props interfaces must be defined for all components.
- Event handler types must be correctly specified.
- Ref types must be properly defined.
- Children types must be explicit when needed.
- Generic components must have proper type constraints.

### 4.3 · Best Practices

- Types must be exported alongside components when needed externally.
- Utility types (`Partial`, `Pick`, `Omit`) must be used effectively.
- Type inference must be leveraged where types are obvious.
- Discriminated unions must be used for complex state.
- Type guards must be used for runtime type checking.

---

## 5 · Testing

### 5.1 · Unit Tests

- Components must have appropriate test coverage.
- Tests must focus on behaviour, not implementation details.
- Edge cases and error states must always be tested.
- Mocks must be used appropriately and never excessively.
- Tests must be readable and serve as documentation.

### 5.2 · Testing Library Best Practices

- Queries must follow priority: `getByRole` > `getByLabelText` > `getByText`.
- `userEvent` must always be preferred over `fireEvent`.
- Async operations must use `waitFor` or `findBy` queries.
- Tests must avoid querying by test IDs when better options exist.
- Accessibility queries must always be preferred.

### 5.3 · Integration Tests

- Critical user flows must have integration tests.
- API mocking must be consistent and realistic.
- Tests must be independent and able to run in isolation.
- Setup and teardown must always be handled properly.
- Tests must run reliably without flakiness.

---

## 6 · Accessibility

### 6.1 · Semantic HTML

- Appropriate HTML elements must always be used (`button`, `nav`, `main`, etc.).
- Heading hierarchy must be logical (`h1` > `h2` > `h3`).
- Lists must use proper `ul`/`ol`/`li` elements.
- Forms must always have associated labels.
- Tables must only be used for tabular data.

### 6.2 · ARIA

- ARIA attributes must only be used when semantic HTML is insufficient.
- `aria-label` and `aria-describedby` must be used appropriately.
- Live regions must announce dynamic content.
- Focus management must be handled for modals and dynamic content.
- `aria-hidden` must be used correctly.

### 6.3 · Keyboard Navigation

- All interactive elements must be keyboard accessible.
- Focus order must be logical.
- Focus indicators must always be visible.
- Keyboard shortcuts must never conflict with assistive technology.
- Skip links must be provided for main content.

---

## 7 · Security

### 7.1 · Input Handling

- User input must always be validated on both client and server.
- `dangerouslySetInnerHTML` must never be used unless the content is sanitised.
- URL parameters must always be validated before use.
- File uploads must be validated and restricted.

### 7.2 · Data Protection

- Sensitive data must never be stored in local storage.
- API keys must never be exposed in client-side code.
- Authentication tokens must be handled securely.
- CORS must be properly configured.
- HTTPS must be enforced for all requests.

### 7.3 · Dependencies

- Dependencies must only come from trusted sources.
- Dependencies must be regularly updated.
- Security vulnerabilities must be addressed promptly.
- Lock files must always be committed.
- Unused dependencies must be removed.

---

## 8 · Code Style

### 8.1 · Formatting

- Code must follow consistent formatting (Prettier/ESLint).
- Import statements must be organised (external, internal, relative).
- Unused imports and variables must never exist.
- Quote style (single/double) must be consistent throughout the codebase.
- Semicolon usage must be consistent throughout the codebase.

### 8.2 · Code Organisation

- Related code must always be grouped together.
- Magic numbers must be extracted to named constants.
- Complex conditions must be extracted to named variables.
- Early returns must be used to improve readability.
- Functions must always be kept small and focused.

### 8.3 · React-Specific

- JSX must be properly formatted and indented.
- Conditional rendering must be clean and readable.
- Fragments must be used instead of unnecessary wrapper divs.
- Event handlers must not be inline unless very simple.
- Component composition must always be preferred over prop drilling.

---

## 9 · Error Handling

### 9.1 · Error Boundaries

- Error boundaries must be implemented at appropriate levels.
- Fallback UIs must be user-friendly.
- Errors must always be logged for debugging.
- Error recovery options must be provided where possible.

### 9.2 · API Errors

- Error responses must be handled gracefully.
- User-friendly error messages must always be displayed.
- Retry logic must be implemented where appropriate.
- Network failures must always be handled.
- Loading and error states must be mutually exclusive.

### 9.3 · Form Validation

- Validation messages must be clear and helpful.
- Validation must occur on blur and submit.
- Server-side validation errors must be displayed.
- Form state must always be preserved on validation failure.
- Success feedback must be provided.

---

## 10 · Documentation

### 10.1 · Code Comments

- Complex logic must have explanatory comments.
- TODO comments must always include context or ticket references.
- JSDoc must be used for public APIs and utilities.
- Comments must explain "why", never "what".
- Outdated comments must be removed or updated.

### 10.2 · Component Documentation

- Public components must have usage examples.
- Props must be documented with descriptions.
- Edge cases and limitations must be noted.
- Breaking changes must always be clearly communicated.
- Storybook stories must exist for UI components where applicable.

---

## Non-Negotiables

- The `any` type must never be used — always use `unknown` or a proper type definition.
- `dangerouslySetInnerHTML` must never be used with unsanitised content.
- `useEffect` dependencies must always be correctly specified — never suppress the exhaustive-deps lint rule.
- API keys and secrets must never appear in client-side code.
- All interactive elements must be keyboard accessible — no exceptions.
- Tests must focus on behaviour, never on implementation details.
- State must never be duplicated — derived values must be calculated during render.
- Sensitive data must never be stored in local storage or session storage.

---

## Decision Checklist

Before merging any change, verify each item:

- [ ] Components follow the Single Responsibility Principle and are appropriately sized
- [ ] Props are fully typed with TypeScript interfaces — no `any` usage
- [ ] State is kept close to where it is needed and updates are immutable
- [ ] `useEffect` dependencies are correct and cleanup functions are provided
- [ ] `React.memo`, `useMemo`, and `useCallback` are used where justified
- [ ] Lists have stable, unique `key` props and large lists use virtualisation
- [ ] Testing Library queries follow the priority hierarchy (`getByRole` first)
- [ ] Error boundaries are in place and fallback UIs are user-friendly
- [ ] Semantic HTML is used and all interactive elements are keyboard accessible
- [ ] ARIA attributes are correct and only used when semantic HTML is insufficient
- [ ] No sensitive data is exposed in client-side code or local storage
- [ ] Imports are organised, unused code is removed, and formatting is consistent
- [ ] Form validation is thorough with clear messages on blur and submit
- [ ] Bundle size impact is considered — lazy loading and tree-shaking are applied
