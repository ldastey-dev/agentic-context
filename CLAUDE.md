# agent-contexts

Template repository for AI agent configuration, standards, playbooks, and skills.

## Structure

- `core/` — always-in-context templates (Tier 1, copy to target repo root)
- `standards/` — detailed reference standards (Tier 3, copy to target standards/)
- `skills/` — Claude Code skills (Tier 2, copy to target .claude/skills/)

## Deployment

Run `./deploy.sh /path/to/target-repo` to copy templates.
Then fill in all `[CONFIGURE]` sections in `AGENTS.md` and `CLAUDE.md`.

## Conventions

- British English throughout (optimisation, behaviour, colour)
- Kebab-case file names
- Standards use `## N · Section Title` heading style (middle dot separator)
- `[CONFIGURE]` in headings marks project-specific sections
- `<!-- PROJECT: ... -->` HTML comments mark inline customisation points
- SOLID principles always use full names in text (never SRP, OCP, etc.)
- All instructions prescriptive: "must", "never", "always"
- No emoji unless explicitly requested
- Examples and guidance should be programming language agnostic where possible, or use multiple language examples if necessary
