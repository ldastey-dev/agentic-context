# AGENTS.md

Maintainer-facing guide for working in **this** repository — the source of standards, playbooks, and per-agent configuration templates that `deploy.sh` and `deploy.ps1` distribute into target repositories.

This file is for contributors editing the templates here. It is **not** the `AGENTS.md` that gets shipped to consumers — that template lives at `core/AGENTS.md` and is copied into each target repo by the deploy scripts (the consumer fills in the `[CONFIGURE]` sections; the scripts do not template anything themselves).

---

## What This Repository Is

A single-source-of-truth library of:

- **Standards** (`standards/`) — per-concern prescriptive rules (security, testing, performance, .NET, React, etc.).
- **Playbooks** (`playbooks/`) — step-by-step procedures for assessments, reviews, planning, and refactoring.
- **Core configuration** (`core/`) — the lean, always-in-context files (`AGENTS.md`, `CLAUDE.md`, `.context/index.md`, conventions, per-agent redirects) that every target repo receives.
- **Deploy scripts** (`deploy.sh`, `deploy.ps1`) — the writers that assemble the above into a target repository's layout for the selected agents.

Consumers of this library run `deploy.sh` (or `deploy.ps1`) against their own repository. They never edit content here.

---

## Core Design Principles

These principles are why the repository is structured the way it is. Preserve them.

### 1. One copy of every standard

Every standard, playbook, and convention exists in **exactly one** file. No standard is duplicated per agent. If a fact appears twice in this repo, one of the copies is wrong.

- Standards: one file per concern in `standards/`.
- Playbooks: one file per procedure in `playbooks/{assess,review,plan,refactor,docs}/`.
- Conventions: one file per topic in `core/.context/conventions/`.

If you need to reference the same rule from two playbooks, link to the standard — do not paste the text.

### 2. Separation of concerns: authoring vs. distribution

| Concern | Where | What lives here |
| --- | --- | --- |
| **Authoring** | `standards/`, `playbooks/`, `core/` | The prose. Edit these. |
| **Distribution** | `deploy.sh`, `deploy.ps1` | The writers. They translate this repo's structure into the target's layout, selecting per-agent files based on `--agents`. |

Authoring changes touch markdown only. Distribution changes touch the scripts only. Do not mix.

### 3. Per-agent files are thin redirects, not duplicates

The point of supporting multiple agents (Claude Code, Cursor, Windsurf, Devin, Copilot) is **not** to write multiple copies of our standards. It is to write a small adapter file that each agent reads and then sends the agent to `AGENTS.md` + `.context/index.md`.

- `core/.cursor/rules/standards.mdc`, `core/.windsurfrules`, `core/.devin/devin.json`, `core/.github/copilot-instructions.md`, `core/CLAUDE.md` — all are redirects. None contains a standard.
- For Claude Code and Copilot, `deploy.sh` additionally generates skill wrappers from playbook frontmatter — wrappers, not copies.

If you find yourself writing prose in a per-agent file, stop and put it in `core/AGENTS.md` or a standard instead.

### 4. Context-loaded over always-in-context

Only `core/` is loaded into every agent session. Standards and playbooks are loaded **on demand** when the agent matches a keyword in `core/.context/index.md`. This keeps the always-in-context footprint to ~60 lines.

When adding a new standard or playbook, the new entry in `core/.context/index.md` is what makes it discoverable. Without that entry, agents will never find it.

### 5. Prescriptive, not advisory

Standards use "must", "never", "always". They are not suggestions. Every standard ends with a `## Non-Negotiables` and a `## Decision Checklist` so a reader can act without rereading the body.

---

## Source → Target Layout

