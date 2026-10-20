import { projects as localProjects } from "@/data/projects";
import { skills as localSkills } from "@/data/skills";

// URL de l'API lue dans l'environnement (jamais codée en dur)
const API_URL = process.env.API_URL || "http://127.0.0.1:4000";

async function fetchFromApi(path, fallback) {
  try {
    const res = await fetch(`${API_URL}${path}`, { cache: "no-store" });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return { data: await res.json(), source: "api" };
  } catch (err) {
    console.error(`[API] ${path} indisponible (${err.message}) : données locales utilisées`);
    return { data: fallback, source: "local" };
  }
}

export const getProjects = () => fetchFromApi("/api/projects", localProjects);
export const getSkills = () => fetchFromApi("/api/skills", localSkills);

export async function getProject(slug) {
  const { data, source } = await getProjects();
  return { data: data.find((p) => p.slug === slug), source };
}

const localProfile = {
  name: "Soulayma Hableni",
  title: "Étudiante DevSecOps",
  about: "Étudiante passionnée par le DevOps et la sécurité des chaînes de livraison.",
};

export const getProfile = () => fetchFromApi("/api/profile", localProfile);
