# AGENTS.md

Maintainer-facing guide for working in **this** repository — the source of standards, playbooks, and per-agent configuration templates that `scripts/deploy.sh` and `scripts/deploy.ps1` distribute into target repositories.

This file is for contributors editing the templates here. It is **not** the `AGENTS.md` that gets shipped to consumers — that template lives at `core/AGENTS.md` and is copied into each target repo by the deploy scripts (the consumer fills in the `[CONFIGURE]` sections; the scripts do not template anything themselves).

---

## What This Repository Is

A single-source-of-truth library of:

- **Standards** (`standards/`) — per-concern prescriptive rules (security, testing, performance, .NET, React, etc.).
- **Playbooks** (`playbooks/`) — step-by-step procedures for assessments, reviews, planning, and refactoring.
- **Core configuration** (`core/`) — the lean, always-in-context files (`AGENTS.md`, `CLAUDE.md`, `.context/index.md`, conventions, per-agent redirects) that every target repo receives.
- **Deploy scripts** (`scripts/deploy.sh`, `scripts/deploy.ps1`) — the writers that assemble the above into a target repository's layout for the selected agents.

Consumers of this library run `scripts/deploy.sh` (or `scripts/deploy.ps1`) against their own repository. They never edit content here.

---

## Core Design Principles

These principles are why the repository is structured the way it is. Preserve them.

### 1. One copy of every standard

Every standard, playbook, and convention exists in **exactly one** file. No standard is duplicated per agent. If a fact appears twice in this repo, one of the copies is wrong.

- Standards: one file per concern in `standards/`.
- Playbooks: one file per procedure in `playbooks/{assess,review,plan,refactor,debug,docs,setup}/`.
- Conventions: one file per topic in `core/.context/conventions/`.

If you need to reference the same rule from two playbooks, link to the standard — do not paste the text.

### 2. Separation of concerns: authoring vs. distribution

| Concern | Where | What lives here |
| --- | --- | --- |
| **Authoring** | `standards/`, `playbooks/`, `core/` | The prose. Edit these. |
| **Distribution** | `scripts/deploy.sh`, `scripts/deploy.ps1` | The writers. They translate this repo's structure into the target's layout, selecting per-agent files based on `--agents`. |

Authoring changes touch markdown only. Distribution changes touch the scripts only. Do not mix.

### 3. Per-agent files are thin redirects, not duplicates

The point of supporting multiple agents (Claude Code, Cursor, Windsurf, Devin, Copilot) is **not** to write multiple copies of our standards. It is to write a small adapter file that each agent reads and then sends the agent to `AGENTS.md` + `.context/index.md`.

- `core/.cursor/rules/standards.mdc`, `core/.windsurfrules`, `core/.devin/devin.json`, `core/.github/copilot-instructions.md`, `core/CLAUDE.md` — all are redirects. None contains a standard.
- For Claude Code and Copilot, `scripts/deploy.sh` additionally generates skill wrappers from playbook frontmatter — wrappers, not copies.

If you find yourself writing prose in a per-agent file, stop and put it in `core/AGENTS.md` or a standard instead.

### 4. Context-loaded over always-in-context

Only `core/` is loaded into every agent session. Standards and playbooks are loaded **on demand** when the agent matches a keyword in `core/.context/index.md`. This keeps the always-in-context footprint to ~60 lines.

When adding a new standard or playbook, the new entry in `core/.context/index.md` is what makes it discoverable. Without that entry, agents will never find it.

### 5. Prescriptive, not advisory

Standards use "must", "never", "always". They are not suggestions. Every standard ends with a `## Non-Negotiables` and a `## Decision Checklist` so a reader can act without rereading the body.

### 6. The base is disposable; only the override layer is owned

Everything the deploy scripts write into a target's `.context/` base — standards, playbooks, conventions, `index.md` — is **replaced wholesale on every update**. This is deliberate. It is what removes merging from the update path entirely: there is no three-way merge, no conflict, and no drift to reconcile.

Consumers customise through `.context/overrides/`, which updates never touch, and through the region of their `AGENTS.md` outside the managed block.

The consequence for maintainers: **nothing generated into the base may carry consumer state.** If you add a file to the base that a consumer would reasonably want to edit, you have created a file that updates will silently destroy. Either it belongs in the override layer, or it must be generated from the manifest.

---

## Source → Target Layout

