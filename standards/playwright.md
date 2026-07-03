# Playwright Standards — End-to-End and UI Testing

Prescriptive rules for agents working in a Playwright end-to-end (E2E) and UI
testing project. This standard governs how Playwright suites are written,
structured, and debugged. For shared testing rules that apply across all
frameworks — the Test Trophy Model, behavioural testing, mocking at boundaries,
test isolation, and coverage gates — see `.context/standards/testing.md`; this
document does not restate them.

Apply these rules in addition to, not instead of, the project's own
conventions. Where the project's existing codebase, README, or configuration
already documents a convention, that convention wins; verify it before acting.

---

## 1 · E2E Tests Only — No Unit Tests

If the Playwright project is exclusively for end-to-end tests, never create unit
tests, utility tests, or tests that validate internal framework logic (helpers,
page objects, API wrappers, data generators, framework utilities) in isolation.
All tests must exercise the application through the browser or API as a real
user or consumer would. Unit tests are not required for E2E testing projects.

---

## 2 · Never Skip or Weaken Tests to Fix Failures

- **Never** add `test.skip()` or `test.fixme()` as a resolution to a failing test.
- **Never** weaken assertions (e.g. changing `toEqual` to `toContain`) to make a test pass.
- **Never** add arbitrary `waitForTimeout()` calls. Use Playwright's built-in auto-waiting with `expect` assertions, and where a wait is genuinely required use the proper `waitFor` conditions in preference to `waitForTimeout()`.
- **Never** increase timeout values arbitrarily.
- **Never** catch and ignore errors silently.
- If a fix cannot be determined, **stop and report** the failure with details — do not modify the test to make it pass.
- Treat failing tests as potential application bugs until proven otherwise.

---

## 3 · Never Fabricate Selectors or Fixes

When debugging, every selector must trace back to a real, verifiable source in
the application or existing codebase. Do not:

- Invent selectors by pattern-completion.
- Assume a selector exists because similar ones do.
- Modify a selector "to make it work" without verifying it against the actual application.
- Use arbitrary timeouts not derived from a verified source.

If a selector or pattern cannot be traced, **stop and report** with the search
terms used and the closest matches found.

---

## 4 · Always Analyse the Codebase Before Acting

Before starting any code task, perform mandatory analysis of the relevant
codebase. Verify actual file locations and names — never assume files exist as
described in a task.

---

## 5 · Adhere to the Page Object Model (Conditional)

> **Applicability:** This rule applies only **if** the project uses the Page
> Object Model. Whether it does is determined by the project's existing codebase
> and conventions, or if specified in the README. If it is unclear from the
> README or existing codebase, **check with a human** and record the answer in
> the README for future reference. If the project does not use a Page Object
> Model, this rule does not apply.

All UI interactions must go through Page Object classes. Do not put raw locators
or page interaction logic directly in test files.

### 5.1 · Base Class

- Page objects must extend the project's base page class (e.g. `BasePage`).
- The constructor must call the parent constructor.
- The base class typically provides common utilities: click, fill, select, visibility checks, navigation, and wait helpers.

### 5.2 · Structure

- One page object per file, located in a `pages/` directory organised by application area.
- Use `private readonly` fields for all locators (Playwright `Locator` type, initialised in the constructor).
- Methods represent user actions or verifications, with strict TypeScript typing and explicit return types.

### 5.3 · Example Pattern

```typescript
import { BasePage } from "@pages/base";
import { type Locator, type Page } from "@playwright/test";

export class ExamplePage extends BasePage {
  private readonly submitButton: Locator;
  private readonly nameField: Locator;

  constructor(page: Page) {
    super(page, "Example Page", "/example");
    this.submitButton = page.getByRole("button", { name: "Submit" });
    this.nameField = page.getByLabel("Name");
  }

  async fillName(name: string): Promise<void> {
    await this.nameField.fill(name);
  }

  async submit(): Promise<void> {
    await this.submitButton.click();
  }
}
```

### 5.4 · Reuse — Never Duplicate

Before creating any new page object or test, search the existing `pages/`
directory for matches. Extend existing page objects rather than creating
duplicates. Only create a new page object if no match genuinely exists.

---

## 6 · Selector Strategy

Prefer Playwright's built-in semantic locators in this order of preference:

- `getByRole('button', { name: 'Save' })`
- `getByLabel('Email')`
- `getByText('Confirm')`
- `getByTestId('panel-id')` — maps to the project's configured `testIdAttribute` in `playwright.config.ts`.

Use stable, test-specific attributes (e.g. `data-testid` or the project's
configured `testIdAttribute`) when available. Prefer text content over CSS
classes for resilience.

