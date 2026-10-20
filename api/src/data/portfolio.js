const profile = {
  name: "Soulayma Hableni",
  title: "Étudiante DevSecOps",
  about:
    "Étudiante passionnée par le DevOps et la sécurité des chaînes de livraison : Linux, Docker, Jenkins, Ansible, CI/CD.",
  email: "hablenisoulayma@gmail.com",
  github: "https://github.com/soulaymahableni",
  location: "Sousse, Tunisie",
};

const projects = [
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
  {
    slug: "ansible-automatisation",
    name: "Automatisation avec Ansible",
    summary: "Playbooks : paquets, Docker et Node.js.",
    description: "VM d'administration Ansible, inventory, playbooks idempotents pour installer curl, git, Docker et Node.js sur le serveur Ubuntu.",
    tech: ["Ansible", "SSH", "Ubuntu Server"],
  },
  {
    slug: "api-express",
    name: "API Node.js / Express",
    summary: "API REST qui alimente le portfolio.",
    description: "Routes /api/health, /api/profile, /api/projects et /api/skills, conteneurisées et reliées au frontend avec Docker Compose.",
    tech: ["Node.js", "Express", "Docker Compose"],
  },
];

const skills = [
  { name: "Git", level: 85, description: "Gestion de versions, branches, push via SSH" },
  { name: "Docker", level: 80, description: "Images, conteneurs, Docker Compose" },
  { name: "Jenkins", level: 70, description: "Pipelines CI/CD déclaratifs" },
  { name: "Kubernetes", level: 55, description: "Orchestration de conteneurs" },
  { name: "Ansible", level: 60, description: "Automatisation de configuration" },
  { name: "Terraform", level: 50, description: "Infrastructure as Code" },
  { name: "Argo CD", level: 45, description: "Déploiement GitOps" },
  { name: "Next.js", level: 65, description: "Applications React côté serveur" },
  { name: "Node.js / Express", level: 60, description: "API REST" },
];

module.exports = { profile, projects, skills };
