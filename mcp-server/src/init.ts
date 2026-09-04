/**
 * `agentic-context-mcp init` — the MCP equivalent of the agentic-context
 * repo's `deploy.sh`. Instead of copying ~70 markdown files into the target
 * repo, it:
 *
 *   1. Writes an MCP-flavoured `AGENTS.md` (derived from the canonical
 *      `core/AGENTS.md` template, with the file-based "Context System"
 *      section swapped for MCP tool-call instructions).
 *   2. Writes thin per-agent redirect files (CLAUDE.md, .cursor/rules/,
 *      .windsurfrules, .github/copilot-instructions.md, .devin/devin.json)
 *      pointing at that AGENTS.md.
 *   3. Registers the `agentic-context-mcp` server in each selected agent's
 *      MCP config file (merging into any existing config rather than
 *      clobbering it).
 *
 * Usage:
 *   npx agentic-context-mcp init [target-dir] [--agents claude cursor ...]
 *                                 [--content-base-url URL] [--overwrite|--no-overwrite]
 *
 *   # Point the generated MCP config at a private Azure DevOps repo instead
 *   # of a plain static host. The PAT itself is never taken as a CLI arg
 *   # (avoids shell-history leakage) — set AZURE_DEVOPS_PAT so `init` can
 *   # fetch the AGENTS.md template from it, then fill in the placeholder
 *   # left in the written MCP config yourself.
 *   AZURE_DEVOPS_PAT=*** npx agentic-context-mcp init --source-type azure-devops \
 *     --azure-org my-org --azure-project my-project --azure-repo agentic-context
 */

import { existsSync } from "node:fs";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { ContentSource } from "./content.js";
import { AZURE_DEVOPS_PAT_INSTRUCTIONS } from "./fetchers.js";

const VALID_AGENTS = ["claude", "copilot", "cursor", "devin", "windsurf"] as const;
type Agent = (typeof VALID_AGENTS)[number];

interface InitOptions {
  targetDir: string;
  agents: Agent[];
  overwrite: boolean | null; // null = warn-and-overwrite (no interactive prompt in a one-shot CLI)
  contentBaseUrl?: string;
  sourceType?: string;
  azureOrg?: string;
  azureProject?: string;
  azureRepo?: string;
  azureBranch?: string;
}

const MCP_CONTEXT_SYSTEM_SECTION = `## Context System

This project uses the \`agentic-context\` MCP server for on-demand access to standards, playbooks, and conventions. No files are deployed into this repository — you MUST use the MCP tools rather than assuming file paths exist or relying on prior knowledge of standards.

Before starting any non-trivial task:

1. Call the \`search\` tool with keywords describing the task (e.g. "security OWASP", "refactor code smell") to find relevant standards and playbooks.
2. Call \`get_standard\`, \`get_playbook\`, or \`get_convention\` to load the full content before proceeding.
3. If unsure what's available, call \`get_index\` for the full keyword routing table, or \`list_standards\` / \`list_playbooks\` / \`list_conventions\` to browse everything.

If the \`agentic-context\` MCP tools are not available in this session, stop and tell the user before proceeding — do not silently fall back to unaided judgement on standards that should be loaded from the MCP server.

---
`;

const MCP_STANDARDS_INTRO =
  "The following standards are non-negotiable. Do not weaken them. Detailed guidance is available via the `get_standard` tool — strip `.context/standards/` and `.md` from the path below to get the standard name (e.g. `.context/standards/code-quality.md` → `get_standard(\"code-quality\")`).";

const REDIRECT_NOTE =
  'This project uses the `agentic-context` MCP server for on-demand standards and playbooks. Call its tools (`search`, `get_standard`, `get_playbook`, `get_convention`) before starting any task — see `AGENTS.md` for details.';

