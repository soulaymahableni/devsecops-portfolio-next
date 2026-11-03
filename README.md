
---

# Activité 5 : GitHub Actions et sécurité GitHub (Q70–78)

## Q70 à Q73 : workflow CI

Le workflow `.github/workflows/ci.yml` se déclenche à chaque `push` sur `main` et à chaque Pull Request. Il contient six jobs :

| Job | Rôle | Outil |
|---|---|---|
| `tests-api` | Tests de l'API | Jest, Supertest |
| `tests-frontend` | Tests du frontend | Vitest |
| `secrets` | Détection de secrets | Gitleaks |
| `sast` | Analyse statique du code | Semgrep |
| `dependencies` | Contrôle des dépendances | `npm audit` (seuil critique) |
| `images` | Construction des deux images Docker puis scan | Docker, Trivy (CRITICAL, `--exit-code 1`) |

Le job `images` dépend des deux jobs de tests : si un test échoue, les images ne sont pas construites.

![Workflow GitHub Actions réussi](docs/captures/q70-github-actions-vert.png)

## Q74 : CodeQL et comparaison avec Semgrep

CodeQL est activé par le workflow `.github/workflows/codeql.yml` (push, Pull Request et analyse hebdomadaire). Il a levé une alerte **Permissive CORS configuration** (gravité moyenne) dans `api/src/app.js` : l'API autorisait toutes les origines (`*`). L'alerte a été corrigée en limitant l'origine par défaut (variable `CORS_ORIGIN`), puis fermée.

Avant la correction :

![CodeQL, alerte ouverte](docs/captures/q74-codeql-avant.png)

Après la correction :

![CodeQL, alerte fermée](docs/captures/q74-codeql-apres.png)

| Critère | Semgrep | CodeQL |
|---|---|---|
| Alerte détectée | Absence de protection CSRF (`express-check-csurf-middleware-usage`) | Configuration CORS permissive |
| Pertinence | Faux positif : l'API est stateless, sans cookie ni session | Vraie alerte |
| Traitement | Exception `nosemgrep` avec justification écrite dans le code | Correction du code, alerte fermée |
| Où lire le résultat | Journal du job `sast` | Onglet Security, Code scanning |
| Rôle dans le pipeline | Bloque la CI (`--error`) | Analyse plus profonde du flux de données |

Les deux outils sont complémentaires : Semgrep est rapide et bloque la Pull Request, CodeQL détecte des problèmes que les règles simples de Semgrep ne voient pas.

## Q75 : Dependabot

Le fichier `.github/dependabot.yml` surveille chaque semaine les dépendances npm (`/` et `/api`), les images Docker (`/` et `/api`) et les actions GitHub. Les messages de commit suivent la convention (`chore(deps)`, `chore(docker)`, `ci`). Un **cooldown de 7 jours** a été ajouté pour ne pas proposer une version publiée depuis moins d'une semaine (une version malveillante est souvent retirée dans les premiers jours). Cette règle a été demandée par Semgrep (`dependabot-missing-cooldown`).

![Paramètres de sécurité : graphe de dépendances et alertes Dependabot](docs/captures/q75-parametres-securite-dependabot.png)

![Liste des Pull Requests ouvertes par Dependabot](docs/captures/q75-dependabot-liste-prs.png)

Exemple de Pull Request générée automatiquement :

![Pull Request Dependabot](docs/captures/q75-dependabot-pr.png)

## Q76 : permissions du GITHUB_TOKEN

Le workflow CI et le workflow Release déclarent `permissions: contents: read` (lecture seule) au niveau global. Les jobs qui ont besoin de plus reçoivent uniquement ce qui est nécessaire :

| Workflow | Job | Permissions supplémentaires | Raison |
|---|---|---|---|
| `codeql.yml` | `analyze` | `security-events: write` | Publier les résultats dans l'onglet Security |
| `release.yml` | `release` | `contents: write`, `issues: write`, `pull-requests: write` | Créer le tag et la release |

Principe du moindre privilège : si le token fuit ou si une action tierce est compromise, les dégâts sont limités.

## Q77 : actions épinglées par SHA

Les actions tierces sont référencées par le **SHA du commit**, avec la version en commentaire :

```yaml
- uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5 # v4.3.1
- uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020 # v4.4.0
- uses: github/codeql-action/analyze@9b3254085494b55a0f7c4c2b3d2d52cc712ce370 # v4.39.1
```

