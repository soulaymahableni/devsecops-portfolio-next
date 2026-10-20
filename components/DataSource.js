export default function DataSource({ source }) {
  const fromApi = source === "api";
  return (
    <p className={`source ${fromApi ? "source-api" : "source-local"}`}>
      {fromApi ? "✅ Données fournies par l'API Express" : "⚠️ API indisponible : données locales"}
    </p>
  );
}
