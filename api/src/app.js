const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const { z } = require("zod");
const prisma = require("./db");
const { profile, projects, skills } = require("./data/portfolio");

const app = express();

app.disable("x-powered-by");
app.set("trust proxy", 1); // l'API est derrière le frontend Next (proxy)
app.use(helmet()); // Q50
app.use(cors({ origin: process.env.CORS_ORIGIN || "*" }));
app.use(express.json({ limit: "10kb" }));

// Routes existantes
app.get("/api/health", (req, res) => {
  res.json({
    status: "ok",
    message: "API opérationnelle",
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});
app.get("/api/profile", (req, res) => res.json(profile));
app.get("/api/projects", (req, res) => res.json(projects));
app.get("/api/projects/:slug", (req, res) => {
  const project = projects.find((p) => p.slug === req.params.slug);
  if (!project) return res.status(404).json({ error: "Projet introuvable" });
  res.json(project);
});
app.get("/api/skills", (req, res) => res.json(skills));

// Q51 : rate limiting sur la route sensible
const contactLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: Number(process.env.CONTACT_RATE_LIMIT || 5),
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Trop de requêtes, réessayez plus tard" },
});

// Q48 : validation stricte avec Zod
const contactSchema = z
  .object({
    name: z.string().trim().min(2).max(100),
    email: z.string().trim().email().max(150),
    message: z.string().trim().min(5).max(2000),
  })
  .strict(); // refuse les champs inconnus

// Q46 : POST /api/contact
app.post("/api/contact", contactLimiter, async (req, res, next) => {
  const result = contactSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(400).json({
      error: "Données invalides",
      details: result.error.issues.map((i) => ({
        field: i.path.join("."),
        message: i.message,
      })),
    });
  }
  // Q54 : l'enregistrement en base viendra ici
  try {
    const saved = await prisma.message.create({ data: result.data });
    res.status(201).json({ message: "Message reçu", id: saved.id });
  } catch (err) {
    next(err);
  }
});

app.use((req, res) => res.status(404).json({ error: "Route introuvable" }));

// Q49 : gestion centralisée des erreurs (en dernier)
app.use((err, req, res, next) => {
  if (err.type === "entity.parse.failed") {
    return res.status(400).json({ error: "JSON mal formé" });
  }
  if (err.type === "entity.too.large") {
    return res.status(413).json({ error: "Requête trop volumineuse" });
  }
  console.error(err);
  res.status(err.status || 500).json({ error: "Erreur interne du serveur" });
});

module.exports = app;
