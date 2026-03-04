# Prompts Repository — Agent Instructions

This repository is a **template library** for AI coding agent instructions and assessment playbooks.
It is not a software project — it contains Markdown files that are imported into other repositories.

---

## Repository Structure

```text
templates/                 Importable agent config (cp -a templates/. <target-repo>/)
  AGENTS.md                Canonical coding standards (Devin, Cursor, Windsurf)
  CLAUDE.md                Claude Code instructions (delegates to AGENTS.md)
  .github/instructions/    Per-concern review playbooks (Copilot auto-loads)
  .github/copilot-instructions.md  Copilot global context
  .windsurfrules           Thin redirect → AGENTS.md
  .clinerules              Thin redirect → AGENTS.md
  .cursor/rules/           Cursor rules (redirect → AGENTS.md)

playbooks/                 Standalone prompts (paste into agent conversations)
  repository-review/       Numbered assessment playbooks (00–08)
  planning/                Upfront design work (TDD, ADR, risk, spike)
  refactoring/             Behaviour-preserving code improvement runbooks
```

---

## Conventions

- **British English** throughout (optimisation, behaviour, colour).
- **Kebab-case** file names. `.instructions.md` suffix for Copilot instruction files.
- **`## N · Section Title`** heading style in instruction files (middle dot separator).
- **`[CONFIGURE]`** in section headings marks project-specific placeholders.
- **`<!-- PROJECT: ... -->`** HTML comments mark inline customisation points.
- SOLID principles use **full names** (Single Responsibility Principle, not SRP).
- No SOLID sub-acronyms anywhere.

---

## Editing Guidelines

- Do not modify templates unless explicitly asked.
- Keep standards prescriptive — "must", "never", "always" — not advisory.
- Every instruction file ends with `## Non-Negotiables` and `## Decision Checklist`.
- When updating a standard, update it in ONE place only (the canonical source).
  - Coding standards → `templates/AGENTS.md`
  - Per-concern detail → `templates/.github/instructions/{concern}.instructions.md`
  - Do NOT duplicate standards across agent files.

---

## Code Review Playbooks

When reviewing code, apply the relevant `.instructions.md` playbook from `templates/.github/instructions/`.

When assessing an entire repository, use the numbered playbooks in `playbooks/repository-review/` (00 through 08).
