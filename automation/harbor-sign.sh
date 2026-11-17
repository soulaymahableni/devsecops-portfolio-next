#!/usr/bin/env bash
# Q203 : signature Cosign des images publiees dans Harbor, puis verification avec cosign.pub
set -euo pipefail
KEY=$HOME/cosign-keys/harbor/cosign.key
PUB=$HOME/devsecops-portfolio-next/cosign-harbor.pub
read -rsp "Mot de passe de la cle Cosign (Entree si aucun) : " CP; echo
export COSIGN_PASSWORD="$CP"

# Options de cosign v3 : on desactive le nouveau format et la tlog publique quand l'option existe
HELP_SIGN=$(cosign sign --help 2>&1)
SIGN_FLAGS="--yes --key $KEY --use-signing-config=false --new-bundle-format=false"
for f in --tlog-upload=false --new-bundle-format=false --use-signing-config=false; do
  echo "$HELP_SIGN" | grep -q -- "${f%%=*}" && SIGN_FLAGS="$SIGN_FLAGS $f"
done
HELP_VER=$(cosign verify --help 2>&1)
VER_FLAGS="--key $PUB --new-bundle-format=false"
for f in --insecure-ignore-tlog=true --new-bundle-format=false --private-infrastructure=true; do
  echo "$HELP_VER" | grep -q -- "${f%%=*}" && VER_FLAGS="$VER_FLAGS $f"
done
echo "options signature   : $SIGN_FLAGS"
echo "options verification: $VER_FLAGS"

for img in devsecops-portfolio devsecops-api; do
  ref=$(docker inspect --format '{{range .RepoDigests}}{{println .}}{{end}}' localhost:8085/portfolio/$img:1.0 | grep "^localhost:8085/portfolio/$img@" | head -1)
  echo; echo "== $img : $ref"
  cosign sign $SIGN_FLAGS "$ref"
  echo "-- verification avec cosign.pub --"
  cosign verify $VER_FLAGS "$ref" 2>&1 | tail -4 | cut -c1-200
done

echo; echo "== tags du depot api (une signature classique ajoute un tag sha256-....sig) =="
curl -s -u robot-read-only-not-used "http://localhost:8085/v2/portfolio/devsecops-api/tags/list" >/dev/null 2>&1 || true
docker run --rm --network host gcr.io/go-containerregistry/crane:latest ls localhost:8085/portfolio/devsecops-api 2>&1 | tail -4 || true
echo "FIN : signature terminee"
