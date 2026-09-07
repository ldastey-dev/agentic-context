# Agentic Context MCP Server

An [MCP (Model Context Protocol)](https://modelcontextprotocol.io/) server that serves standards, playbooks, and conventions from the agentic-context library on demand. Connect any AI agent to this server instead of deploying files into every repository.

## How it works

There is no git clone and no build-time content bundling. The server fetches markdown files over plain HTTPS at request time and caches them in memory for a few hours:

- **By default**, it fetches from `raw.githubusercontent.com` for this repo's `main` branch — always current, zero setup.
- **To use your own fork on a static host**, set `CONTENT_BASE_URL` to wherever you publish it (Azure Static Web Apps, Azure Blob Storage static website, GitHub Pages, etc.), as long as the published files mirror this repo's layout (`core/AGENTS.md`, `core/.context/index.md`, `core/.context/conventions/*.md`, `standards/*.md`, `playbooks/**/*.md`).
- **To use a private Azure DevOps repo**, set `CONTENT_SOURCE_TYPE=azure-devops` instead — see [Using a private Azure DevOps repo](#using-a-private-azure-devops-repo) below. No publish step needed; content is read straight from the repo via the Git Items API.
- The list of available standards/playbooks/conventions is derived from `.context/index.md` itself — there's no separate manifest to keep in sync, and no directory-listing API dependency, so this works against any plain static file host or the Azure DevOps API.

## Quick Start

No clone, no build, no content directory. Run it directly:

```bash
npx agentic-context-mcp
```

Or install it globally:

```bash
npm install -g agentic-context-mcp
agentic-context-mcp
```

Either way, the process reads MCP requests on stdin/stdout — you'll normally never invoke it manually. Instead, run [`init`](#one-shot-setup-init) below to wire up your agent automatically, or configure it by hand (see [Agent Configuration](#agent-configuration-manual-reference)).

## One-Shot Setup (`init`)

`agentic-context-mcp init` is the MCP equivalent of the agentic-context repo's `deploy.sh` — instead of copying ~70 markdown files into your repo, it wires up the MCP server and writes a lean `AGENTS.md`:

```bash
npx agentic-context-mcp init --agents all
```

This writes, for each selected agent:

- An MCP-flavoured `AGENTS.md` at the repo root (mandated standards + an MCP-specific "Context System" section instructing the agent to use `search`/`get_standard`/`get_playbook`/`get_convention` — **not** the file-based `deploy.sh` instructions).
- Thin per-agent redirect files (`CLAUDE.md`, `.cursor/rules/standards.mdc`, `.windsurfrules`, `.github/copilot-instructions.md`, `.devin/devin.json`) pointing at that `AGENTS.md`.
- The agent's MCP server registration (`.mcp.json`, `.cursor/mcp.json`, `.vscode/mcp.json`, `.devin/mcp_config.json`) — merged into any existing config rather than overwriting it, so other MCP servers you've already registered are preserved.

Windsurf's MCP config is global (`~/.codeium/windsurf/mcp_config.json`), not project-scoped, so `init` prints the snippet to add manually instead of writing to your home directory.

Options:

```bash
# Target a specific directory instead of the current one
npx agentic-context-mcp init /path/to/repo --agents claude cursor

# Point at your own published fork instead of upstream
npx agentic-context-mcp init --agents all --content-base-url https://your-team-host/agentic-context

# Skip files that already exist instead of overwriting them
npx agentic-context-mcp init --agents all --no-overwrite

# Point at a private Azure DevOps repo instead (PAT via env var, never a CLI arg)
AZURE_DEVOPS_PAT=*** npx agentic-context-mcp init --agents all --source-type azure-devops \
  --azure-org my-org --azure-project my-project --azure-repo agentic-context
```

Run `init` only once per repo — after that, editing standards/playbooks upstream (or in your fork) is picked up automatically by the running server, no need to re-run `init`. Re-run it only if you add/remove agents or change the content source.

## Configuration

| Env var | Default | Purpose |
| ------- | ------- | ------- |
| `CONTENT_BASE_URL` | `https://raw.githubusercontent.com/ldastey-dev/agentic-context/main` | Base URL content is fetched from (plain static host). Point this at your own published fork. Ignored when `CONTENT_SOURCE_TYPE=azure-devops`. |
| `CONTENT_SOURCE_TYPE` | `raw` | `raw` (fetch `CONTENT_BASE_URL` as a static file host) or `azure-devops` (fetch via the Azure DevOps Git Items API — see below). |
| `CONTENT_AUTH_TOKEN` | _(none)_ | Optional bearer token sent with `raw` requests, for a static host that requires auth. |
| `CACHE_TTL_MINUTES` | `240` (4 hours) | How long fetched files are cached in memory before being re-fetched. |
| `AZURE_DEVOPS_ORG` | _(required for azure-devops)_ | Azure DevOps organisation name (the segment right after `dev.azure.com/`). |
| `AZURE_DEVOPS_PROJECT` | _(required for azure-devops)_ | Azure DevOps project name. |
| `AZURE_DEVOPS_REPO` | _(required for azure-devops)_ | Azure Repos Git repository name. |
| `AZURE_DEVOPS_PAT` | _(required for azure-devops)_ | Personal Access Token with **Code (Read)** scope. Sent as HTTP Basic auth; never logged. |
| `AZURE_DEVOPS_BRANCH` | `main` | Branch/ref to read content from. |
| `AZURE_DEVOPS_API_VERSION` | `7.1` | Azure DevOps REST API version, in case you need to pin an older one. |

## Using a private Azure DevOps repo

If your fork of this repo's content lives in a private Azure Repos Git repository (Azure DevOps Services, `dev.azure.com`), point the server at it directly — no static-site publish step required, since the server reads files straight from the repo via the [Git Items REST API](https://learn.microsoft.com/en-us/rest/api/azure/devops/git/items/get?view=azure-devops-rest-7.1).

1. **Create a PAT** in Azure DevOps (User Settings → Personal Access Tokens) scoped to **Code (Read)** only, for the project containing the repo.
2. **Configure the server** with these env vars instead of `CONTENT_BASE_URL`:

   ```json
   {
     "mcpServers": {
       "agentic-context": {
         "command": "npx",
         "args": ["-y", "agentic-context-mcp"],
         "env": {
           "CONTENT_SOURCE_TYPE": "azure-devops",
           "AZURE_DEVOPS_ORG": "my-org",
           "AZURE_DEVOPS_PROJECT": "my-project",
           "AZURE_DEVOPS_REPO": "agentic-context",
           "AZURE_DEVOPS_BRANCH": "main",
           "AZURE_DEVOPS_PAT": "${file:.devin/credentials/agentic-context}"
         }
       }
     }
   }
   ```

   Or use `init` to generate this for you — see [One-Shot Setup](#one-shot-setup-init). `init` never takes the PAT as a CLI argument (that would leak into shell history); it reads `AZURE_DEVOPS_PAT` from the environment to fetch the `AGENTS.md` template during setup, then creates `.devin/credentials/agentic-context` (pre-filled with instructions and added to `.gitignore`) and writes a `${file:...}` reference into the generated MCP config. Replace the contents of `.devin/credentials/agentic-context` with your real PAT afterwards; the server resolves the file reference at startup so the PAT is never stored in the config JSON.
3. **Keep the PAT out of version control.** The `.devin/credentials/` folder is added to `.gitignore` by `init`. Treat the written `.mcp.json` / `.cursor/mcp.json` / etc. the same as any other file containing a secret if you instead embed the PAT directly, or store the PAT in your agent's secret-aware env-var mechanism instead of the JSON file if one is available.
4. **Rotate the PAT** before its expiry (Azure DevOps PATs expire; the server will start failing fetches with a 401/403 once it does — it falls back to serving stale cached content until the cache TTL runs out, then errors).

This is cloud Azure DevOps Services (`dev.azure.com`) only today; on-premises Azure DevOps Server / TFS uses a different base URL pattern and isn't supported.

## Publishing your own fork

If you've customised standards or playbooks for your project, publish the same directory layout as this repo to any static host that serves plain files over HTTPS:

```text
<your-static-host>/
  core/
    AGENTS.md
    .context/
      index.md
      conventions/{code,workflow,communication}.md
  standards/*.md
  playbooks/{assess,review,plan,refactor,docs,setup}/*.md
```

Then point your server at it:

```bash
CONTENT_BASE_URL=https://your-team.z13.web.core.windows.net/agentic-context npx -y agentic-context-mcp
```

Any CI step that copies these directories to Azure Static Web Apps / Blob Storage `$web` / GitHub Pages on every merge to your fork's default branch keeps the server's content current — no redeploy of the MCP server itself required, since it fetches fresh content up to the cache TTL.

For a **private** static host, add auth headers in front of it (e.g. an Azure Front Door / APIM rule that injects a key from a private network) — the server does a plain unauthenticated `fetch()`, so any access control needs to happen at the hosting layer, or ask to extend `ContentSource` with a header/token option if you need built-in auth support.

## Agent Configuration (manual reference)

`init` (above) writes these for you. Use this section if you'd rather configure an agent by hand, or need to see exactly what `init` produces.

All examples below use `npx -y agentic-context-mcp` so nothing needs to be installed up front — npm fetches and caches the package on first run. Swap in `agentic-context-mcp` directly (no `npx`) if you installed it globally.

### Claude Code

```bash
claude mcp add agentic-context -- npx -y agentic-context-mcp
```

With a custom content source:

```bash
claude mcp add agentic-context -e CONTENT_BASE_URL=https://your-team-host/agentic-context -- npx -y agentic-context-mcp
```

Or in `.mcp.json`:

```json
{
  "mcpServers": {
    "agentic-context": {
      "command": "npx",
      "args": ["-y", "agentic-context-mcp"],
      "env": {
        "CONTENT_BASE_URL": "https://your-team-host/agentic-context"
      }
    }
  }
}
```

### Cursor

In `.cursor/mcp.json` (project) or `~/.cursor/mcp.json` (global):

```json
{
  "mcpServers": {
    "agentic-context": {
      "command": "npx",
      "args": ["-y", "agentic-context-mcp"]
    }
  }
}
```

### Windsurf

In `~/.codeium/windsurf/mcp_config.json`:

```json
{
  "mcpServers": {
    "agentic-context": {
      "command": "npx",
      "args": ["-y", "agentic-context-mcp"]
    }
  }
}
```

### Devin

```bash
devin mcp add agentic-context -- npx -y agentic-context-mcp
```

Or in `.devin/mcp_config.json`:

```json
{
  "mcpServers": {
    "agentic-context": {
      "command": "npx",
      "args": ["-y", "agentic-context-mcp"]
    }
  }
}
```

### GitHub Copilot (VS Code)

In `.vscode/mcp.json`:

```json
{
  "servers": {
    "agentic-context": {
      "command": "npx",
      "args": ["-y", "agentic-context-mcp"]
    }
  }
}
```

## CLI Commands

| Command | Purpose |
| ------- | ------- |
| `agentic-context-mcp` | Start the MCP server (stdio). This is what your agent config should invoke. |
| `agentic-context-mcp init [target-dir] [--agents ...]` | One-shot setup: writes `AGENTS.md`, per-agent redirects, and MCP registration into a repo. See [One-Shot Setup](#one-shot-setup-init). |
| `agentic-context-mcp --help` / `-h` | Print usage and the content-source env vars. |
| `agentic-context-mcp init --help` / `-h` | Print `init`'s options, including the Azure DevOps flags. |

## Available Tools (server)

| Tool | Description |
| ---- | ----------- |
| `search` | Keyword search across all content — returns matching standards, playbooks, and conventions ranked by relevance |
| `get_index` | Full context index (keyword routing table) |
| `get_agents_config` | AGENTS.md template with mandated standards and `[CONFIGURE]` sections |
| `list_standards` | List all available coding standards |
| `get_standard` | Fetch a specific standard by name (e.g. `security`, `testing`, `dotnet`) |
| `list_playbooks` | List all playbooks, optionally filtered by category |
| `get_playbook` | Fetch a specific playbook by category and name (e.g. `assess` + `security`) |
| `list_conventions` | List all conventions (code, workflow, communication) |
| `get_convention` | Fetch a specific convention by name |

## Development (working on the server itself)

The `npx`/global-install instructions above are for *using* the server. If you're changing the server's own code, clone this repo and work from `mcp-server/`:

```bash
cd mcp-server
npm install

# Run without a build step
npm run dev

# Build and test with MCP Inspector
npm run build
npx @modelcontextprotocol/inspector node build/cli.js
```

Since content is fetched live from the network (not bundled), editing a standard/playbook in the repo and pushing it is immediately visible to any running server once the cache TTL expires — no rebuild, no republish of this package needed for content changes. Publishing a new version of `agentic-context-mcp` to npm is only required when the server's own code (tools, caching logic, etc.) changes.

### Tests

```bash
npm test
```

Runs on Node's built-in test runner (`node:test`, via `tsx`) — no extra test framework dependency. `pretest` builds the project first, since the CLI tests spawn the compiled binary (`build/cli.js`) as a real child process, mirroring how the agentic-context repo's own `tests/test-deploy.sh` invokes `deploy.sh` as a black box and asserts on its output.

| File | Covers |
| ---- | ------ |
| `test/content.test.ts` | `ContentSource` — fetching, manifest parsing from `index.md`, search ranking, in-memory caching |
| `test/content-stale-fallback.test.ts` | Serving stale cached content instead of throwing when a refetch fails |
| `test/fetchers.test.ts` | `RawUrlFetcher` / `AzureDevOpsFetcher` / `createFetcher` — URL construction, Basic/Bearer auth headers, env var fallback, missing-config errors |
| `test/init.test.ts` | `init` — AGENTS.md transformation, per-agent redirects, MCP config JSON merge (including preserving unrelated pre-existing servers), `--no-overwrite`, Windsurf's print-only path, the Azure DevOps source flow (PAT never leaks into the written config) |
| `test/cli.test.ts` | The built binary end-to-end: MCP handshake + `tools/list` + `tools/call` over stdio, the `init` subcommand writing real files, and `--help`/`init --help` |

Most tests run against a local fixture HTTP server (`test/helpers/fixture-server.ts`) serving `test/fixtures/repo/` — a minimal stand-in for this repo's layout — so the suite is fast, deterministic, and doesn't depend on GitHub being reachable. The exceptions: one test ("omits the env override when `--content-base-url` is not provided") deliberately exercises the real upstream default, and the Azure DevOps tests (`test/fetchers.test.ts`, and the `azure-devops source: ...` tests in `test/init.test.ts`) stub `global.fetch` directly instead, since there's no local Azure DevOps server to stand in for `dev.azure.com`.

Run just the `content`/`init` unit tests (skipping the slower CLI process-spawning tests) during development:

```bash
npm run test:unit
```

### Publishing a new version

Releases are published by [`.github/workflows/publish-mcp-server.yml`](../.github/workflows/publish-mcp-server.yml) whenever a tag matching `mcp-v*` is pushed, using [npm Trusted Publishing](https://docs.npmjs.com/trusted-publishers/) (OIDC) — no `NPM_TOKEN` secret involved.

```bash
cd mcp-server
npm version <patch|minor|major> --no-git-tag-version   # bumps package.json + package-lock.json only
git add package.json package-lock.json
git commit -m "chore(mcp-server): bump version to $(node -p "require('./package.json').version")"
git tag "mcp-v$(node -p "require('./package.json').version")"
git push && git push --tags
```

`npm version` normally creates a `vX.Y.Z` tag by default, which won't match the workflow's trigger — hence `--no-git-tag-version` plus tagging manually with the `mcp-v` prefix. Pushing that tag triggers the workflow, which builds, tests, and publishes.

**Prerelease versions (`0.1.0-beta.1`, `1.0.0-rc.1`, etc.) need a dist-tag.** npm refuses to guess one for any version containing a `-`, since it won't silently make a prerelease the `latest` install target — `npm publish` errors with `You must specify a tag using --tag when publishing a prerelease version.` if you don't pass one. The workflow handles this automatically (derives `beta`/`rc`/etc. from the version string, falls back to `latest` for plain releases), but if you ever publish manually, pass it yourself:

```bash
npm publish --tag beta   # or whatever the prerelease identifier is
```

Forgetting `--tag` on a prerelease is also caught by `npm publish --dry-run`, which is worth running locally before pushing a release tag.

**One-time setup required before this works** (only the npm package owner can do this):

1. **First publish must be manual.** A Trusted Publisher can only be configured for a package that already exists on npm, so the very first release has to be `npm publish` run locally by someone with publish rights. If `package.json`'s version is a prerelease at that point, remember `--tag` (above).
2. **Configure the Trusted Publisher** on the package's npmjs.com Settings page → "Trusted Publisher" → GitHub Actions, with:
   - Organization/user and repository set to this GitHub repo
   - Workflow filename: `publish-mcp-server.yml`
   - Environment name: left blank (not used here)

After that, all subsequent releases go through the tag-triggered workflow. Contributors without npm/repo-admin access can still open PRs that change the workflow itself — GitHub withholds secrets and OIDC tokens from fork-originated pull request runs, so the workflow only actually publishes once merged and run from the base repo.
