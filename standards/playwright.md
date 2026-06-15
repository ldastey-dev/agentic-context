# Playwright Standards - End-to-End and UI Testing

This document summarises the general rules that agentic AI should follow when working in a Playwright end-to-end testing project, distilled from a project's README and agentic AI rule files (`.devinrules`, `.rules`, `AGENTS.md`, `copilot-instructions.md`, `debug-protocol.md`, and no-unit-test guidance).

---

## 1. For E2E Tests — No Unit Tests

If the Playwright project is exclusively for end-to-end Playwright tests, never create unit tests, utility tests, or tests that validate internal framework logic in isolation. Unit tests are not required for end-to-end testing projects.

---

## 2. Never Skip or Weaken Tests to Fix Failures

- **Never** add `test.skip()` or `test.fixme()` as a resolution to a failing test.
- **Never** weaken assertions (e.g., changing `toEqual` to `toContain`) to make a test pass.
- **Never** add arbitrary `waitForTimeout()` calls. Use Playwright's built-in auto-waiting with `expect` assertions where possible, and if necessary use the proper `waitFor` conditions preferentially over `waitForTimeout()`.
- **Never** increase timeout values arbitrarily.
- If a fix cannot be determined, **stop and report** the failure with details — do not modify the test to make it pass.
- Treat failing tests as potential application bugs until proven otherwise.

---

## 3. Never Fabricate Selectors or Fixes

When debugging, every selector must trace back to a real, verifiable source in the application or existing codebase. Do not:

- Invent selectors by pattern-completion.
- Assume a selector exists because similar ones do.
- Modify a selector "to make it work" without verifying it against the actual application.
- Use arbitrary timeouts not derived from a verified source.

If a selector or pattern cannot be traced, **stop and report** with the search terms used and the closest matches found.

---

## 4. Always Analyse the Codebase Before Acting

Before starting any code task, perform mandatory analysis of the relevant codebase. Verify actual file locations and names — never assume files exist as described in a task.

---

## 5. Reuse Existing Page Objects — Never Duplicate

Before creating any new page object or test, search the existing page objects directory for matches. Extend existing page objects rather than creating duplicates. Only create a new page object if no match genuinely exists.

---

## 6. Adhere to Page Object Model

This rule applies only **if** the project uses Page Object Model. Whether the project uses a Page Object Model is determined by the project's existing codebase and conventions, or if specified in the README. If it is unclear from the README or existing codebase, **check with a human** and add this information to the README for future reference. If the project does not use a Page Object Model, the following rule does not apply.

All UI interactions must go through Page Object classes. Do not put raw locators or page interaction logic directly in test files.

- Use a private `locators` object for all selectors.
- Prefer semantic selectors (`getByRole`, `getByText`, `getByLabel`) over CSS selectors.
- Use stable test-specific attributes (e.g. `data-testid` or similar) when available.
- For tabbed UIs / duplicate-DOM situations, you may where necessary use XPath selectors scoped to a known container ID. Never use positional selectors (`.first()`, `.nth()`) to disambiguate duplicates.

---

## 7. Waiting Strategy: Trust Auto-Waiting, Avoid Manual Waits

Rely on Playwright's built-in auto-waiting. Use explicit `waitFor` conditions when needed. Never use `page.waitForTimeout()` or manual polling loops.

---

## 8. Timeout Configuration

Do not explicitly define the timeout when the project's default is intended. Only specify timeout values when they differ from the configured default.

---

## 9. Test Tagging Conventions

Follow the project's existing test tagging conventions. When adding new tags, ensure they are registered everywhere the project requires (e.g. both the test file and any CI pipeline configuration).

---

## 10. Directory Structure Preservation

Tests should be organised into folders matching the area of functionality. Do not reorganise existing test structure unnecessarily. When adding new directories, ensure they are registered wherever the project requires (e.g. CI pipeline configuration).

---

## 11. TypeScript and Code Quality Standards

- Use strict TypeScript typing — avoid `any`.
- Use modern `async/await` throughout (no `.then()` chains).
- Follow existing code style in the project.
- Include JSDoc documentation for public methods.
- TypeScript compilation must pass (e.g. `npm run type-check`).
- Respect the project's configured tooling — do not run linters or formatters that the project has not set up.

---

## 12. Environment Configuration

- Never hardcode credentials or URLs in test files.
- Supply configuration through environment variables or the project's documented environment setup.
- Derive related configuration values programmatically where the project provides helpers, rather than duplicating them.
- Keep secrets out of source control.

---

## 13. Structured Debug Protocol

When debugging failing tests:

- Debug one test at a time — never batch-debug multiple failures.
- Stop after 2 failed fix attempts on the same test and escalate.

---

## 14. Visual Debugging (Playwright Inspector)

When a user requests visual debugging, use `PWDEBUG=1` to launch the Playwright Inspector. After issuing the command, **pause and wait** for the user to confirm they are done before taking further action.

---

## 15. Test Data and Resource Management

- Always clean up any test data or resources created during a test (e.g. in `afterEach` hooks) to keep environments clean and tests independent.

---

## 16. Scope Boundaries

- Only add tests that correspond to actual required test scenarios — do not add extra, speculative tests.
- Do not add tests to verify helper or framework function implementations (see Rule 1).
- Preserve all existing functionality when modifying or enhancing files — ensure no breaking changes.
