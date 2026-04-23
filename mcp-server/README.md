# agentic-context MCP server (planned)

This directory is the future home of an **optional** [Model Context Protocol](https://modelcontextprotocol.io) server that serves the agentic-context library (standards, playbooks, conventions, index) directly to agents over MCP, rather than via files copied into each consumer's repository.

**Status:** not yet implemented. This document describes the intended architecture so a contributor can pick it up and build it. Nothing here changes the current `deploy.sh` / `deploy.ps1` behaviour.

## Why this, and why later

The `deploy.sh` copy model is the right default today — any agent can read markdown from disk, no runtime required, everything auditable in the consumer's git history. The trade-off is fragmentation: every consumer repo keeps its own copy, and improvements to `.context/standards/security.md` do not propagate without re-running `update`.

MCP is the native transport for "context that many agents read". Once adoption is broad enough, a consumer can register an `agentic-context` MCP server and get the live, versioned library without vendoring. For agents that don't speak MCP, the copy-deploy remains.

This is sequenced deliberately:

1. **Now** (this PR): versioned deploy + lockfile + `update` subcommand. Solves the immediate pain of drift and update-clobbering without requiring a runtime.
2. **Later** (this directory): MCP server that exposes the same content as live resources. Copy-deploy and MCP coexist; consumers pick what matches their agents.

## Design

### Where it lives

**Same repo, this subdirectory.** Reasons:

- Content is the product; the server is a thin interface. Keeping them together means a single PR can update a standard and the server's exposure of it.
- No cross-repo coordination, no submodule pain.
- The repository already has a Bash/PowerShell install surface — adding an npm package as a sibling subdirectory does not impose anything on consumers who don't want the server.
- Consumers who only use `deploy.sh` can ignore `mcp-server/` entirely.

### Language and SDK

**TypeScript** with [`@modelcontextprotocol/sdk`](https://www.npmjs.com/package/@modelcontextprotocol/sdk). Rationale:

- First-class, well-supported MCP implementation.
- Thin dependency footprint — the server is essentially a file reader + URI router.
- `npx`-compatible distribution makes consumer integration one line in an MCP client config.

### Content model: resources, not tools

MCP exposes two primitives: **tools** (callable functions) and **resources** (fetchable content by URI). For this library, resources are the right fit — the content is static markdown, not dynamic computation.

URI scheme:

```
agentic-context://index                             — the routing index
agentic-context://standards/{name}                  — e.g. standards/security
agentic-context://playbooks/{category}/{name}       — e.g. playbooks/assess/security
agentic-context://conventions/{name}                — e.g. conventions/code
agentic-context://agents-md                         — the canonical AGENTS.md template
```

Each resource returns the file content as `text/markdown`.

An optional single **tool** may be worth adding for convenience:

- `match_keywords(query: string)` — replicates the keyword-matching behaviour of `.context/index.md`, returning a ranked list of resource URIs whose `keywords` frontmatter matches the query. This offloads the "which standards/playbooks are relevant?" decision from the agent's planning step to a fast deterministic lookup.

### Source of truth

The server reads directly from the sibling directories at the repo root:

- `../VERSION`
- `../core/.context/` (conventions + index)
- `../standards/`
- `../playbooks/`
- `../core/AGENTS.md`

There is **no build step that duplicates content** into `mcp-server/`. The markdown files remain the single source of truth for both the deploy path and the MCP path.

### Versioning

The server reports the same semver as `VERSION`. Clients can pin to a specific version via npm (`@agentic-context/mcp-server@^0.2`) for reproducibility, or follow the moving tag for live updates.

### Distribution

Publish as `@agentic-context/mcp-server` on npm. Consumer integration:

**Claude Code** — register in `.mcp.json` / `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "agentic-context": {
      "command": "npx",
      "args": ["-y", "@agentic-context/mcp-server@latest"]
    }
  }
}
```

**Cursor / Windsurf / other MCP clients** — analogous configuration in their MCP client settings.

### Out of scope (for the first cut)

- Writing / modifying content via MCP (the repo is the source of truth; edits happen via PRs, not via agents).
- Authentication. This is a read-only library of public engineering guidance; if a user ever needs a private variant, they fork or overlay.
- A Python implementation. TypeScript covers every major MCP client today. Revisit if a widely-used client emerges that needs Python hosting.

## Migration path from copy-deploy to MCP

Consumers adopt in stages, at their own pace:

1. **Today — copy-deploy only.** `./deploy.sh init` into the target repo; periodic `./deploy.sh update`.
2. **Hybrid.** Keep the deploy (agents that read files still work), and *additionally* register the MCP server in the agents that support it. Agents that use MCP get live content; agents that don't, use the copies.
3. **MCP-first.** For a consumer whose entire toolchain supports MCP, the deploy becomes optional — the MCP server is the single source. They may still run `./deploy.sh init` once to get `AGENTS.md` and the agent redirect stubs (configure-owned files), then never touch the standards or playbooks locally.

The deploy path is not deprecated in any of these stages. It remains the universal fallback.

## Implementation checklist (for the contributor who picks this up)

- [ ] `mcp-server/package.json` — declare `@agentic-context/mcp-server`, mark `bin`, target ESM, sensible engines range.
- [ ] `mcp-server/src/server.ts` — an MCP stdio server using `@modelcontextprotocol/sdk`.
- [ ] Resource listing: enumerate `../standards/*.md`, `../playbooks/*/*.md`, `../core/.context/conventions/*.md`, `../core/.context/index.md`, `../core/AGENTS.md`.
- [ ] Resource read: return file contents with `text/markdown` mime type.
- [ ] Optional `match_keywords` tool backed by YAML frontmatter parsing.
- [ ] `mcp-server/README.md` — update with user-facing install + config snippets once shipped.
- [ ] Add a `mcp-server/` section to the root `README.md` describing how to enable it in consuming agents.
- [ ] GitHub Actions: test on Node LTS; publish to npm on tagged releases.
- [ ] Version parity: the server reads `../VERSION` at runtime and advertises it in the MCP server info block.