The on-disk tree for this repository is documented in the [Repository Structure section of the README](README.md#repository-structure). Do not duplicate it here.

The directory layout in this repo is **not** the layout in target repos. The deploy scripts remap source paths to target paths as follows:

| Source here | Target repo path |
| --- | --- |
| `core/AGENTS.md` | `<repo>/AGENTS.md` |
| `core/CLAUDE.md` | `<repo>/CLAUDE.md` |
| `core/.context/index.md` | `<repo>/.context/index.md` |
| `core/.context/conventions/*` | `<repo>/.context/conventions/*` |
| `standards/*.md` | `<repo>/.context/standards/*.md` |
| `playbooks/**/*.md` | `<repo>/.context/playbooks/**/*.md` |
| `core/.cursor/`, `.devin/`, `.windsurfrules`, `.github/copilot-instructions.md` | mirrored to target (only when the agent is selected) |
| Skill wrappers generated from `playbooks/**/*.md` frontmatter | `<repo>/.claude/skills/` and `<repo>/.github/skills/` (Claude/Copilot only) |

---

## Working in This Repository

### Adding a new standard

1. Create `standards/<concern>.md`. Use the `## N · Section Title` heading style (middle-dot separator).
2. End with `## Non-Negotiables` and `## Decision Checklist`.
3. Add a row to the Domain Standards or Technology Standards table in `core/AGENTS.md`.
4. Add a keyword route in `core/.context/index.md`.
5. If there is a matching assessment or review playbook, link to it from the standard.

### Adding a new playbook

1. Create `playbooks/<category>/<name>.md` where category is `assess`, `review`, `plan`, `refactor`, or `docs`.
2. Use YAML frontmatter:

   ```yaml
   ---
   name: <category>-<name>
   description: "One-line description used by deploy.sh to generate skill wrappers."
   keywords: [phrase one, phrase two]
   ---
   ```

3. Use semantic, non-numbered headings (`## Role`, `## Phase 1: Discovery`, ...).
4. Add a keyword route in `core/.context/index.md`.
5. Do not generate skill wrappers by hand. `deploy.sh` does that from the frontmatter.

### Adding support for a new agent

1. Add the agent's redirect file under `core/` (e.g. `core/.newagent/config.yaml`).
2. The redirect must point the agent to `AGENTS.md` and `.context/index.md` — never duplicate standards.
3. Extend `deploy.sh` and `deploy.ps1`: agent flag parsing, interactive menu entry, copy step.
4. Update the README's "Supported Agents" table.

### Editing standards or playbooks

- Keep instructions prescriptive ("must", "never", "always").
- Use **British English** throughout (optimisation, behaviour, colour).
- Use **kebab-case** for file names.
- Spell SOLID principles in full — never SRP, OCP, etc.
- Mark project-specific sections in templates with `[CONFIGURE]` in the heading and `<!-- PROJECT: ... -->` HTML comments inline.

### Editing deploy scripts

- `deploy.sh` (bash) and `deploy.ps1` (PowerShell) must stay behaviour-equivalent. A change to one usually needs the matching change in the other.
- Both must honour the overwrite guard (`--overwrite` / `--no-overwrite`, interactive prompt otherwise).
- The interactive `--agents` menu must work on macOS, Linux, and Windows PowerShell.
- **Never run `deploy.sh` or `deploy.ps1` against this repository.** This repo is the source library, not a deploy target. Running the scripts here writes `/AGENTS.md`, `/CLAUDE.md`, `/.context/`, `/.cursor/`, `/.devin/`, `/.windsurfrules`, `/.github/copilot-instructions.md`, `/.claude/`, and `/.github/skills/` at the repo root — the `.gitignore` keeps those out of commits, but they overlay tracked source paths (`core/AGENTS.md` is the tracked source; `/AGENTS.md` is the tracked maintainer guide) and create confusing untracked state. To test a deploy-script change, run it against an empty scratch directory (`mkdir /tmp/agentic-context-test && ./deploy.sh /tmp/agentic-context-test`) or another repo entirely.

---

## What Belongs Where

| If you are adding... | Put it in... |
| --- | --- |
| A prescriptive rule about how code should be written | `standards/<concern>.md` |
| A procedure for assessing or changing code | `playbooks/<category>/<name>.md` |
| A workflow, communication, or naming convention | `core/.context/conventions/*.md` |
| The lean per-project config every target repo gets | `core/AGENTS.md` |
| A pointer for a specific agent to find AGENTS.md | `core/<agent-specific-file>` |
| A keyword route to discover a standard or playbook | `core/.context/index.md` |
| Anything about how files are written to target repos | `deploy.sh` and `deploy.ps1` |

If a change does not fit any row above, it probably does not belong in this repo.

---

## What Does Not Belong Here

- **Engagement artefacts.** Assessment reports, pen-test write-ups, and review outputs produced *by* using these playbooks against a target codebase. Keep them locally under `/engagements/` (git-ignored), alongside any `reviews/` directories (also ignored at any depth).
- **Deploy outputs.** Anything written to the repo root by `deploy.sh` (e.g. a generated `/AGENTS.md` template copy, `/.context/`, `/.cursor/`, etc.) when this repo is used as its own deploy target for local testing. The `.gitignore` anchors these with leading slashes so they cannot be accidentally committed; `core/<same name>` is the tracked source and is never affected.
- **Per-agent duplicates of standards.** See Core Design Principle 3.
- **Local editor or agent settings** beyond what every contributor needs. `/.claude/`, `/.cursor/`, `/.devin/` at the repo root, and `.vscode/` at any depth, are ignored.

---

## Conventions

The shared writing conventions (British English, kebab-case file names, the `## N · Section Title` standards heading style, semantic playbook headings, `[CONFIGURE]` markers, and `<!-- PROJECT: ... -->` inline customisation points) are documented in the [Conventions section of the README](README.md#conventions). They apply equally to maintainers and consumers — do not restate them here.

Additional rules that apply specifically to maintainers of this template repo:

- **Prescriptive language** — standards must use "must", "never", "always". They are not advisory.
- **SOLID principles in full** — never SRP, OCP, LSP, ISP, DIP. Spell them out so an agent loading the standard out of context can still understand it.

---

## Non-Negotiables

- **Never run `deploy.sh` or `deploy.ps1` against this repository.** Test deploy-script changes in a scratch directory or against another repo. See [Editing deploy scripts](#editing-deploy-scripts) for the reasoning.
- Never duplicate a standard across files. One canonical home per rule.
- Never write a standard inside a per-agent redirect file.
- Never paste playbook text into a skill wrapper — regenerate from frontmatter.
- Keep authoring (markdown) and distribution (deploy scripts) separate in every change.
- Never commit engagement artefacts or root-level deploy outputs.
- `deploy.sh` and `deploy.ps1` must remain behaviour-equivalent.

## Decision Checklist

Before opening a PR, confirm:

- [ ] No existing file already covers this content (would be duplication).
- [ ] Prose lives in `standards/`, `playbooks/`, or `core/.context/` — not in a per-agent file.
- [ ] If a new standard or playbook: added to `core/.context/index.md` and (for standards) the table in `core/AGENTS.md`.
- [ ] If a deploy script change: both `deploy.sh` and `deploy.ps1` updated, and tested against a scratch directory — never against this repo.
- [ ] If a new agent: redirect file added under `core/`, both deploy scripts updated, README table updated.
- [ ] British English, kebab-case, prescriptive language.
- [ ] No engagement artefacts or generated deploy outputs in the diff.
