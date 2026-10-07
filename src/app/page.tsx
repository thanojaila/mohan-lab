import type { Metadata } from "next";
import Link from "next/link";
import { LoadingImage } from "./components/LoadingImage";
import { StudyCallout } from "./components/StudyCallout";
import { heroImage, latestNews, projects } from "./lib/content";
import { pageMetadata } from "./lib/metadata";

export const metadata: Metadata = pageMetadata(
  "Translational Research at the University of Houston",
  "Mohan Lab combines high-plex omics, biomarkers, AI, and bioengineering to understand lupus and other complex diseases—and move discoveries toward patient care.",
);

const focusAreas = [
  { number: "/01", title: "Disease mechanisms", text: "Spatial and high-plex omics reveal the molecular systems driving lupus, kidney injury, cancer, and inflammatory disease." },
  { number: "/02", title: "Biomarkers & diagnostics", text: "Liquid biopsy and biomarker programs seek precise, less invasive ways to diagnose disease and monitor activity." },
  { number: "/03", title: "Translational bioengineering", text: "AI, microfluidics, 3D models, and rapid tests turn biological findings into tools for research and clinical care." },
];

const expertiseItems = ["Lupus nephritis", "High-plex omics", "Biomarkers", "Liquid biopsy", "AI & digital health", "Bioengineering"];

export default function Home() {
  return (
    <>
      <section className="home-hero">
        <figure className="hero-photo-stage">
          <LoadingImage
            src={heroImage}
            alt="Mohan Lab researchers at the University of Houston"
            width={1800}
            height={809}
            sizes="100vw"
            priority
          />
          <div className="hero-photo-wash" aria-hidden="true" />
          <div className="shell hero-photo-title">
            <div className="hero-kicker">University of Houston · Biomedical Engineering</div>
            <h1>Mohan Lab</h1>
          </div>
        </figure>
        <div className="hero-copy-band">
          <div className="shell hero-intro-grid">
            <p>
              <strong>Translational biomedical research in autoimmunity, cancer, and chronic disease.</strong>
              {" "}We combine immunology, high-plex omics, data science, and bioengineering to study disease mechanisms and improve diagnosis.
            </p>
            <div className="hero-actions">
              <Link className="button button-primary" href="/research">Research projects <span>→</span></Link>
              <Link className="button button-ghost" href="/people">Lab members</Link>
            </div>
          </div>
        </div>
        <div className="hero-photo-caption">
          <div className="shell">
            <span>Biomedical Engineering · Houston, Texas</span>
            <span>Mohan Lab team</span>
          </div>
        </div>
      </section>

      <StudyCallout />
      <div className="expertise-strip" aria-label="Mohan Lab research areas">
        <div className="shell expertise-grid">
          {expertiseItems.map((item) => (
            <div className="expertise-item" key={item}>{item}</div>
          ))}
        </div>
      </div>

      <section className="mission-band">
        <div className="shell mission-grid">
          <div className="mission-copy">
            <span className="eyebrow">Research overview</span>
            <h2>Connecting disease biology with measurement.</h2>
            <p>
              The lab studies molecular mechanisms of disease and develops biomarkers, assays, and computational methods for diagnosis and monitoring.
            </p>
            <Link className="text-link" href="/research">View all research projects <span>→</span></Link>
          </div>
          <div className="mission-visual">
            <LoadingImage
              src={projects[0]?.image || heroImage}
              alt="Spatial omics research from the Mohan Lab"
              width={1400}
              height={960}
              sizes="(max-width: 820px) 100vw, 60vw"
            />
            <div className="mission-note"><strong>Spatial and high-plex omics</strong><span>Mechanisms · biomarkers · clinical translation</span></div>
          </div>
        </div>
      </section>

      <section className="focus-section section-pad">
        <div className="shell">
          <div className="section-heading split-heading">
            <div><span className="eyebrow">Research areas</span><h2>Current areas of investigation</h2></div>
            <p>Projects span autoimmune disease, cancer, chronic illness, diagnostics, and biomedical engineering.</p>
          </div>
          <div className="focus-grid">
            {focusAreas.map((focus) => (
              <article className="focus-card" key={focus.number}>
                <span>{focus.number}</span>
                <h3>{focus.title}</h3>
                <p>{focus.text}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="featured-research section-pad">
        <div className="shell">
          <div className="section-heading split-heading light">
            <div><span className="eyebrow light">Research</span><h2>Selected projects</h2></div>
            <Link className="text-link light" href="/research">View all {projects.length} projects <span>→</span></Link>
          </div>
          <div className="project-showcase">
            {projects.slice(0, 4).map((project, index) => (
              <Link className={`showcase-card card-${index + 1}`} href={`/research/${project.slug}`} key={project.slug}>
                <LoadingImage
                  src={project.image}
                  alt=""
                  width={720}
                  height={480}
                  sizes="(max-width: 820px) 100vw, 25vw"
                />
                <div className="showcase-overlay" />
                <div className="showcase-copy">
                  <span>{project.category}</span>
                  <h3>{project.title}</h3>
                  <i aria-hidden="true">↗</i>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </section>

      <section className="people-feature section-pad">
        <div className="shell people-feature-grid">
          <div className="people-group-photo">
            <LoadingImage
              src={heroImage}
              alt="Mohan Lab faculty, staff, and trainees gathered for a full lab photograph"
              width={1800}
              height={809}
              sizes="(max-width: 820px) 100vw, 60vw"
            />
          </div>
          <div className="people-copy">
            <span className="eyebrow">People</span>
            <h2>Faculty, staff, and trainees</h2>
            <p>Engineers, data scientists, physicians, and molecular researchers work together across projects, methods, and stages of training.</p>
            <Link className="button button-dark" href="/people">View lab members <span>→</span></Link>
          </div>
        </div>
      </section>

      <section className="news-section section-pad">
        <div className="shell">
          <div className="section-heading split-heading">
            <div><span className="eyebrow">News</span><h2>Recent lab activity</h2></div>
            <Link className="text-link" href="/news">News and events <span>→</span></Link>
          </div>
          <div className="news-grid">
            {latestNews.slice(0, 3).map((item) => (
              <Link className="news-card" href="/news" key={item.title}>
                <div className="news-image">
                  <LoadingImage src={item.image} alt="" width={800} height={500} sizes="(max-width: 820px) 100vw, 33vw" />
                </div>
                <span>{item.date}</span>
                <h3>{item.title}</h3>
                <p>{item.detail}</p>
              </Link>
            ))}
          </div>
        </div>
      </section>

      <section className="join-cta">
        <div className="shell join-grid">
          <div><span className="eyebrow light">Opportunities</span><h2>Research training at Mohan Lab</h2></div>
          <div><p>Information for high school interns, undergraduates, graduate students, and visiting scholars.</p><Link className="button button-white" href="/opportunities">View opportunities <span>→</span></Link></div>
        </div>
      </section>
      <span style={{ display: "none" }} data-ci-cd-check="ok" />
    </>
  );
}
