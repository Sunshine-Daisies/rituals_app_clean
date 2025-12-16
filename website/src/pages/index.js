import React from 'react';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={styles.heroBanner}>
      <img src="img/logo.png" className={styles.giantLogo} alt="Background Logo" />
      <div className="container">
        <h1 className="hero__title">{siteConfig.title}</h1>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className={styles.heroButtonPrimary}
            to="/docs/intro">
            Get Started 🚀
          </Link>
          <Link
            className={styles.heroButtonSecondary}
            to="https://github.com/Sunshine-Daisies/rituals_app_clean">
            GitHub 💻
          </Link>
        </div>
        
        <div className={styles.techStack}>
          <span>Flutter</span>
          <span className={styles.dot}>•</span>
          <span>Node.js</span>
          <span className={styles.dot}>•</span>
          <span>TypeScript</span>
          <span className={styles.dot}>•</span>
          <span>Docker</span>
          <span className={styles.dot}>•</span>
          <span>Firebase</span>
        </div>
      </div>
    </header>
  );
}

export default function Home() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={`Hello from ${siteConfig.title}`}
      description="Rituals App Technical Documentation">
      <HomepageHeader />
      <main>
      </main>
    </Layout>
  );
}
