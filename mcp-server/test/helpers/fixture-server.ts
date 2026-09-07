/**
 * Minimal static file HTTP server used by tests to stand in for
 * raw.githubusercontent.com (or a team's published fork) without touching
 * the network. Serves files from a fixture directory and tracks how many
 * times each path was requested, so tests can assert on caching behaviour.
 */

import { createServer, type Server } from "node:http";
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import type { AddressInfo } from "node:net";

export interface FixtureServer {
  url: string;
  requestCounts: Record<string, number>;
  close(): Promise<void>;
}

export function startFixtureServer(rootDir: string): Promise<FixtureServer> {
  const requestCounts: Record<string, number> = {};
  let server: Server;

  return new Promise((resolvePromise, reject) => {
    server = createServer(async (req, res) => {
      const path = decodeURIComponent(req.url || "/").replace(/^\/+/, "");
      requestCounts[path] = (requestCounts[path] || 0) + 1;
      try {
        const data = await readFile(join(rootDir, path));
        res.writeHead(200, { "Content-Type": "text/plain" });
        res.end(data);
      } catch {
        res.writeHead(404, { "Content-Type": "text/plain" });
        res.end("Not Found");
      }
    });

    server.on("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const address = server.address() as AddressInfo;
      resolvePromise({
        url: `http://127.0.0.1:${address.port}`,
        requestCounts,
        close: () => new Promise((res) => server.close(() => res())),
      });
    });
  });
}
