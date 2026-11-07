import React, {useState} from 'react';
import Link from '@docusaurus/Link';
import useLandingCopy from '@site/src/components/landingCopy';
import HeroBoard from './HeroBoard';
import styles from './styles.module.css';

export default function HeroSection(): React.JSX.Element {
  const {hero, cta} = useLandingCopy();
  const [paused, setPaused] = useState(false);

  return (
    <section className={styles.hero} data-paused={paused}>
      <div className={styles.gridBackdrop} aria-hidden="true" />

      <div className={`container ${styles.heroContainer}`}>
        <div className={styles.heroHead}>
          <h1 className={`${styles.heroTitle} ${styles.animateIn} ${styles.delay1}`}>
            {hero.title}
            <span className={styles.titleAccent}>{hero.titleAccent}</span>
          </h1>
          <p className={`${styles.heroSubtitle} ${styles.animateIn} ${styles.delay2}`}>{hero.subtitle}</p>
          <div className={`${styles.actions} ${styles.animateIn} ${styles.delay3}`}>
            <a
              className={styles.primary}
              href={`mailto:thunnv@katalyst.vn?subject=${encodeURIComponent(cta.mailSubject)}`}
            >
              {hero.primary}
            </a>
            <Link className={styles.secondary} to="/docs/get-started/introduction">
              {hero.secondary}
            </Link>
          </div>
        </div>

        <div className={`${styles.animateIn} ${styles.delay4}`}>
          <HeroBoard copy={hero.board} />
        </div>
      </div>

      <button
        type="button"
        className={styles.pause}
        aria-label={paused ? hero.play : hero.pause}
        aria-pressed={paused}
        onClick={() => setPaused(!paused)}
      >
        {paused ? (
          <svg viewBox="0 0 16 16" aria-hidden="true"><path d="M5 3.5v9l7-4.5z" /></svg>
        ) : (
          <svg viewBox="0 0 16 16" aria-hidden="true"><path d="M5 3.5h2v9H5zM9 3.5h2v9H9z" /></svg>
        )}
      </button>
    </section>
  );
}
