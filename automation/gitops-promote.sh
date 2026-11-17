#!/usr/bin/env bash
# Q212-Q213 : promotion dev -> staging -> prod par Git, sans reconstruire l'image
set -euo pipefail
cd $HOME/portfolio-gitops
OLD=sha256:d4159e72a3ba7ddb6ff733276af714c43aef4fc35f084520920116ee98ec3db3
NEW=$(grep -A0 'digest: sha256:983ad336' overlays/dev/kustomization.yaml | awk '{print $2}' | head -1)
echo "empreinte validee en dev : $NEW"
promote() {
  env=$1
  python3 - "$env" "$OLD" "$NEW" <<'PY'
import sys
env, old, new = sys.argv[1:4]
p = "overlays/%s/kustomization.yaml" % env
s = open(p).read()
assert s.count(old) == 1, "empreinte a promouvoir introuvable dans " + p
open(p, "w").write(s.replace(old, new))
PY
  echo "---- promotion vers $env :"
  git diff overlays/$env/kustomization.yaml | grep -E "^[+-] "
  git commit -qam "feat(gitops): promotion de l'API vers $env (meme empreinte signee que dev, sans reconstruction)" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_012BLQio8toTgBgMBnUs4xS8"
  for i in 1 2 3 4 5 6; do git push -q origin gitops 2>&1 | tail -1 && break; sleep 10; done
  kubectl annotate application portfolio-$env -n argocd argocd.argoproj.io/refresh=hard --overwrite >/dev/null
  sleep 80
  kubectl get application portfolio-$env -n argocd --no-headers
}
promote staging
promote prod
echo
echo "== Q213 : empreintes reellement executees dans chaque environnement =="
printf "%-10s %-12s %s\n" ENV COMPOSANT EMPREINTE
for e in dev staging prod; do
  for app in api frontend; do
    d=$(kubectl get pods -n portfolio-$e -l app=$app -o jsonpath='{.items[*].spec.containers[0].image}' | tr ' ' '\n' | sort -u | sed 's/.*@sha256:/sha256:/' | cut -c1-23)
    printf "%-10s %-12s %s\n" $e $app "$d"
  done
done
echo
echo "== verification de la signature de l'API promue =="
cosign verify --key $HOME/devsecops-portfolio-next/cosign-harbor.pub --new-bundle-format=false --insecure-ignore-tlog=true localhost:8085/portfolio/devsecops-api@$NEW 2>&1 | grep -E "verified|Error" | head -2
kubectl get applications -n argocd
echo "FIN : promotion terminee"
