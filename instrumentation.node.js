// Q226 : fournisseur de traces du frontend, envoye en OTLP/HTTP vers Tempo.
import { resourceFromAttributes } from "@opentelemetry/resources";
import { NodeTracerProvider, BatchSpanProcessor } from "@opentelemetry/sdk-trace-node";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";

const endpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT.replace(/\/$/, "");

const provider = new NodeTracerProvider({
  resource: resourceFromAttributes({
    "service.name": process.env.OTEL_SERVICE_NAME || "portfolio-frontend",
    "deployment.environment.name": process.env.DEPLOY_ENV || "inconnu",
  }),
  spanProcessors: [
    new BatchSpanProcessor(new OTLPTraceExporter({ url: `${endpoint}/v1/traces` }), {
      scheduledDelayMillis: 2000,
    }),
  ],
});

// register() installe aussi le gestionnaire de contexte (AsyncLocalStorage) et la propagation W3C :
// sans cela, les spans de Next.js et les notres ne seraient pas rattaches a la meme trace.
provider.register();
