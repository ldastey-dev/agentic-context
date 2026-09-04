/**
 * Content source — fetches standards, playbooks, and conventions over plain
 * HTTPS from wherever they're published, with an in-memory TTL cache.
 *
 * No git clone, no build-time bundling, no local checkout required.
 *
 * Resolution (see fetchers.ts for the full precedence rules):
 *   - CONTENT_BASE_URL env var, if set, fetches from a plain static host.
 *     Point this at a team's own published fork (Azure Static Web Apps,
 *     Blob Storage static site, GitHub Pages, etc.) as long as it mirrors
 *     this repo's file layout.
 *   - CONTENT_SOURCE_TYPE=azure-devops switches to the Azure DevOps Git
 *     Items REST API instead, for teams whose fork lives in a private Azure
 *     Repos repo. Requires AZURE_DEVOPS_ORG, AZURE_DEVOPS_PROJECT,
 *     AZURE_DEVOPS_REPO, and AZURE_DEVOPS_PAT.
 *   - Otherwise defaults to raw.githubusercontent.com for this repo's main
 *     branch.
 *
 * The manifest of available standards/playbooks/conventions is derived from
 * `.context/index.md` itself (the keyword routing table already lists every
 * file with its keywords and summary) — no separate manifest file needed,
 * and no directory-listing API dependency, so this works against any plain
 * static file host.
 */

import { createFetcher, type AzureDevOpsFetcherOptions, type SourceFetcher } from "./fetchers.js";

const DEFAULT_CACHE_TTL_MINUTES = 240; // 4 hours

interface CacheEntry {
  text: string;
  fetchedAt: number;
}

export interface ManifestEntry {
  keywords: string;
  sourcePath: string;
  summary: string;
  category: "standard" | "playbook" | "convention" | "unknown";
  subcategory?: string;
  name: string;
}

export class ContentSource {
  private fetcher: SourceFetcher;
  private configError?: Error;
  private cacheTtlMs: number;
  private cache = new Map<string, CacheEntry>();
  private manifestCache: ManifestEntry[] | null = null;
  private manifestFetchedAt = 0;

  constructor(options?: {
    baseUrl?: string;
    cacheTtlMinutes?: number;
    fetcher?: SourceFetcher;
    sourceType?: string;
    authToken?: string;
    azureDevOps?: Partial<AzureDevOpsFetcherOptions>;
  }) {
    if (options?.fetcher) {
      this.fetcher = options.fetcher;
    } else {
      try {
        this.fetcher = createFetcher({
          baseUrl: options?.baseUrl,
          sourceType: options?.sourceType,
          authToken: options?.authToken,
          azureDevOps: options?.azureDevOps,
        });
      } catch (err) {
        this.configError = err as Error;
        this.fetcher = {
          describe: () => `unconfigured: ${this.configError!.message}`,
          fetch: async () => {
            throw this.configError!;
          },
        };
      }
    }

    const ttlMinutes =
      options?.cacheTtlMinutes ??
      Number(process.env.CACHE_TTL_MINUTES) ??
      DEFAULT_CACHE_TTL_MINUTES;
    this.cacheTtlMs = (Number.isFinite(ttlMinutes) && ttlMinutes > 0
      ? ttlMinutes
      : DEFAULT_CACHE_TTL_MINUTES) * 60 * 1000;
  }

  /** Human-readable description of the active content source, for logs. */
  describeSource(): string {
    return this.fetcher.describe();
  }

  /** Fetch a file at a repo-relative path, using the cache when fresh. */
  private async fetchFile(relativePath: string, forceFresh = false): Promise<string> {
    const cached = this.cache.get(relativePath);
    const isFresh = cached && Date.now() - cached.fetchedAt < this.cacheTtlMs;

    if (!forceFresh && isFresh) {
      return cached.text;
    }

    if (this.configError) throw this.configError;

    const description = `${this.fetcher.describe()}/${relativePath}`;
    let response: Response;
    try {
      response = await this.fetcher.fetch(relativePath);
    } catch (err) {
      if (cached) return cached.text; // serve stale on network failure
      throw new Error(`Failed to fetch ${description}: ${err}`);
    }

    if (!response.ok) {
      if (cached) return cached.text; // serve stale rather than fail hard
      throw new Error(`${response.status} ${response.statusText} fetching ${description}`);
    }

    const text = await response.text();
    this.cache.set(relativePath, { text, fetchedAt: Date.now() });
    return text;
  }