### 6.1 · Rules

- Never use `.first()`, `.nth()`, or other positional selectors to disambiguate duplicates.
- Never fabricate selectors by pattern-completion — every selector must trace back to a real, verifiable source in the application.

### 6.2 · Exception — Tabbed or Panelled UIs

Role-, label-, and text-based locators are always the first choice. As an
**exception**, applications with tabbed or panelled layouts often render the
same element text in multiple panels simultaneously. Where a semantic locator
cannot disambiguate these duplicates, scope an XPath selector to a known,
stable container ID rather than resorting to positional selectors:

```typescript
// Exception — scoped to a specific panel by its stable container ID
private readonly saveButton = this.page.locator(
  'xpath=//*[@id="details-panel"]//button[text()="Save"]'
);

// Distinguish interactive elements from dropdown items
private readonly actionButton = this.page.locator(
  'xpath=//*[@id="panel-id"]//button[text()="Action"][not(@role="menuitem")]'
);

// Wrong — positional selectors to disambiguate duplicates
private readonly saveButtonWrong = this.page.getByRole('button', { name: 'Save' }).first();
```

Only use this exception when a semantic locator genuinely cannot resolve the
duplication, and always scope to a stable container ID — never a positional index.

---

## 7 · Fixtures for Dependency Injection

Use Playwright fixtures to inject page objects, configuration, and shared setup
into tests rather than constructing them inline.

- Identify the project's fixture composition files (typically in a `fixtures/` directory): a primary composed fixture that combines all fixture modules, plus specialised fixtures for authentication, browser configuration, credentials, and URLs.
- Fixtures provide dependency injection for page objects and configuration.
- Do not create new fixture files without discussion — extend existing ones.
- When a test needs credentials, use fixtures or `process.env` at module scope — never hardcode values.

---

## 8 · Test Structure, Steps, and Tagging

### 8.1 · Directory Structure

Organise tests into folders matching the area of functionality:

```
tests/
  [application]/
    [feature]/
      [testname].spec.ts
```

Do not reorganise existing test structure unnecessarily. When adding a new
directory, register it wherever the project requires (e.g. the CI pipeline's
test directory list).

### 8.2 · Test Tagging

Follow the project's existing tagging conventions. Tags are commonly placed as
prefixes in the `test.describe` description string:

```typescript
test.describe("@smoke @critical Standard Feature Tests", () => {
  // ...
});
```

When adding new tags, ensure they are registered everywhere the project
requires (e.g. both the test file and any CI pipeline configuration). **Never
fabricate test tags.** When porting tests from another framework, transpose the
original tags — do not invent new ones.

### 8.3 · Test Steps and Serial Mode

- Use `test.step()` to group logical steps within a test for clearer reporting and failure attribution.
- Use `test.describe.configure({ mode: 'serial' })` for dependent test flows that must run in order.

---

## 9 · Waiting Strategy: Trust Auto-Waiting, Avoid Manual Waits

### 9.1 · Trust Auto-Waiting

Playwright automatically waits for elements to be actionable before performing
actions. Rely on this built-in auto-waiting and on `expect` assertions.

### 9.2 · Explicit Waits (When Needed)

```typescript
// Wait for a state change
await element.waitFor({ state: "visible" });
await element.waitFor({ state: "hidden" });

// Wait for a network response
await page.waitForResponse(
  (resp) => resp.url().includes("/api/endpoint") && resp.status() === 200,
);

// Expect with the configured default timeout
await expect(element).toBeVisible();

// Expect with a non-default timeout (only when the default is insufficient)
await expect(element).toBeVisible({ timeout: 15_000 });
```

### 9.3 · Prohibited

```typescript
// Never use manual waits
await page.waitForTimeout(2000);

// Never use polling loops as a substitute for Playwright's built-in waits
// Use expect() instead:
await expect(element).toBeVisible();
```

> **Exception:** Bounded polling loops are permissible only when waiting for a
> condition that has no Playwright-native wait — e.g. polling an API endpoint
> until a backend state changes, or verifying eventual consistency in an async
> workflow. Use a bounded loop with a reasonable timeout and a clear failure
> message; never poll as a substitute for auto-waiting on the DOM.

### 9.4 · Timeout Configuration

- Check the project's `playwright.config.ts` for the configured test `timeout` and `expect` timeout.
- Do not explicitly specify the default timeout value — it is already the default.
- Only specify timeout values when they differ from the configured default.
- Some suites (e.g. accessibility scans) may have intentionally high timeouts. **Do not change these** without understanding why they exist.

---

