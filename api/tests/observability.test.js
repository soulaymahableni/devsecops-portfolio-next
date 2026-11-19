// Q223 / Q227 : identifiant de correlation et continuite de trace
jest.mock("../src/db", () => ({
  message: { create: jest.fn(async ({ data }) => ({ id: 1, ...data })) },
}));

const request = require("supertest");
const app = require("../src/app");
const { withSpan } = require("../src/observability");

describe("Identifiant de correlation", () => {
  test("reutilise un X-Request-Id valide envoye par le frontend", async () => {
    const res = await request(app).get("/api/health").set("X-Request-Id", "front-req-12345678");
    expect(res.headers["x-request-id"]).toBe("front-req-12345678");
  });

  test("remplace un X-Request-Id invalide par un identifiant genere", async () => {
    const res = await request(app).get("/api/health").set("X-Request-Id", "<script>alert(1)</script>");
    expect(res.headers["x-request-id"]).toMatch(/^[\w-]{8,64}$/);
    expect(res.headers["x-request-id"]).not.toContain("script");
  });

  test("ignore un traceparent mal forme sans planter", async () => {
    const res = await request(app).get("/api/health").set("traceparent", "pas-un-traceparent");
    expect(res.status).toBe(200);
  });
});

describe("withSpan", () => {
  test("sans tracage actif, execute simplement la fonction", async () => {
    await expect(withSpan({}, "test", {}, async () => 42)).resolves.toBe(42);
  });

  test("propage l'erreur de la fonction", async () => {
    await expect(withSpan({}, "test", {}, async () => { throw new Error("boom"); })).rejects.toThrow("boom");
  });
});
