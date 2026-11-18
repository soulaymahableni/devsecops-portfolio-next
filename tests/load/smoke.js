// Q239-Q241 : test de charge simple du frontend (qui interroge l'API a chaque page).
// Les seuils (thresholds) font echouer k6, donc le pipeline, s'ils ne sont pas respectes.
import http from "k6/http";
import { check, sleep } from "k6";

const P95 = Number(__ENV.P95_MS || 1500);

export const options = {
  stages: [
    { duration: "15s", target: 10 }, // montee en charge
    { duration: "30s", target: 10 }, // palier : 10 utilisateurs virtuels
    { duration: "5s", target: 0 },   // descente
  ],
  thresholds: {
    http_req_failed: ["rate<0.01"],                 // moins de 1 % d'erreurs
    http_req_duration: [`p(95)<${P95}`],            // latence p95
    "http_req_duration{page:accueil}": [`p(95)<${P95}`],
    "http_req_duration{page:projets}": [`p(95)<${P95}`],
    checks: ["rate>0.99"],
  },
};

const BASE = __ENV.BASE_URL || "http://localhost:3000";

export default function () {
  const accueil = http.get(`${BASE}/`, { tags: { page: "accueil" } });
  check(accueil, { "accueil : statut 200": (r) => r.status === 200 });
  const projets = http.get(`${BASE}/projects`, { tags: { page: "projets" } });
  check(projets, { "projets : statut 200": (r) => r.status === 200 });
  sleep(1);
}
