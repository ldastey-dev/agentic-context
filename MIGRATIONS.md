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

Your `AGENTS.md` gains a managed block delimited by
`<!-- agentic-context:begin -->` and `<!-- agentic-context:end -->`. Only that
block is rewritten on update; everything above and below it is yours.

### Migrating

Run the migration from the root of the repository that has the deployment:

```bash
# Dry run first. Nothing is written.
/path/to/agentic-context/scripts/migrate.sh .

# When the report looks right:
/path/to/agentic-context/scripts/migrate.sh . --apply
```

```powershell
# Windows PowerShell 5.1 or PowerShell 7+
& C:\path\to\agentic-context\scripts\migrate.ps1 . -Apply
```

The migration:

1. Compares every deployed file against the published `1.0.0` baseline, so it
   can tell a file you edited from one you never touched.
2. Promotes each edited file into `.context/overrides/`, preserving your content
   and marking it `mode: replace`.
3. Restores the base to pristine library content.
4. Moves files you added yourself into the override layer, where updates cannot
   remove them.
5. Writes `.context/manifest.json` and installs `.context/bin/` tooling.
6. Prepends the managed block to `AGENTS.md`, leaving your existing content
   below it untouched.

It refuses to run on a dirty git tree, so every change it makes is reviewable
with `git diff` before you commit.

### After migrating

Two follow-ups are worth doing by hand — the migration cannot make these
judgements for you:

- **Trim `AGENTS.md`.** Content that the managed block now supplies may still be
  duplicated below it. Delete the duplicates.
- **Convert `mode: replace` to `mode: extend` where you can.** The migration is
  conservative and marks every promoted file `replace`, which pins the whole file
  and means you stop receiving library improvements to it. If your change was an
  addition rather than a contradiction, `extend` keeps the library version and
  appends yours. See `.context/overrides/README.md`.

The migration compares against the `1.0.0` baseline by default, which hashes the
content this library shipped at the point versioning was introduced. If you
deployed from an older commit than that, some files will be reported as edited
when you never touched them — promote only the ones you recognise, or pass
`--baseline` to point at a baseline file you generated yourself from the commit
you actually deployed. Without a baseline the migration cannot distinguish your
edits from library content and will not run.

### If you never edited anything

Migration is still worth running: it installs the manifest and update tooling
that let the deployment stay current. It will report no promotions and simply
convert the layout.
