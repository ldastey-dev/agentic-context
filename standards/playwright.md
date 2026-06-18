# Playwright E2E Testing Standards

Coding standards for AI agents working in Playwright end-to-end test repositories. All rules are general best practices derived from real-world codebase conventions, existing rule files, and project knowledge.

---

## 1 · E2E Tests Only — No Unit Tests

This repository is exclusively for end-to-end Playwright tests. Never add unit tests, utility tests, or any non-E2E test types. Do not create tests that validate internal framework logic (helpers, page objects, API wrappers, data generators, framework utilities) in isolation. All tests must exercise the application through the browser or API as a real user or consumer would.

---

## 2 · Critical Test Fix Rules (Non-Negotiable)

- **Never** add `test.skip()` or `test.fixme()` to resolve a failing test.
- **Never** weaken assertions (e.g., changing `toEqual` to `toContain`) to make a test pass.
- **Never** add arbitrary `waitForTimeout()` calls.
- **Never** increase timeout values arbitrarily.
- **Never** catch and ignore errors silently.
- Treat failing tests as potential application bugs until proven otherwise.
- If you cannot determine a fix, **stop and report** the failure with details — do not modify the test to make it pass.

---

## 3 · Always Analyse the Codebase Before Acting

Before starting any code task, perform mandatory analysis of the relevant codebase. Verify actual file locations and names — never assume files exist as described in a task.

---

## 4 · Never Fabricate Selectors or Fixes

When debugging, every selector must trace back to a real, verifiable source in the application or existing codebase. Do not:

- Invent selectors by pattern-completion.
- Assume a selector exists because similar ones do.
- Modify a selector "to make it work" without verifying it against the actual application.
- Use arbitrary timeouts not derived from a verified source.

If a selector or pattern cannot be traced, **stop and report** with the search terms used and the closest matches found.

---

## 5 · Page Object Model (Conditional)

> **Applicability:** This rule applies only **if** the project uses Page Object Model. Whether the project uses a Page Object Model is determined by the project's existing codebase and conventions, or if specified in the README. If it is unclear from the README or existing codebase, **check with a human** and add this information to the README for future reference. If the project does not use a Page Object Model, the following rule does not apply.

All UI interactions must go through Page Object classes. Do not put raw locators or page interaction logic directly in test files.

### 5.1 · Base Class

- Page objects must extend the project's base page class (e.g. `BasePage`).
- Constructor must call the parent constructor.
- The base class typically provides common utilities: click, fill, select, visibility checks, navigation, and wait helpers.

### 5.2 · Structure

- One page object per file, located in a `pages/` directory organised by application area.
- Use `private readonly` fields for all locators (Playwright `Locator` type initialised in the constructor).
- Methods represent user actions or verifications, with proper TypeScript typing and explicit return types.

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

Before creating any new page object, search the existing `pages/` directory for matches. Extend existing page objects rather than creating duplicates. Only create a new page object if no match genuinely exists.

---

## 6 · Selector Strategy

### 6.1 · Simple Single-Instance Pages

Prefer Playwright's built-in semantic locators:

- `getByRole('button', { name: 'Save' })`
- `getByText('Confirm')`
- `getByLabel('Email')`
- `getByTestId('panel-id')` — maps to the project's configured `testIdAttribute` in `playwright.config.ts`.

### 6.2 · Tabbed / Panelled UIs

Applications with tabbed or panelled layouts often render the same element text in multiple panels. For these UIs, XPath scoped to container IDs is **required**:

```typescript
// ✅ Correct — scoped to a specific panel
private readonly saveButton = this.page.locator(
  'xpath=//*[@id="details-panel"]//button[text()="Save"]'
);

// ✅ Correct — distinguish interactive elements from dropdown items
private readonly actionButton = this.page.locator(
  'xpath=//*[@id="panel-id"]//button[text()="Action"][not(@role="menuitem")]'
);

// ❌ Wrong — positional selectors to disambiguate duplicates
private readonly saveButton = this.page.getByRole('button', { name: 'Save' }).first();
private readonly saveButton = this.page.getByRole('button', { name: 'Save' }).nth(1);
```

### 6.3 · Rules

- Never use `.first()`, `.nth()`, or positional selectors to disambiguate duplicates.
- Distinguish interactive elements from dropdown items with `[not(@role="menuitem")]`.
- Prefer text content over CSS classes for resilience.
- Never fabricate selectors by pattern-completion — every selector must trace back to a real, verifiable source in the application.

---

## 7 · Fixture System

### 7.1 · Import Sources

Identify the project's fixture composition files (typically in a `fixtures/` directory). Common patterns:

- A primary composed fixture file that combines all fixture modules.
- Specialised fixture files for authentication, browser config, credentials, URLs, and third-party integrations.

