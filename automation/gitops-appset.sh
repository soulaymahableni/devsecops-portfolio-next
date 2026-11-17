#!/usr/bin/env bash
# Q211, Q215 : trois environnements generes par un ApplicationSet
set -euo pipefail
REPO=$HOME/devsecops-portfolio-next
echo "== 1. dev repasse a 1 replica (RAM) =="
cd $HOME/portfolio-gitops
sed -i 's/count: 2/count: 1/' overlays/dev/kustomization.yaml
git commit -am "chore(gitops): dev revient a 1 replica" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_012BLQio8toTgBgMBnUs4xS8" | tail -1
for i in 1 2 3 4 5 6; do git push origin gitops 2>&1 | tail -1 && break; sleep 10; done
echo "== 2. l'ApplicationSet remplace l'application creee a la main =="
kubectl patch application portfolio-dev -n argocd --type merge -p '{"metadata":{"finalizers":null}}'
kubectl delete application portfolio-dev -n argocd
kubectl apply -f $REPO/k8s/argocd/applicationset.yaml
sleep 100
kubectl get applicationset -n argocd
kubectl get applications -n argocd
for e in dev staging prod; do echo "--- portfolio-$e"; kubectl get pods -n portfolio-$e --no-headers 2>/dev/null | awk '{print "  "$1, $2, $3}'; done
free -h | head -2
echo "FIN : ApplicationSet cree"
