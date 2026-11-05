#!/usr/bin/env bash
# Q134/Q135 : construit toute la plateforme uniquement à partir des scripts.
# Floci -> Terraform (ressources AWS locales) -> Ansible (déploiement Docker) -> test
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
AWSF="aws --profile floci --endpoint-url http://localhost:4566"
ANSIBLE="${ANSIBLE_PLAYBOOK:-ansible-playbook}"
START=$(date +%s)

echo "[1/5] Démarrage de Floci"
docker compose up -d floci
until [ "$(docker inspect -f '{{.State.Health.Status}}' devsecops-floci)" = "healthy" ]; do sleep 2; done

echo "[2/5] Préparation du backend Terraform (bucket tfstate et table tf-locks)"
$AWSF s3api head-bucket --bucket tfstate 2>/dev/null || $AWSF s3 mb s3://tfstate
$AWSF dynamodb describe-table --table-name tf-locks >/dev/null 2>&1 || $AWSF dynamodb create-table \
  --table-name tf-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST >/dev/null

echo "[3/5] Terraform : création des ressources"
cd terraform/envs/platform
terraform init -input=false -backend-config=../../backend.hcl >/dev/null
terraform apply -auto-approve -input=false | tail -4
mkdir -p "$ROOT/automation/generated"
terraform output -json > "$ROOT/automation/generated/tf.json"
cd "$ROOT"

echo "[4/5] Ansible : déploiement de la pile Docker"
"$ANSIBLE" -i localhost, automation/ansible/deploy.yml | tail -8

echo "[5/5] Test de bout en bout"
curl -sf -X POST http://localhost:4000/api/contact -H "Content-Type: application/json" \
  -d '{"name":"Rebuild","email":"rebuild@example.com","message":"Test après reconstruction"}'
echo
echo "Reconstruction terminée en $(( $(date +%s) - START )) secondes."
