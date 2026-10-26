export const dynamic = "force-dynamic";

export async function POST(request) {
  const body = await request.json().catch(() => null);
  try {
    const res = await fetch(`${process.env.API_URL}/api/contact`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Forwarded-For": request.headers.get("x-forwarded-for") ?? "",
      },
      body: JSON.stringify(body),
    });
    const data = await res.json().catch(() => ({}));
    return Response.json(data, { status: res.status });
  } catch {
    return Response.json({ error: "API indisponible" }, { status: 502 });
  }
}
