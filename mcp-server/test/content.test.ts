import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { ContentSource } from "../src/content.js";
import { AZURE_DEVOPS_PAT_INSTRUCTIONS } from "../src/fetchers.js";
import { startFixtureServer, type FixtureServer } from "./helpers/fixture-server.js";

async function withTempDir(fn: (dir: string) => Promise<void>): Promise<void> {
  const dir = await mkdtemp(join(tmpdir(), "agentic-context-content-"));
  try {
    await fn(dir);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

const __dirname = dirname(fileURLToPath(import.meta.url));
const FIXTURES_DIR = join(__dirname, "fixtures", "repo");

let fixtureServer: FixtureServer;

before(async () => {
  fixtureServer = await startFixtureServer(FIXTURES_DIR);
});

after(async () => {
  await fixtureServer.close();
});

test("getIndex fetches the context index", async () => {
  const source = new ContentSource({ baseUrl: fixtureServer.url });
  const index = await source.getIndex();
  assert.match(index, /Context Index/);
});

test("getAgentsConfig fetches AGENTS.md", async () => {
  const source = new ContentSource({ baseUrl: fixtureServer.url });
  const agents = await source.getAgentsConfig();
  assert.match(agents, /## Context System/);
});

test("getStandard fetches a standard's full content by name", async () => {
  const source = new ContentSource({ baseUrl: fixtureServer.url });
  const content = await source.getStandard("security");
  assert.match(content, /OWASP Top 10/);
});

test("getStandard rejects for a standard that doesn't exist", async () => {
  const source = new ContentSource({ baseUrl: fixtureServer.url });
  await assert.rejects(() => source.getStandard("does-not-exist"));
});

test("getPlaybook fetches a playbook by category and name", async () => {
  const source = new ContentSource({ baseUrl: fixtureServer.url });
  const content = await source.getPlaybook("assess", "security");
  assert.match(content, /Principal Security Engineer/);
});

test("getConvention fetches a convention by name", async () => {
  const source = new ContentSource({ baseUrl: fixtureServer.url });
  const content = await source.getConvention("code");
  assert.match(content, /Simplicity First/);
});

test("listStandards derives entries from the index manifest", async () => {
  const source = new ContentSource({ baseUrl: fixtureServer.url });
  const standards = await source.listStandards();
  const names = standards.map((s) => s.name).sort();
  assert.deepEqual(names, ["security", "testing"]);
  assert.ok(standards.every((s) => s.category === "standard"));
});

test("listPlaybooks filters by category and sets subcategory", async () => {
  const source = new ContentSource({ baseUrl: fixtureServer.url });
  const assessPlaybooks = await source.listPlaybooks("assess");
  assert.equal(assessPlaybooks.length, 1);
  assert.equal(assessPlaybooks[0].name, "security");
  assert.equal(assessPlaybooks[0].subcategory, "assess");

  const allPlaybooks = await source.listPlaybooks();
  assert.equal(allPlaybooks.length, 2);
});

test("listConventions derives entries from the index manifest", async () => {
  const source = new ContentSource({ baseUrl: fixtureServer.url });
  const conventions = await source.listConventions();
  assert.equal(conventions.length, 3);
  assert.ok(conventions.some((c) => c.name === "code"));
});

test("search ranks matches by how many terms hit the keyword list", async () => {
  const source = new ContentSource({ baseUrl: fixtureServer.url });
  const results = await source.search("security OWASP");
  assert.ok(results.length > 0);
  assert.equal(results[0].relevance, "high");
  assert.ok(results.some((r) => r.category === "standard" && r.name === "security"));
});

test("search returns an empty array when nothing matches", async () => {
  const source = new ContentSource({ baseUrl: fixtureServer.url });
  const results = await source.search("nonexistent-zzz-term");
  assert.equal(results.length, 0);
});

test("caches fetched content within the TTL window", async () => {
  const before = fixtureServer.requestCounts["standards/security.md"] || 0;
  const source = new ContentSource({ baseUrl: fixtureServer.url, cacheTtlMinutes: 60 });
  await source.getStandard("security");
  await source.getStandard("security");
  assert.equal(fixtureServer.requestCounts["standards/security.md"] - before, 1);
});

test("re-fetches once the cache TTL has expired", async () => {
  const before = fixtureServer.requestCounts["standards/testing.md"] || 0;
  const source = new ContentSource({ baseUrl: fixtureServer.url, cacheTtlMinutes: 1 / 60000 }); // ~1ms
  await source.getStandard("testing");
  await new Promise((r) => setTimeout(r, 30));
  await source.getStandard("testing");
  assert.equal(fixtureServer.requestCounts["standards/testing.md"] - before, 2);
});

test("the manifest itself is cached, not re-fetched per list call", async () => {
  const before = fixtureServer.requestCounts["core/.context/index.md"] || 0;
  const source = new ContentSource({ baseUrl: fixtureServer.url, cacheTtlMinutes: 60 });
  await source.listStandards();
  await source.listPlaybooks();
  await source.listConventions();
  await source.search("security");
  assert.equal(fixtureServer.requestCounts["core/.context/index.md"] - before, 1);
});

test("ContentSource starts and surfaces a clear error when the Azure DevOps PAT file is missing", async () => {
  await withTempDir(async (dir) => {
    const originalCwd = process.cwd();
    const originalEnv = { ...process.env };
    process.chdir(dir);
    try {
      process.env.CONTENT_SOURCE_TYPE = "azure-devops";
      process.env.AZURE_DEVOPS_ORG = "env-org";
      process.env.AZURE_DEVOPS_PROJECT = "env-project";
      process.env.AZURE_DEVOPS_REPO = "env-repo";
      process.env.AZURE_DEVOPS_PAT = "${file:missing-credentials}";

      const source = new ContentSource();
      assert.match(source.describeSource(), /unconfigured/);
      await assert.rejects(() => source.getIndex(), /missing-credentials/);
    } finally {
      process.chdir(originalCwd);
      process.env = originalEnv;
    }
  });
});

test("ContentSource starts and surfaces a clear error when the Azure DevOps PAT file still has placeholder instructions", async () => {
  await withTempDir(async (dir) => {
    await writeFile(join(dir, "agentic-context"), AZURE_DEVOPS_PAT_INSTRUCTIONS, "utf-8");

    const originalCwd = process.cwd();
    const originalEnv = { ...process.env };
    process.chdir(dir);
    try {
      process.env.CONTENT_SOURCE_TYPE = "azure-devops";
      process.env.AZURE_DEVOPS_ORG = "env-org";
      process.env.AZURE_DEVOPS_PROJECT = "env-project";
      process.env.AZURE_DEVOPS_REPO = "env-repo";
      process.env.AZURE_DEVOPS_PAT = "${file:agentic-context}";

      const source = new ContentSource();
      assert.match(source.describeSource(), /placeholder/);
      await assert.rejects(() => source.getAgentsConfig(), /placeholder/);
    } finally {
      process.chdir(originalCwd);
      process.env = originalEnv;
    }
  });
});