**Pourquoi la chaîne CI/CD est une surface d'attaque.** Un tag comme `@v4` est modifiable : si le compte d'un mainteneur est compromis, l'attaquant peut déplacer le tag vers du code malveillant, qui s'exécuterait dans notre pipeline avec accès au code, aux secrets et au token. Un SHA est immuable. Plus largement, le pipeline exécute du code tiers, manipule des secrets et produit les artefacts livrés en production : le compromettre revient à compromettre tout ce qu'il livre. Dependabot (écosystème `github-actions`) propose ensuite les mises à jour de ces SHA de façon contrôlée.

## Q78 : GitHub Actions et Jenkins

| Critère | GitHub Actions | Jenkins |
|---|---|---|
| Hébergement | Géré par GitHub | Auto-hébergé (notre VM) |
| Configuration | YAML dans `.github/workflows` | `Jenkinsfile` (Groovy) |
| Maintenance | Aucune | Mises à jour, plugins, disque, mémoire |
| Intégration avec GitHub | Native (checks de PR, CodeQL, Dependabot) | Via plugins |
| Contrôle et coûts | Minutes limitées, runners GitHub | Contrôle total, coût matériel |
| Réseau | Accès Internet rapide | Dépend de la VM (lent ici) |

---

# Activité 6 : Git Workflow (Q79–84)

## Q79 : stratégie Git et nommage des branches

Flux de travail : `branch` → `Pull Request` → `review` → `merge`. Personne ne pousse directement sur `main`. Chaque changement passe par une branche courte, une Pull Request vérifiée par la CI, puis un merge.

Format des branches : `<type>/<description-courte-en-minuscules-avec-tirets>`

| Préfixe | Usage | Exemple |
|---|---|---|
| `feat/` | Nouvelle fonctionnalité | `feat/formulaire-contact` |
| `fix/` | Correction de bug | `fix/validation-email` |
| `docs/` | Documentation | `docs/readme-activite-6` |
| `ci/` | Pipeline, workflows | `ci/dependabot-cooldown`, `ci/semantic-release` |
| `build/` | Dockerfile, build | `build/api-multistage` |
| `chore/` | Maintenance, dépendances | `chore/maj-dependances` |
| `test/` | Tests | `test/echec-volontaire` |

Pull Request avec tous les contrôles verts, prête à être mergée :

![Pull Request verte](docs/captures/q79-pr-verte.png)

Après le merge (branche supprimée) :

![Pull Request mergée](docs/captures/q79-pr-mergee.png)

## Q80 : protection de la branche principale

Un ruleset GitHub `protect-main` est actif sur la branche par défaut :

- Pull Request obligatoire avant le merge (push direct interdit)
- suppression de la branche interdite
- force push interdit
- liste de contournement (*bypass*) vide : même le propriétaire doit passer par une Pull Request

![Ruleset protect-main actif, liste de contournement vide](docs/captures/q80-ruleset-protect-main.png)

## Q81 : contrôles obligatoires avant le merge

