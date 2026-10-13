export const projects = [
  {
    slug: "mini-cv",
    name: "Mini CV One Page",
    summary: "CV en HTML5/CSS3/JavaScript versionné avec Git.",
    description: "Premier projet du parcours : une page unique de CV, publiée sur GitHub et poussée via une clé SSH.",
    tech: ["HTML5", "CSS3", "JavaScript", "Git"],
  },
  {
    slug: "portfolio-docker",
    name: "Portfolio dockerisé",
    summary: "Portfolio servi par Nginx dans un conteneur.",
    description: "Image Docker cv-docker basée sur Nginx, lancée avec docker run puis déployée avec Docker Compose.",
    tech: ["Docker", "Nginx", "Docker Compose"],
  },
  {
    slug: "vagrant-vm",
    name: "VM automatisée avec Vagrant",
    summary: "Création d'une VM Ubuntu Server par code.",
    description: "Vagrantfile configurant le nom, l'IP privée, la mémoire et le nombre de CPU de la VM.",
    tech: ["Vagrant", "Ubuntu Server", "VirtualBox"],
  },
  {
    slug: "portfolio-nextjs",
    name: "Portfolio Next.js",
    summary: "Migration du portfolio vers Next.js.",
    description: "Application composée de composants réutilisables, de données séparées et de pages dédiées aux projets.",
    tech: ["Next.js", "React", "JavaScript"],
  },
  {
    slug: "pipeline-jenkins",
    name: "Pipeline Jenkins",
    summary: "CI : checkout, installation, build.",
    description: "Jenkinsfile déclaratif qui récupère le dépôt GitHub, installe les dépendances npm et construit l'application.",
    tech: ["Jenkins", "Pipeline", "Node.js"],
  },
];

export function getProject(slug) {
  return projects.find((p) => p.slug === slug);
}
