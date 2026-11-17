#!/usr/bin/env bash
# Q205 : installation d'Argo CD (allegee) sur K3s
set -euo pipefail
sudo -v

echo "== 1. le depot GitHub est-il public ? =="
code=$(curl -s -o /dev/null -w '%{http_code}' --retry 5 --retry-all-errors --retry-delay 3 --max-time 20 https://github.com/soulaymahableni/devsecops-portfolio-next || true)
echo "HTTP $code (200 = public)"
if [ "$code" = "404" ]; then echo "ECHEC : le depot n'est pas public (404). Il faudra un jeton d'acces pour Argo CD."; exit 1; fi
[ "$code" = "200" ] || echo "(verification impossible : reseau instable, on continue)"

echo "== 2. liberer de la RAM (anciens conteneurs d'un autre TP) =="
docker stop prometheus grafana 2>&1 | tr '\n' ' '; echo
free -h | head -2

echo "== 3. pare-feu : interface web d'Argo CD =="
sudo ufw allow 30443/tcp comment 'Argo CD (interface web)' | tail -1

echo "== 4. images (pre-telechargement avec Docker) =="
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update argo >/dev/null
VER=$(helm search repo argo/argo-cd -o json | python3 -c 'import sys,json; print(json.load(sys.stdin)[0]["version"])')
echo "chart argo-cd version $VER"
SETS="--set dex.enabled=false --set notifications.enabled=false --set server.service.type=NodePort --set server.service.nodePortHttps=30443 --set server.service.nodePortHttp=30081"
for img in $(helm template argocd argo/argo-cd -n argocd --version $VER $SETS | grep -E '^\s+image:' | awk '{print $2}' | tr -d '"' | sort -u); do
  echo ">>> $img"
  for t in 1 2 3 4 5 6; do docker pull -q "$img" >/dev/null 2>&1 && break; echo "  (nouvel essai $t)"; sleep 10; done
  docker save "$img" | sudo k3s ctr images import - >/dev/null 2>&1
done

echo "== 5. installation d'Argo CD =="
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace --version $VER $SETS --wait --timeout 10m
kubectl get pods -n argocd
echo
echo "Interface web : https://192.168.190.141:30443   (utilisateur : admin)"
echo "FIN : Argo CD installe (chart $VER)"
