// Q226 : point d'entree OpenTelemetry de Next.js.
// Le SDK n'est charge que dans le runtime Node et seulement si un collecteur est configure.
export async function register() {
  if (process.env.NEXT_RUNTIME === "nodejs" && process.env.OTEL_EXPORTER_OTLP_ENDPOINT) {
    await import("./instrumentation.node.js");
  }
}
