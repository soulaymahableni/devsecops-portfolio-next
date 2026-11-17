#!/usr/bin/env bash
# Q216-Q217 : met a jour l'empreinte d'image d'un overlay de la branche gitops.
# usage : gitops-update.sh <dev|staging|prod> <api|portfolio> <sha256:...>
# DRY_RUN=1 (defaut) : affiche le diff puis annule. DRY_RUN=0 : commit + push.
# Dans Jenkins : GITOPS_TOKEN (identifiant Jenkins) => clone temporaire de la branche gitops.
set -euo pipefail
ENVN=${1:?env} COMP=${2:?api|portfolio} DIGEST=${3:?sha256:...}
echo "$DIGEST" | grep -Eq '^sha256:[a-f0-9]{64}$' || { echo "empreinte invalide"; exit 1; }
case "$COMP" in api) IMG=devsecops-api;; portfolio) IMG=devsecops-portfolio;; *) echo "composant inconnu"; exit 1;; esac
REPO=${GITOPS_REPO:-https://github.com/soulaymahableni/devsecops-portfolio-next.git}
if [ -n "${GITOPS_TOKEN:-}" ]; then
  DIR=$(mktemp -d); ASK=$(mktemp); trap 'rm -rf "$DIR" "$ASK"' EXIT
  printf '#!/bin/sh\necho "$GITOPS_TOKEN"\n' > "$ASK"; chmod +x "$ASK"
  export GIT_ASKPASS="$ASK" GIT_USERNAME=x GIT_TERMINAL_PROMPT=0
  git clone -q --depth 1 -b gitops "$REPO" "$DIR"
else
  DIR=$HOME/portfolio-gitops
fi
cd "$DIR"
F=overlays/$ENVN/kustomization.yaml
python3 - "$F" "$IMG" "$DIGEST" <<'PY'
import re, sys
path, img, digest = sys.argv[1:4]
cur, n, out = None, 0, []
for line in open(path).read().split("\n"):
    m = re.match(r"^\s*-?\s*name:\s*(\S+)", line)
    if m: cur = m.group(1)
    if cur and cur.endswith(img) and re.match(r"^\s*digest:\s*sha256:[a-f0-9]+", line):
        line = re.sub(r"sha256:[a-f0-9]+", digest, line); n += 1
    out.append(line)
assert n == 1, "bloc image %s introuvable (ou en double) dans %s" % (img, path)
open(path, "w").write("\n".join(out))
PY
git --no-pager diff -- "$F" | grep -E '^[+-] ' || echo "(aucun changement : meme empreinte)"
if [ "${DRY_RUN:-1}" = "1" ]; then git checkout -- "$F"; echo "[dry-run] rien n'a ete commite"; exit 0; fi
git diff --quiet -- "$F" && exit 0
git -c user.name="jenkins-ci" -c user.email="jenkins@portfolio.local" commit -qam "ci(gitops): $ENVN $COMP -> $DIGEST" -m "Mise a jour automatique par le pipeline Jenkins (build signe)"
for i in 1 2 3 4 5 6; do git push -q origin gitops && break; sleep 10; done
echo "pousse sur gitops : Argo CD synchronise $ENVN"
