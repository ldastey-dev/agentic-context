---
name: debug
description: "Run scientific debugging on a failing test, crash, or bug — reproduce, locate, hypothesise, fix, verify, and search for sibling defects."
keywords: [debug, debugging, bug, failing test, crash, error, fix, reproduce]
---

# Scientific Debugging Runbook

## Role

You are a **Senior Engineer** chasing a bug. Your output is a root-cause fix, verified by the original repro and additional test cases, with a regression test and a recorded search for similar defects.

---

## Objective

Resolve a single defect using the scientific method. Do not fix symptoms. Do not make multiple changes at once. Do not stop at "it works on my machine."

Load `.context/standards/debugging.md` before starting and apply it at every phase.

---

## Phase 1: STABILISE — Reproduce the Failure

- Run the failing test or repro and capture the output before reading or editing implementation code.
- If the standard test runner is unavailable, run the smallest runnable form directly.
- Reduce the failure to the smallest inputs, sequence, and environment that still fail.
- Record the exact conditions: inputs, environment variables, order of operations, and frequency.
- If the failure is intermittent, treat it as a timing, initialisation, or shared-state problem.

**Phase exit criterion:** The failure reproduces on demand and its output is captured.

---

## Phase 2: LOCATE — Narrow the Suspicious Region

- Inspect recent commits, deployments, and config changes first.
- Use binary search: disable or bypass sections until the failure disappears.
- Grep for the failing value, error message, or suspicious symbol.
- Check modules with prior defect history and the code most recently changed.
- Identify the narrowest scope where the failure originates.

**Phase exit criterion:** The suspicious region is one function, one module, or one service boundary.

---

## Phase 3: HYPOTHESISE — Form a Testable Explanation

- Generate 2–4 competing explanations for the failure.
- Select the most probable one and state it as a specific, testable hypothesis.
- Identify what evidence would disprove it.

**Phase exit criterion:** A single, disprovable hypothesis is written down before any code change.

---

## Phase 4: EXPERIMENT — Disprove the Hypothesis

- Add targeted logging, a temporary assertion, or a failing test that would pass if the hypothesis is true.
- Run the repro and capture the result.
- If the evidence disproves the hypothesis, discard it and return to Phase 3 with the next candidate.
- If the evidence supports the hypothesis, proceed to Phase 5.

**Phase exit criterion:** The hypothesis is either disproven or confirmed by observation.

---

## Phase 5: FIX — Root Cause Only

- Read the surrounding code (hundreds of lines, not just the error line).
- Rule out competing hypotheses before editing.
- Make one minimal change that addresses the root cause.
- Keep the original source until the fix is verified.

**Phase exit criterion:** One focused change resolves the failure in the repro.

---

## Phase 6: TEST — Verify and Triangulate

- Run the original repro and confirm it passes.
- Add a regression test that fails on the original code.
- Add at least one additional test case that would expose the same class of defect.
- Run the full test suite.

**Phase exit criterion:** The original repro, regression test, and full suite are green.

---

## Phase 7: SEARCH — Find Sibling Defects

- Grep for the same pattern in the same module and adjacent modules.
- Check other code from the same author or era.
- Record the search result: defects found, none found, or follow-up tasks created.

**Phase exit criterion:** A search for similar defects has been run and recorded.

---

## Non-Negotiables

- The observed failure is captured before any implementation edit.
- Only one hypothesis is tested at a time.
- Every fix ships with a regression test.
- Every fix is followed by a sibling-defect search.
- The full suite is green before the bug is marked resolved.

## Decision Checklist

- [ ] The failure reproduces on demand and output is captured.
- [ ] The hypothesis is specific and supported by an experiment.
- [ ] The change addresses the root cause, not a symptom.
- [ ] A regression test fails on the original code and passes now.
- [ ] The full test suite is green.
- [ ] A search for similar defects has been run and recorded.