  async getIndex(): Promise<string> {
    return this.fetchFile("core/.context/index.md");
  }

  async getAgentsConfig(): Promise<string> {
    return this.fetchFile("core/AGENTS.md");
  }

  async getStandard(name: string): Promise<string> {
    return this.fetchFile(`standards/${name}.md`);
  }

  async getPlaybook(category: string, name: string): Promise<string> {
    return this.fetchFile(`playbooks/${category}/${name}.md`);
  }

  async getConvention(name: string): Promise<string> {
    return this.fetchFile(`core/.context/conventions/${name}.md`);
  }

  /** Parse `.context/index.md` into a structured manifest of every entry. */
  async getManifest(): Promise<ManifestEntry[]> {
    const isFresh =
      this.manifestCache && Date.now() - this.manifestFetchedAt < this.cacheTtlMs;
    if (isFresh) return this.manifestCache!;

    const index = await this.getIndex();
    const entries: ManifestEntry[] = [];

    for (const line of index.split("\n")) {
      const match = line.match(/^\|\s*(.+?)\s*\|\s*`(.+?)`\s*\|\s*(.+?)\s*\|$/);
      if (!match) continue;
      const [, keywords, targetPath, summary] = match;
      if (targetPath.startsWith("Keywords")) continue; // header row guard

      const entry = this.mapTargetPathToEntry(targetPath, keywords, summary);
      if (entry) entries.push(entry);
    }

    this.manifestCache = entries;
    this.manifestFetchedAt = Date.now();
    return entries;
  }

  /** Translate a target-repo path from index.md (e.g. `.context/standards/x.md`)
   *  into the source-repo-relative path and category/name metadata. */
  private mapTargetPathToEntry(
    targetPath: string,
    keywords: string,
    summary: string
  ): ManifestEntry | null {
    let category: ManifestEntry["category"] = "unknown";
    let sourcePath = "";
    let subcategory: string | undefined;
    let name = "";

    if (targetPath.startsWith(".context/standards/")) {
      category = "standard";
      const file = targetPath.slice(".context/standards/".length);
      sourcePath = `standards/${file}`;
      name = file.replace(/\.md$/, "");
    } else if (targetPath.startsWith(".context/playbooks/")) {
      category = "playbook";
      const rest = targetPath.slice(".context/playbooks/".length);
      const parts = rest.split("/");
      subcategory = parts[0];
      const file = parts.slice(1).join("/");
      sourcePath = `playbooks/${rest}`;
      name = file.replace(/\.md$/, "");
    } else if (targetPath.startsWith(".context/conventions/")) {
      category = "convention";
      const file = targetPath.slice(".context/conventions/".length);
      sourcePath = `core/.context/conventions/${file}`;
      name = file.replace(/\.md$/, "");
    } else {
      return null;
    }

    return { keywords, sourcePath, summary, category, subcategory, name };
  }

  async listStandards(): Promise<ManifestEntry[]> {
    const manifest = await this.getManifest();
    return manifest.filter((e) => e.category === "standard");
  }

  async listPlaybooks(category?: string): Promise<ManifestEntry[]> {
    const manifest = await this.getManifest();
    return manifest.filter(
      (e) => e.category === "playbook" && (!category || e.subcategory === category)
    );
  }

  async listConventions(): Promise<ManifestEntry[]> {
    const manifest = await this.getManifest();
    return manifest.filter((e) => e.category === "convention");
  }

  /** Keyword search across the manifest, ranked by how many terms match. */
  async search(
    query: string
  ): Promise<Array<ManifestEntry & { relevance: "high" | "medium" | "low" }>> {
    const manifest = await this.getManifest();
    const terms = query.toLowerCase().split(/\s+/).filter(Boolean);

    const results: Array<ManifestEntry & { relevance: "high" | "medium" | "low" }> = [];

    for (const entry of manifest) {
      const keywordList = entry.keywords.toLowerCase().split(",").map((k) => k.trim());
      const matchedTerms = terms.filter((term) => keywordList.some((k) => k.includes(term)));
      if (matchedTerms.length === 0) continue;

      const relevance =
        matchedTerms.length === terms.length
          ? "high"
          : matchedTerms.length > 1
            ? "medium"
            : "low";

      results.push({ ...entry, relevance });
    }

    const order = { high: 0, medium: 1, low: 2 };
    results.sort((a, b) => order[a.relevance] - order[b.relevance]);
    return results;
  }
}
