import About from "@/components/About";
import Skills from "@/components/Skills";
import Projects from "@/components/Projects";
import Experience from "@/components/Experience";
import Contact from "@/components/Contact";

export default function Home() {
  return (
    <>
      <About />
      <Skills />
      <Projects limit={3} />
      <Experience />
      <Contact />
    </>
  );
}