export const INIT_HELP = `agentic-context-mcp init [target-dir] [options]

One-shot setup for a target repo — the MCP equivalent of the agentic-context
repo's deploy.sh. Writes an MCP-flavoured AGENTS.md, thin per-agent redirect
files, and the agentic-context MCP server registration for each selected
agent. Run once per repo; re-run only if you add/remove agents or change the
content source.

Arguments:
  target-dir                    Directory to write into (default: current directory)

Options:
  --agents <a b c... | all>     Agents to configure: ${VALID_AGENTS.join(" ")} (default: all)
  --overwrite                   Overwrite existing files without prompting
  --no-overwrite                Skip files that already exist instead of overwriting them
  --content-base-url <url>      Fetch content from a static host instead of upstream GitHub
  --source-type <type>          Content source: "raw" (default) or "azure-devops"
  --azure-org <name>            Azure DevOps organisation (azure-devops source only)
  --azure-project <name>        Azure DevOps project (azure-devops source only)
  --azure-repo <name>           Azure DevOps repository (azure-devops source only)
  --azure-branch <name>         Azure DevOps branch (default: main; azure-devops source only)
  -h, --help                    Show this help and exit

For the azure-devops source, the PAT is never passed as a CLI flag (it would
leak into shell history) — set the AZURE_DEVOPS_PAT environment variable
during init so it can fetch AGENTS.md. The generated .devin/credentials/agentic-context
file is pre-filled with instructions; replace its contents with your PAT
(Code (Read) scope). The credentials folder is added to .gitignore.

Examples:
  npx agentic-context-mcp init --agents all
  npx agentic-context-mcp init /path/to/repo --agents claude cursor
  npx agentic-context-mcp init --agents all --content-base-url https://your-team-host/agentic-context
  AZURE_DEVOPS_PAT=*** npx agentic-context-mcp init --source-type azure-devops \\
    --azure-org my-org --azure-project my-project --azure-repo agentic-context

See mcp-server/README.md in the agentic-context repo for full documentation.
`;

function parseArgs(argv: string[]): InitOptions {
  let targetDir = process.cwd();
  let agents: Agent[] = [];
  let overwrite: boolean | null = null;
  let contentBaseUrl = process.env.CONTENT_BASE_URL;
  let sourceType = process.env.CONTENT_SOURCE_TYPE;
  let azureOrg = process.env.AZURE_DEVOPS_ORG;
  let azureProject = process.env.AZURE_DEVOPS_PROJECT;
  let azureRepo = process.env.AZURE_DEVOPS_REPO;
  let azureBranch = process.env.AZURE_DEVOPS_BRANCH;

  const args = [...argv];
  while (args.length > 0) {
    const arg = args.shift()!;
    if (arg === "--agents") {
      while (args.length > 0 && !args[0].startsWith("--")) {
        const value = args.shift()!;
        if (value === "all") {
          agents.push(...VALID_AGENTS);
        } else if ((VALID_AGENTS as readonly string[]).includes(value)) {
          agents.push(value as Agent);
        } else {
          console.error(`[init] Unknown agent "${value}" — skipping. Valid: ${VALID_AGENTS.join(", ")}, all`);
        }
      }
    } else if (arg === "--overwrite") {
      overwrite = true;
    } else if (arg === "--no-overwrite") {
      overwrite = false;
    } else if (arg === "--content-base-url") {
      contentBaseUrl = args.shift();
    } else if (arg === "--source-type") {
      sourceType = args.shift();
    } else if (arg === "--azure-org") {
      azureOrg = args.shift();
    } else if (arg === "--azure-project") {
      azureProject = args.shift();
    } else if (arg === "--azure-repo") {
      azureRepo = args.shift();
    } else if (arg === "--azure-branch") {
      azureBranch = args.shift();
    } else if (!arg.startsWith("--")) {
      targetDir = resolve(arg);
    }
  }

  if (agents.length === 0) {
    agents = [...VALID_AGENTS];
  }
  agents = [...new Set(agents)];

  return { targetDir, agents, overwrite, contentBaseUrl, sourceType, azureOrg, azureProject, azureRepo, azureBranch };
}

async function writeFileGuarded(filePath: string, content: string, overwrite: boolean | null): Promise<void> {
  const exists = existsSync(filePath);
  if (exists && overwrite === false) {
    console.error(`[init] Skipped (already exists): ${filePath}`);
    return;
  }
  if (exists && overwrite === null) {
    console.error(`[init] Overwriting existing file (use --no-overwrite to skip instead): ${filePath}`);
  }
  await mkdir(dirname(filePath), { recursive: true });
  await writeFile(filePath, content, "utf-8");
  console.error(`[init] Wrote ${filePath}`);
}

/** Merge an MCP server entry into an existing JSON config file rather than clobbering it. */
async function mergeMcpConfig(
  filePath: string,
  rootKey: "mcpServers" | "servers",
  serverName: string,
  serverConfig: Record<string, unknown>
): Promise<void> {
  let existing: Record<string, unknown> = {};
  if (existsSync(filePath)) {
    try {
      existing = JSON.parse(await readFile(filePath, "utf-8"));
    } catch {
      console.error(`[init] Warning: ${filePath} exists but is not valid JSON — it will be overwritten.`);
      existing = {};
    }
  }

  const servers = (existing[rootKey] as Record<string, unknown>) || {};
  servers[serverName] = serverConfig;
  existing[rootKey] = servers;

  await mkdir(dirname(filePath), { recursive: true });
  await writeFile(filePath, JSON.stringify(existing, null, 2) + "\n", "utf-8");
  console.error(`[init] Updated ${filePath} (${rootKey}.${serverName})`);
}

