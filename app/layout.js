import "./globals.css";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

export const metadata = {
  title: "DevSecOps Portfolio",
  description: "Portfolio DevSecOps : Git, Docker, Jenkins, Kubernetes, Ansible, Terraform, Argo CD",
};

export default function RootLayout({ children }) {
  return (
    <html lang="fr">
      <body>
        <Header />
        <main>{children}</main>
        <Footer />
      </body>
    </html>
  );
}
