#!/usr/bin/env bash
# Q205-Q206 : contenu de la branche gitops, namespaces, secrets et application dev
set -euo pipefail
REPO=$HOME/devsecops-portfolio-next
GIT=$HOME/portfolio-gitops
HARBOR=192.168.190.141:8085
API_DIGEST=sha256:d4159e72a3ba7ddb6ff733276af714c43aef4fc35f084520920116ee98ec3db3
FRONT_DIGEST=sha256:c98ad2554e11b8685db982888d8746292c52e1216082252b1df6d05425f95702

echo "== 1. branche gitops : base et overlays =="
cd "$GIT"
rm -rf base overlays
cp -r "$REPO/kustomize/base" base
python3 - <<'PY'
for p in ("base/20-frontend-deployment.yaml", "base/30-api-deployment.yaml"):
    s = open(p).read()
    assert s.count("imagePullPolicy: Never") == 1 and "harbor-pull" not in s, p
    s = s.replace("imagePullPolicy: Never", "imagePullPolicy: IfNotPresent")
    s = s.replace("      serviceAccountName: portfolio-app\n", "      serviceAccountName: portfolio-app\n      imagePullSecrets:\n        - name: harbor-pull\n")
    open(p, "w").write(s)
print("base adaptee (imagePullSecrets, IfNotPresent)")
PY
for spec in dev:1 staging:1 prod:2; do
  env="${spec%%:*}"; n="${spec##*:}"
  mkdir -p overlays/$env
  cat > overlays/$env/kustomization.yaml <<KUS
# environnement $env : $n replica(s) ; images Harbor epinglees par empreinte (meme image signee partout)
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: portfolio-$env
resources:
  - ../../base
replicas:
  - name: frontend
    count: $n
  - name: api
    count: $n
images:
  - name: devsecops-portfolio
    newName: $HARBOR/portfolio/devsecops-portfolio
    digest: $FRONT_DIGEST
  - name: devsecops-api
    newName: $HARBOR/portfolio/devsecops-api
    digest: $API_DIGEST
patches:
  - target:
      kind: ConfigMap
      name: portfolio-config
    patch: |-
      - op: replace
        path: /data/API_URL
        value: http://api.portfolio-$env.svc.cluster.local:4000
      - op: replace
        path: /data/CORS_ORIGIN
        value: https://$env.portfolio.local
KUS
done
echo "-- images obtenues (dev) :"
kubectl kustomize overlays/dev | grep -E "image:|replicas:"
cat > README.md <<'MD'
# Branche GitOps du portfolio

Contient uniquement les manifests suivis par Argo CD : `base/` et `overlays/{dev,staging,prod}`.
Les images viennent de Harbor et sont epinglees par empreinte (`@sha256`) : la meme image signee
est deployee dans les trois environnements. Les secrets ne sont jamais dans Git.
Argo CD suit `targetRevision: gitops` (branche orpheline, remplace le second depot).
MD
git add -A
git commit -m "feat(gitops): base et overlays dev/staging/prod, images Harbor epinglees par empreinte" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_012BLQio8toTgBgMBnUs4xS8" | tail -1
for i in 1 2 3 4 5 6; do git push origin gitops 2>&1 | tail -1 && break; echo "push : nouvel essai $i"; sleep 10; done

echo "== 2. namespaces et secrets (hors Git) =="
for env in dev staging prod; do
  kubectl create namespace portfolio-$env --dry-run=client -o yaml | kubectl apply -f -
  kubectl label namespace portfolio-$env verify-images=enabled --overwrite >/dev/null
  for sec in portfolio-secret harbor-pull; do
    kubectl get secret $sec -n portfolio -o json | python3 -c '
import sys, json
s = json.load(sys.stdin)
for k in ("namespace","resourceVersion","uid","creationTimestamp","ownerReferences","managedFields","annotations"):
    s["metadata"].pop(k, None)
s["metadata"]["namespace"] = "'portfolio-$env'"
print(json.dumps(s))' | kubectl apply -f - >/dev/null
  done
  echo "portfolio-$env : secrets copies"
done

echo "== 3. application Argo CD portfolio-dev =="
kubectl apply -f "$REPO/k8s/argocd/application-dev.yaml"
sleep 60
kubectl get applications -n argocd
kubectl get pods -n portfolio-dev
echo "FIN : gitops-init termine"
