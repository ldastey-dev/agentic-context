# Testing Standards — Mandatory Coverage & Quality

> Replace bracketed placeholders (`[PACKAGE_NAME]`, `[TEST_RUNNER]`,
> `[COVERAGE_TOOL]`, `[AUTH_ENV_VAR]`, `[API_CLIENT_CLASS]`) with project values.

---

## 1 · Test Trophy Model

Follow the Test Trophy — **not** the Test Pyramid. Invest most effort in
integration tests, then unit tests, with static analysis as the foundation.

| Layer            | Ratio | Purpose                                       |
| ---------------- | ----- | --------------------------------------------- |
| **Static**       | ████░ | Linting, type-checking, formatting             |
| **Unit**         | ███░░ | Pure logic in isolation — fast, deterministic   |
| **Integration**  | █████ | Modules working together, real-ish boundaries   |
| **E2E**          | ██░░░ | Full system validation — slow, high-confidence  |

Every layer must pass before code is merged. No exceptions.

---

## 2 · Coverage Requirements

- **Minimum 90 % line coverage** is enforced on every PR via CI.
- Coverage must **never decrease** between commits. New code without tests fails the gate.
- Run locally:
  ```bash
  # Generic pattern — substitute your runner and package
  [TEST_RUNNER] --cov=[PACKAGE_NAME] --cov-report=term-missing
  ```

---

## 3 · Test Structure

Mirror the source layout under a top-level `tests/` directory:

```
tests/
  conftest.py            <- shared fixtures (test client, mock services, env vars)
  unit/
    test_<module>.py     <- one file per source module
  integration/
    test_<feature>.py    <- cross-module / service tests
  e2e/
    test_<workflow>.py   <- optional: full-system smoke tests
```

---

## 4 · Behavioural Testing — Test *What*, Not *How*

- Assert on **observable outcomes**: return values, side effects, state changes.
- Do **not** assert on internal call order or implementation details.
- If a refactor breaks a test but not the feature, the test was wrong.

---

## 5 · Test Naming Conventions

Use `test_<unit>_<behaviour>` — names should read like sentences:

```
test_login_returns_token_on_valid_credentials
test_login_raises_on_expired_session
test_parse_config_ignores_unknown_keys
test_upload_retries_on_transient_failure
```

Avoid meaningless names: `test1`, `test_it`, `test_thing`.

---

## 6 · Test Layers — Detailed

### Unit Tests (required for every module)

- Test each function in **isolation**. Mock all external I/O.
- Every public function needs **at least** two tests:
  1. **Happy path** — valid inputs, correct output shape.
  2. **Error / edge case** — empty input, missing config, upstream failure.

### Integration Tests (run conditionally)

- Mark with a runner-appropriate tag (e.g. `@pytest.mark.integration`,
  `describe.skip` in Jest, `[Category("Integration")]` in xUnit).
- Skip automatically when credentials are unavailable:
  ```python
  pytestmark = pytest.mark.skipif(
      not os.environ.get("[AUTH_ENV_VAR]"),
      reason="Credentials not available"
  )
  ```
- Never run against production. Use sandboxed / ephemeral environments.

### E2E Tests (optional, high-value)

- Cover critical user journeys only. Set hard timeouts. Isolate from other layers.

---

## 7 · Mocking Strategy

> Mock at **boundaries**, never at internals.

| Do mock                         | Do NOT mock                         |
| ------------------------------- | ----------------------------------- |
| HTTP clients / API calls        | Private helper functions             |
| Database connections            | The module under test itself         |
| File system I/O                 | Language built-ins (unless necessary) |
| Environment variables           | Data classes / value objects          |
| External service SDKs           | Pure transformation logic             |

```python
# Good — mock at the boundary
with patch("[PACKAGE_NAME].service.[API_CLIENT_CLASS]") as mock:
    mock.return_value.get.return_value = {"id": 1, "status": "ok"}
    assert my_service.fetch_item(1).status == "ok"

# Bad — mocking an internal helper defeats the purpose
with patch("[PACKAGE_NAME].service._parse_response"):  # DON'T
    ...
```

---

## 8 · Test Isolation & Independence

- Every test must be **independent** — no shared mutable state, no ordering.
- Use fresh fixtures per test. Prefer factory functions over shared instances.
- Clean up side effects: temp files, database rows, monkey-patched env vars.

---

## 9 · Fixtures & Shared Setup

Provide reusable fixtures in `conftest.py` (or equivalent):