async function writeAzureCredentialsFiles(options: InitOptions): Promise<void> {
  if (options.sourceType !== "azure-devops") return;

  const credentialsDir = join(options.targetDir, ".devin", "credentials");
  const credentialsFile = join(credentialsDir, "agentic-context");
  if (!existsSync(credentialsFile)) {
    await mkdir(credentialsDir, { recursive: true });
    await writeFile(credentialsFile, AZURE_DEVOPS_PAT_INSTRUCTIONS + "\n", "utf-8");
    console.error(`[init] Wrote ${credentialsFile}`);
  } else {
    console.error(`[init] Skipped (already exists): ${credentialsFile}`);
  }

  await ensureGitignoreEntry(options.targetDir, ".devin/credentials/");
}

async function ensureGitignoreEntry(targetDir: string, entry: string): Promise<void> {
  const gitignorePath = join(targetDir, ".gitignore");
  let content = "";
  if (existsSync(gitignorePath)) {
    content = await readFile(gitignorePath, "utf-8");
    if (content.includes(entry)) {
      console.error(`[init] .gitignore already ignores ${entry}`);
      return;
    }
    if (!content.endsWith("\n")) content += "\n";
  }
  content += entry + "\n";
  await writeFile(gitignorePath, content, "utf-8");
  console.error(`[init] Updated .gitignore to ignore ${entry}`);
}

const AZURE_DEVOPS_PAT_FILE_REF = "${file:.devin/credentials/agentic-context}";

function buildServerConfig(options: InitOptions): Record<string, unknown> {
  const config: Record<string, unknown> = {
    command: "npx",
    args: ["-y", "agentic-context-mcp"],
  };

  if (options.sourceType === "azure-devops") {
    const env: Record<string, string> = { CONTENT_SOURCE_TYPE: "azure-devops" };
    if (options.azureOrg) env.AZURE_DEVOPS_ORG = options.azureOrg;
    if (options.azureProject) env.AZURE_DEVOPS_PROJECT = options.azureProject;
    if (options.azureRepo) env.AZURE_DEVOPS_REPO = options.azureRepo;
    if (options.azureBranch) env.AZURE_DEVOPS_BRANCH = options.azureBranch;
    env.AZURE_DEVOPS_PAT = AZURE_DEVOPS_PAT_FILE_REF;
    config.env = env;
  } else if (options.contentBaseUrl) {
    config.env = { CONTENT_BASE_URL: options.contentBaseUrl };
  }

  return config;
}

/** Fetch the canonical AGENTS.md template and swap the file-based Context
 *  System section for MCP tool-call instructions. */
function transformAgentsMd(agentsMd: string): string {
  let result = agentsMd.replace(
    /## Context System[\s\S]*?\n---\n/,
    MCP_CONTEXT_SYSTEM_SECTION
  );
  result = result.replace(
    /The following standards are non-negotiable\. Do not weaken them\. Detailed guidance is in `\.context\/standards\/`\./,
    MCP_STANDARDS_INTRO
  );
  return result;
}

async function writeAgentsMd(source: ContentSource, options: InitOptions): Promise<void> {
  const template = await source.getAgentsConfig();
  const transformed = transformAgentsMd(template);
  await writeFileGuarded(join(options.targetDir, "AGENTS.md"), transformed, options.overwrite);
}

