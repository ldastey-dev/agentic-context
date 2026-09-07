import { test } from "node:test";
import assert from "node:assert/strict";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { ContentSource } from "../src/content.js";
import { startFixtureServer } from "./helpers/fixture-server.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const FIXTURES_DIR = join(__dirname, "fixtures", "repo");

// Isolated in its own file/server (rather than sharing content.test.ts's
// fixture server) because it deliberately takes the server down mid-test.
test("serves stale cached content when a refetch fails instead of throwing", async () => {
  const server = await startFixtureServer(FIXTURES_DIR);
  try {
    const source = new ContentSource({ baseUrl: server.url, cacheTtlMinutes: 1 / 60000 }); // ~1ms
    const first = await source.getConvention("code");

    await server.close();
    await new Promise((r) => setTimeout(r, 30));

    const second = await source.getConvention("code");
    assert.equal(second, first);
  } finally {
    // server may already be closed; ignore double-close errors
    await server.close().catch(() => {});
  }
});
