#!/usr/bin/env bash
# Q210 : nouvelle version de l'API (1.1), signee, deployee par Git
set -euo pipefail
KEY=$HOME/cosign-keys/harbor/cosign.key
OLD=sha256:d4159e72a3ba7ddb6ff733276af714c43aef4fc35f084520920116ee98ec3db3
read -rsp "Mot de passe de la cle Cosign : " CP; echo
export COSIGN_PASSWORD="$CP"
mkdir -p /tmp/api11 && cd /tmp/api11
printf 'FROM localhost:8085/portfolio/devsecops-api:1.0\nLABEL org.opencontainers.image.version="1.1"\n' > Dockerfile
echo "== 1. construction de l'image 1.1 =="
docker build -q -t localhost:8085/portfolio/devsecops-api:1.1 .
echo "== 2. envoi dans Harbor =="
docker push localhost:8085/portfolio/devsecops-api:1.1 2>&1 | tail -1
REF=$(docker inspect --format '{{range .RepoDigests}}{{println .}}{{end}}' localhost:8085/portfolio/devsecops-api:1.1 | grep '^localhost:8085/portfolio/devsecops-api@' | head -1)
NEW=${REF##*@}
echo "nouvelle empreinte : $NEW"
echo "== 3. signature =="
cosign sign --yes --key "$KEY" --use-signing-config=false --new-bundle-format=false --tlog-upload=false "$REF" 2>&1 | grep -E "Pushing|Error" || true
cosign verify --key $HOME/devsecops-portfolio-next/cosign-harbor.pub --new-bundle-format=false --insecure-ignore-tlog=true "$REF" 2>&1 | grep -E "verified|Error" | head -2
echo "== 4. Git : l'API de dev passe a la nouvelle empreinte =="
cd $HOME/portfolio-gitops
python3 - "$OLD" "$NEW" <<'PY'
import sys
old, new = sys.argv[1], sys.argv[2]
p = "overlays/dev/kustomization.yaml"
s = open(p).read()
assert s.count(old) == 1, "empreinte API introuvable dans l'overlay dev"
open(p, "w").write(s.replace(old, new))
PY
git diff overlays/dev/kustomization.yaml | grep -E "^[+-] "
git commit -am "feat(gitops): API 1.1 (nouvelle image signee) en dev" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_012BLQio8toTgBgMBnUs4xS8" | tail -1
for i in 1 2 3 4 5 6; do git push origin gitops 2>&1 | tail -1 && break; sleep 10; done
kubectl annotate application portfolio-dev -n argocd argocd.argoproj.io/refresh=hard --overwrite
sleep 75
kubectl get applications -n argocd
kubectl get pods -n portfolio-dev -o custom-columns=POD:.metadata.name,PRET:.status.containerStatuses[0].ready,IMAGE:.spec.containers[0].image | cut -c1-150
echo "FIN : API 1.1 deployee par Git"