### 7.2 · Rules

- Fixtures provide dependency injection for page objects and configuration.
- Do not create new fixture files without discussion — extend existing ones.
- When a test needs credentials, use fixtures or `process.env` at module scope — never hardcode values.

---

## 8 · Test Structure and Tagging

### 8.1 · File Organisation

```
tests/
  [application]/
    [feature]/
      [testname].spec.ts
```

Organise tests by application area and feature. Check the project's existing directory structure for the canonical list of application directories.

### 8.2 · Test Tagging

Tags are placed as prefixes in the `test.describe` description string:

```typescript
test.describe("@AllTests @smoke @critical Standard Feature Tests", () => {
  // ...
});
```

When adding new tags, ensure they are registered in the CI pipeline configuration. When adding a new directory under `tests/`, ensure it is added to the pipeline's test directory list.

**Never fabricate test tags.** When porting tests from another framework, always transpose the original tags — do not invent new ones.

### 8.3 · Test Steps and Serial Mode

- Use `test.step()` for better reporting of logical steps within a test.
- Use `test.describe.configure({ mode: 'serial' })` for dependent test flows that must run in order.

---

## 9 · Waiting Strategy

### 9.1 · Trust Auto-Waiting

Playwright automatically waits for elements to be actionable before performing actions. Rely on this.

### 9.2 · Explicit Waits (When Needed)

```typescript
// ✅ Wait for visibility
await element.waitFor({ state: "visible" });
await element.waitFor({ state: "hidden" });

// ✅ Wait for network response
await page.waitForResponse(
  (resp) => resp.url().includes("/api/endpoint") && resp.status() === 200,
);

// ✅ Expect with default timeout
await expect(element).toBeVisible();

// ✅ Expect with non-default timeout (only when the default is insufficient)
await expect(element).toBeVisible({ timeout: 15_000 });
```

### 9.3 · Prohibited

```typescript
// ❌ Never use manual waits
await page.waitForTimeout(2000);

// ❌ Never use polling loops as a substitute for Playwright's built-in waits
while (!(await element.isVisible())) {
  await sleep(100);
}
// ✅ Use expect() instead
await expect(element).toBeVisible();
```

> **Exception:** Polling loops are permissible when waiting for conditions that have no Playwright-native wait — e.g. polling an API endpoint until a backend state changes, checking MailCatcher for email delivery, or verifying eventual consistency in async workflows. In these cases, use a bounded loop with a reasonable timeout and a clear failure message.

### 9.4 · Timeout Configuration

- Check the project's `playwright.config.ts` for the configured test timeout and `expect` timeout.
- Do not explicitly specify the default timeout value — it is already the default.
- Only specify timeout values when they differ from the configured default.
- Some suites (e.g. accessibility scans) may have intentionally high timeouts. **Do not change these** without understanding why they exist.

---

## 10 · Resource Locking for Parallel Execution

### 10.1 · Purpose

When multiple parallel workers compete for the same shared resources (e.g. timeslots, accounts, data records), use a resource locking mechanism to prevent race conditions.

### 10.2 · Usage

If the project provides a `ResourceLock` helper (or similar), follow its pattern:

```typescript
const lock = new ResourceLock();
const slot = await lock.acquireSlot("resource_key");
try {
  // Use the acquired resource
} finally {
  await lock.releaseSlot("resource_key");
}
```

### 10.3 · Rules

- Always release locks in a `finally` block (preferred), or in `afterAll`/`afterEach` if the lock was acquired in a hook.
- Ensure enough resource slots exist for the maximum shard/worker count.
- When running with sharding (`SHARD_INDEX` / `SHARD_TOTAL`), slots should be partitioned across shards to prevent cross-shard collisions.

---

## 11 · Test Data Generation

### 11.1 · Use Project Utilities

Check the project's `helpers/` directory for data generation utilities (e.g. `TestDataGenerator`). Use these to generate realistic test data:

```typescript
const forename = await TestDataGenerator.generateCustomerForename();
const surname = await TestDataGenerator.generateCustomerSurname();
const email = await TestDataGenerator.generateFakeEmail(forename, surname);
const mobile = await TestDataGenerator.generateFakeMobileNumber();
const customer = await TestDataGenerator.generateCustomerData();
```

### 11.2 · Rules

- Never hardcode names, emails, or phone numbers in tests.
- Use the project's data generation utilities for complete test data objects.
- Check the configured locale for region-specific formats (phone numbers, postcodes, etc.).

---

## 12 · Test Data Cleanup Pattern

### 12.1 · Correct Pattern

Tests that create data (e.g. bookings, records, users) must clean up after themselves using `afterEach` hooks:

