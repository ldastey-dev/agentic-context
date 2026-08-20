/**
 * Black-box tests for the built CLI binary (build/cli.js), spawned as a real
 * child process — mirroring the style of the repo's own tests/test-deploy.sh
 * (invoke the real script, assert on real output/files) rather than testing
 * internals directly. Requires `npm run build` to have run first (see the
 * `pretest` script in package.json).
 */

import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { mkdtemp, readFile, rm, access } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { startFixtureServer, type FixtureServer } from "./helpers/fixture-server.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const FIXTURES_DIR = join(__dirname, "fixtures", "repo");
const CLI_PATH = join(__dirname, "..", "build", "cli.js");

let fixtureServer: FixtureServer;

before(async () => {
  try {
    await access(CLI_PATH);
  } catch {
    throw new Error(`${CLI_PATH} not found — run "npm run build" before the test suite.`);
  }
  fixtureServer = await startFixtureServer(FIXTURES_DIR);
});

after(async () => {
  await fixtureServer.close();
});

interface JsonRpcExchange {
  stdout: string;
  stderr: string;
}

/** Spawn the CLI, write newline-delimited JSON-RPC requests to stdin, and
 *  collect everything written to stdout/stderr before the process exits. */
function runServerRequests(requests: object[], env: Record<string, string> = {}): Promise<JsonRpcExchange> {
  return new Promise((resolvePromise, reject) => {
    const child = spawn(process.execPath, [CLI_PATH], {
      env: { ...process.env, ...env },
    });

    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => (stdout += chunk));
    child.stderr.on("data", (chunk) => (stderr += chunk));

    const timeout = setTimeout(() => {
      child.kill();
      reject(new Error(`Timed out waiting for CLI response. stderr so far: ${stderr}`));
    }, 10000);

    child.on("error", (err) => {
      clearTimeout(timeout);
      reject(err);
    });

    // Give the process a moment to start listening, then send requests and
    // close stdin so it doesn't hang around after replying.
    setTimeout(() => {
      for (const req of requests) {
        child.stdin.write(JSON.stringify(req) + "\n");
      }
      child.stdin.end();
    }, 300);

    child.on("close", () => {
      clearTimeout(timeout);
      resolvePromise({ stdout, stderr });
    });
  });
}

function parseJsonRpcLines(stdout: string): any[] {
  return stdout
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => JSON.parse(line));
}

test("starting with no subcommand serves the MCP protocol over stdio", async () => {
  const { stdout, stderr } = await runServerRequests(
    [
      {
        jsonrpc: "2.0",
        id: 1,
        method: "initialize",
        params: { protocolVersion: "2024-11-05", capabilities: {}, clientInfo: { name: "test", version: "1.0.0" } },
      },
      { jsonrpc: "2.0", method: "notifications/initialized" },
      { jsonrpc: "2.0", id: 2, method: "tools/list", params: {} },
    ],
    { CONTENT_BASE_URL: fixtureServer.url }
  );

  const messages = parseJsonRpcLines(stdout);
  const initResponse = messages.find((m) => m.id === 1);
  assert.equal(initResponse.result.serverInfo.name, "agentic-context");

  const toolsResponse = messages.find((m) => m.id === 2);
  const toolNames = toolsResponse.result.tools.map((t: { name: string }) => t.name).sort();
  assert.deepEqual(toolNames, [
    "get_agents_config",
    "get_convention",
    "get_index",
    "get_playbook",
    "get_standard",
    "list_conventions",
    "list_playbooks",
    "list_standards",
    "search",
  ]);

  assert.match(stderr, /Server started/);
  assert.match(stderr, new RegExp(fixtureServer.url.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));
});

test("search tool call returns matches fetched from CONTENT_BASE_URL", async () => {
  const { stdout } = await runServerRequests(
    [
      {
        jsonrpc: "2.0",
        id: 1,
        method: "initialize",
        params: { protocolVersion: "2024-11-05", capabilities: {}, clientInfo: { name: "test", version: "1.0.0" } },
      },
      { jsonrpc: "2.0", method: "notifications/initialized" },
      { jsonrpc: "2.0", id: 2, method: "tools/call", params: { name: "search", arguments: { query: "security" } } },
    ],
    { CONTENT_BASE_URL: fixtureServer.url }
  );

  const messages = parseJsonRpcLines(stdout);
  const searchResponse = messages.find((m) => m.id === 2);
  const text = searchResponse.result.content[0].text;
  assert.match(text, /standard: security/);
});

/** Spawn the CLI with plain args and collect stdout/stderr/exit code — for
 *  one-shot commands like `--help` that don't speak the MCP protocol. */
function runCli(args: string[]): Promise<{ stdout: string; stderr: string; exitCode: number }> {
  return new Promise((resolvePromise, reject) => {
    const child = spawn(process.execPath, [CLI_PATH, ...args]);
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => (stdout += chunk));
    child.stderr.on("data", (chunk) => (stderr += chunk));
    child.on("error", reject);
    child.on("close", (code) => resolvePromise({ stdout, stderr, exitCode: code ?? 1 }));
  });
}

test("--help prints usage without starting the server", async () => {
  const { stdout, stderr, exitCode } = await runCli(["--help"]);
  assert.equal(exitCode, 0);
  assert.match(stdout, /Usage:/);
  assert.match(stdout, /agentic-context-mcp init \[options\]/);
  assert.doesNotMatch(stderr, /Server started/);
});

test("-h is a shorthand for --help", async () => {
  const { stdout, exitCode } = await runCli(["-h"]);
  assert.equal(exitCode, 0);
  assert.match(stdout, /Usage:/);
});

test("init --help prints init's options without touching the network or filesystem", async () => {
  const { stdout, stderr, exitCode } = await runCli(["init", "--help"]);
  assert.equal(exitCode, 0);
  assert.match(stdout, /agentic-context-mcp init \[target-dir\] \[options\]/);
  assert.match(stdout, /--source-type <type>/);
  assert.match(stdout, /--azure-org <name>/);
  assert.match(stdout, /AZURE_DEVOPS_PAT/);
  assert.doesNotMatch(stderr, /\[init\]/); // no actual init work happened
});

test("`init` subcommand writes real files when invoked as a CLI", async () => {
  const dir = await mkdtemp(join(tmpdir(), "agentic-context-cli-init-"));
  try {
    const exitCode = await new Promise<number>((resolvePromise, reject) => {
      const child = spawn(
        process.execPath,
        [CLI_PATH, "init", dir, "--agents", "claude", "--content-base-url", fixtureServer.url],
        { stdio: ["ignore", "ignore", "ignore"] }
      );
      child.on("error", reject);
      child.on("close", (code) => resolvePromise(code ?? 1));
    });

    assert.equal(exitCode, 0);
    const agentsMd = await readFile(join(dir, "AGENTS.md"), "utf-8");
    assert.match(agentsMd, /agentic-context` MCP server/);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});