## 10 · Parallelism and Sharding

- Enable `fullyParallel` so independent tests run concurrently; keep tests independent so parallel execution is safe (no shared mutable state, no ordering assumptions).
- Use `test.describe.configure({ mode: 'serial' })` only for genuinely dependent flows.
- When running with sharding (`--shard=<index>/<total>`), partition any shared test resources across shards to prevent cross-shard collisions, and generate blob reports per shard for later merging.
- Where multiple parallel workers compete for the same shared resource (timeslots, accounts, data records), use the project's resource-locking helper if one exists, and always release the resource in a `finally` block. Ensure enough resource slots exist for the maximum worker or shard count.

---

## 11 · Test Data and Resource Management

- Use the project's data generation utilities (e.g. a `TestDataGenerator` in the `helpers/` directory) to produce realistic test data. Never hardcode names, emails, or phone numbers in tests.
- Check the configured locale for region-specific formats (phone numbers, postcodes, etc.).
- Tests that create data (bookings, records, users) must clean up after themselves — typically in an `afterEach` hook — to keep environments clean and tests independent.
- Read environment variables into module-scoped constants and validate them at load before use. Never pass `process.env.*` inline to constructors: an unset variable is `undefined` at runtime, so cleanup may silently skip, leaving orphan data that causes cascading failures. A non-null assertion (`!`) is compile-time only and does not guard against this — validate explicitly and fail fast.

```typescript
// Correct — read once at module scope and validate at load.
// The `!` non-null assertion is compile-time only and provides no runtime
// guard, so validate explicitly and fail fast if the variable is unset.
const testTenantId = process.env.TEST_TENANT_ID;
if (!testTenantId) {
  throw new Error("TEST_TENANT_ID must be set before running data-creation tests");
}

test.describe("Data Creation Tests", () => {
  let record: TestRecord;

  test.afterEach(async () => {
    if (record?.id) {
      await record.delete();
    }
  });

  test("create record", async () => {
    record = new TestRecord(testTenantId);
    // ...
  });
});

// Wrong — inline read with no validation; if undefined, cleanup may silently
// skip and leave orphan data.
new TestRecord(process.env.TEST_TENANT_ID);
```

---

## 12 · Environment Configuration

- Never hardcode credentials or URLs in test files.
- Configure the base URL via `.env` or environment variables. If the project derives API URLs from the base URL, use the provided helper functions — do not hardcode them.
- Credentials must come from CI/CD variable groups or secret stores. If the project provides an environment generation script, use it to populate `.env` from CI variables.
- Keep secrets out of source control.
- Check the project's README or global setup file for the list of required environment variables (commonly a base URL, API keys, admin credentials, and tenant identifiers).

---

## 13 · API Testing

- Place API helpers in a dedicated directory (e.g. `apiHelpers/`) and JSON response schemas in a `schemas/` directory.
- Use Playwright's `request` fixture or `APIRequestContext`.
- Where the project provides helper classes for common operations (e.g. data lifecycle management), use them.
- Validate response bodies against JSON schemas using a schema validator (e.g. Ajv).
- Tag API tests with the project's API tag (e.g. `@API`).

---

## 14 · Global Setup and Teardown

- **Setup** (e.g. `tests/global.setup.ts`) creates dynamic test data or resources for test isolation (temporary accounts, tenants, or environments) and outputs any dynamic environment variables for cross-shard consumption.
- **Teardown** (e.g. `tests/global.teardown.ts`) deletes the dynamic resources created during setup.
- Configure setup and teardown as Playwright projects with dependency chains so they run in the correct order.
- Allow setup and teardown to be skipped via environment variables (e.g. `SKIP_GLOBAL_SETUP`, `SKIP_GLOBAL_TEARDOWN`) for local iteration.

---

## 15 · TypeScript and Code Quality Standards

- Use strict TypeScript typing — avoid `any`.
- Provide explicit function return types on all functions.
- Use modern `async/await` throughout (no `.then()` chains).
- Prefer `const`; never use `var`.
- Follow the existing code style in the project and include JSDoc documentation for public methods.
- Export types for reusable structures.
- TypeScript compilation must pass (e.g. `npm run type-check`), and there must be no unused variables or imports.
- Run the project's formatting command before committing.
- Respect the project's configured tooling — do not run linters or formatters that the project has not set up.

---

## 16 · Playwright Configuration Defaults

Review the project's `playwright.config.ts` before relying on any default.
Where the project has no strong reason to differ, prefer these defaults:

