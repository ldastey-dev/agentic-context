/**
 * Source fetchers — pluggable strategies for retrieving a single repo-relative
 * file's raw contents over HTTPS. `ContentSource` (content.ts) owns caching,
 * manifest parsing, and search; it doesn't know or care which fetcher is
 * behind it.
 *
 * Two implementations ship today:
 *   - `RawUrlFetcher` — concatenates a base URL with the relative path.
 *     Works for raw.githubusercontent.com, GitHub Pages, Azure Static Web
 *     Apps, Blob Storage static sites, or any plain static file host.
 *     Optionally sends a bearer token for hosts that require auth.
 *   - `AzureDevOpsFetcher` — calls the Azure DevOps Git Items REST API
 *     (`_apis/git/repositories/{repo}/items?path=...`), which is required
 *     for private Azure Repos since there is no static raw-file endpoint.
 *     Authenticates with a PAT via HTTP Basic auth.
 */

import { readFileSync } from "node:fs";
import { resolve } from "node:path";

export interface SourceFetcher {
  /** Human-readable description of where content comes from, for logs. */
  describe(): string;
  /** Fetch a repo-relative file (e.g. "standards/security.md"). */
  fetch(relativePath: string): Promise<Response>;
}

export const AZURE_DEVOPS_PAT_INSTRUCTIONS = `Paste your Azure DevOps Personal Access Token (PAT) into this file, replacing these instructions. It needs only Code (Read) scope. This file is gitignored — do not commit it.`;

const DEFAULT_BASE_URL =
  "https://raw.githubusercontent.com/ldastey-dev/agentic-context/main";

export class RawUrlFetcher implements SourceFetcher {
  constructor(
    private readonly baseUrl: string,
    private readonly authToken?: string
  ) {}

  describe(): string {
    return this.baseUrl;
  }

  fetch(relativePath: string): Promise<Response> {
    const url = `${this.baseUrl}/${relativePath}`;
    const headers: Record<string, string> = {};
    if (this.authToken) headers.Authorization = `Bearer ${this.authToken}`;
    return fetch(url, { headers });
  }
}

export interface AzureDevOpsFetcherOptions {
  organization: string;
  project: string;
  repository: string;
  /** Branch/ref to read from. Defaults to "main". */
  branch?: string;
  /** Personal Access Token with at least Code (Read) scope. */
  pat: string;
  /** Azure DevOps REST API version. Defaults to "7.1". */
  apiVersion?: string;
}

export class AzureDevOpsFetcher implements SourceFetcher {
  private readonly branch: string;
  private readonly apiVersion: string;

  constructor(private readonly opts: AzureDevOpsFetcherOptions) {
    this.branch = opts.branch || "main";
    this.apiVersion = opts.apiVersion || "7.1";
  }

  describe(): string {
    return `azure-devops:${this.opts.organization}/${this.opts.project}/${this.opts.repository}@${this.branch}`;
  }

  fetch(relativePath: string): Promise<Response> {
    const { organization, project, repository, pat } = this.opts;
    const path = relativePath.startsWith("/") ? relativePath : `/${relativePath}`;

    const url =
      `https://dev.azure.com/${encodeURIComponent(organization)}/${encodeURIComponent(project)}` +
      `/_apis/git/repositories/${encodeURIComponent(repository)}/items` +
      `?path=${encodeURIComponent(path)}` +
      `&versionDescriptor.version=${encodeURIComponent(this.branch)}` +
      `&api-version=${this.apiVersion}&$format=text`;

    // Azure DevOps PATs authenticate over Basic auth with an empty username.
    const token = Buffer.from(`:${pat}`).toString("base64");
    return fetch(url, { headers: { Authorization: `Basic ${token}` } });
  }
}

export interface FetcherOptions {
  /** Plain static-host base URL. If set, always builds a RawUrlFetcher. */
  baseUrl?: string;
  /** Bearer token to send with RawUrlFetcher requests, if the host needs auth. */
  authToken?: string;
  /** "raw" (default) or "azure-devops". Ignored when `baseUrl` is set. */
  sourceType?: string;
  azureDevOps?: Partial<AzureDevOpsFetcherOptions>;
}

function resolveEnvReference(value?: string): string | undefined {
  if (!value) return value;
  const match = value.match(/^\$\{file:(.+)\}$/);
  if (!match) return value;
  const filePath = match[1];
  try {
    return readFileSync(resolve(filePath), "utf-8").replace(/\r?\n+$/, "");
  } catch (err) {
    throw new Error(`Failed to read file referenced by ${value}: ${filePath} — ${err}`);
  }
}

/**
 * Build a fetcher from explicit options, falling back to environment
 * variables for anything not passed in — mirroring the precedence already
 * used for `CONTENT_BASE_URL` (explicit option > env var > default).
 */
export function createFetcher(options?: FetcherOptions): SourceFetcher {
  if (options?.baseUrl) {
    return new RawUrlFetcher(
      options.baseUrl.replace(/\/+$/, ""),
      resolveEnvReference(options.authToken ?? process.env.CONTENT_AUTH_TOKEN)
    );
  }

  const sourceType = (options?.sourceType ?? process.env.CONTENT_SOURCE_TYPE ?? "raw").toLowerCase();

  if (sourceType === "azure-devops") {
    const organization = options?.azureDevOps?.organization ?? process.env.AZURE_DEVOPS_ORG;
    const project = options?.azureDevOps?.project ?? process.env.AZURE_DEVOPS_PROJECT;
    const repository = options?.azureDevOps?.repository ?? process.env.AZURE_DEVOPS_REPO;
    const branch = options?.azureDevOps?.branch ?? process.env.AZURE_DEVOPS_BRANCH;
    const rawPat = options?.azureDevOps?.pat ?? process.env.AZURE_DEVOPS_PAT;
    const pat = resolveEnvReference(rawPat);
    const apiVersion = options?.azureDevOps?.apiVersion ?? process.env.AZURE_DEVOPS_API_VERSION;

    if (pat && pat.includes(AZURE_DEVOPS_PAT_INSTRUCTIONS)) {
      throw new Error(
        "The Azure DevOps PAT is still the placeholder instructions. Replace the contents of .devin/credentials/agentic-context with your real PAT (Code (Read) scope)."
      );
    }

    const missing = [
      ["AZURE_DEVOPS_ORG", organization],
      ["AZURE_DEVOPS_PROJECT", project],
      ["AZURE_DEVOPS_REPO", repository],
      ["AZURE_DEVOPS_PAT", pat],
    ]
      .filter(([, value]) => !value)
      .map(([name]) => name);

    if (missing.length > 0) {
      throw new Error(
        `CONTENT_SOURCE_TYPE=azure-devops requires ${missing.join(", ")} to be set.`
      );
    }

    return new AzureDevOpsFetcher({
      organization: organization!,
      project: project!,
      repository: repository!,
      branch,
      pat: pat!,
      apiVersion,
    });
  }

  const baseUrl = process.env.CONTENT_BASE_URL ?? DEFAULT_BASE_URL;
  return new RawUrlFetcher(
    baseUrl.replace(/\/+$/, ""),
    resolveEnvReference(options?.authToken ?? process.env.CONTENT_AUTH_TOKEN)
  );
}
