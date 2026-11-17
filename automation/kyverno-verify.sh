#!/usr/bin/env bash
# Q202-Q204 : K3s tire depuis Harbor, Kyverno verifie les signatures Cosign avant deploiement
set -euo pipefail
cd ~/devsecops-portfolio-next
HARBOR=192.168.190.141:8085
sudo -v

echo "== 1. K3s : registre Harbor en HTTP + seuil d'eviction =="
sudo mkdir -p /etc/rancher/k3s
if sudo test -f /etc/rancher/k3s/registries.yaml; then sudo cp /etc/rancher/k3s/registries.yaml /etc/rancher/k3s/registries.yaml.bak; echo "(ancien registries.yaml sauvegarde en .bak)"; fi
sudo tee /etc/rancher/k3s/registries.yaml >/dev/null <<REG
mirrors:
  "$HARBOR":
    endpoint:
      - "http://$HARBOR"
REG
if sudo test -f /etc/rancher/k3s/config.yaml && sudo grep -q "kubelet-arg" /etc/rancher/k3s/config.yaml; then
  echo "ATTENTION : config.yaml contient deja kubelet-arg, je n'y touche pas (verifie-le a la main)"
else
  sudo tee -a /etc/rancher/k3s/config.yaml >/dev/null <<CFG
kubelet-arg:
  - "eviction-hard=memory.available<100Mi,nodefs.available<5%,nodefs.inodesFree<5%,imagefs.available<5%"
CFG
fi
sudo systemctl restart k3s
echo "attente de K3s..."
for i in $(seq 1 40); do kubectl get nodes 2>/dev/null | grep -q " Ready" && break; sleep 5; done
kubectl get nodes | tail -1
sleep 30
kubectl describe node automatisation | grep -E "DiskPressure|Taints" | cut -c1-100

echo "== 2. images Kyverno (pre-telechargement avec Docker) =="
helm repo add kyverno https://kyverno.github.io/kyverno/ >/dev/null 2>&1 || true
helm repo update kyverno >/dev/null
KV_SET="--set admissionController.replicas=1 --set backgroundController.enabled=false --set cleanupController.enabled=false --set reportsController.enabled=false"
for img in $(helm template kyverno kyverno/kyverno -n kyverno --version 3.9.2 $KV_SET | grep -E '^\s+image:' | awk '{print $2}' | tr -d '"' | sort -u); do
  echo ">>> $img"
  docker pull -q "$img" >/dev/null
  docker save "$img" | sudo k3s ctr images import - >/dev/null 2>&1
done

echo "== 3. installation de Kyverno (allegee) =="
helm upgrade --install kyverno kyverno/kyverno -n kyverno --create-namespace --version 3.9.2 $KV_SET --wait --timeout 8m
kubectl get pods -n kyverno

echo "== 4. secret Harbor pour Kyverno et le namespace de test =="
kubectl create namespace verif-signatures --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace verif-signatures verify-images=enabled --overwrite
for ns in kyverno verif-signatures; do
  kubectl get secret harbor-pull -n portfolio -o json | python3 -c '
import sys, json
s = json.load(sys.stdin)
for k in ("namespace","resourceVersion","uid","creationTimestamp","ownerReferences","managedFields","annotations"):
    s["metadata"].pop(k, None)
s["metadata"]["namespace"] = "'$ns'"
print(json.dumps(s))' | kubectl apply -f -
done

echo "== 5. politique verifyImages (cle publique cosign-harbor.pub) =="
VER=$(kubectl get crd imagevalidatingpolicies.policies.kyverno.io -o jsonpath='{.spec.versions[*].name}')
echo "versions de l'API disponibles : $VER"
for v in v1 v1beta1 v1alpha1; do echo " $VER " | grep -q " $v " && API_VER=$v && break; done
echo "version utilisee : policies.kyverno.io/$API_VER"
PUBKEY=$(sed 's/^/            /' cosign-harbor.pub)
mkdir -p k8s/policies
cat > k8s/policies/kyverno-verify-images.yaml <<POL
# Q203-Q204 : refuse tout pod dont l'image Harbor n'est pas signee avec la cle cosign-harbor.pub
apiVersion: policies.kyverno.io/$API_VER
kind: ImageValidatingPolicy
metadata:
  name: verifier-images-harbor
spec:
  validationActions: [Deny]
  evaluation:
    background:
      enabled: false
  webhookConfiguration:
    timeoutSeconds: 20
  matchConstraints:
    namespaceSelector:
      matchLabels:
        verify-images: enabled
    resourceRules:
      - apiGroups: ['']
        apiVersions: ['v1']
        operations: ['CREATE', 'UPDATE']
        resources: ['pods']
  matchImageReferences:
    - glob: '$HARBOR/portfolio/*'
  credentials:
    secrets: [harbor-pull]
  attestors:
    - name: cosign
      cosign:
        key:
          data: |
$PUBKEY
        ctlog:
          insecureIgnoreSCT: true
          insecureIgnoreTlog: true
  validations:
    - expression: >-
        images.containers.map(image, verifyImageSignatures(image, [attestors.cosign])).all(e, e > 0)
      message: 'Image refusee : signature Cosign absente ou invalide'
POL
kubectl apply -f k8s/policies/kyverno-verify-images.yaml
sleep 20
kubectl get imagevalidatingpolicies 2>&1 | head -4

echo "== 6. image NON signee dans Harbor =="
docker tag postgres:16-alpine localhost:8085/portfolio/non-signe:1.0
docker push localhost:8085/portfolio/non-signe:1.0 2>&1 | tail -1

mkdir -p docs
{
echo "### Test 1 : pod avec l'image SIGNEE (attendu : accepte)"
cat <<POD | kubectl apply -f - 2>&1
apiVersion: v1
kind: Pod
metadata: {name: image-signee, namespace: verif-signatures}
spec:
  imagePullSecrets: [{name: harbor-pull}]
  containers:
    - name: api
      image: $HARBOR/portfolio/devsecops-api:1.0
      imagePullPolicy: IfNotPresent
      command: ["node","-e","setTimeout(()=>{},300000)"]
      securityContext: {runAsNonRoot: true, runAsUser: 1000, allowPrivilegeEscalation: false, capabilities: {drop: [ALL]}}
POD
echo
echo "### Test 2 : pod avec l'image NON SIGNEE (attendu : refuse)"
cat <<POD | kubectl apply -f - 2>&1 || true
apiVersion: v1
kind: Pod
metadata: {name: image-non-signee, namespace: verif-signatures}
spec:
  imagePullSecrets: [{name: harbor-pull}]
  containers:
    - name: x
      image: $HARBOR/portfolio/non-signe:1.0
      imagePullPolicy: IfNotPresent
      command: ["sleep","300"]
POD
} | tee docs/kyverno-verifyimages-test.txt
echo
kubectl get pods -n verif-signatures
echo "FIN : lot B termine"