async function writeAgentRedirects(options: InitOptions): Promise<void> {
  const { targetDir, overwrite } = options;

  if (options.agents.includes("claude")) {
    const content = `# CLAUDE.md\n\nRead and apply \`AGENTS.md\` for project conventions and workflow rules.\n\n## Context System\n\n${REDIRECT_NOTE}\n`;
    await writeFileGuarded(join(targetDir, "CLAUDE.md"), content, overwrite);
  }

  if (options.agents.includes("cursor")) {
    const content = `Follow the rules defined in AGENTS.md at the repository root. That file is the\nsingle source of truth for all coding standards, architecture decisions, and\nworkflow conventions.\n\n${REDIRECT_NOTE}\n`;
    await writeFileGuarded(join(targetDir, ".cursor", "rules", "standards.mdc"), content, overwrite);
  }

  if (options.agents.includes("windsurf")) {
    const content = `# Windsurf Agent Rules\n\nFollow the rules defined in AGENTS.md. That file is the single source of truth\nfor all coding standards, architecture decisions, and workflow conventions.\n\n${REDIRECT_NOTE}\n`;
    await writeFileGuarded(join(targetDir, ".windsurfrules"), content, overwrite);
  }

  if (options.agents.includes("copilot")) {
    const content = `# GitHub Copilot Instructions\n\nRead and apply \`AGENTS.md\` for project conventions and workflow rules.\n\n${REDIRECT_NOTE}\n`;
    await writeFileGuarded(join(targetDir, ".github", "copilot-instructions.md"), content, overwrite);
  }

  if (options.agents.includes("devin")) {
    const devinJson = {
      agent_instructions: "AGENTS.md",
      repo_notes: {
        content: `This project uses the agentic-context MCP server for on-demand standards and playbooks. Call its tools (search, get_standard, get_playbook, get_convention) before starting any task. AGENTS.md is the single source of truth for project conventions.`,
      },
    };
    await writeFileGuarded(
      join(targetDir, ".devin", "devin.json"),
      JSON.stringify(devinJson, null, 2) + "\n",
      overwrite
    );
  }
}

async function writeMcpConfigs(options: InitOptions): Promise<void> {
  const { targetDir, agents } = options;
  const serverConfig = buildServerConfig(options);

  if (agents.includes("claude")) {
    await mergeMcpConfig(join(targetDir, ".mcp.json"), "mcpServers", "agentic-context", serverConfig);
  }

  if (agents.includes("cursor")) {
    await mergeMcpConfig(join(targetDir, ".cursor", "mcp.json"), "mcpServers", "agentic-context", serverConfig);
  }

  if (agents.includes("copilot")) {
    await mergeMcpConfig(join(targetDir, ".vscode", "mcp.json"), "servers", "agentic-context", serverConfig);
  }

  if (agents.includes("devin")) {
    await mergeMcpConfig(join(targetDir, ".devin", "mcp_config.json"), "mcpServers", "agentic-context", serverConfig);
  }

  if (agents.includes("windsurf")) {
    // Windsurf's MCP config is global (~/.codeium/windsurf/mcp_config.json), not
    // project-scoped — writing to a user's home directory from a project-scoped
    // CLI is surprising, so print the snippet instead of writing it.
    console.error(
      "[init] Windsurf reads MCP config from ~/.codeium/windsurf/mcp_config.json (global, not project-scoped)."
    );
    console.error("[init] Add this entry manually (or via Windsurf's Settings > Tools > Add Server):");
    console.error(
      JSON.stringify({ mcpServers: { "agentic-context": serverConfig } }, null, 2)
    );
  }
}

export async function runInit(argv: string[]): Promise<void> {
  if (argv.includes("--help") || argv.includes("-h")) {
    console.log(INIT_HELP);
    return;
  }

  const options = parseArgs(argv);
  const source = new ContentSource({
    baseUrl: options.contentBaseUrl,
    sourceType: options.sourceType,
    azureDevOps: {
      organization: options.azureOrg,
      project: options.azureProject,
      repository: options.azureRepo,
      branch: options.azureBranch,
    },
  });

  console.error(`[init] Target directory: ${options.targetDir}`);
  console.error(`[init] Agents: ${options.agents.join(", ")}`);
  console.error(`[init] Content source: ${source.describeSource()}`);
  console.error("");

  await writeAgentsMd(source, options);
  await writeAgentRedirects(options);
  await writeAzureCredentialsFiles(options);
  await writeMcpConfigs(options);

  console.error("");
  console.error("[init] Done. Next steps:");
  console.error("  1. Fill in the [CONFIGURE] sections in AGENTS.md.");
  if (options.sourceType === "azure-devops") {
    console.error(
      "  2. Paste your Azure DevOps PAT (Code (Read) scope) into .devin/credentials/agentic-context in this repo, replacing the instructions there. It is already gitignored."
    );
    console.error("  3. Restart your agent so it picks up the new MCP server registration.");
    console.error("  4. Verify with a search, e.g. ask your agent to search for \"security\".");
  } else {
    console.error("  2. Restart your agent so it picks up the new MCP server registration.");
    console.error("  3. Verify with a search, e.g. ask your agent to search for \"security\".");
  }
}
