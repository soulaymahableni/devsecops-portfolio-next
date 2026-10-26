import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { describe, test, expect, vi, afterEach } from "vitest";
import Contact from "../components/Contact";

afterEach(() => vi.restoreAllMocks());

function remplir() {
  fireEvent.change(screen.getByPlaceholderText("Nom"), { target: { name: "name", value: "Soulayma" } });
  fireEvent.change(screen.getByPlaceholderText("Email"), { target: { name: "email", value: "test@example.com" } });
  fireEvent.change(screen.getByPlaceholderText("Message"), { target: { name: "message", value: "Bonjour, ceci est un test" } });
}

describe("Formulaire Contact", () => {
  test("affiche les trois champs et le bouton", () => {
    render(<Contact />);
    expect(screen.getByPlaceholderText("Nom")).toBeInTheDocument();
    expect(screen.getByPlaceholderText("Email")).toBeInTheDocument();
    expect(screen.getByPlaceholderText("Message")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Envoyer" })).toBeInTheDocument();
  });

  test("affiche le succès quand l'API répond 201", async () => {
    global.fetch = vi.fn().mockResolvedValue({ ok: true, status: 201, json: async () => ({ message: "Message reçu" }) });
    render(<Contact />);
    remplir();
    fireEvent.click(screen.getByRole("button", { name: "Envoyer" }));
    await waitFor(() => expect(screen.getByText(/envoyé avec succès/i)).toBeInTheDocument());
  });

  test("affiche une erreur quand l'API répond 400", async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: false, status: 400,
      json: async () => ({ error: "Données invalides", details: [{ field: "email", message: "Invalid email address" }] }),
    });
    render(<Contact />);
    remplir();
    fireEvent.click(screen.getByRole("button", { name: "Envoyer" }));
    await waitFor(() => expect(screen.getByText(/Données invalides/)).toBeInTheDocument());
  });
});
