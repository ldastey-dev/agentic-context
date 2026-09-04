import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { AzureDevOpsFetcher, RawUrlFetcher, createFetcher } from "../src/fetchers.js";

async function withTempDir(fn: (dir: string) => Promise<void>): Promise<void> {
  const dir = await mkdtemp(join(tmpdir(), "agentic-context-fetchers-"));
  try {
    await fn(dir);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

/** Minimal Response stand-in so tests don't need a real network call. */
function fakeResponse(): Response {
  return new Response("content", { status: 200 });
}

test("RawUrlFetcher concatenates base URL and relative path", async () => {
  const requested: Array<{ url: string; headers: Headers }> = [];
  const originalFetch = globalThis.fetch;
  globalThis.fetch = (async (url: string, init?: RequestInit) => {
    requested.push({ url, headers: new Headers(init?.headers) });
    return fakeResponse();
  }) as typeof fetch;

  try {
    const fetcher = new RawUrlFetcher("https://example.com/repo");
    await fetcher.fetch("standards/security.md");
    assert.equal(requested[0].url, "https://example.com/repo/standards/security.md");
    assert.equal(requested[0].headers.get("authorization"), null);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("RawUrlFetcher sends a bearer token when one is configured", async () => {
  const requested: Array<{ headers: Headers }> = [];
  const originalFetch = globalThis.fetch;
  globalThis.fetch = (async (_url: string, init?: RequestInit) => {
    requested.push({ headers: new Headers(init?.headers) });
    return fakeResponse();
  }) as typeof fetch;

  try {
    const fetcher = new RawUrlFetcher("https://example.com/repo", "secret-token");
    await fetcher.fetch("standards/security.md");
    assert.equal(requested[0].headers.get("authorization"), "Bearer secret-token");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("RawUrlFetcher.describe returns the base URL", () => {
  const fetcher = new RawUrlFetcher("https://example.com/repo");
  assert.equal(fetcher.describe(), "https://example.com/repo");
});

test("AzureDevOpsFetcher builds the Git Items API URL with query params and Basic auth", async () => {
  const requested: Array<{ url: string; headers: Headers }> = [];
  const originalFetch = globalThis.fetch;
  globalThis.fetch = (async (url: string, init?: RequestInit) => {
    requested.push({ url, headers: new Headers(init?.headers) });
    return fakeResponse();
  }) as typeof fetch;

  try {
    const fetcher = new AzureDevOpsFetcher({
      organization: "my-org",
      project: "my-project",
      repository: "agentic-context",
      pat: "my-pat",
    });
    await fetcher.fetch("standards/security.md");

    const url = new URL(requested[0].url);
    assert.equal(url.origin, "https://dev.azure.com");
    assert.equal(url.pathname, "/my-org/my-project/_apis/git/repositories/agentic-context/items");
    assert.equal(url.searchParams.get("path"), "/standards/security.md");
    assert.equal(url.searchParams.get("versionDescriptor.version"), "main");
    assert.equal(url.searchParams.get("api-version"), "7.1");
    assert.equal(url.searchParams.get("$format"), "text");

    const expectedAuth = `Basic ${Buffer.from(":my-pat").toString("base64")}`;
    assert.equal(requested[0].headers.get("authorization"), expectedAuth);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("AzureDevOpsFetcher honours a custom branch and api version", async () => {
  const requested: string[] = [];
  const originalFetch = globalThis.fetch;
  globalThis.fetch = (async (url: string) => {
    requested.push(url);
    return fakeResponse();
  }) as typeof fetch;

  try {
    const fetcher = new AzureDevOpsFetcher({
      organization: "my-org",
      project: "my-project",
      repository: "agentic-context",
      pat: "my-pat",
      branch: "release",
      apiVersion: "7.0",
    });
    await fetcher.fetch("core/AGENTS.md");

    const url = new URL(requested[0]);
    assert.equal(url.searchParams.get("versionDescriptor.version"), "release");
    assert.equal(url.searchParams.get("api-version"), "7.0");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("AzureDevOpsFetcher.describe summarises org/project/repo/branch", () => {
  const fetcher = new AzureDevOpsFetcher({
    organization: "my-org",
    project: "my-project",
    repository: "agentic-context",
    pat: "my-pat",
    branch: "release",
  });
  assert.equal(fetcher.describe(), "azure-devops:my-org/my-project/agentic-context@release");
});

test("createFetcher builds a RawUrlFetcher when baseUrl is passed explicitly", () => {
  const fetcher = createFetcher({ baseUrl: "https://example.com/repo/" });
  assert.ok(fetcher instanceof RawUrlFetcher);
  assert.equal(fetcher.describe(), "https://example.com/repo"); // trailing slash stripped
});

test("createFetcher builds an AzureDevOpsFetcher when sourceType is azure-devops", () => {
  const fetcher = createFetcher({
    sourceType: "azure-devops",
    azureDevOps: {
      organization: "my-org",
      project: "my-project",
      repository: "agentic-context",
      pat: "my-pat",
    },
  });
  assert.ok(fetcher instanceof AzureDevOpsFetcher);
  assert.equal(fetcher.describe(), "azure-devops:my-org/my-project/agentic-context@main");
});

test("createFetcher throws a clear error when required Azure DevOps settings are missing", () => {
  assert.throws(
    () => createFetcher({ sourceType: "azure-devops", azureDevOps: { organization: "my-org" } }),
    /AZURE_DEVOPS_PROJECT.*AZURE_DEVOPS_REPO.*AZURE_DEVOPS_PAT/
  );
});

test("createFetcher reads Azure DevOps settings from environment variables as a fallback", () => {
  const originalEnv = { ...process.env };
  process.env.CONTENT_SOURCE_TYPE = "azure-devops";
  process.env.AZURE_DEVOPS_ORG = "env-org";
  process.env.AZURE_DEVOPS_PROJECT = "env-project";
  process.env.AZURE_DEVOPS_REPO = "env-repo";
  process.env.AZURE_DEVOPS_PAT = "env-pat";

  try {
    const fetcher = createFetcher();
    assert.equal(fetcher.describe(), "azure-devops:env-org/env-project/env-repo@main");
  } finally {
    process.env = originalEnv;
  }
});

test("createFetcher expands a ${file:path} reference in AZURE_DEVOPS_PAT", async () => {
  await withTempDir(async (dir) => {
    await writeFile(join(dir, "agentic-context"), "file-pat-value\n", "utf-8");

    const requested: Array<{ headers: Headers }> = [];
    const originalFetch = globalThis.fetch;
    globalThis.fetch = (async (_url: string, init?: RequestInit) => {
      requested.push({ headers: new Headers(init?.headers) });
      return new Response("content", { status: 200 });
    }) as typeof fetch;

    const originalCwd = process.cwd();
    const originalEnv = { ...process.env };
    process.chdir(dir);
    try {
      process.env.CONTENT_SOURCE_TYPE = "azure-devops";
      process.env.AZURE_DEVOPS_ORG = "env-org";
      process.env.AZURE_DEVOPS_PROJECT = "env-project";
      process.env.AZURE_DEVOPS_REPO = "env-repo";
      process.env.AZURE_DEVOPS_PAT = "${file:agentic-context}";

      const fetcher = createFetcher();
      await fetcher.fetch("core/AGENTS.md");
      const expectedAuth = `Basic ${Buffer.from(":file-pat-value").toString("base64")}`;
      assert.equal(requested[0].headers.get("authorization"), expectedAuth);
    } finally {
      process.chdir(originalCwd);
      process.env = originalEnv;
      globalThis.fetch = originalFetch;
    }
  });
});

test("createFetcher throws a clear error when a ${file:path} reference cannot be read", async () => {
  await withTempDir(async (dir) => {
    const originalCwd = process.cwd();
    const originalEnv = { ...process.env };
    process.chdir(dir);
    try {
      process.env.CONTENT_SOURCE_TYPE = "azure-devops";
      process.env.AZURE_DEVOPS_ORG = "env-org";
      process.env.AZURE_DEVOPS_PROJECT = "env-project";
      process.env.AZURE_DEVOPS_REPO = "env-repo";
      process.env.AZURE_DEVOPS_PAT = "${file:missing-pat.txt}";

      assert.throws(() => createFetcher(), /missing-pat\.txt/);
    } finally {
      process.chdir(originalCwd);
      process.env = originalEnv;
    }
  });
});
