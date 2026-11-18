#!/usr/bin/env bash
# Attend qu'Argo CD ait deploye une empreinte dans un environnement, puis que les pods soient prets.
# usage : attendre-deploiement.sh <dev|staging|prod> <api|frontend> <sha256:...>
set -euo pipefail
ENVN=${1:?env} DEPLOY=${2:?api|frontend} DIGEST=${3:?sha256:...}
NS=portfolio-$ENVN
kubectl -n argocd annotate application "portfolio-$ENVN" argocd.argoproj.io/refresh=hard --overwrite >/dev/null || true
for i in $(seq 1 60); do
  IMG=$(kubectl -n "$NS" get deploy "$DEPLOY" -o jsonpath='{.spec.template.spec.containers[0].image}')
  case "$IMG" in *"$DIGEST"*) break;; esac
  echo "attente d'Argo CD ($i/60) : $NS/$DEPLOY n'a pas encore l'empreinte"; sleep 10
done
case "$IMG" in *"$DIGEST"*) ;; *) echo "delai depasse : empreinte non deployee"; exit 1;; esac
kubectl -n "$NS" rollout status "deploy/$DEPLOY" --timeout=600s
echo "$NS/$DEPLOY : empreinte deployee et pods prets"
