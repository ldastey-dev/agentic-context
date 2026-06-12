# ResDiary-QAPlaywright Standards — Playwright E2E Testing

Coding standards for AI agents working in the [ResDiary-QAPlaywright](https://github.com/ResDiary/ResDiary-QAPlaywright) repository. All rules are derived from the actual codebase conventions, existing rule files, and project knowledge.

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

## 3 · Page Object Model (Mandatory)

All UI interactions must go through Page Object classes. Do not put raw locators or page interaction logic directly in test files.

### 3.1 · Base Class

- Page objects must extend `BasePage` from `pages/base/BasePage.ts`.
- Constructor must call `super(page)` — `pageTitle` and `pageUrl` are optional.
- `BasePage` provides common utilities: `clickElement()`, `fillText()`, `selectDropdown()`, `isElementVisible()`, `getElementText()`, `waitForElementToBeStable()`, `navigateTo()`, `waitForPageLoad()`.

### 3.2 · Structure

- One page object per file, located at `pages/[application]/[pagename].page.ts`.
- Applications: `resdiaryFull`, `accessEvo`, `devHub`, `dishCult`, `resdiaryMobile`, `reserveWithGoogle`.
- Use `private readonly` fields for all locators (Playwright `Locator` type initialised in the constructor).
- Methods represent user actions or verifications, with proper TypeScript typing and explicit return types.

### 3.3 · Example Pattern

```typescript
import { BasePage } from "@pages/base";
import { type Locator, type Page, expect } from "@playwright/test";

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

### 3.4 · Reuse — Never Duplicate

Before creating any new page object, search the existing `pages/` directory for matches. Extend existing page objects rather than creating duplicates. Only create a new page object if no match genuinely exists.

---

## 4 · Selector Strategy

### 4.1 · Simple Single-Instance Pages

Prefer Playwright's built-in semantic locators:

- `getByRole('button', { name: 'Save' })`
- `getByText('Confirm Booking')`
- `getByLabel('Email')`
- `getByTestId('booking-panel')` — maps to `data-at` attribute (configured in `playwright.config.ts` as `testIdAttribute: 'data-at'`).

### 4.2 · Tabbed / Panelled UIs (Default in ResDiary)

ResDiary's admin interface uses tabbed and panelled layouts where the same element text appears in multiple panels. For these UIs, XPath scoped to container IDs is **required**:

```typescript
// ✅ Correct — scoped to a specific panel
private readonly saveButton = this.page.locator(
  'xpath=//*[@id="booking-details-panel"]//button[text()="Save"]'
);

// ✅ Correct — distinguish interactive elements from dropdown items
private readonly actionButton = this.page.locator(
  'xpath=//*[@id="panel-id"]//button[text()="Action"][not(@role="menuitem")]'
);

// ❌ Wrong — positional selectors to disambiguate duplicates
private readonly saveButton = this.page.getByRole('button', { name: 'Save' }).first();
private readonly saveButton = this.page.getByRole('button', { name: 'Save' }).nth(1);
```

### 4.3 · Rules

- Never use `.first()`, `.nth()`, or positional selectors to disambiguate duplicates.
- Distinguish interactive elements from dropdown items with `[not(@role="menuitem")]`.
- Prefer text content over CSS classes for resilience.
- Never fabricate selectors by pattern-completion — every selector must trace back to a real, verifiable source in the application.

---

## 5 · Fixture System

### 5.1 · Import Sources

- Primary: `fixtures/index.ts` — the main fixture composition combining all fixture modules.
- Legacy/Enhanced: `fixtures/enhancedFixtures.ts` — provides `test`, `authTest`, `adminTest`, `widgetTest`.

### 5.2 · Available Fixture Modules

| File                  | Provides                                                                                                                                                                       |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `index.ts`            | Composed fixture with `browserConfig`, `userCredentials`, `systemUrls`, `rdfullConfig`, `commsConfig`, `dishcultConfig`, `stripeConfig`, `stylingConfig`, `rdlConfig`, `guest` |
| `enhancedFixtures.ts` | `test` (base), `authTest` (auto-login), `adminTest` (admin creds), `widgetTest`, `performanceTest`                                                                             |
| `evoFixtures.ts`      | Access Evo workspace fixtures                                                                                                                                                  |
| `mcpFixtures.ts`      | MCP integration fixtures                                                                                                                                                       |
| `userFixtures.ts`     | `UserCredentials` type and credential injection                                                                                                                                |
| `urlFixtures.ts`      | `SystemUrls` type with all environment URLs                                                                                                                                    |
| `stripeFixtures.ts`   | Stripe payment configuration                                                                                                                                                   |
| `browserFixtures.ts`  | Browser configuration (viewport, locale, geolocation)                                                                                                                          |

### 5.3 · Rules

- Fixtures provide dependency injection for page objects and configuration.
- Do not create new fixture files without discussion — extend existing ones.
- When a test needs credentials, use fixtures or `process.env` at module scope — never hardcode values.

---

## 6 · Test Structure and Tagging

### 6.1 · File Organisation

```
tests/
  [application]/
    [feature]/
      [testname].spec.ts
```

Applications: `resdiaryFull`, `accessEvo`, `accessibilityTesting`, `API`, `authentication`, `devHub`, `dishCult`, `resdiaryMobile`, `reserveWithGoogle`.

### 6.2 · Test Tagging

Tags are placed as prefixes in the `test.describe` description string:

```typescript
test.describe("@AllTests @rdf-critical @rdf @rdf-widget Standard Widget Tests", () => {
  // ...
});
```

Common tags: `@AllTests`, `@rdf`, `@rdf-critical`, `@API`, `@ConsumerAPI`, `@Accessibility`, `@ReserveWithGoogle`, `@DevHub`, `@Evo`, `@DishCult`, `@migration`.

When adding new tags, ensure they are registered in the CI pipeline YAML (`testTag` values). When adding a new directory under `tests/`, ensure it is added to the `testDir` values in the pipeline YAML.

**Never fabricate test tags.** When porting tests from the Browser framework, always transpose the original tags — do not invent new ones.

### 6.3 · Test Steps and Serial Mode

- Use `test.step()` for better reporting of logical steps within a test.
- Use `test.describe.configure({ mode: 'serial' })` for dependent test flows that must run in order.

---

## 7 · Waiting Strategy

### 7.1 · Trust Auto-Waiting

Playwright automatically waits for elements to be actionable before performing actions. Rely on this.

### 7.2 · Explicit Waits (When Needed)

```typescript
// ✅ Wait for visibility
await element.waitFor({ state: "visible" });
await element.waitFor({ state: "hidden" });

// ✅ Wait for network response
await page.waitForResponse(
  (resp) => resp.url().includes("/api/bookings") && resp.status() === 200,
);

// ✅ Expect with default timeout (do NOT specify timeout: 5000 — that is the default)
await expect(element).toBeVisible();

// ✅ Expect with non-default timeout
await expect(element).toBeVisible({ timeout: 15_000 });
```

### 7.3 · Prohibited

```typescript
// ❌ Never use manual waits
await page.waitForTimeout(2000);

// ❌ Never use polling loops
while (!(await element.isVisible())) {
  await sleep(100);
}
```

### 7.4 · Timeout Configuration

- Default Playwright timeout: `360,000ms` (6 minutes) — configured in `playwright.config.ts`.
- The default `expect` timeout is `5,000ms`. Do not explicitly specify `timeout: 5000` — it is the default.
- Only specify timeout values when they differ from the configured default.
- Some accessibility suites (`diary-grid.spec.ts`, `diary-admin.spec.ts`) have intentionally high timeouts (`600,000ms`). **Do not change these** — they run full axe sweeps that legitimately require extended time.

---

## 8 · Resource Locking for Parallel Execution

### 8.1 · Purpose

Use `ResourceLock` from `helpers/framework/resourceLock.ts` to prevent race conditions when multiple parallel workers try to book the same table/timeslot combinations.

### 8.2 · Usage

```typescript
const lock = new ResourceLock();
const slot = await lock.acquireSlot("001_closeout");
try {
  // Use slot.diary, slot.area, slot.table, slot.time, etc.
} finally {
  await lock.releaseSlot("001_closeout");
}
```

### 8.3 · Rules

- File-based locking with configurable TTL and shard-aware partitioning.
- Always release locks in `afterAll` or `afterEach`.
- Ensure test data tags in `data/testdataset.dat` have enough slots for the maximum shard count (e.g., 5 slots for 5 shards).
- Shard isolation: when running with `SHARD_INDEX` / `SHARD_TOTAL`, slots are partitioned across shards to prevent cross-shard collisions.

---

## 9 · Test Data Generation

### 9.1 · Faker via TestDataGenerator

Use `TestDataGenerator` from `helpers/testDataGenerator.ts` (or `helpers/framework/testDataGenerator.ts`):

```typescript
const forename = await TestDataGenerator.generateCustomerForename();
const surname = await TestDataGenerator.generateCustomerSurname();
const email = await TestDataGenerator.generateFakeEmail(forename, surname);
const mobile = await TestDataGenerator.generateFakeMobileNumber();
const customer = await TestDataGenerator.generateCustomerData(); // complete object
```

### 9.2 · Rules

- Never hardcode customer names, emails, or phone numbers in tests.
- Use `TestDataGenerator.generateCustomerData()` for complete customer objects.
- UK locale is pre-configured (mobile numbers start with `07`, landlines with `01`/`02`).

---

## 10 · Reservation Cleanup Pattern

### 10.1 · Correct Pattern

Tests that create bookings must use `Reservation` objects with `afterEach` hooks for teardown:

```typescript
const microSiteName = process.env.AUTO_TEST_PROVIDER_1_MICROSITE_NAME!;

test.describe("Booking Tests", () => {
  let reservation: Reservation;

  test.afterEach(async () => {
    if (reservation?.bookingRef) {
      await reservation.cancel();
    }
  });

  test("create booking", async ({ page }) => {
    reservation = new Reservation(10, 30, 30, "en-GB", microSiteName);
    // ...
  });
});
```

### 10.2 · Critical: Module-Scope Environment Variables

Always read environment variables (especially `*MICROSITE*` vars) into module-scoped constants. Never pass `process.env.*` inline to the `Reservation` constructor — if the env var is `undefined`, `cancel()` will silently skip without throwing, leaving orphan bookings that cause cascading test failures.

```typescript
// ✅ Correct — module scope
const microSiteName = process.env.AUTO_TEST_PROVIDER_1_MICROSITE_NAME!;

// ❌ Wrong — inline, risks undefined
new Reservation(
  10,
  30,
  30,
  "en-GB",
  process.env.AUTO_TEST_PROVIDER_1_MICROSITE_NAME,
);
```

---

## 11 · Environment Configuration

### 11.1 · URL Configuration

- Only set `BASEURL` in `.env` — API URL is auto-derived via `getApiBaseUrl()` in `helpers/envHelpers.ts`.
- URL pattern: `BASEURL='envname.goodluckwiththerelease.com'`.
- API URL is derived as `https://api-{BASEURL}` (except `rdbranch.com` which uses `https://api.rdbranch.com`).

### 11.2 · Credentials

- Credentials come from Azure DevOps Variable Groups (`QAPlaywright`, `QABrowserFramework`).
- Use `python3 generate_env.py` to generate `.env` from ADO variables.
- Never hardcode credentials or URLs in test files.
- Keep secrets out of source control.

### 11.3 · Required Environment Variables for Global Setup

`BASEURL`, `RD_AUTOMATION_KEY`, `ADMIN_USER_ID`, `PROVIDER_GROUP_ID`, `TEMPLATE_PROVIDER_ID`.

Global setup can be skipped with `SKIP_GLOBAL_SETUP=true`.

---

## 12 · API Testing

### 12.1 · Structure

- API helpers in `apiHelpers/` directory: `auth.ts`, `consumerApi.ts`, `restaurantApi.ts`, `widgetApi.ts`, `loginAuth.ts`, `backOfficeAuth.ts`, `accessaCloudApi.ts`, `accessAiApi.ts`.
- JSON schemas in `schemas/` directory (subdirectories: `consumerApi`, `widgetApi`).

### 12.2 · Rules

- Use Playwright's `request` fixture or `APIRequestContext`.
- Use the `Reservation` helper class for booking lifecycle (create, cancel, verify).
- Validate response schemas using Ajv against JSON schemas in `schemas/`.
- Tag API tests with `@API` and specific API tags (e.g., `@ConsumerAPI`).

---

## 13 · TypeScript Standards

### 13.1 · ESLint Rules (Enforced)

| Rule                                               | Level   |
| -------------------------------------------------- | ------- |
| `@typescript-eslint/no-unused-vars`                | `error` |
| `@typescript-eslint/no-explicit-any`               | `warn`  |
| `@typescript-eslint/explicit-function-return-type` | `error` |
| `prefer-const`                                     | `error` |
| `no-var`                                           | `error` |

### 13.2 · Conventions

- Strict typing — avoid `any`.
- Explicit function return types on all functions (ESLint enforced).
- `prefer-const` and `no-var` enforced.
- Use `async/await` consistently — no `.then()` chains.
- Prefer `type` over `interface` for new type definitions.
- Export types for reusable structures.
- Always run `npm run format-write` before creating commits.
- Always check for unused variables and imports before committing.

---

## 14 · Naming Conventions

| Artefact          | Convention                              | Example                                    |
| ----------------- | --------------------------------------- | ------------------------------------------ |
| Page Object class | `[PageName]Page`                        | `DiaryPage`, `DiaryLoginPage`              |
| Page Object file  | `[pagename].page.ts`                    | `diary.page.ts`, `diaryLogin.page.ts`      |
| Test file         | `[feature].spec.ts`                     | `bookingNoDeposit.spec.ts`                 |
| Helper file       | `[purpose]Helper.ts` or `[purpose].ts`  | `envHelpers.ts`, `reservation.ts`          |
| Fixture file      | `[context]Fixtures.ts`                  | `enhancedFixtures.ts`, `stripeFixtures.ts` |
| API helper        | `[service]Api.ts` or `[service]Auth.ts` | `restaurantApi.ts`, `loginAuth.ts`         |

---

## 15 · Global Setup and Teardown

### 15.1 · Setup (`tests/global.setup.ts`)

- Creates a dynamic test provider (temporary venue) for test isolation.
- Creates test users (admin and general) attached to the dynamic provider.
- Outputs dynamic environment variables (`DYNAMIC_PROVIDER_ID`, `DYNAMIC_PROVIDER_NAME`, etc.) for cross-shard consumption.

### 15.2 · Teardown (`tests/global.teardown.ts`)

- Deletes the dynamic provider and associated resources created during setup.

### 15.3 · Configuration

- Setup/teardown are configured as Playwright projects with dependency chains.
- Can be skipped: `SKIP_GLOBAL_SETUP=true`, `SKIP_GLOBAL_TEARDOWN=true`.
- Outputs to `global-setup-output.json` for cross-shard variable passing.

---

## 16 · Playwright Configuration

Key settings from `playwright.config.ts`:

| Setting            | Value                   |
| ------------------ | ----------------------- |
| `timeout`          | `360,000ms` (6 minutes) |
| `testIdAttribute`  | `data-at`               |
| `trace`            | `retain-on-failure`     |
| `screenshot`       | `on-first-failure`      |
| `locale`           | `en-GB`                 |
| `timezoneId`       | `Europe/London`         |
| `retries`          | `1` on CI, `0` locally  |
| `fullyParallel`    | `true`                  |
| `viewport`         | `1920 × 963`            |
| Reporter (sharded) | `blob`                  |
| Reporter (local)   | `html` + `json`         |

---

## 17 · CI/CD Pipeline

- Azure DevOps with sharding support across multiple agents.
- Blob reports when in shard mode, HTML + JSON locally.
- Daily scheduled runs at 7am on `main`.
- Environments: `QaAutomation` (default), `QaDevelopment`, `Feature`.
- Test filtering via `--grep` with tag parameters.
- Pipeline templates in `templates/` directory.

---

## 18 · Accessibility Testing

- Dedicated suites in `tests/accessibilityTesting/`.
- Uses axe-core for WCAG compliance scanning.
- `diary-grid.spec.ts` and `diary-admin.spec.ts` have intentionally high timeouts (`600,000ms`) for full axe sweeps — **do not change these**.
- Tag with `@Accessibility`.

---

## 19 · Migration from Robot Framework

### 19.1 · Pre-Migration Checks

- Check existing tests and page objects **before** creating anything new.
- Directory structure must mirror: `Tests/resdiary_full/` → `tests/resdiaryFull/`.
- Robot Framework keywords map to Page Object methods.

### 19.2 · Tag Handling

- **Never fabricate test tags.** Always transpose the original tags from the Browser framework tests into Playwright format.
- Add `#migrated-from-robot` tags to migrated files.
- Check the `Browser_MCP_Migration` branch for recent pipeline YAML changes that may be needed for new test directories.

### 19.3 · Structure

- Never reorganise existing test structure during migration.
- When a new `tests/` subdirectory is added, register it in the pipeline YAML (`testDir` values).

---

## 20 · MCP Integration

MCP (Model Context Protocol) is used for AI-assisted test creation and maintenance.

### 20.1 · Workflow

1. **Identify application** — determine which application area the test belongs to.
2. **Search existing tests** — check for existing coverage before creating new tests.
3. **Find page objects** — locate and reuse existing page objects.
4. **Check fixtures** — identify appropriate fixtures for the test context.
5. **Generate** — create the test following all conventions in this document.

### 20.2 · Rules

- Before creating any new test, check existing tests by application.
- Reuse existing page objects — **never** create duplicates.
- Follow the pattern recognition workflow above.

---

## 21 · Commit and PR Standards

- Always run `npm run format-write` before creating commits.
- Formatting and casing changes must be in separate commits from feature changes.
- When committing only npm package updates, use conventional commit format: `chore(deps): updating package x from version y to z`.
- If an ADO work item number is provided, append with `AB#` prefix: `chore(deps): updating package x from version y to z AB#2241754`.

---

## 22 · Debugging Protocol

### 22.1 · Structured Debugging

- Debug one test at a time — never batch-debug multiple failures.
- Stop after 2 failed fix attempts on the same test and escalate.
- Every selector must trace back to a real, verifiable source — do not fabricate selectors by pattern-completion.

### 22.2 · Visual Debugging (Playwright Inspector)

When stepping through a test visually:

```bash
PWDEBUG=1 npx playwright test tests/path/to/your.spec.ts
```

This opens the Playwright Inspector for interactive step-through with live locator inspection.
