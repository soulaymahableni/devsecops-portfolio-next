const express = require("express");
const cors = require("cors");
const { profile, projects, skills } = require("./data/portfolio");

const app = express();
const PORT = process.env.PORT || 4000;

app.disable("x-powered-by");
app.use(cors({ origin: process.env.CORS_ORIGIN || "*" }));
app.use(express.json());

// Étape 30
app.get("/api/health", (req, res) => {
  res.json({
    status: "ok",
    message: "API opérationnelle",
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});

// Étape 31
app.get("/api/profile", (req, res) => res.json(profile));

// Étape 32
app.get("/api/projects", (req, res) => res.json(projects));

// Détail d'un projet (utilisé par /projects/[slug])
app.get("/api/projects/:slug", (req, res) => {
  const project = projects.find((p) => p.slug === req.params.slug);
  if (!project) return res.status(404).json({ error: "Projet introuvable" });
  res.json(project);
});

// Étape 33
app.get("/api/skills", (req, res) => res.json(skills));

app.use((req, res) => res.status(404).json({ error: "Route introuvable" }));

app.listen(PORT, "0.0.0.0", () => {
  console.log(`API démarrée sur http://localhost:${PORT}`);
});
