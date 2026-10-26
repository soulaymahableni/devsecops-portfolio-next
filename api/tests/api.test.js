jest.mock("../src/db", () => ({
  message: {
    create: jest.fn(async ({ data }) => ({ id: 1, ...data })),
  },
}));

const request = require("supertest");
const app = require("../src/app");

describe("Routes de l'API", () => {
  test("GET /api/health renvoie 200 et status ok", async () => {
    const res = await request(app).get("/api/health");
    expect(res.status).toBe(200);
    expect(res.body.status).toBe("ok");
  });

  test("GET /api/projects renvoie un tableau", async () => {
    const res = await request(app).get("/api/projects");
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  test("GET /api/skills renvoie un tableau", async () => {
    const res = await request(app).get("/api/skills");
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  test("Route inconnue renvoie 404", async () => {
    const res = await request(app).get("/api/inexistante");
    expect(res.status).toBe(404);
  });

  test("Helmet : pas de X-Powered-By", async () => {
    const res = await request(app).get("/api/health");
    expect(res.headers["x-powered-by"]).toBeUndefined();
    expect(res.headers["x-content-type-options"]).toBe("nosniff");
  });

  test("POST /api/contact valide renvoie 201", async () => {
    const res = await request(app)
      .post("/api/contact")
      .send({ name: "Soulayma", email: "test@example.com", message: "Bonjour, ceci est un test" });
    expect(res.status).toBe(201);
    expect(res.body.id).toBe(1);
  });
});