```python
# conftest.py — generic fixture patterns
import pytest
from unittest.mock import MagicMock, patch

@pytest.fixture(autouse=True)
def mock_env_vars(monkeypatch):
    """Inject safe test values for all required env vars."""
    monkeypatch.setenv("[AUTH_ENV_VAR]", "test-token-value")

@pytest.fixture
def test_client():
    """Return an in-process test client for the application."""
    from [PACKAGE_NAME].app import create_app
    return create_app(testing=True).test_client()

@pytest.fixture
def mock_external_service():
    """Patch the external API client at the boundary."""
    with patch("[PACKAGE_NAME].service.[API_CLIENT_CLASS]") as mock:
        yield mock.return_value

@pytest.fixture
def clean_database(tmp_path):
    """Provide an isolated database for each test."""
    db_path = tmp_path / "test.db"
    # set up schema, yield connection, tear down
    yield db_path
```

---

## 10 · Parametrised Testing

Use parametrised tests to cover multiple inputs without duplicating logic:

```python
# Python (pytest)
@pytest.mark.parametrize("input_val,expected", [
    ("valid_token", True),
    ("",            False),
    (None,          False),
    ("expired",     False),
])
def test_validate_token(input_val, expected):
    assert validate_token(input_val) is expected
```

```javascript
// JavaScript (Jest / Vitest)
test.each([
  ["valid_token", true],
  ["",            false],
  [null,          false],
])("validate_token(%s) -> %s", (input, expected) => {
  expect(validateToken(input)).toBe(expected);
});
```

Cover at minimum: happy path, empty / null, boundary, and known error values.

---

## 11 · Coverage Configuration

Example for Python (`pyproject.toml`):

```toml
[tool.pytest.ini_options]
addopts = "--cov=[PACKAGE_NAME] --cov-report=term-missing --cov-fail-under=90"
testpaths = ["tests"]

[tool.coverage.run]
source = ["[PACKAGE_NAME]"]
omit = ["*/__init__.py"]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "if __name__ == .__main__.:",
    "raise NotImplementedError",
]
```

Adapt for your ecosystem:

| Ecosystem  | Runner          | Coverage tool         | Config file      |
| ---------- | --------------- | --------------------- | ---------------- |
| Java       | JUnit 5         | JaCoCo                | `pom.xml` / `build.gradle` |
| C# / .NET  | xUnit / NUnit   | coverlet              | `.runsettings`   |
| JavaScript | Jest / Vitest   | built-in / c8 / v8    | `jest.config.*`  |
| PHP        | PHPUnit         | built-in / pcov       | `phpunit.xml`    |
| Python     | pytest          | coverage / pytest-cov | `pyproject.toml` |

---

## 12 · Test-First Workflow

1. **Write a failing test** describing desired behaviour.
2. **Implement** minimum code to pass.
3. **Refactor** while keeping tests green.
4. **Add edge-case tests** — empty inputs, error responses, boundaries.
5. **Verify coverage** before committing.

Never merge production code without a corresponding test.

---

## 13 · Non-Negotiables

| Rule | Detail |
| ---- | ------ |
| No `sleep()` in tests | Use deterministic waits, mocked clocks, or event-based synchronisation. |
| No flaky tests | A test that fails intermittently is **worse** than no test. Fix or delete. |
| No test interdependence | Test A must never rely on Test B running first. |
| No production credentials | Tests use fakes, mocks, or sandboxed tokens — never real secrets. |
| No ignoring failures | `@skip` / `xfail` must include a tracking issue. Permanent skips are deleted. |
| No testing implementation | Assert on behaviour and outputs, not internal call graphs. |
| No merged PR below 90 % coverage | CI blocks the merge. No manual overrides without documented justification. |

---

## 14 · Decision Checklist

Before opening a PR, confirm every item:

- [ ] All new public functions have unit tests (happy path + error case)
- [ ] Integration tests exist for cross-module or external-service interactions
- [ ] Tests pass locally **and** in CI (no unexpected skips)
- [ ] Coverage >= 90 % and has not decreased
- [ ] No `sleep()`, no flaky assertions, no order-dependent tests
- [ ] Mocks target boundaries only — no internal implementation mocking
- [ ] Test names describe the behaviour being verified
- [ ] Parametrised tests cover empty, null, boundary, and error inputs
- [ ] Fixtures clean up after themselves (temp files, env vars, DB rows)
- [ ] `@skip` / `xfail` markers reference a tracking issue
