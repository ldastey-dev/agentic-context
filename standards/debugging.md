# Debugging Standards — Scientific Method for Defect Resolution

Every bug is investigated and fixed using the scientific method. No guessing, no random changes, no symptom-only fixes.

---

## 1 · The Scientific Method

Use the seven-step sequence in order. Skipping a step introduces false fixes and hidden regressions.

```text
STABILISE → LOCATE → HYPOTHESISE → EXPERIMENT → FIX → TEST → SEARCH
```

### 1.1 · STABILISE

Get a reliable reproduction before doing anything else. You cannot debug what you cannot reproduce.

- Reduce the failure to the smallest case that still fails.
- Record exact inputs, environment, and order of operations.
- Intermittent failures are usually initialisation errors, timing issues, or shared state.
- The first action of a debugging session must be to run the failing test or repro and capture its output. If the standard runner is unavailable, run the repro directly (`python -c`, a direct script, `dotnet run`, etc.). No edit to implementation code is allowed before the observed failure is captured.

### 1.2 · LOCATE

Narrow the suspicious region before forming a hypothesis.

- Binary search: disable or bypass sections until the failure disappears.
- Check recently changed code first.
- Check modules with prior defect history.
- Look for patterns: specific data, user, environment, or call order.

### 1.3 · HYPOTHESISE

Form one specific, testable hypothesis at a time.

- Good: "The counter is not reset between requests because X shares state with Y."
- Bad: "The bug is somewhere in the cache layer."
- Rank competing candidates and brainstorm alternatives before committing to one.

### 1.4 · EXPERIMENT

Design a test that will disprove the hypothesis.

- Add targeted logging, an assertion, or a failing test that would pass if the hypothesis holds.
- Observe before changing production code.
- Record results and discard or refine the hypothesis based on evidence.

### 1.5 · FIX

Fix the root cause, not the symptom.

- Understand the surrounding code (hundreds of lines, not just the error line).
- Rule out competing hypotheses before committing to the diagnosis.
- Make one change at a time. Keep the original source until the fix is verified.

### 1.6 · TEST

Verify the fix actually works.

- Triangulate: multiple different test cases, not just the original repro.
- Add a regression test that would have caught the bug.
- Run the full suite and report the result.

### 1.7 · SEARCH

Defects cluster. Before marking the fix complete, search for the same pattern elsewhere.

- Grep for the same defect pattern in the same module and adjacent modules.
- Check other code from the same author or era.
- Record the result of the search in the PR or task notes.

---

## 2 · Common Defect Quick Check

Rule these out before deep investigation.

- Off-by-one: loop bounds (`<` vs `<=`), array index vs length.
- Null / undefined dereference before checking.
- Race condition (intermittent, timing-dependent).
- Uninitialised variable.
- Incorrect operator precedence (add explicit parentheses).
- Floating-point equality (`==` instead of epsilon comparison).
- Resource leak: file handle, connection, or lock not released on an error path.
- Logic inversion: wrong branch taken.

---

## 3 · Time Boxing

Debugging stops feeling systematic when it exceeds these windows.

| Phase | Max Time | Action If Exceeded |
|-------|----------|-------------------|
| Quick-and-dirty | 15–30 min | Switch to systematic method |
| Single hypothesis | 30–60 min | Generate new hypotheses |
| Systematic debugging | 2–4 hours | Take a break, consult a colleague |
| Same bug, multiple days | N/A | Consider a brute-force rewrite |

---

## 4 · Red Flags

These behaviours must be interrupted immediately.

- **Shotgun debugging:** random code changes without a hypothesis.
- **Superstitious debugging:** repeating the same failed approach.
- **Symptom fixing:** special-case workarounds instead of root cause.
- **Panic debugging:** rushing, making multiple changes at once.
- **Compiler blame:** assuming the bug is in the compiler, library, or hardware before ruling out your own code.
- **No reproduction case:** proceeding without a stable repro.
- **Circular debugging:** revisiting the same code without new data.
- **No regression test:** fixing a bug without a test that exposes it.

---

## 5 · Non-Negotiables

- The first action is always to reproduce the failure and capture the observed output.
- A hypothesis must be testable and disprovable before any production code is changed.
- Every bug fix ships with a regression test.
- Every fix is followed by a search for similar defects.
- Only one change is made at a time.

## 6 · Decision Checklist

Before declaring a bug fixed, confirm:

| # | Question | Evidence |
|---|---|---|
| 1 | Is the failure reproduced and its output captured? | Repro command + output |
| 2 | Is the hypothesis specific, testable, and supported by evidence? | Experiment result |
| 3 | Is the root cause fixed, not the symptom? | Code change explanation |
| 4 | Is the fix verified by the original repro and additional cases? | Test results |
| 5 | Is a regression test in place that would fail on the old code? | Test name / file |
| 6 | Has a search for similar defects been run and recorded? | Grep / search notes |
| 7 | Is the full suite green? | CI / local test run |
