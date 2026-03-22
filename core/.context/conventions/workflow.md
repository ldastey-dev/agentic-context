# Workflow Conventions

## Workflow Orchestration

### Plan Mode Default

- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions).
- If something goes sideways, STOP and re-plan immediately — don't keep pushing.
- Use plan mode for verification steps, not just building.
- Write detailed specs upfront to reduce ambiguity.

### Subagent Strategy

- Use subagents liberally to keep main context window clean.
- Offload research, exploration, and parallel analysis to subagents.
- For complex problems, throw more compute at it via subagents.
- One task per subagent for focused execution.

### Self-Improvement Loop

- After ANY correction from the user: update `tasks/lessons.md` with the pattern.
- Write rules for yourself that prevent the same mistake.
- Ruthlessly iterate until mistake rate drops.
- Review lessons at session start for the relevant project.

### Verification Before Done

- Never mark a task complete without proving it works.
- Diff behaviour between main and your changes when relevant.
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness.

### Demand Elegance (Balanced)

- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution."
- Skip this for simple, obvious fixes — don't over-engineer.
- Challenge your own work before presenting it.

### Autonomous Bug Fixing

- When given a bug report: just fix it. Don't ask for hand-holding.
- Point at logs, errors, failing tests — then resolve them.
- Zero context switching required from the user.
- Fix failing CI tests without being told how.

### Autonomous Improvement During Review

- When reviewing code or conducting an assessment, if you identify issues: fix them. Do not ask for permission to improve code health.
- Prioritise coverage and pipeline excellence first — a strong safety net enables all other improvements.
- Delegate fixes to subagents: construct a focused prompt for each fix, starting with test coverage, then pipeline quality, then the fix itself.
- Small, focused improvements compound. A review that also adds missing tests and fixes a lint warning leaves the codebase better than it was found.

---

## Task Management

1. **Plan First:** Write plan to `tasks/todo.md` with checkable items.
2. **Verify Plan:** Check in before starting implementation.
3. **Track Progress:** Mark items complete as you go.
4. **Explain Changes:** High-level summary at each step.
5. **Document Results:** Add review section to `tasks/todo.md`.
6. **Capture Lessons:** Update `tasks/lessons.md` after corrections.

---

## Assessment and Review Workflows

When asked to assess or review an application, codebase, or system:

- Check `.context/index.md` for the relevant standard and playbook.
- **PR-level:** Apply the relevant standard for the change.
- **Codebase-level:** Use the matching assessment playbook for a structured evaluation.
- **Planning:** Use the matching planning playbook when designing new features or changes.
