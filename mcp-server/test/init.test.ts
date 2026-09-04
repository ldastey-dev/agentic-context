import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile, mkdir } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { runInit } from "../src/init.js";
import { startFixtureServer, type FixtureServer } from "./helpers/fixture-server.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const FIXTURES_DIR = join(__dirname, "fixtures", "repo");

let fixtureServer: FixtureServer;

before(async () => {
  fixtureServer = await startFixtureServer(FIXTURES_DIR);
});

after(async () => {
  await fixtureServer.close();
});

async function withTempDir(fn: (dir: string) => Promise<void>): Promise<void> {
  const dir = await mkdtemp(join(tmpdir(), "agentic-context-init-test-"));
  try {
    await fn(dir);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

/** Capture console.error output for the duration of fn, then restore it. */
async function captureStderr(fn: () => Promise<void>): Promise<string[]> {
  const logs: string[] = [];
  const original = console.error;
  console.error = (...args: unknown[]) => {
    logs.push(args.map(String).join(" "));
  };
  try {
    await fn();
  } finally {
    console.error = original;
  }
  return logs;
}

/**
 * Stub `global.fetch` to answer Azure DevOps Git Items API requests from the
 * local fixture directory instead of hitting dev.azure.com, so the
 * azure-devops init tests stay offline and deterministic. Also asserts every
 * request carries Basic auth with the expected PAT.
 */
async function withStubbedAzureDevOpsFetch(expectedPat: string, fn: () => Promise<void>): Promise<void> {
  const original = globalThis.fetch;
  globalThis.fetch = (async (url: string, init?: RequestInit) => {
    const parsed = new URL(url);
    assert.equal(parsed.hostname, "dev.azure.com");

    const headers = new Headers(init?.headers);
    const expectedAuth = `Basic ${Buffer.from(`:${expectedPat}`).toString("base64")}`;
    assert.equal(headers.get("authorization"), expectedAuth);

    const relativePath = parsed.searchParams.get("path")!.replace(/^\/+/, "");
    try {
      const text = await readFile(join(FIXTURES_DIR, relativePath), "utf-8");
      return new Response(text, { status: 200 });
    } catch {
      return new Response("Not found", { status: 404 });
    }
  }) as typeof fetch;

  try {
    await fn();
  } finally {
    globalThis.fetch = original;
  }
}

test("writes an MCP-flavoured AGENTS.md, replacing the file-based Context System section", async () => {
  await withTempDir(async (dir) => {
    await captureStderr(() =>
      runInit([dir, "--agents", "claude", "--content-base-url", fixtureServer.url])
    );

    const agentsMd = await readFile(join(dir, "AGENTS.md"), "utf-8");
    assert.match(agentsMd, /agentic-context` MCP server for on-demand access/);
    assert.match(agentsMd, /Call the `search` tool/);
    assert.doesNotMatch(agentsMd, /read `\.context\/index\.md` and load files/);
    // The rest of the template (mandated standards tables etc.) should survive untouched
    assert.match(agentsMd, /## Mandated Standards/);
    assert.match(agentsMd, /Simplicity First/);
  });
});

test("writes claude redirect file and registers the MCP server in .mcp.json", async () => {
  await withTempDir(async (dir) => {
    await captureStderr(() =>
      runInit([dir, "--agents", "claude", "--content-base-url", fixtureServer.url])
    );

    const claudeMd = await readFile(join(dir, "CLAUDE.md"), "utf-8");
    assert.match(claudeMd, /agentic-context` MCP server/);

    const mcpConfig = JSON.parse(await readFile(join(dir, ".mcp.json"), "utf-8"));
    const entry = mcpConfig.mcpServers["agentic-context"];
    assert.equal(entry.command, "npx");
    assert.deepEqual(entry.args, ["-y", "agentic-context-mcp"]);
  });
});

test("propagates --content-base-url into the written server's CONTENT_BASE_URL env", async () => {
  await withTempDir(async (dir) => {
    await captureStderr(() =>
      runInit([dir, "--agents", "cursor", "--content-base-url", fixtureServer.url])
    );

    const mcpConfig = JSON.parse(await readFile(join(dir, ".cursor", "mcp.json"), "utf-8"));
    assert.equal(mcpConfig.mcpServers["agentic-context"].env.CONTENT_BASE_URL, fixtureServer.url);
  });
});

test("omits the env override when --content-base-url is not provided", { timeout: 20000 }, async () => {
  // No --content-base-url here: this exercises the real default (upstream
  // GitHub) content source, so it needs network access, unlike the other
  // init tests which stay offline via the fixture server.
  await withTempDir(async (dir) => {
    await captureStderr(() => runInit([dir, "--agents", "cursor"]));

    const mcpConfig = JSON.parse(await readFile(join(dir, ".cursor", "mcp.json"), "utf-8"));
    const entry = mcpConfig.mcpServers["agentic-context"];
    assert.equal(entry.command, "npx");
    assert.equal(entry.env, undefined);
  });
});

test("writes .vscode/mcp.json under the 'servers' key for copilot", async () => {
  await withTempDir(async (dir) => {
    await captureStderr(() =>
      runInit([dir, "--agents", "copilot", "--content-base-url", fixtureServer.url])
    );

    const mcpConfig = JSON.parse(await readFile(join(dir, ".vscode", "mcp.json"), "utf-8"));
    assert.ok(mcpConfig.servers["agentic-context"]);
    assert.equal(mcpConfig.mcpServers, undefined);
  });
});

test("windsurf prints the config snippet instead of writing a project file", async () => {
  await withTempDir(async (dir) => {
    const logs = await captureStderr(() =>
      runInit([dir, "--agents", "windsurf", "--content-base-url", fixtureServer.url])
    );

    assert.ok(logs.some((l) => l.includes("~/.codeium/windsurf/mcp_config.json")));
    assert.ok(logs.some((l) => l.includes("agentic-context")));
  });
});

test("--no-overwrite skips files that already exist", async () => {
  await withTempDir(async (dir) => {
    const sentinel = "# SENTINEL — do not overwrite\n";
    await writeFile(join(dir, "AGENTS.md"), sentinel, "utf-8");

    await captureStderr(() =>
      runInit([dir, "--agents", "claude", "--content-base-url", fixtureServer.url, "--no-overwrite"])
    );

    const agentsMd = await readFile(join(dir, "AGENTS.md"), "utf-8");
    assert.equal(agentsMd, sentinel);
  });
});

test("overwrites by default when a file already exists", async () => {
  await withTempDir(async (dir) => {
    await writeFile(join(dir, "AGENTS.md"), "# stale content\n", "utf-8");

    await captureStderr(() =>
      runInit([dir, "--agents", "claude", "--content-base-url", fixtureServer.url])
    );

    const agentsMd = await readFile(join(dir, "AGENTS.md"), "utf-8");
    assert.match(agentsMd, /agentic-context` MCP server/);
  });
});

test("merging MCP config preserves unrelated pre-existing servers", async () => {
  await withTempDir(async (dir) => {
    await mkdir(dir, { recursive: true });
    await writeFile(
      join(dir, ".mcp.json"),
      JSON.stringify({ mcpServers: { "some-other-server": { command: "foo", args: ["bar"] } } }),
      "utf-8"
    );

    await captureStderr(() =>
      runInit([dir, "--agents", "claude", "--content-base-url", fixtureServer.url])
    );

    const mcpConfig = JSON.parse(await readFile(join(dir, ".mcp.json"), "utf-8"));
    assert.deepEqual(mcpConfig.mcpServers["some-other-server"], { command: "foo", args: ["bar"] });
    assert.ok(mcpConfig.mcpServers["agentic-context"]);
  });
});

test("running with --agents all configures every agent without throwing", async () => {
  await withTempDir(async (dir) => {
    await captureStderr(() =>
      runInit([dir, "--agents", "all", "--content-base-url", fixtureServer.url])
    );

    for (const file of [
      "AGENTS.md",
      "CLAUDE.md",
      join(".cursor", "rules", "standards.mdc"),
      ".windsurfrules",
      join(".github", "copilot-instructions.md"),
      join(".devin", "devin.json"),
      ".mcp.json",
      join(".cursor", "mcp.json"),
      join(".vscode", "mcp.json"),
      join(".devin", "mcp_config.json"),
    ]) {
      await assert.doesNotReject(
        readFile(join(dir, file), "utf-8"),
        `expected ${file} to be written`
      );
    }
  });
});

test("defaults to all agents when --agents is omitted", async () => {
  await withTempDir(async (dir) => {
    await captureStderr(() => runInit([dir, "--content-base-url", fixtureServer.url]));
    await assert.doesNotReject(readFile(join(dir, "CLAUDE.md"), "utf-8"));
    await assert.doesNotReject(readFile(join(dir, ".windsurfrules"), "utf-8"));
  });
});

test("azure-devops source: fetches AGENTS.md via the Git Items API and authenticates with the PAT", async () => {
  process.env.AZURE_DEVOPS_PAT = "test-pat";
  try {
    await withStubbedAzureDevOpsFetch("test-pat", () =>
      withTempDir(async (dir) => {
        await captureStderr(() =>
          runInit([
            dir,
            "--agents",
            "claude",
            "--source-type",
            "azure-devops",
            "--azure-org",
            "my-org",
            "--azure-project",
            "my-project",
            "--azure-repo",
            "agentic-context",
          ])
        );

        const agentsMd = await readFile(join(dir, "AGENTS.md"), "utf-8");
        assert.match(agentsMd, /agentic-context` MCP server for on-demand access/);
        assert.match(agentsMd, /## Mandated Standards/);
      })
    );
  } finally {
    delete process.env.AZURE_DEVOPS_PAT;
  }
});

test("azure-devops source: writes a file-reference PAT and credentials instructions, never the real PAT", async () => {
  process.env.AZURE_DEVOPS_PAT = "super-secret-pat";
  try {
    await withStubbedAzureDevOpsFetch("super-secret-pat", () =>
      withTempDir(async (dir) => {
        await captureStderr(() =>
          runInit([
            dir,
            "--agents",
            "claude",
            "--source-type",
            "azure-devops",
            "--azure-org",
            "my-org",
            "--azure-project",
            "my-project",
            "--azure-repo",
            "agentic-context",
            "--azure-branch",
            "release",
          ])
        );

        const mcpConfig = JSON.parse(await readFile(join(dir, ".mcp.json"), "utf-8"));
        const env = mcpConfig.mcpServers["agentic-context"].env;
        assert.equal(env.CONTENT_SOURCE_TYPE, "azure-devops");
        assert.equal(env.AZURE_DEVOPS_ORG, "my-org");
        assert.equal(env.AZURE_DEVOPS_PROJECT, "my-project");
        assert.equal(env.AZURE_DEVOPS_REPO, "agentic-context");
        assert.equal(env.AZURE_DEVOPS_BRANCH, "release");
        assert.equal(env.AZURE_DEVOPS_PAT, "${file:.devin/credentials/agentic-context}");
        assert.ok(!JSON.stringify(mcpConfig).includes("super-secret-pat"));

        const credentials = await readFile(join(dir, ".devin", "credentials", "agentic-context"), "utf-8");
        assert.match(credentials, /Code \(Read\) scope/);

        const gitignore = await readFile(join(dir, ".gitignore"), "utf-8");
        assert.ok(gitignore.includes(".devin/credentials/"));
      })
    );
  } finally {
    delete process.env.AZURE_DEVOPS_PAT;
  }
});

test("azure-devops source: prints a reminder to fill in the credentials file", async () => {
  process.env.AZURE_DEVOPS_PAT = "test-pat";
  try {
    await withStubbedAzureDevOpsFetch("test-pat", () =>
      withTempDir(async (dir) => {
        const logs = await captureStderr(() =>
          runInit([
            dir,
            "--agents",
            "claude",
            "--source-type",
            "azure-devops",
            "--azure-org",
            "my-org",
            "--azure-project",
            "my-project",
            "--azure-repo",
            "agentic-context",
          ])
        );

        assert.ok(logs.some((l) => l.includes(".devin/credentials/agentic-context")));
        assert.ok(logs.some((l) => l.includes("gitignored")));
      })
    );
  } finally {
    delete process.env.AZURE_DEVOPS_PAT;
  }
});
