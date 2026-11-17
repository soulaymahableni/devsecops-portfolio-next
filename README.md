# Branche GitOps du portfolio

Contient uniquement les manifests suivis par Argo CD : `base/` et `overlays/{dev,staging,prod}`.
Les images viennent de Harbor et sont epinglees par empreinte (`@sha256`) : la meme image signee
est deployee dans les trois environnements. Les secrets ne sont jamais dans Git.
Argo CD suit `targetRevision: gitops` (branche orpheline, remplace le second depot).
