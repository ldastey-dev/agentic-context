# Migrations

Upgrade notes for consumers of this library. Only versions that require you to
act appear here; ordinary releases are picked up by `update.sh` with no manual
step.

---

## Unversioned to 1.0.0 — the override model

If you deployed this library before it carried a `VERSION`, your deployment has
no `.context/manifest.json` and no `.context/overrides/`. This is a one-off
migration; every release after 1.0.0 is picked up by `update.sh` with no manual
step.

### What changed

Before 1.0.0, deploying was a one-way copy. Anything you edited afterwards was
yours, but the next deploy would either overwrite it or refuse to touch it, and
nothing could tell the difference between a file you had deliberately customised
and one you had never touched. In practice a deployment drifted from the library
and could never be safely refreshed.

From 1.0.0 the deployed tree is split in two:

| Layer | Path | Who owns it |
| --- | --- | --- |
| Base | `.context/standards/`, `.context/playbooks/`, `.context/conventions/`, `.context/index.md` | The library. Replaced wholesale on every update. |
| Overrides | `.context/overrides/` | You. Never touched by an update. |

Because the base is disposable, updating is a delete-and-recopy with no merge
and no conflicts. Because overrides sit outside it, your customisations survive
untouched. Divergence becomes structurally impossible rather than something you
have to detect and reconcile.

Your `AGENTS.md` gains a managed block. The start marker carries the version it
was written from, so it looks like `<!-- agentic-context:begin 1.0.0 -->`, and
the block ends with `<!-- agentic-context:end -->`. Both markers are required:
tooling that finds a begin marker without a matching end marker treats the file
as unmanaged and leaves it alone rather than guessing where the block stops.
Only that block is rewritten on update; everything above and below it is yours.

### Migrating

Commit or stash any outstanding work, pull the latest library, then re-run
deploy exactly as you did originally:

```bash
/path/to/agentic-context/scripts/deploy.sh --agents claude copilot /path/to/your-repo
```

```powershell
# Windows PowerShell 5.1 or PowerShell 7+
& C:\path\to\agentic-context\scripts\deploy.ps1 -Agents claude,copilot -TargetRepo C:\path\to\your-repo
```

The old root-level `./deploy.sh` and `.\deploy.ps1` still work and forward to
`scripts/`. Deploy detects the pre-versioning layout and runs the migration
first, then refreshes your agent files and skill wrappers as usual.

To preview the migration without deploying, or to migrate without touching
agent files, run it directly:

```bash
# Dry run first. Nothing is written.
/path/to/agentic-context/scripts/migrate.sh /path/to/your-repo

# When the report looks right:
/path/to/agentic-context/scripts/migrate.sh /path/to/your-repo --apply
```

```powershell
& C:\path\to\agentic-context\scripts\migrate.ps1 C:\path\to\your-repo -Apply
```

The migration:

1. Compares every deployed file against the `unversioned` baseline, which
   records every revision the library shipped before versioning. A file that
   matches any of them is recognised as untouched, whichever commit you
   deployed from.
2. Promotes each file you edited into `.context/overrides/`, preserving your
   content and marking it `mode: replace`.
3. Keeps an edited `index.md` as `.context/overrides/index.md` with
   `mode: extend`, so your routes survive and the library's new routes still
   reach you.
4. Moves files you added yourself into the override layer, where updates cannot
   remove them, and removes unedited files the library no longer ships.
5. Restores the base to pristine library content.
6. Writes `.context/manifest.json`, recording the agents your deployment
   serves, and installs `.context/bin/` tooling.
7. Converts `AGENTS.md`. If its framework sections (`## Context System` through
   `## Mandated Standards`) are as the library shipped them, they are replaced
   in place by the managed block, and your title and `[CONFIGURE]` sections are
   untouched. If you edited those sections, the managed block is prepended
   instead and your original content is kept below it for you to review.

It refuses to run on a dirty git tree, so every change it makes is reviewable
with `git diff` before you commit.

### After migrating

Two follow-ups may be worth doing by hand — the migration cannot make these
judgements for you:

- **Trim `AGENTS.md`**, only if the migration reported that it prepended the
  managed block. Delete the sections below it that the block now supplies.
- **Convert `mode: replace` to `mode: extend` where you can.** The migration is
  conservative and marks every promoted file `replace`, which pins the whole file
  and means you stop receiving library improvements to it. If your change was an
  addition rather than a contradiction, `extend` keeps the library version and
  appends yours. See `.context/overrides/README.md`.

The `unversioned` baseline is deliberately distinct from the per-release
`<version>.sha256` baselines, which record what each tagged release shipped. If
you deployed from a fork whose content never existed in this repository, pass
`--baseline` to point at a baseline you generated from the commit you actually
deployed. Without a baseline the migration cannot distinguish your edits from
library content and will not run.

### If you never edited anything

Migration is still worth running: it installs the manifest and update tooling
that let the deployment stay current. It will report no promotions and simply
convert the layout.
