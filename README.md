# Branche GitOps du portfolio

Cette branche orpheline contient **uniquement les manifests** déployés par Argo CD
(namespaces `portfolio-dev`, `portfolio-staging` et `portfolio-prod`).
Elle remplace le second dépôt `devsecops-portfolio-gitops` : même principe,
historique séparé du code applicatif. Argo CD suit `targetRevision: gitops`.
