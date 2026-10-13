const experiences = [
  { period: "2026", title: "Parcours DevSecOps", text: "Linux, Docker, Jenkins, Vagrant, Next.js, CI/CD." },
  { period: "2025", title: "Formation en informatique", text: "Réseaux, systèmes et développement web." },
];

export default function Experience() {
  return (
    <section id="experience" className="section">
      <h2>Experience</h2>
      <ul className="timeline">
        {experiences.map((e) => (
          <li key={e.title}>
            <strong>{e.period}</strong> — {e.title}
            <br />
            {e.text}
          </li>
        ))}
      </ul>
    </section>
  );
}
