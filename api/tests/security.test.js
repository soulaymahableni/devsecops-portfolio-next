jest.mock("../src/db", () => ({
  message: { create: jest.fn(async ({ data }) => ({ id: 1, ...data })) },
}));

const request = require("supertest");
const app = require("../src/app");
const prisma = require("../src/db");

let n = 0;
const post = () =>
  request(app).post("/api/contact").set("X-Forwarded-For", `10.0.0.${++n}`);

const valid = { name: "Soulayma", email: "test@example.com", message: "Bonjour, ceci est un test" };

describe("Entrées invalides", () => {
  test("corps vide -> 400", async () => {
    expect((await post().send({})).status).toBe(400);
  });
  test("email invalide -> 400", async () => {
    expect((await post().send({ ...valid, email: "pas-un-email" })).status).toBe(400);
  });
  test("nom trop court -> 400", async () => {
    expect((await post().send({ ...valid, name: "S" })).status).toBe(400);
  });
  test("message trop long -> 400", async () => {
    expect((await post().send({ ...valid, message: "a".repeat(2001) })).status).toBe(400);
  });
  test("champ inconnu refusé (strict) -> 400", async () => {
    expect((await post().send({ ...valid, admin: true })).status).toBe(400);
  });
  test("types incorrects -> 400", async () => {
    expect((await post().send({ name: 123, email: [], message: {} })).status).toBe(400);
  });
});

describe("Requêtes malformées", () => {
  test("JSON cassé -> 400 JSON mal formé", async () => {
    const res = await post().set("Content-Type", "application/json").send('{"name":');
    expect(res.status).toBe(400);
    expect(res.body.error).toBe("JSON mal formé");
  });
  test("corps trop volumineux -> 413", async () => {
    const res = await post().send({ ...valid, message: "a".repeat(20000) });
    expect(res.status).toBe(413);
  });
});

describe("Tentatives d'injection", () => {
  test("injection SQL : traitée comme du texte, jamais exécutée", async () => {
    const payload = "Robert'); DROP TABLE \"Message\";--";
    const res = await post().send({ ...valid, name: payload });
    expect(res.status).toBe(201);
    expect(prisma.message.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ name: payload }),
    });
  });
  test("réponse sans stack trace", async () => {
    const res = await post().set("Content-Type", "application/json").send("{bad");
    expect(JSON.stringify(res.body)).not.toMatch(/at .*\.js/);
  });
});

describe("Rate limiting", () => {
  test("la 6e requête depuis la même IP -> 429", async () => {
    const codes = [];
    for (let i = 0; i < 6; i++) {
      const r = await request(app)
        .post("/api/contact")
        .set("X-Forwarded-For", "203.0.113.50")
        .send(valid);
      codes.push(r.status);
    }
    expect(codes.slice(0, 5).every((c) => c === 201)).toBe(true);
    expect(codes[5]).toBe(429);
  });
});
