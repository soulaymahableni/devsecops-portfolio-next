import { describe, test, expect, vi, afterEach } from "vitest";
import { tracedFetch } from "../lib/tracing";

afterEach(() => vi.restoreAllMocks());

describe("tracedFetch (Q227 : identifiant de correlation Next.js -> API)", () => {
  test("envoie l'identifiant de correlation fourni dans X-Request-Id", async () => {
    global.fetch = vi.fn().mockResolvedValue({ status: 200 });
    await tracedFetch("http://api.local/api/projects", { cache: "no-store" }, "req-12345678");
    const [url, init] = global.fetch.mock.calls[0];
    expect(url).toBe("http://api.local/api/projects");
    expect(init.cache).toBe("no-store");
    expect(init.headers.get("X-Request-Id")).toBe("req-12345678");
  });

  test("genere un identifiant quand aucun n'est fourni", async () => {
    global.fetch = vi.fn().mockResolvedValue({ status: 200 });
    await tracedFetch("http://api.local/api/skills");
    expect(global.fetch.mock.calls[0][1].headers.get("X-Request-Id")).toMatch(/^[\w-]{8,64}$/);
  });

  test("conserve les en-tetes existants et propage l'erreur reseau", async () => {
    global.fetch = vi.fn().mockRejectedValue(new Error("reseau coupe"));
    await expect(
      tracedFetch("http://api.local/api/contact", { method: "POST", headers: { "Content-Type": "application/json" } })
    ).rejects.toThrow("reseau coupe");
    expect(global.fetch.mock.calls[0][1].headers.get("Content-Type")).toBe("application/json");
  });
});
