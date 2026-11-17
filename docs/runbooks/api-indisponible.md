# Runbook : API indisponible ou dégradée

**Alertes concernées** : `ApiTargetDown`, `ApiErrorBudgetFastBurn`, `ApiLatencyP95High`

## 1. Symptôme et impact
- `ApiTargetDown` : Prometheus ne joint plus `/metrics` d'un pod de l'API (pod arrêté, en boucle de redémarrage ou version sans `/metrics`).
- `ApiErrorBudgetFastBurn` : plus de 14,4 % d'erreurs 5xx sur 5 min **et** sur 1 h. Le budget d'erreur mensuel (SLO 99 %) serait épuisé en environ 2 jours.
- `ApiLatencyP95High` : 5 % des requêtes les plus lentes dépassent 500 ms depuis 5 min.

## 2. Diagnostic (dans l'ordre)
1. Quel environnement ? `kubectl get pods -A -l app=api`
2. État du pod : `kubectl describe pod -n <namespace> <pod>` (événements : image refusée par Kyverno, sonde en échec, mémoire).
3. Journaux : `kubectl logs -n <namespace> <pod> --tail=50` (chercher le `requestId` d'une requête en erreur, puis le suivre dans Loki).
4. Base de données : `kubectl get pods -n <namespace> -l app=postgres`.
5. Dernier changement : `git log --oneline -5` sur la branche `gitops` (une promotion récente est la cause la plus probable).

## 3. Résolution
- Mauvaise version déployée : revenir au digest précédent dans `overlays/<env>/kustomization.yaml` de la branche `gitops` (`git revert` du commit de promotion). Argo CD redéploie l'ancienne image signée.
- Pod bloqué : `kubectl delete pod -n <namespace> <pod>` (le Deployment le recrée).
- Image refusée (`no matching signatures`) : l'image n'est pas signée, la signer avec Cosign puis relancer la synchronisation.

## 4. Escalade
Si l'API n'est pas rétablie en 15 minutes en prod : prévenir le responsable de l'environnement et geler les promotions.

## 5. Après l'incident
Noter la cause, la durée et le budget d'erreur consommé ; ajouter un test ou une alerte si le problème n'était pas détecté.
