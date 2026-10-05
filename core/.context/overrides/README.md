# Overrides

This directory is **yours**. The framework never reads, writes or deletes anything in it.

Everything else under `.context/` is **base content**: it belongs to the framework, and
`update.sh` replaces it wholesale every time you take a new version. If you edit a base file
directly, your change is silently reverted on the next update.

Put your changes here instead. They survive every update, forever.

---

## How resolution works

Mirror the path of the file you want to change, relative to `.context/`.

| Base file | Your override |
| --- | --- |
| `.context/standards/security.md` | `.context/overrides/standards/security.md` |
| `.context/playbooks/review/code-quality.md` | `.context/overrides/playbooks/review/code-quality.md` |
| `.context/conventions/code.md` | `.context/overrides/conventions/code.md` |

When an agent is about to load a base file, it checks for the override first. If one exists,
the override takes precedence.

---

## The two modes

Every override declares what it does in YAML frontmatter.

### `mode: replace` — throw the base away

Use when the framework's version is wrong for you and you want your own rules entirely.

```markdown
---
overrides: standards/testing.md
mode: replace
---

# Testing Standard

We use a different model from the framework default. This file is the whole truth;
the base standard is ignored.

## Non-Negotiables

- Minimum coverage is 75%, measured on the service layer only.
```

### `mode: extend` — keep the base, layer on top

Use when the framework is broadly right and you want to tighten, relax or add to it. This is
the common case, and it is the one that ages best — you keep inheriting upstream improvements.

```markdown
---
overrides: standards/testing.md
mode: extend
---

## Coverage

Coverage minimum is **95%**, not the framework default of 90%.

## Additional Requirement

Every bug fix must ship with a regression test that fails without the fix.
```

The base standard loads first, then this file. Where the two conflict, this file wins.
Everything the base says that this file does not contradict still applies.

**Prefer `extend`.** A `replace` override is a permanent fork of that file: you stop receiving
upstream improvements to it entirely.

---

## Frontmatter reference

| Field | Required | Values | Meaning |
| --- | --- | --- | --- |
| `overrides` | Yes | Path relative to `.context/` | The base file this override applies to |
| `mode` | No | `replace` (default) or `extend` | Whether the base is discarded or layered under |

`overrides` must match the file's own location. `.context/overrides/standards/security.md`
must declare `overrides: standards/security.md`. `update.sh` warns when they disagree,
because a mismatch usually means a file was copied and the frontmatter was not updated.

---

## Adding something entirely new

An override does not have to correspond to a base file. To add a standard or playbook the
framework does not ship, put it here with no `overrides` field:

```markdown
---
name: standards-billing-domain
description: "Rules specific to our billing domain."
keywords: [billing, invoice, dunning, payment retry]
---
```

Then add a keyword route for it in your `AGENTS.md`, **outside** the managed block, so agents
can discover it. Do not add it to `.context/index.md` — that file is base content and your
edit would be reverted on the next update.

---

## What happens on update

`update.sh` will:

- Replace every base file under `.context/standards/`, `.context/playbooks/` and
  `.context/conventions/` with the new version.
- **Never touch this directory.**
- Report any base file you had edited directly, and restore it — with a pointer to the
  override path you should have used.
- Report standards and playbooks that were **added** or **removed** upstream. A removed base
  file whose override still exists is flagged: your override now points at nothing, so either
  delete it or convert it into a standalone addition.

---

## Checking your overrides

```bash
.context/bin/update.sh --check
```

Reports the current version, whether a newer one is available, and any override whose
`overrides:` target no longer exists.
