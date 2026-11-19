import { tracedFetch } from "@/lib/tracing";

export const dynamic = "force-dynamic";

export async function POST(request) {
  const body = await request.json().catch(() => null);
  // Identifiant de correlation : reutilise celui du navigateur s'il est valide, sinon genere
  const recu = request.headers.get("x-request-id") ?? "";
  const requestId = /^[\w-]{8,64}$/.test(recu) ? recu : undefined;
  try {
    const res = await tracedFetch(`${process.env.API_URL}/api/contact`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Forwarded-For": request.headers.get("x-forwarded-for") ?? "",
      },
      body: JSON.stringify(body),
    }, requestId);
    const data = await res.json().catch(() => ({}));
    return Response.json(data, {
      status: res.status,
      headers: { "X-Request-Id": res.headers.get("x-request-id") ?? "" },
    });
  } catch {
    return Response.json({ error: "API indisponible" }, { status: 502 });
  }
}