Les six contrôles de la CI sont des *required status checks* : `tests-api`, `tests-frontend` (tests), `sast`, `secrets`, `dependencies` et `images` (construction et scan d'image).

![Contrôles obligatoires du ruleset](docs/captures/q80-ruleset-checks.png)

Pour le démontrer, une Pull Request (`test/echec-volontaire`) contient un test qui échoue volontairement. Les checks `tests-api` et `sast` sont en échec, `images` est ignoré, et le bouton **Merge pull request** reste grisé : le merge est bloqué.

![Pull Request bloquée par un contrôle en échec](docs/captures/q81-pr-bloquee.png)

![Détail de la Pull Request bloquée](docs/captures/q81-pr-bloquee-detail.png)

Cette Pull Request a ensuite été fermée sans merge. Le contrôle `sast` était aussi en échec pour une raison réelle : Semgrep demandait un `cooldown` dans la configuration de Dependabot. La correction est passée par une Pull Request normale (voir Q75).

## Q82 : Conventional Commits

Les messages de commit suivent le format `type: description` :

| Type | Effet sur la version | Exemple |
|---|---|---|
| `feat:` | MINOR | `feat: automatisation des releases avec semantic-release` |
| `fix:` | PATCH | `fix: CORS restreint par défaut au frontend (alerte CodeQL)` |
| `perf:` | PATCH | `perf: Dockerfile API multi-stage (image de 325 Mo à 149 Mo)` |
| `ci:` | aucun | `ci: ajout du cooldown de 7 jours à Dependabot` |
| `test:` | aucun | `test: échec volontaire pour démontrer le blocage` |
| `docs:` | aucun | `docs: mise à jour du README` |
| `chore(deps):` | aucun | commits générés par Dependabot |

Un changement incompatible s'écrit `feat!:` (ou avec un pied de message `BREAKING CHANGE:`) et déclenche une version MAJOR.

## Q83 : Semantic Versioning

Format `MAJOR.MINOR.PATCH`. Un `fix:` ou un `perf:` incrémente le PATCH, un `feat:` le MINOR, un changement incompatible le MAJOR.

| Version | Déclenchée par | Contenu |
|---|---|---|
| v1.0.0 | `feat:` (première release) | Automatisation des releases, correction CORS |
| v1.0.1 | `perf:` (PATCH) | Dockerfile API multi-stage |

![Release v1.0.1](docs/captures/q83-release-v1.0.1.png)

## Q84 : semantic-release

Le fichier `.releaserc.json` active trois plugins : `commit-analyzer` (calcule la version à partir des commits), `release-notes-generator` (génère le changelog) et `github` (crée le tag et la release). Le workflow `.github/workflows/release.yml` se lance à chaque merge sur `main`.

Comme `main` est protégée, le robot ne commite aucun fichier : le changelog est publié dans les notes de la release.

![Release générée automatiquement (v1.0.0)](docs/captures/q84-release-v1.0.0.png)

![Exécution du workflow Release](docs/captures/q84-workflow-release.png)

---

# Section 19 : optimisation des images (Q85–89)

## Q85 : état initial

| Image | Taille (contenu) | Temps de build (`--no-cache`) | Vulnérabilités HIGH/CRITICAL (Trivy) |
|---|---|---|---|
| API (Dockerfile à un seul stage) | 325 Mo (1,22 Go sur disque) | 2 min 06 s | 12 (12 HIGH, 0 CRITICAL) |
| Frontend (déjà multi-stage, mode `standalone`) | 85,7 Mo (334 Mo sur disque) | non mesuré | non mesuré |

## Q86 : Dockerfiles multi-stage

Le Dockerfile du frontend Next.js était déjà en trois stages (`deps`, `builder`, `runner`). Celui de l'API est passé de un à trois stages :

```dockerfile
# 1) Dépendances de production uniquement
FROM node:22-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# 2) Génération du client Prisma
FROM deps AS build
RUN apk add --no-cache openssl
COPY prisma ./prisma
RUN npx prisma generate

# 3) Image finale minimale
FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
RUN apk add --no-cache openssl \
    && rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx

COPY --from=build --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node package*.json ./
COPY --chown=node:node prisma ./prisma
COPY --chown=node:node src ./src

USER node
EXPOSE 4000
CMD ["sh", "-c", "./node_modules/.bin/prisma migrate deploy && node src/server.js"]
```

Les gains viennent de trois changements :

1. `COPY --chown` remplace `RUN chown -R`, qui créait une couche dupliquant tout `node_modules`.
2. L'image finale ne contient que `node_modules`, `prisma` et `src`, sans cache npm.
3. npm et npx sont retirés de l'image finale : ils embarquent leurs propres dépendances (par exemple `brace-expansion`), source de vulnérabilités, et ne servent pas à l'exécution. Prisma est lancé directement depuis `node_modules/.bin`.

L'image a été testée avec une base PostgreSQL : les migrations s'appliquent et l'API démarre (« API démarrée sur http://localhost:4000 »).

![Pull Request du Dockerfile multi-stage](docs/captures/q86-pr-multistage-mergee.png)

## Q87 : comparaison avant / après (API)

| Indicateur | Avant | Après | Évolution |
|---|---|---|---|
| Taille (contenu) | 325 Mo | **149 Mo** | −54 % |
| Taille sur disque | 1,22 Go | **595 Mo** | −51 % |
| Temps de build (`--no-cache`) | 2 min 06 s | **1 min 02 s** | −51 % |
| Vulnérabilités HIGH/CRITICAL | 12 | **2** | −83 % |

Les temps dépendent du réseau et des couches déjà téléchargées. La baisse des vulnérabilités vient surtout du retrait de npm de l'image finale : réduire l'image réduit aussi la surface d'attaque.

## Q88 : BuildKit et Buildx

Les builds utilisent Docker Buildx avec BuildKit (builder `multiarch-host`, pilote `docker-container`, BuildKit v0.33.1).

![Version de Buildx et builders disponibles](docs/captures/q88-buildx.png)

## Q89 : image multi-architecture (amd64 et arm64)

L'émulation `arm64` est installée avec `tonistiigi/binfmt` (QEMU) :

![Émulation arm64 installée](docs/captures/q89-binfmt-arm64.png)

Construction et publication dans un registre local temporaire :

```bash
docker buildx build --builder multiarch-host \
  --platform linux/amd64,linux/arm64 \
  -t localhost:5000/devsecops-api:1.0.1 --push ./api
docker buildx imagetools inspect localhost:5000/devsecops-api:1.0.1
```

Résultat : un index OCI avec deux manifestes (`linux/amd64` et `linux/arm64`). Les deux entrées `unknown/unknown` de type `attestation-manifest` sont les attestations de provenance et de SBOM ajoutées automatiquement par BuildKit.

![Résultat de docker buildx imagetools inspect](docs/captures/q89-imagetools-inspect.png)

---

# Section 20 : registre privé Harbor (Q90–93)

## Q90 : installation de Harbor

Harbor v2.14.6 est installé avec l'installeur en ligne sur la VM, avec le scanner Trivy intégré (`./install.sh --with-trivy`). Il est accessible sur `http://192.168.190.141:8085`. Le port 8085 a été choisi car 8081 (Jenkins) et 8082 (autre application) sont déjà utilisés. Le lab utilise HTTP : Docker déclare ce registre dans `insecure-registries`. En production, il faudrait activer TLS.

![Installation de Harbor réussie](docs/captures/q90-harbor-installation.png)

![Harbor : liste des projets](docs/captures/q90-harbor-projets.png)

## Q91 : images publiées dans Harbor

| Image | Nom complet | Tag |
|---|---|---|
| API | `192.168.190.141:8085/devsecops/api` | `eca768d` (SHA du commit) |
| API optimisée | `192.168.190.141:8085/devsecops/api` | `multistage` |
| Frontend | `192.168.190.141:8085/devsecops/portfolio` | `eca768d` (SHA du commit) |

![Dépôts du projet devsecops](docs/captures/q91-harbor-depots.png)

<!-- À compléter : publication automatique depuis le pipeline Jenkins (étape Push Harbor avec l'identifiant harbor-robot) -->

## Q92 : permissions RBAC

- Projet `devsecops` **privé** (aucun téléchargement anonyme).
- Utilisateur `developpeur` avec le rôle **Développeur** (peut envoyer et télécharger des images, sans droits d'administration).
- Compte robot `robot$devsecops+pipeline` pour le pipeline : droits **Lister, Pull et Push** sur les dépôts uniquement (pas de suppression), expiration à 30 jours. Son secret est stocké dans un identifiant Jenkins (`harbor-robot`), jamais dans le dépôt.

![Compte robot du pipeline](docs/captures/q92-harbor-robot.png)

## Q93 : scan automatique Harbor et comparaison avec Trivy

Le scan automatique à l'envoi est activé dans la configuration du projet. Harbor utilise Trivy, la même base de vulnérabilités que le pipeline.

![Résultat du scan de l'image API](docs/captures/q93-harbor-scan-artefact.png)

![Détail des vulnérabilités](docs/captures/q93-harbor-scan-details.png)

| | Pipeline (Trivy) | Harbor (Trivy) |
|---|---|---|
| Filtre de gravité | `CRITICAL` uniquement, bloque le build | Toutes gravités affichées |
| Résultat sur `api:eca768d` | 0 critique, le build passe | 25 vulnérabilités au total, gravité maximale **Haute**, aucune critique |
| Moment du scan | Avant la livraison | Après la publication, à chaque envoi |

Les deux outils sont d'accord (aucune vulnérabilité critique). La différence de nombre vient du filtre de gravité, pas du moteur. Les paquets concernés sont `brace-expansion` (embarqué dans npm), `body-parser` et `deepmerge-ts`.

<!-- À compléter : résultat du scan de l'image api:multistage (comparaison avant/après dans Harbor) -->
