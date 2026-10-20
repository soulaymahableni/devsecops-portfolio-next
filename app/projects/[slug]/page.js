import Link from "next/link";
import { notFound } from "next/navigation";
import { getProject } from "@/lib/api";
import DataSource from "@/components/DataSource";

export const dynamic = "force-dynamic";

export async function generateMetadata({ params }) {
  const { slug } = await params;
  const { data: project } = await getProject(slug);
  return { title: project ? `${project.name} | DevSecOps Portfolio` : "Projet introuvable" };
}

export default async function ProjectPage({ params }) {
  const { slug } = await params;
  const { data: project, source } = await getProject(slug);
  if (!project) notFound();

  return (
    <section className="section">
      <p><Link href="/projects">← Retour aux projets</Link></p>
      <h1>{project.name}</h1>
      <DataSource source={source} />
      <p>{project.description}</p>
      <p className="tags">
        {project.tech.map((t) => (
          <span key={t} className="tag">{t}</span>
        ))}
      </p>
    </section>
  );
}