| Setting            | Recommended default               |
| ------------------ | --------------------------------- |
| `timeout`          | Project-specific (check config)   |
| `expect.timeout`   | Project-specific (check config)   |
| `testIdAttribute`  | Project-specific (e.g. `data-testid`) |
| `trace`            | `retain-on-failure`               |
| `screenshot`       | `only-on-failure`                 |
| `retries`          | `1` on CI, `0` locally            |
| `fullyParallel`    | `true`                            |
| Reporter (sharded) | `blob`                            |
| Reporter (local)   | `html` + `json`                   |

Traces, screenshots, and retries exist to make failures diagnosable and to
absorb genuine flakiness in CI — configure them once in the config, not
per-test.

---

## 17 · CI/CD Integration

- Check the project's CI/CD configuration for pipeline structure and sharding support before changing it.
- Use blob reports in shard mode and HTML + JSON reports locally.
- Filter tests via `--grep` with tag parameters; register new tags and new test directories wherever the pipeline requires.
- For shared testing gates that apply beyond Playwright, see `.context/standards/testing.md` and `.context/standards/ci-cd.md`.

---

## 18 · Accessibility Testing

- Keep dedicated accessibility suites in a separate directory (e.g. `tests/accessibility/`).
- Use axe-core (via `@axe-core/playwright`) for WCAG compliance scanning, and tag these tests (e.g. `@Accessibility`).
- Accessibility suites may have intentionally high timeouts for full axe sweeps — **do not change these** without understanding why.
- For the underlying WCAG requirements, see `.context/standards/accessibility.md`.

---

## 19 · Debugging Protocol

### 19.1 · Structured Debugging

- Debug one test at a time — never batch-debug multiple failures.
- Stop after 2 failed fix attempts on the same test and escalate.
- Every selector must trace back to a real, verifiable source — do not fabricate selectors by pattern-completion.

### 19.2 · Visual Debugging (Playwright Inspector)

When a user requests visual debugging, launch the Playwright Inspector for
interactive step-through with live locator inspection:

```bash
PWDEBUG=1 npx playwright test tests/path/to/your.spec.ts
```

After issuing the command, **pause and wait** for the user to confirm they are
done before taking further action.

---

## 20 · Scope Boundaries

- Only add tests that correspond to actual required test scenarios — do not add extra, speculative tests.
- Do not add tests to verify helper or framework function implementations (see Section 1).
- Preserve all existing functionality when modifying or enhancing files — ensure no breaking changes.

---

## 21 · Non-Negotiables

| Rule | Detail |
| ---- | ------ |
| No unit tests | E2E-only projects test through the browser or API, never internal logic in isolation. |
| No `test.skip()` or `test.fixme()` | Never skip tests to hide failures. |
| No weakened assertions | Never change `toEqual` to `toContain` to pass a failing test. |
| No `waitForTimeout()` | Use Playwright's built-in auto-waiting and explicit `waitFor` conditions. |
| No fabricated selectors | Every selector must trace back to a real, verifiable source. |
| No positional selectors | Never use `.first()` or `.nth()` to disambiguate duplicates — scope to a stable container ID. |
| No hardcoded credentials or URLs | Use fixtures, environment variables, or CI/CD secret stores. |
| No duplicate page objects | Search the existing `pages/` directory before creating anything new (if the Page Object Model is used). |
| No inline `process.env` in constructors | Read environment variables into module-scoped constants first. |
| Always clean up test data | Use `afterEach` (or teardown) hooks to prevent orphan data causing cascading failures. |
| Stop and report | Escalate after 2 failed fix attempts on one test; never mutate a test to force a pass. |

---

## 22 · Decision Checklist

Before opening a PR, confirm every item:

- [ ] If the Page Object Model is used: all UI interactions go through Page Object classes (no raw locators in test files)
- [ ] If the Page Object Model is used: new page objects extend the base class and use `private readonly` locators
- [ ] If the Page Object Model is used: no duplicate page objects — existing ones reused or extended
- [ ] Selectors prefer `getByRole` / `getByLabel` / `getByText`; XPath-to-container used only as the tabbed/panelled-UI exception
- [ ] Test tags match existing conventions and are registered in the CI pipeline configuration
- [ ] No `waitForTimeout()`, no polling loops substituting Playwright waits, no arbitrary timeout increases
- [ ] Environment variables read into module-scoped constants (not inline)
- [ ] Test data cleanup in `afterEach` (or teardown) for any test that creates data
- [ ] `trace`, `screenshot`, and `retries` configured in `playwright.config.ts`, not per-test
- [ ] Project formatting command executed and TypeScript compilation passes, with no unused variables or imports
- [ ] Test file placed in the correct directory per project conventions