```typescript
const testConfig = process.env.TEST_SITE_IDENTIFIER!;

test.describe("Data Creation Tests", () => {
  let record: TestRecord;

  test.afterEach(async () => {
    if (record?.id) {
      await record.delete();
    }
  });

  test("create record", async ({ page }) => {
    record = new TestRecord(testConfig);
    // ...
  });
});
```

### 12.2 · Critical: Module-Scope Environment Variables

Always read environment variables into module-scoped constants. Never pass `process.env.*` inline to constructors — if the env var is `undefined`, cleanup methods may silently skip without throwing, leaving orphan data that causes cascading test failures.

```typescript
// ✅ Correct — module scope
const testConfig = process.env.TEST_SITE_IDENTIFIER!;

// ❌ Wrong — inline, risks undefined
new TestRecord(process.env.TEST_SITE_IDENTIFIER);
```

---

## 13 · Environment Configuration

### 13.1 · URL Configuration

- Configure the base URL in `.env` or environment variables.
- If the project derives API URLs from the base URL, use the provided helper functions — do not hardcode API URLs.

### 13.2 · Credentials

- Credentials should come from CI/CD variable groups or secret stores.
- If the project provides an environment generation script, use it to populate `.env` from CI variables.
- Never hardcode credentials or URLs in test files.
- Keep secrets out of source control.

### 13.3 · Required Environment Variables

Check the project's README or global setup file for the list of required environment variables. Common patterns include a base URL, API keys, admin credentials, and test provider/tenant identifiers.

---

## 14 · API Testing

### 14.1 · Structure

- API helpers should live in a dedicated directory (e.g. `apiHelpers/`).
- JSON schemas for response validation should live in a `schemas/` directory.

### 14.2 · Rules

- Use Playwright's `request` fixture or `APIRequestContext`.
- If the project provides helper classes for common operations (e.g. data lifecycle management), use them.
- Validate response schemas using a JSON schema validator (e.g. Ajv).
- Tag API tests with appropriate tags (e.g. `@API`).

---

## 15 · TypeScript Standards

### 15.1 · ESLint Rules (Enforced)

Check the project's ESLint configuration. Common enforced rules include:

| Rule                                               | Level   |
| -------------------------------------------------- | ------- |
| `@typescript-eslint/no-unused-vars`                | `error` |
| `@typescript-eslint/no-explicit-any`               | `warn`  |
| `@typescript-eslint/explicit-function-return-type` | `error` |
| `prefer-const`                                     | `error` |
| `no-var`                                           | `error` |

### 15.2 · Conventions

- Strict typing — avoid `any`.
- Explicit function return types on all functions (ESLint enforced).
- `prefer-const` and `no-var` enforced.
- Use `async/await` consistently — no `.then()` chains.
- Prefer `type` over `interface` for new type definitions.
- Export types for reusable structures.
- Always run the project's formatting command before creating commits.
- Always check for unused variables and imports before committing.
- TypeScript compilation must pass.
- Respect the project's configured tooling — do not run linters or formatters that the project has not set up.

---

## 16 · Naming Conventions

| Artefact          | Convention                              | Example                                |
| ----------------- | --------------------------------------- | -------------------------------------- |
| Page Object class | `[PageName]Page`                        | `LoginPage`, `DashboardPage`           |
| Page Object file  | `[pagename].page.ts`                    | `login.page.ts`, `dashboard.page.ts`   |
| Test file         | `[feature].spec.ts`                     | `checkout.spec.ts`                     |
| Helper file       | `[purpose]Helper.ts` or `[purpose].ts`  | `envHelpers.ts`, `dataUtils.ts`        |
| Fixture file      | `[context]Fixtures.ts`                  | `authFixtures.ts`, `configFixtures.ts` |
| API helper        | `[service]Api.ts` or `[service]Auth.ts` | `usersApi.ts`, `loginAuth.ts`          |

---

## 17 · Global Setup and Teardown

### 17.1 · Setup (`tests/global.setup.ts`)

- Creates dynamic test data or resources for test isolation (e.g. temporary accounts, tenants, or environments).
- Outputs dynamic environment variables for cross-shard consumption.

### 17.2 · Teardown (`tests/global.teardown.ts`)

- Deletes dynamic resources created during setup.

### 17.3 · Configuration

- Setup/teardown are configured as Playwright projects with dependency chains.
- Can be skipped via environment variables (e.g. `SKIP_GLOBAL_SETUP=true`, `SKIP_GLOBAL_TEARDOWN=true`).
- Outputs to a JSON file for cross-shard variable passing.

---

## 18 · Playwright Configuration

Review the project's `playwright.config.ts` for key settings. Common configuration includes:

