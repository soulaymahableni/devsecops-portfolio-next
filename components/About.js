import { getProfile } from "@/lib/api";
import DataSource from "@/components/DataSource";

export default async function About() {
  const { data: profile, source } = await getProfile();

  return (
    <section id="about" className="section">
      <h1>{profile.name}</h1>
      <h2>{profile.title}</h2>
      <DataSource source={source} />
      <p>{profile.about}</p>
      {profile.location && <p>📍 {profile.location}</p>}
    </section>
  );
}
