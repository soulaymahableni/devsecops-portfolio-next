"use client";
import { useState } from "react";

export default function Contact() {
  const [form, setForm] = useState({ name: "", email: "", message: "" });
  const [status, setStatus] = useState(null);

  const onChange = (e) => setForm({ ...form, [e.target.name]: e.target.value });

  async function onSubmit(e) {
    e.preventDefault();
    setStatus({ type: "info", text: "Envoi en cours..." });
    try {
      const res = await fetch("/api/contact", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(form),
      });
      const data = await res.json();
      if (res.ok) {
        setStatus({ type: "ok", text: "Message envoyé avec succès !" });
        setForm({ name: "", email: "", message: "" });
      } else if (res.status === 429) {
        setStatus({ type: "error", text: "Trop de messages, réessayez plus tard." });
      } else {
        const details = (data.details || []).map((d) => `${d.field} : ${d.message}`).join(" | ");
        setStatus({ type: "error", text: data.error + (details ? ` (${details})` : "") });
      }
    } catch {
      setStatus({ type: "error", text: "Erreur réseau." });
    }
  }

  return (
    <section id="contact" className="section">
      <h2>Contact</h2>
      <p>Email : <a href="mailto:hablenisoulayma@gmail.com">hablenisoulayma@gmail.com</a></p>
      <p>GitHub : <a href="https://github.com/soulaymahableni">github.com/soulaymahableni</a></p>

      <form onSubmit={onSubmit} style={{ display: "grid", gap: "0.75rem", maxWidth: 480, marginTop: "1rem" }}>
        <input name="name" placeholder="Nom" value={form.name} onChange={onChange} required />
        <input name="email" type="email" placeholder="Email" value={form.email} onChange={onChange} required />
        <textarea name="message" placeholder="Message" rows={5} value={form.message} onChange={onChange} required />
        <button type="submit">Envoyer</button>
        {status && <p role="status">{status.text}</p>}
      </form>
    </section>
  );
}