| Setting            | Typical Values                    |
| ------------------ | --------------------------------- |
| `timeout`          | Project-specific (check config)   |
| `testIdAttribute`  | Project-specific (e.g. `data-at`) |
| `trace`            | `retain-on-failure`               |
| `screenshot`       | `on-first-failure`                |
| `locale`           | Project-specific                  |
| `timezoneId`       | Project-specific                  |
| `retries`          | `1` on CI, `0` locally            |
| `fullyParallel`    | `true`                            |
| Reporter (sharded) | `blob`                            |
| Reporter (local)   | `html` + `json`                   |

---

## 19 · CI/CD Pipeline

- Check the project's CI/CD configuration for pipeline structure and sharding support.
- Use blob reports when in shard mode, HTML + JSON locally.
- Test filtering via `--grep` with tag parameters.
- Pipeline templates typically live in a `templates/` directory.

---

## 20 · Accessibility Testing

- Dedicated suites should live in a separate directory (e.g. `tests/accessibility/`).
- Use axe-core for WCAG compliance scanning.
- Accessibility suites may have intentionally high timeouts for full axe sweeps — **do not change these** without understanding why.
- Tag with `@Accessibility`.

---

## 21 · MCP Integration

MCP (Model Context Protocol) is used for AI-assisted test creation and maintenance.

### 21.1 · Workflow

1. **Identify application** — determine which application area the test belongs to.
2. **Search existing tests** — check for existing coverage before creating new tests.
3. **Find page objects** — locate and reuse existing page objects.
4. **Check fixtures** — identify appropriate fixtures for the test context.
5. **Generate** — create the test following all conventions in this document.

### 21.2 · Rules

- Before creating any new test, check existing tests by application area.
- Reuse existing page objects — **never** create duplicates.
- Follow the pattern recognition workflow above.

---

## 22 · Commit and PR Standards

- Always run the project's formatting command before creating commits.
- Formatting and casing changes must be in separate commits from feature changes.
- When committing only package updates, use conventional commit format: `chore(deps): updating package x from version y to z`.
- If a work item/ticket number is provided, append it using the project's linking convention.

---

## 23 · Debugging Protocol

### 23.1 · Structured Debugging

- Debug one test at a time — never batch-debug multiple failures.
- Stop after 2 failed fix attempts on the same test and escalate.
- Every selector must trace back to a real, verifiable source — do not fabricate selectors by pattern-completion.

### 23.2 · Visual Debugging (Playwright Inspector)

When stepping through a test visually:

```bash
PWDEBUG=1 npx playwright test tests/path/to/your.spec.ts
```

This opens the Playwright Inspector for interactive step-through with live locator inspection. After issuing the command, **pause and wait** for the user to confirm they are done before taking further action.

---

## 24 · Scope Boundaries

- Only add tests that correspond to actual required test scenarios — do not add extra, speculative tests.
- Do not add tests to verify helper or framework function implementations (see Rule 1).
- Preserve all existing functionality when modifying or enhancing files — ensure no breaking changes.
- Always clean up any test data or resources created during a test (e.g. in `afterEach` hooks) to keep environments clean and tests independent.

---

## 25 · Non-Negotiables

| Rule | Detail |
| ---- | ------ |
| No unit tests | This repository is exclusively for E2E tests. No exceptions. |
| No `test.skip()` or `test.fixme()` | Never skip tests to hide failures. |
| No weakened assertions | Never change `toEqual` to `toContain` to pass a failing test. |
| No `waitForTimeout()` | Use Playwright's built-in auto-waiting and explicit `waitFor` conditions. |
| No fabricated selectors | Every selector must trace back to a real, verifiable source. |
| No positional selectors | Never use `.first()`, `.nth()` to disambiguate duplicates — scope to a container. |
| No hardcoded credentials | Use fixtures, environment variables, or CI/CD secret stores. |
| No duplicate page objects | Search existing `pages/` directory before creating anything new (if POM is used). |
| No inline `process.env` in constructors | Read environment variables into module-scoped constants. |
| Always clean up test data | Use `afterEach` hooks to prevent orphan data causing cascading failures. |

---

## 26 · Decision Checklist

Before opening a PR, confirm every item:

- [ ] If POM is used: all UI interactions go through Page Object classes (no raw locators in test files)
- [ ] If POM is used: new page objects extend the base class and use `private readonly` locators
- [ ] If POM is used: no duplicate page objects — existing ones reused or extended
- [ ] Test tags match existing conventions and are registered in CI pipeline configuration
- [ ] Selectors are scoped to container IDs for tabbed/panelled UIs
- [ ] No `waitForTimeout()`, no polling loops substituting Playwright waits, no arbitrary timeout increases
- [ ] Environment variables read into module-scoped constants (not inline)
- [ ] Test data cleanup in `afterEach` for any test that creates data
- [ ] Project formatting command executed before commit
- [ ] No unused variables or imports
- [ ] TypeScript compilation passes
- [ ] Test file placed in correct directory per project conventions