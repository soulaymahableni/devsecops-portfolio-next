import Link from "next/link";
import { notFound } from "next/navigation";
import { projects, getProject } from "@/data/projects";

export function generateStaticParams() {
  return projects.map((p) => ({ slug: p.slug }));
}

export async function generateMetadata({ params }) {
  const { slug } = await params;
  const project = getProject(slug);
  return { title: project ? `${project.name} | DevSecOps Portfolio` : "Projet introuvable" };
}

export default async function ProjectPage({ params }) {
  const { slug } = await params;
  const project = getProject(slug);
  if (!project) notFound();

  return (
    <section className="section">
      <p><Link href="/projects">← Retour aux projets</Link></p>
      <h1>{project.name}</h1>
      <p>{project.description}</p>
      <p className="tags">
        {project.tech.map((t) => (
          <span key={t} className="tag">{t}</span>
        ))}
      </p>
    </section>
  );
}
