// Q227 : appel de l'API avec propagation de la trace (traceparent) et de l'identifiant
// de correlation (X-Request-Id). Sans OpenTelemetry actif, seul X-Request-Id est envoye.
import { randomUUID } from "node:crypto";
import { trace, SpanKind, SpanStatusCode, isSpanContextValid } from "@opentelemetry/api";

const tracer = trace.getTracer("portfolio-frontend");

function journal(champs) {
  if (process.env.NODE_ENV === "test") return;
  console.log(JSON.stringify({ ts: new Date().toISOString(), service: "portfolio-frontend", ...champs }));
}

export function tracedFetch(url, init = {}, requestId = randomUUID()) {
  const cible = new URL(url);
  const method = init.method || "GET";
  return tracer.startActiveSpan(
    `${method} ${cible.pathname}`,
    {
      kind: SpanKind.CLIENT,
      attributes: {
        "http.request.method": method,
        "url.full": `${cible.origin}${cible.pathname}`,
        "peer.service": "portfolio-api",
        "request.id": requestId,
      },
    },
    async (span) => {
      const contexte = span.spanContext();
      const traceId = isSpanContextValid(contexte) ? contexte.traceId : undefined;
      const headers = new Headers(init.headers);
      headers.set("X-Request-Id", requestId);
      if (traceId) headers.set("traceparent", `00-${traceId}-${contexte.spanId}-0${contexte.traceFlags & 1}`);
      const debut = Date.now();
      try {
        const res = await fetch(url, { ...init, headers });
        span.setAttribute("http.response.status_code", res.status);
        if (res.status >= 500) span.setStatus({ code: SpanStatusCode.ERROR });
        journal({ level: "info", msg: "api_call", requestId, traceId, method, path: cible.pathname, status: res.status, durationMs: Date.now() - debut });
        return res;
      } catch (err) {
        span.setStatus({ code: SpanStatusCode.ERROR, message: err.message });
        journal({ level: "error", msg: "api_call_failed", requestId, traceId, method, path: cible.pathname, error: err.message, durationMs: Date.now() - debut });
        throw err;
      } finally {
        span.end();
      }
    },
  );
}