The on-disk tree for this repository is documented in the [Repository Structure section of the README](README.md#repository-structure). Do not duplicate it here.

The directory layout in this repo is **not** the layout in target repos. The deploy scripts remap source paths to target paths as follows:

| Source here | Target repo path |
| --- | --- |
| `core/AGENTS.md` | `<repo>/AGENTS.md` (managed block only after first deploy) |
| `core/CLAUDE.md` | `<repo>/CLAUDE.md` |
| `core/.context/index.md` | `<repo>/.context/index.md` |
| `core/.context/conventions/*` | `<repo>/.context/conventions/*` |
| `core/.context/overrides/*` | `<repo>/.context/overrides/*` (scaffold only — never overwritten) |
| `standards/*.md` | `<repo>/.context/standards/*.md` |
| `playbooks/**/*.md` | `<repo>/.context/playbooks/**/*.md` |
| `scripts/{update,migrate}.{sh,ps1}`, `scripts/lib/*` | `<repo>/.context/bin/` |
| `core/.cursor/`, `.devin/`, `.windsurfrules`, `.github/copilot-instructions.md` | mirrored to target (only when the agent is selected) |
| Skill wrappers generated from `playbooks/**/*.md` frontmatter | `<repo>/.claude/skills/` and `<repo>/.github/skills/` (Claude/Copilot only) |

Generated into the target, with no source file here: `<repo>/.context/manifest.json` and `<repo>/.context/VERSION`.

---

## Working in This Repository

### Adding a new standard

1. Create `standards/<concern>.md`. Use the `## N · Section Title` heading style (middle-dot separator).
2. End with `## Non-Negotiables` and `## Decision Checklist`.
3. Add a row to the Domain Standards or Technology Standards table in `core/AGENTS.md`.
4. Add a keyword route in `core/.context/index.md`.
5. If there is a matching assessment or review playbook, link to it from the standard.

### Adding a new playbook

1. Create `playbooks/<category>/<name>.md` where category is `assess`, `review`, `plan`, `refactor`, `debug`, `docs`, or `setup`.
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
5. Do not generate skill wrappers by hand. `scripts/deploy.sh` does that from the frontmatter.

### Adding support for a new agent

1. Add the agent's redirect file under `core/` (e.g. `core/.newagent/config.yaml`).
2. The redirect must point the agent to `AGENTS.md` and `.context/index.md` — never duplicate standards.
3. Extend `scripts/deploy.sh` and `scripts/deploy.ps1`: agent flag parsing, interactive menu entry, copy step.
4. Update the README's "Supported Agents" table.

### Editing standards or playbooks

- Keep instructions prescriptive ("must", "never", "always").
- Use **British English** throughout (optimisation, behaviour, colour).
- Use **kebab-case** for file names.
- Spell SOLID principles in full — never SRP, OCP, etc.
- Mark project-specific sections in templates with `[CONFIGURE]` in the heading and `<!-- PROJECT: ... -->` HTML comments inline.

### Editing deploy scripts

- `scripts/deploy.sh` (bash) and `scripts/deploy.ps1` (PowerShell) must stay behaviour-equivalent. A change to one usually needs the matching change in the other.
- Both must honour the overwrite guard (`--overwrite` / `--no-overwrite`, interactive prompt otherwise).
- The interactive `--agents` menu must work on macOS, Linux, and Windows PowerShell.
- **`scripts/deploy.sh` must be portable to macOS and Linux.** macOS ships bash 3.2 as `/bin/bash` and BSD userland, so bash 4+ syntax (`declare -A`, `mapfile`, `${var,,}`) and GNU-only utilities are forbidden. Use portable equivalents: `shasum -a 256` or a `sha256sum` fallback rather than assuming `sha256sum`; `find … -exec test -x {} \; -print` rather than `find -perm /111`; `sed -i.bak` (then delete the backup) rather than bare `sed -i`. The same rule applies to every `.sh` file in `playbooks/`.
- **`scripts/deploy.ps1` must run on Windows PowerShell 5.1 and PowerShell 7+.** 5.1 is the oldest supported baseline and is where the historic parse and `Add-Type` bugs surfaced. PowerShell 7-only syntax (ternaries, `??`, `-Parallel`) is forbidden. `PSScriptAnalyzerSettings.psd1` encodes this and is enforced in CI.
- **CI enforces both.** `.github/workflows/deploy-sh-tests.yml` and `.github/workflows/deploy-ps1-tests.yml` run on every pull request from any branch (and on every commit pushed to an open pull request), plus every push to `main`, with **no path filters** — these scripts are load-bearing for every consumer, so they are never allowed to go untested. `scripts/deploy.sh` is tested on Ubuntu and macOS (including explicitly under `/bin/bash` 3.2) and linted with `shellcheck --severity=warning`; `scripts/deploy.ps1` is tested on Windows PowerShell 5.1, and on PowerShell 7 across Windows, Linux and macOS. Do not add path filters to these workflows and do not restrict the `pull_request` trigger to specific branches.
- **Never run `scripts/deploy.sh` or `scripts/deploy.ps1` against this repository.** This repo is the source library, not a deploy target. Running the scripts here writes `/AGENTS.md`, `/CLAUDE.md`, `/.context/`, `/.cursor/`, `/.devin/`, `/.windsurfrules`, `/.github/copilot-instructions.md`, `/.claude/`, and `/.github/skills/` at the repo root — the `.gitignore` keeps those out of commits, but they overlay tracked source paths (`core/AGENTS.md` is the tracked source; `/AGENTS.md` is the tracked maintainer guide) and create confusing untracked state. To test a deploy-script change, run it against an empty scratch directory (`mkdir /tmp/agentic-context-test && ./scripts/deploy.sh /tmp/agentic-context-test`) or another repo entirely.

---

### Versioning and releases

**Never edit `VERSION`, `CHANGELOG.md`, or `scripts/baselines/<version>.sha256` by hand.** All three are written by `.github/workflows/release.yml` when a change lands on `main`, and `.github/workflows/version-gate.yml` rejects any pull request that touches them. A hand-written baseline is the most damaging of the three: `migrate.sh` uses it to tell a pristine file from a consumer's edit, so a wrong baseline silently corrupts every future migration.

A release is cut only when **deployable content** changes. Deployable means content that reaches a consumer repository:

| Deployable — cuts a release | Not deployable — cuts nothing |
| --- | --- |
| `core/**`, `standards/**`, `playbooks/**` | `README.md`, this file, `MIGRATIONS.md` |
| `scripts/deploy.{sh,ps1}` | `.github/workflows/**` |
| `scripts/update.{sh,ps1}` | `scripts/tests/**`, `scripts/deploy.Tests.ps1` |
| `scripts/migrate.{sh,ps1}` | `scripts/ci/**` |
| `scripts/lib/common.{sh,ps1}` | `.gitignore`, editor config |

This list lives in exactly one place — `is_deployable` in `scripts/ci/next-version.sh` — and both the gate and the release job call that script, so the version reported on a pull request is always the version its merge cuts. If you add a new file that ships to consumers, add it there or it will never trigger a release and every deployment will silently miss it.

The pull request title sets the **size** of the bump, never whether one happens. The derivation and what each number means to a consumer are in the [Versioning section of the README](README.md#versioning) — do not restate them here. The maintainer-facing rule is the one the table cannot express: an unrecognised type must never block a release. A deployable change is a release regardless of how its author labelled it, so mislabelling may understate a version but must never lose one.

Choose the bump by its effect on a consumer's deployment, not by how much prose changed. Renaming or removing a deployed path is a major even if it is a one-line change, because an override pointing at the old path is orphaned by it. Rewriting a standard in full is a patch if every path survives.

The first release is a special case: with no tag to bump from, the version already in `VERSION` is published as-is rather than bumped past. `next-version.sh` handles this when `--latest-tag` is empty, and both the gate and the release job pass it explicitly so they cannot disagree.

Ordering inside the release job is load-bearing. The commit must be pushed **before** the tag is created, because tagging first produces a tag whose tree still holds the previous `VERSION` — a consumer resolving that tag would download content that contradicts the version it was told to expect. The job also runs under `concurrency: cancel-in-progress: false` so releases queue rather than cancel, and guards against re-triggering itself with both an actor check and `[skip ci]`.

Any change that requires a consumer to act needs a section in `MIGRATIONS.md` and a matching baseline, or adopters on the previous version cannot upgrade. Because consumers are pinned to their major line by default, a major is never applied silently — which is what makes it safe to cut one when a deployment genuinely needs attention, rather than contorting a change to avoid it.

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
| Anything about how files are written to target repos | `scripts/deploy.sh` and `scripts/deploy.ps1` |
| Anything about how a deployed repo detects or applies updates | `scripts/update.sh` and `scripts/update.ps1` |
| Logic shared by the deploy, update and migrate scripts | `scripts/lib/common.sh` and `scripts/lib/common.ps1` |
| Anything about how a release is computed or published | `scripts/ci/*` and `.github/workflows/release.yml` |
| What a consumer must do to upgrade across a MAJOR | `MIGRATIONS.md` |

If a change does not fit any row above, it probably does not belong in this repo.

---

## What Does Not Belong Here

- **Engagement artefacts.** Assessment reports, pen-test write-ups, and review outputs produced *by* using these playbooks against a target codebase. Keep them locally under `/engagements/` (git-ignored), alongside any `reviews/` directories (also ignored at any depth).
- **Deploy outputs.** Anything written to the repo root by `scripts/deploy.sh` (e.g. a generated `/AGENTS.md` template copy, `/.context/`, `/.cursor/`, etc.) when this repo is used as its own deploy target for local testing. The `.gitignore` anchors these with leading slashes so they cannot be accidentally committed; `core/<same name>` is the tracked source and is never affected.
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

- **Never run `scripts/deploy.sh` or `scripts/deploy.ps1` against this repository.** Test deploy-script changes in a scratch directory or against another repo. See [Editing deploy scripts](#editing-deploy-scripts) for the reasoning.
- Never duplicate a standard across files. One canonical home per rule.
- Never write a standard inside a per-agent redirect file.
- Never paste playbook text into a skill wrapper — regenerate from frontmatter.
- Keep authoring (markdown) and distribution (deploy scripts) separate in every change.
- Never commit engagement artefacts or root-level deploy outputs.
- `scripts/deploy.sh` and `scripts/deploy.ps1` must remain behaviour-equivalent.
- `scripts/deploy.sh` must run on macOS bash 3.2 with BSD userland as well as on Linux with GNU userland. No bash 4+ syntax, no GNU-only utilities.
- `scripts/deploy.ps1` must run on Windows PowerShell 5.1 as well as PowerShell 7+. No PowerShell 7-only syntax.
- The same portability and behaviour-equivalence rules apply in full to `scripts/update.*`, `scripts/migrate.*` and `scripts/lib/common.*`. They ship to consumers and run on their machines, not ours.
- The deploy-script workflows must run on every pull request from any branch, with no path filters. Never narrow their triggers.
- Never edit `VERSION`, `CHANGELOG.md` or `scripts/baselines/<version>.sha256` by hand. CI owns all three. `scripts/baselines/unversioned.sha256` is the one exception: it records the pre-versioning content for `migrate`, is committed by hand, and CI can never overwrite it because `write-baseline.sh` accepts only valid SemVer.
- Never add a file to a consumer's base layer that a consumer would want to edit. It belongs in the override layer, or it will be destroyed on the next update.
- Never let an unrecognised commit type block a release. The type sets the size of a bump, never whether one happens.

## Decision Checklist

Before opening a PR, confirm:

- [ ] No existing file already covers this content (would be duplication).
- [ ] Prose lives in `standards/`, `playbooks/`, or `core/.context/` — not in a per-agent file.
- [ ] If a new standard or playbook: added to `core/.context/index.md` and (for standards) the table in `core/AGENTS.md`.
- [ ] If a deploy script change: both `scripts/deploy.sh` and `scripts/deploy.ps1` updated, and tested against a scratch directory — never against this repo.
- [ ] If a deploy script change: `shellcheck --severity=warning` is clean, and no bash 4+ syntax, GNU-only utilities, or PowerShell 7-only syntax was introduced.
- [ ] If an update or migrate script change: the bash and PowerShell versions were run against the same fixture and their output trees diffed for parity.
- [ ] If a new file now ships to consumers: `is_deployable` in `scripts/ci/next-version.sh` was updated, or it will never trigger a release.
- [ ] If consumers must act to upgrade: `MIGRATIONS.md` has a section for it.
- [ ] No hand-edits to `VERSION`, `CHANGELOG.md` or `scripts/baselines/<version>.sha256`.
- [ ] If a new agent: redirect file added under `core/`, both deploy scripts updated, README table updated.
- [ ] British English, kebab-case, prescriptive language.
- [ ] No engagement artefacts or generated deploy outputs in the diff.
