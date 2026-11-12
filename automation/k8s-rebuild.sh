#!/usr/bin/env bash
# Q146 : détruit puis recrée le cluster K3s uniquement par automatisation (Ansible),
# puis redéploie le portfolio. Le mot de passe sudo est saisi à la main, jamais stocké.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/ansible/k3s"
INV=inventory-local.ini
PLAY="${ANSIBLE_PLAYBOOK:-ansible-playbook}"

read -rsp "Mot de passe sudo : " ANSIBLE_BECOME_PASS; echo
export ANSIBLE_BECOME_PASS
export ANSIBLE_HOST_KEY_CHECKING=False
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
START=$(date +%s)

echo "[1/4] Destruction du cluster (K3s désinstallé, données supprimées)"
"$PLAY" -i "$INV" site.yml -e k3s_state=absent | tail -6

echo "[2/4] Création du cluster : SSH, Docker, K3s"
"$PLAY" -i "$INV" site.yml -e docker_user="$USER" | tail -12

echo "[3/4] Déploiement du portfolio (images + manifests)"
"$PLAY" -i "$INV" app.yml | tail -10

echo "[4/4] Vérification"
kubectl get nodes
kubectl get pods -n portfolio
echo "Cluster recréé et portfolio redéployé en $(( $(date +%s) - START )) secondes."
