import Link from "next/link";
import { projects } from "@/data/projects";

export default function Projects({ limit }) {
  const list = limit ? projects.slice(0, limit) : projects;

  return (
    <section id="projects" className="section">
      <h2>Projects</h2>
      <div className="grid">
        {list.map((project) => (
          <article key={project.slug} className="card">
            <h3>{project.name}</h3>
            <p>{project.summary}</p>
            <p className="tags">
              {project.tech.map((t) => (
                <span key={t} className="tag">{t}</span>
              ))}
            </p>
            <Link href={`/projects/${project.slug}`}>Voir le projet →</Link>
          </article>
        ))}
      </div>
      {limit && (
        <p><Link href="/projects">Tous les projets →</Link></p>
      )}
    </section>
  );
}
