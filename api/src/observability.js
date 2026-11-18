// Q220-Q223 : metriques Prometheus + identifiant de correlation + journal JSON
// Q226-Q228 : traces OpenTelemetry (actives seulement si OTEL_EXPORTER_OTLP_ENDPOINT est defini)
const client = require("prom-client");
const { randomUUID } = require("crypto");
const { SpanKind, SpanStatusCode, ROOT_CONTEXT, trace, isSpanContextValid } = require("@opentelemetry/api");

// Q227 : reprend la trace envoyee par le frontend (en-tete W3C traceparent)
const TRACEPARENT = /^00-([0-9a-f]{32})-([0-9a-f]{16})-([0-9a-f]{2})$/;
function contexteParent(entete) {
  const m = typeof entete === "string" ? TRACEPARENT.exec(entete) : null;
  if (!m) return ROOT_CONTEXT;
  const sc = { traceId: m[1], spanId: m[2], traceFlags: parseInt(m[3], 16) & 1, isRemote: true };
  return isSpanContextValid(sc) ? trace.setSpanContext(ROOT_CONTEXT, sc) : ROOT_CONTEXT;
}

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

let tracer = null;
if (process.env.OTEL_EXPORTER_OTLP_ENDPOINT) {
  const { BasicTracerProvider, BatchSpanProcessor } = require("@opentelemetry/sdk-trace-base");
  const { OTLPTraceExporter } = require("@opentelemetry/exporter-trace-otlp-http");
  const { resourceFromAttributes } = require("@opentelemetry/resources");
  const provider = new BasicTracerProvider({
    resource: resourceFromAttributes({
      "service.name": process.env.OTEL_SERVICE_NAME || "portfolio-api",
      "deployment.environment.name": process.env.DEPLOY_ENV || "inconnu",
    }),
    spanProcessors: [
      new BatchSpanProcessor(
        new OTLPTraceExporter({ url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT.replace(/\/$/, "") + "/v1/traces" }),
        { scheduledDelayMillis: 2000 }
      ),
    ],
  });
  tracer = provider.getTracer("portfolio-api");
}

function observability(req, res, next) {
  const incoming = req.headers["x-request-id"];
  const id = typeof incoming === "string" && /^[\w-]{8,64}$/.test(incoming) ? incoming : randomUUID();
  req.id = id;
  res.setHeader("X-Request-Id", id);
  const span = tracer
    ? tracer.startSpan(
        req.method + " " + req.path,
        {
          kind: SpanKind.SERVER,
          attributes: { "http.request.method": req.method, "url.path": req.path, "request.id": id },
        },
        contexteParent(req.headers.traceparent)
      )
    : null;
  req.span = span;
  const traceId = span ? span.spanContext().traceId : undefined;
  if (traceId) res.setHeader("X-Trace-Id", traceId);
  const start = process.hrtime.bigint();
  res.on("finish", () => {
    const sec = Number(process.hrtime.bigint() - start) / 1e9;
    const route = req.route ? req.baseUrl + req.route.path : "non_trouvee";
    const labels = { method: req.method, route, status: String(res.statusCode) };
    httpTotal.inc(labels);
    httpDuration.observe(labels, sec);
    if (span) {
      span.updateName(req.method + " " + route);
      span.setAttribute("http.route", route);
      span.setAttribute("http.response.status_code", res.statusCode);
      if (res.statusCode >= 500) span.setStatus({ code: SpanStatusCode.ERROR });
      span.end();
    }
    if (req.path !== "/metrics" && process.env.NODE_ENV !== "test") {
      console.log(JSON.stringify({
        ts: new Date().toISOString(), level: "info", msg: "http_request",
        requestId: id, traceId, method: req.method, route, status: res.statusCode,
        durationMs: Math.round(sec * 1000),
      }));
    }
  });
  next();
}

// Q228 : span enfant (Postgres, Floci...) rattache a la requete courante
async function withSpan(req, name, attributes, fn) {
  if (!tracer || !req.span) return fn();
  const span = tracer.startSpan(name, { kind: SpanKind.CLIENT, attributes }, trace.setSpan(ROOT_CONTEXT, req.span));
  try {
    return await fn();
  } catch (err) {
    span.setStatus({ code: SpanStatusCode.ERROR, message: err.name });
    throw err;
  } finally {
    span.end();
  }
}

async function metricsHandler(req, res) {
  res.set("Content-Type", registry.contentType);
  res.end(await registry.metrics());
}

module.exports = { observability, metricsHandler, withSpan };
