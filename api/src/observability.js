// Q220-Q223 : metriques Prometheus + identifiant de correlation + journal JSON
const client = require("prom-client");
const { randomUUID } = require("crypto");

const registry = new client.Registry();
client.collectDefaultMetrics({ register: registry });

const httpTotal = new client.Counter({
  name: "http_requests_total",
  help: "Nombre de requetes HTTP",
  labelNames: ["method", "route", "status"],
  registers: [registry],
});
const httpDuration = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "Duree des requetes HTTP",
  labelNames: ["method", "route", "status"],
  buckets: [0.01, 0.05, 0.1, 0.3, 0.5, 1, 2, 5],
  registers: [registry],
});

function observability(req, res, next) {
  const incoming = req.headers["x-request-id"];
  const id = typeof incoming === "string" && /^[\w-]{8,64}$/.test(incoming) ? incoming : randomUUID();
  req.id = id;
  res.setHeader("X-Request-Id", id);
  const start = process.hrtime.bigint();
  res.on("finish", () => {
    const sec = Number(process.hrtime.bigint() - start) / 1e9;
    const route = req.route ? req.baseUrl + req.route.path : "non_trouvee";
    const labels = { method: req.method, route, status: String(res.statusCode) };
    httpTotal.inc(labels);
    httpDuration.observe(labels, sec);
    if (req.path !== "/metrics" && process.env.NODE_ENV !== "test") {
      console.log(JSON.stringify({
        ts: new Date().toISOString(), level: "info", msg: "http_request",
        requestId: id, method: req.method, route, status: res.statusCode,
        durationMs: Math.round(sec * 1000),
      }));
    }
  });
  next();
}

async function metricsHandler(req, res) {
  res.set("Content-Type", registry.contentType);
  res.end(await registry.metrics());
}

module.exports = { observability, metricsHandler };
