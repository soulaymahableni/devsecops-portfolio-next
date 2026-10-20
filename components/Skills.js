import { getSkills } from "@/lib/api";
import DataSource from "@/components/DataSource";

export default async function Skills() {
  const { data: skills, source } = await getSkills();

  return (
    <section id="skills" className="section">
      <h2>DevSecOps Skills</h2>
      <DataSource source={source} />
      <div className="grid">
        {skills.map((skill) => (
          <div key={skill.name} className="card">
            <h3>{skill.name}</h3>
            <p>{skill.description}</p>
            <div className="bar" aria-label={`Niveau ${skill.level}%`}>
              <div className="bar-fill" style={{ width: `${skill.level}%` }} />
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
