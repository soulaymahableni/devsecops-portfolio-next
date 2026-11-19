/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "standalone",
  // Q226 : paquets OpenTelemetry charges depuis node_modules (et copies dans le mode standalone)
  serverExternalPackages: [
    "@opentelemetry/resources",
    "@opentelemetry/sdk-trace-node",
    "@opentelemetry/exporter-trace-otlp-http",
  ],
};

export default nextConfig;
