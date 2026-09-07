/**
 * Agentic Context MCP Server
 *
 * Serves standards, playbooks, and conventions from the agentic-context
 * repository via the Model Context Protocol — fetched over plain HTTPS at
 * request time and cached in memory. No git clone, no build-time bundling.
 *
 * Content source:
 *   - CONTENT_BASE_URL env var (optional) — point at a team's own published
 *     fork (Azure Static Web Apps, Blob Storage static site, GitHub Pages,
 *     etc.), as long as it mirrors this repo's file layout.
 *   - CONTENT_SOURCE_TYPE=azure-devops (optional) — fetch from a private
 *     Azure Repos repo via the Git Items REST API instead. Requires
 *     AZURE_DEVOPS_ORG, AZURE_DEVOPS_PROJECT, AZURE_DEVOPS_REPO, and
 *     AZURE_DEVOPS_PAT (a PAT with Code (Read) scope); AZURE_DEVOPS_BRANCH
 *     defaults to "main".
 *   - Defaults to raw.githubusercontent.com for the upstream repo's main
 *     branch.
 *   - CACHE_TTL_MINUTES env var (optional, default 240 / 4 hours) controls
 *     how long fetched content is cached before being re-fetched.
 *
 * Transport: stdio (default for local MCP servers)
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { ContentSource } from "./content.js";

export async function startServer(): Promise<void> {
  const source = new ContentSource();

  const server = new McpServer({
    name: "agentic-context",
    version: "0.1.0",
  });

  // ---------------------------------------------------------------------------
  // Tool: search
  // ---------------------------------------------------------------------------
  server.registerTool(
    "search",
    {
      description:
        "Search the agentic-context knowledge base by keywords. Returns matching standards, playbooks, and conventions ranked by relevance. Use this when starting a task to find which standards and playbooks apply.",
      inputSchema: {
        query: z
          .string()
          .describe(
            "Space-separated keywords to search for (e.g. 'security OWASP', 'refactor code smell', 'testing coverage')"
          ),
      },
    },
    async ({ query }) => {
      try {
        const results = await source.search(query);
        if (results.length === 0) {
          return {
            content: [
              {
                type: "text" as const,
                text: `No matches found for "${query}". Try broader terms or use list_standards / list_playbooks to see all available content.`,
              },
            ],
          };
        }

        const formatted = results
          .map(
            (r) =>
              `[${r.relevance.toUpperCase()}] ${r.category}: ${r.name}${r.subcategory ? ` (${r.subcategory})` : ""}\n  Keywords: ${r.keywords} | Summary: ${r.summary}\n  -> Use get_${r.category} to load the full content`
          )
          .join("\n\n");

        return {
          content: [
            {
              type: "text" as const,
              text: `Found ${results.length} matches for "${query}":\n\n${formatted}`,
            },
          ],
        };
      } catch (err) {
        return {
          content: [{ type: "text" as const, text: `Search error: ${err}` }],
          isError: true,
        };
      }
    }
  );

  // ---------------------------------------------------------------------------
  // Tool: get_index
  // ---------------------------------------------------------------------------
  server.registerTool(
    "get_index",
    {
      description:
        "Get the full context index — the keyword routing table that maps task keywords to standards, playbooks, and conventions. Load this first to understand what content is available.",
      inputSchema: {},
    },
    async () => {
      try {
        const index = await source.getIndex();
        return { content: [{ type: "text" as const, text: index }] };
      } catch (err) {
        return {
          content: [{ type: "text" as const, text: `Error loading index: ${err}` }],
          isError: true,
        };
      }
    }
  );

  // ---------------------------------------------------------------------------
  // Tool: get_agents_config
  // ---------------------------------------------------------------------------
  server.registerTool(
    "get_agents_config",
    {
      description:
        "Get the AGENTS.md template — the lean project configuration file with mandated standards, core principles, and [CONFIGURE] sections for project-specific setup.",
      inputSchema: {},
    },
    async () => {
      try {
        const config = await source.getAgentsConfig();
        return { content: [{ type: "text" as const, text: config }] };
      } catch (err) {
        return {
          content: [{ type: "text" as const, text: `Error loading AGENTS.md: ${err}` }],
          isError: true,
        };
      }
    }
  );

  // ---------------------------------------------------------------------------
  // Tool: list_standards
  // ---------------------------------------------------------------------------
  server.registerTool(
    "list_standards",
    {
      description:
        "List all available coding standards (e.g. security, testing, code-quality, dotnet, react). Returns names and descriptions.",
      inputSchema: {},
    },
    async () => {
      try {
        const standards = await source.listStandards();
        const formatted = standards.map((s) => `- ${s.name}: ${s.summary}`).join("\n");
        return {
          content: [
            {
              type: "text" as const,
              text: `Available standards (${standards.length}):\n\n${formatted}\n\nUse get_standard with the name to load the full content.`,
            },
          ],
        };
      } catch (err) {
        return {
          content: [{ type: "text" as const, text: `Error listing standards: ${err}` }],
          isError: true,
        };
      }
    }
  );

  // ---------------------------------------------------------------------------
  // Tool: get_standard
  // ---------------------------------------------------------------------------
  server.registerTool(
    "get_standard",
    {
      description:
        "Get the full content of a specific coding standard. Standards contain prescriptive rules with Non-Negotiables and Decision Checklists.",
      inputSchema: {
        name: z
          .string()
          .describe(
            "Standard name without .md extension (e.g. 'security', 'testing', 'code-quality', 'dotnet', 'react')"
          ),
      },
    },
    async ({ name }) => {
      try {
        const content = await source.getStandard(name);
        return { content: [{ type: "text" as const, text: content }] };
      } catch {
        const standards = await source.listStandards();
        const available = standards.map((s) => s.name).join(", ");
        return {
          content: [
            {
              type: "text" as const,
              text: `Standard "${name}" not found. Available standards: ${available}`,
            },
          ],
          isError: true,
        };
      }
    }
  );

  // ---------------------------------------------------------------------------
  // Tool: list_playbooks
  // ---------------------------------------------------------------------------
  server.registerTool(
    "list_playbooks",
    {
      description:
        "List all available playbooks organised by category (assess, review, plan, refactor, docs, setup). Returns names, categories, and descriptions.",
      inputSchema: {
        category: z
          .string()
          .optional()
          .describe(
            "Optional category filter: 'assess', 'review', 'plan', 'refactor', 'docs', or 'setup'"
          ),
      },
    },
    async ({ category }) => {
      try {
        const playbooks = await source.listPlaybooks(category);

        const grouped: Record<string, typeof playbooks> = {};
        for (const p of playbooks) {
          const cat = p.subcategory || "other";
          if (!grouped[cat]) grouped[cat] = [];
          grouped[cat].push(p);
        }

        const formatted = Object.entries(grouped)
          .map(([cat, items]) => {
            const list = items.map((p) => `  - ${p.name}: ${p.summary}`).join("\n");
            return `### ${cat}\n${list}`;
          })
          .join("\n\n");

        return {
          content: [
            {
              type: "text" as const,
              text: `Available playbooks (${playbooks.length}):\n\n${formatted}\n\nUse get_playbook with category and name to load the full content.`,
            },
          ],
        };
      } catch (err) {
        return {
          content: [{ type: "text" as const, text: `Error listing playbooks: ${err}` }],
          isError: true,
        };
      }
    }
  );

  // ---------------------------------------------------------------------------
  // Tool: get_playbook
  // ---------------------------------------------------------------------------
  server.registerTool(
    "get_playbook",
    {
      description:
        "Get the full content of a specific playbook. Playbooks are step-by-step procedures for assessments, reviews, planning, refactoring, docs generation, or setup tasks.",
      inputSchema: {
        category: z
          .string()
          .describe(
            "Playbook category: 'assess', 'review', 'plan', 'refactor', 'docs', or 'setup'"
          ),
        name: z
          .string()
          .describe(
            "Playbook name without .md extension (e.g. 'security', 'code-quality', 'safe-refactor')"
          ),
      },
    },
    async ({ category, name }) => {
      try {
        const content = await source.getPlaybook(category, name);
        return { content: [{ type: "text" as const, text: content }] };
      } catch {
        const playbooks = await source.listPlaybooks();
        const inCategory = playbooks.filter((p) => p.subcategory === category);
        if (inCategory.length > 0) {
          const available = inCategory.map((p) => p.name).join(", ");
          return {
            content: [
              {
                type: "text" as const,
                text: `Playbook "${name}" not found in category "${category}". Available in ${category}: ${available}`,
              },
            ],
            isError: true,
          };
        }
        const categories = [...new Set(playbooks.map((p) => p.subcategory))].join(", ");
        return {
          content: [
            {
              type: "text" as const,
              text: `Category "${category}" not found. Available categories: ${categories}`,
            },
          ],
          isError: true,
        };
      }
    }
  );

  // ---------------------------------------------------------------------------
  // Tool: list_conventions
  // ---------------------------------------------------------------------------
  server.registerTool(
    "list_conventions",
    {
      description:
        "List all available conventions (code, workflow, communication). These are style and process guidance documents.",
      inputSchema: {},
    },
    async () => {
      try {
        const conventions = await source.listConventions();
        const formatted = conventions.map((c) => `- ${c.name}: ${c.summary}`).join("\n");
        return {
          content: [
            {
              type: "text" as const,
              text: `Available conventions (${conventions.length}):\n\n${formatted}\n\nUse get_convention with the name to load the full content.`,
            },
          ],
        };
      } catch (err) {
        return {
          content: [{ type: "text" as const, text: `Error listing conventions: ${err}` }],
          isError: true,
        };
      }
    }
  );

  // ---------------------------------------------------------------------------
  // Tool: get_convention
  // ---------------------------------------------------------------------------
  server.registerTool(
    "get_convention",
    {
      description:
        "Get the full content of a specific convention document (code, workflow, or communication).",
      inputSchema: {
        name: z
          .string()
          .describe(
            "Convention name without .md extension: 'code', 'workflow', or 'communication'"
          ),
      },
    },
    async ({ name }) => {
      try {
        const content = await source.getConvention(name);
        return { content: [{ type: "text" as const, text: content }] };
      } catch {
        const conventions = await source.listConventions();
        const available = conventions.map((c) => c.name).join(", ");
        return {
          content: [
            {
              type: "text" as const,
              text: `Convention "${name}" not found. Available conventions: ${available}`,
            },
          ],
          isError: true,
        };
      }
    }
  );

  const transport = new StdioServerTransport();
  await server.connect(transport);
  // All logging must go to stderr — stdout is the MCP JSON-RPC channel
  console.error("[agentic-context-mcp] Server started");
  console.error(`[agentic-context-mcp] Content source: ${source.describeSource()}`);
}
