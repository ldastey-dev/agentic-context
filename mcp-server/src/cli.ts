#!/usr/bin/env node

/**
 * CLI entry point for `agentic-context-mcp`.
 *
 * With no subcommand, starts the MCP server on stdio (the normal path when
 * an agent launches this as `npx -y agentic-context-mcp`).
 *
 * `agentic-context-mcp init [target-dir] [--agents ...]` runs the one-shot
 * setup equivalent of the agentic-context repo's `deploy.sh`, but configured
 * for MCP usage instead of copying files.
 *
 * `agentic-context-mcp --help` / `agentic-context-mcp init --help` print
 * usage without starting the server or touching the network.
 */

const HELP = `agentic-context-mcp — MCP server for agentic-context standards, playbooks, and conventions

Usage:
  agentic-context-mcp                 Start the MCP server on stdio (this is what your agent config should invoke)
  agentic-context-mcp init [options]  One-shot setup: writes AGENTS.md, per-agent redirects, and MCP registration into a repo
  agentic-context-mcp --help          Show this help
  agentic-context-mcp init --help     Show init's options

Content source (env vars, read by the server):
  CONTENT_BASE_URL          Base URL for a static host (default: raw.githubusercontent.com/ldastey-dev/agentic-context/main)
  CONTENT_SOURCE_TYPE       "raw" (default) or "azure-devops"
  CONTENT_AUTH_TOKEN        Optional bearer token for a private "raw" static host
  CACHE_TTL_MINUTES         Minutes to cache fetched content (default: 240)
  AZURE_DEVOPS_ORG/PROJECT/REPO/PAT/BRANCH/API_VERSION   Required when CONTENT_SOURCE_TYPE=azure-devops

See mcp-server/README.md in the agentic-context repo for full documentation.
`;

const [, , command, ...rest] = process.argv;

async function main() {
  if (command === "--help" || command === "-h") {
    console.log(HELP);
    return;
  }
  if (command === "init") {
    const { runInit } = await import("./init.js");
    await runInit(rest);
  } else {
    const { startServer } = await import("./server.js");
    await startServer();
  }
}

main().catch((err) => {
  console.error("[agentic-context-mcp] Fatal error:", err);
  process.exit(1);
});
